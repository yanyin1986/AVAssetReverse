//
//  AVAssetReverseSession.m
//  YoungCam
//
//  Created by Leon.yan on 3/11/16.
//  Copyright © 2016 wantu. All rights reserved.
//

#import "AVAssetReverseSession.h"
#import "AVAssetToolsConstants.h"

@interface AVAssetReverseSession()

@property (nonatomic, assign) BOOL canceled;
@property (nonatomic, assign) CMTime durationTime;
@property (nonatomic, assign) CMTime writenTime;

#if OS_OBJECT_HAVE_OBJC_SUPPORT == 1
@property (nonatomic, strong) dispatch_queue_t appendQueue;
#else
@property (nonatomic, assign) dispatch_queue_t appendQueue;
#endif

@end

@implementation AVAssetReverseSession

+ (NSArray<NSString *> *)supportOutputFileTypes
{
    return @[AVFileTypeAppleM4V,
             AVFileTypeMPEG4,
             AVFileTypeQuickTimeMovie];
}

- (instancetype)initWithAsset:(AVAsset *)asset
{
    self = [super init];
    if (self) {
        _asset = asset;
        _timeRange = kCMTimeRangeInvalid;
        _status = AVAssetReverseSessionStatusUnknown;
        _canceled = NO;
        _durationTime = kCMTimeInvalid;
        _writenTime = kCMTimeInvalid;
        _appendQueue = dispatch_queue_create("appendQueue", NULL);
    }
    return self;
}

- (void)setOutputURL:(NSURL *)outputURL
{
    if (_status == AVAssetReverseSessionStatusUnknown) {
        _outputURL = outputURL;
    } else {
        NSLog(@"can't set outputURL");
    }
}

- (void)setOutputFileType:(NSString *)outputFileType
{
    if (_status == AVAssetReverseSessionStatusUnknown) {
        if ([[[self class] supportOutputFileTypes] containsObject:outputFileType]) {
            _outputFileType = outputFileType;
        } else {
            NSLog(@"output file type not support");
        }
    } else {
        NSLog(@"can't set outputFileType");
    }
}

- (void)setTimeRange:(CMTimeRange)timeRange
{
    if (_status == AVAssetReverseSessionStatusUnknown) {
        _timeRange = timeRange;
    } else {
        NSLog(@"can't set timeRange");
    }
}

- (void)cancelReverse
{
    NSLog(@"cancel reverse..................");
    if (_status == AVAssetReverseSessionStatusReversing && _canceled != YES) {
        _canceled = YES;
    }
}

- (void)reverseAsynchronouslyWithCompletionHandler:(void (^)(void))handler
{
    if (_status == AVAssetReverseSessionStatusCancelled ||
        _status == AVAssetReverseSessionStatusCompleted ||
        _status == AVAssetReverseSessionStatusFailed) {
        NSLog(@"can't reverse asset, it's finished.");
        return;
    }
    
    if (_status == AVAssetReverseSessionStatusReversing) {
        NSLog(@"it's reversing now.");
        return;
    }
    
    if ([[_asset tracksWithMediaType:AVMediaTypeVideo] count] <= 0) {
        NSLog(@"this asset has no video track");
        _error = [NSError errorWithDomain:AVTErrorDomain
                                     code:AVTErrorCodeHasNoVideoTracks
                                 userInfo:nil];
        if (handler) {
            handler();
        }
        return;
    }
    
    if (_outputURL == nil) {
        NSLog(@"please set output file firt");
        _error = [NSError errorWithDomain:AVTErrorDomain
                                     code:AVTErrorCodeOutputFileNotSet
                                 userInfo:nil];
        if (handler) {
            handler();
        }
        return;
    }
    
    if (_outputFileType == nil) {
        NSLog(@"please set output file firt");
        _error = [NSError errorWithDomain:AVTErrorDomain
                                     code:AVTErrorCodeOutputFileTypeNotSet
                                 userInfo:nil];
        if (handler) {
            handler();
        }
        return;
    }
    
    NSDate *start = [NSDate new];
    
    _status = AVAssetReverseSessionStatusWaiting;
    __block NSError *error;
    AVAssetTrack *videoTrack = [[_asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    CMTimeScale timeScale = videoTrack.naturalTimeScale;
    
    float nominalFrameRate = videoTrack.nominalFrameRate;
    CMTime frameRate = videoTrack.minFrameDuration;
    NSLog(@"videoSourceInfo:\n");
    NSLog(@".nominalFrameRate => %g", nominalFrameRate);
    NSLog(@".minFrameDuration => %g", CMTimeGetSeconds(frameRate));
    
    // Initialize the writer
    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:_outputURL
                                                      fileType:_outputFileType
                                                         error:&error];
    NSDictionary *writerOutputSettings = [self writterSettingWithAVAssetTrack:videoTrack];
    AVAssetWriterInput *writerInput =
    [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                   outputSettings:writerOutputSettings
                                 sourceFormatHint:(__bridge CMFormatDescriptionRef)[videoTrack.formatDescriptions lastObject]];
    [writerInput setExpectsMediaDataInRealTime:NO];
    [writerInput setTransform:videoTrack.preferredTransform];
    
    // Initialize an input adaptor so that we can append PixelBuffer
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    [writer addInput:writerInput];
    [writer startWriting];
    CMTime startTime = kCMTimeZero;
    [writer startSessionAtSourceTime:startTime];
    
    //
    if (CMTIMERANGE_IS_INVALID(_timeRange)) {
        NSLog(@"time range not set, use whole timeRange");
        _timeRange = videoTrack.timeRange;
    }
    
    CMTimeRange videoTimeRange;
    if (CMTimeRangeEqual(_timeRange, videoTrack.timeRange)) {
        videoTimeRange = videoTrack.timeRange;
    } else {
        videoTimeRange = _timeRange;
    }
    // Initialize the reader
    CMTime durationTime = videoTimeRange.duration;//videoTrack.timeRange.duration;
    CFTimeInterval duration = CMTimeGetSeconds(durationTime);
    
    CGSize naturalSize = videoTrack.naturalSize;
    size_t frameSize = (naturalSize.width * naturalSize.height) * 3 / 2;
    size_t framePerSecondSize = frameSize * nominalFrameRate;
    
    NSLog(@"----------");
    NSLog(@"frame size       -> %zu", frameSize);
    NSLog(@"frame per second -> %zu", framePerSecondSize);
    
    size_t maxSize = 1024 * 1024 * 100;
    
    size_t maxDuration = floorl(maxSize / framePerSecondSize);
    maxDuration = MAX(1.0, maxDuration);
    
    CFTimeInterval clipDuration = maxDuration;
    NSUInteger clipCount = ceil(duration / clipDuration);
    
    _durationTime = durationTime;
    _writenTime = kCMTimeZero;
    //
    NSLog(@"need to split reader video track to [%ld] clips", (unsigned long) clipCount);
    CMTime clipTime = CMTimeMakeWithSeconds(clipDuration, timeScale);
    
    NSMutableArray *timeRanges = [NSMutableArray array];
    
    CMTime endTime = CMTimeRangeGetEnd(videoTimeRange);
    for (NSUInteger i = 0; i < clipCount; i++) {
        CMTime startTime = CMTimeSubtract(endTime, clipTime);
        CMTime durationTime = clipTime;
        if (CMTimeCompare(startTime, videoTimeRange.start) < 0) {
            startTime = videoTimeRange.start;
            durationTime = CMTimeSubtract(endTime, startTime);
        }
        CMTimeRange r = CMTimeRangeMake(startTime, durationTime);
        NSLog(@"clip[%ld] =>", (unsigned long) i);
        CMTimeRangeShow(r);
        
        [timeRanges addObject:[NSValue valueWithCMTimeRange:r]];
        endTime = startTime;
    }
    
    _status = AVAssetReverseSessionStatusReversing;
    //
    __block NSMutableArray *samples = [[NSMutableArray alloc] init];
    dispatch_async(_appendQueue, ^{
        for (NSUInteger i = 0; i < clipCount; i++) {
            @autoreleasepool {
                // read
                AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:_asset error:&error];
                CMTime clipStartTime = CMTimeMakeWithSeconds(clipDuration * i, timeScale);
                CMTimeRange range = [[timeRanges objectAtIndex:i] CMTimeRangeValue];
                reader.timeRange = range;
                NSDictionary *readerOutputSettings = [self readerSetting];
                AVAssetReaderTrackOutput* readerOutput =
                [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                           outputSettings:readerOutputSettings];
                [reader addOutput:readerOutput];
                [reader startReading];
                
                
                CMSampleBufferRef sample;
                while(!_canceled && (sample = [readerOutput copyNextSampleBuffer])) {
                    [samples addObject:(__bridge id)sample];
                    CFRelease(sample);
                }
                
                if (_canceled) {
                    break;
                }
                
                
                NSLog(@"------------");
                NSLog(@"startToWriterClip[%ld]", (unsigned long)i);
                CMTimeRangeShow(range);
                
                // write
                for(NSInteger i = 0; i < samples.count; i++) {
                    // Get the presentation time for the frame
                    CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples[i]);
                    CMTime newPresentationTime = CMTimeAdd(clipStartTime, CMTimeSubtract(presentationTime, range.start));
                    // take the image/pixel buffer from tail end of the array
                    CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer((__bridge CMSampleBufferRef)samples[samples.count - i - 1]);
                    size_t dataSize = CVPixelBufferGetDataSize(imageBufferRef);
                    NSLog(@"data size -> %zu", dataSize);
                    
                    while (!writerInput.readyForMoreMediaData) {
                        [NSThread sleepForTimeInterval:0.05];
                    }
                    NSLog(@"append image at %g", CMTimeGetSeconds(newPresentationTime));
                    [pixelBufferAdaptor appendPixelBuffer:imageBufferRef
                                     withPresentationTime:newPresentationTime];
                    _writenTime = newPresentationTime;
                    if (_canceled) {
                        break;
                    }
                }
                [samples removeAllObjects];
            }
        }
        
        if (_canceled) {
            [writerInput markAsFinished];
            [writer cancelWriting];
            _status = AVAssetReverseSessionStatusCancelled;
            if (handler) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler();
                });
            }
        } else {
            while (!writerInput.readyForMoreMediaData) {
                [NSThread sleepForTimeInterval:0.1];
            }
            
            [writerInput markAsFinished];
            [writer finishWritingWithCompletionHandler:^{
                NSLog(@"time spent -> %f", -[start timeIntervalSinceNow]);
                NSLog(@"!%@", writer);
                if (writer.status == AVAssetWriterStatusCompleted) {
                    _status = AVAssetReverseSessionStatusCompleted;
                } else if (writer.status == AVAssetWriterStatusCancelled) {
                    _status = AVAssetReverseSessionStatusCancelled;
                    NSLog(@"cancelled");
                } else { //(writer.status == AVAssetWriterStatusFailed) {
                    _status = AVAssetReverseSessionStatusFailed;
                }
                
                if (handler) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler();
                    });
                }
            }];
        }
    });
    
}

- (float)progress
{
    if (_status == AVAssetReverseSessionStatusReversing && CMTIME_IS_VALID(_durationTime) && CMTIME_IS_VALID(_writenTime)) {
        return CMTimeGetSeconds(_writenTime) / CMTimeGetSeconds(_durationTime);
    } else {
        return 0.0;
    }
}

- (NSDictionary *)readerSetting
{
    return @{(__bridge id) kCVPixelBufferPixelFormatTypeKey :@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange), };
}

- (NSDictionary *)writterSettingWithAVAssetTrack:(AVAssetTrack *)videoTrack
{
    NSDictionary *videoCompressionProps =
    @{
      AVVideoAverageBitRateKey : @(videoTrack.estimatedDataRate),
      };
    
    NSDictionary *writerOutputSettings =
    @{
      AVVideoCodecKey : AVVideoCodecH264,
      AVVideoWidthKey : @(videoTrack.naturalSize.width),
      AVVideoHeightKey : @(videoTrack.naturalSize.height),
      AVVideoCompressionPropertiesKey : videoCompressionProps,
      };
    return writerOutputSettings;
}

@end
