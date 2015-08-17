
#import "AVUtilities.h"
#import <AVFoundation/AVFoundation.h>

@implementation AVUtilities

+ (void)assetByReversingAsset:(AVAsset *)asset outputURL:(NSURL *)outputURL completion:(void (^)(void))handler {
    
    NSError *error;
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    CGSize naturalSize = videoTrack.naturalSize;
    CMTimeScale timeScale = videoTrack.naturalTimeScale;
    //videoTrack.naturalTimeScale -> frameDuration   1/600 ?
    
    float nominalFrameRate = videoTrack.nominalFrameRate;
    CMTime frameRate = videoTrack.minFrameDuration;
    NSLog(@"videoSourceInfo:\n");
    NSLog(@".nominalFrameRate => %g", nominalFrameRate);
    NSLog(@".minFrameDuration => %g", CMTimeGetSeconds(frameRate));
    
    // Initialize the writer
    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:outputURL
                                                      fileType:AVFileTypeAppleM4V
                                                         error:&error];

    NSDictionary *writerOutputSettings = [self writterSettingWithAVAssetTrack:videoTrack];
    AVAssetWriterInput *writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                     outputSettings:writerOutputSettings
                                                                   sourceFormatHint:(__bridge CMFormatDescriptionRef)[videoTrack.formatDescriptions lastObject]];
    [writerInput setExpectsMediaDataInRealTime:NO];
    
    // Initialize an input adaptor so that we can append PixelBuffer
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    [writer addInput:writerInput];
    [writer startWriting];
    CMTime startTime = kCMTimeZero;
    //CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples[0]);
    [writer startSessionAtSourceTime:startTime];
    
    // Initialize the reader
    CMTime durationTime = videoTrack.timeRange.duration;
    CFTimeInterval duration = CMTimeGetSeconds(durationTime);
    CFTimeInterval clipDuration = 3.0;
    NSUInteger clipCount = ceil(duration / clipDuration);
    
    //
    NSLog(@"need to split reader video track to [%ld] clips", clipCount);
    
    CMTime clipTime = CMTimeMakeWithSeconds(clipDuration, videoTrack.naturalTimeScale);
    
    NSMutableArray *timeRanges = [NSMutableArray array];
    CMTime endTime = CMTimeRangeGetEnd(videoTrack.timeRange);
    for (NSUInteger i = 0; i < clipCount; i++) {
        CMTime startTime = CMTimeSubtract(endTime, clipTime);
        CMTime durationTime = clipTime;
        if (CMTimeGetSeconds(startTime) <= 0) {
            startTime = CMTimeMakeWithSeconds(0, timeScale);
            durationTime = endTime;
        }
        
        CMTimeRange r = CMTimeRangeMake(startTime, durationTime);
        NSLog(@"clip[%ld] =>", i);
        CMTimeRangeShow(r);
        
        [timeRanges addObject:[NSValue valueWithCMTimeRange:r]];
        endTime = startTime;
    }
    
    //
    
    NSMutableArray *samples = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < clipCount; i++) {
        @autoreleasepool {
            // read
            AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
            CMTime clipStartTime = CMTimeMakeWithSeconds(clipDuration * i, timeScale);
            CMTimeRange range = [[timeRanges objectAtIndex:i] CMTimeRangeValue];
            reader.timeRange = range;
            NSDictionary *readerOutputSettings = [self readerSetting];
            AVAssetReaderTrackOutput* readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                                                outputSettings:readerOutputSettings];
            [reader addOutput:readerOutput];
            [reader startReading];
            
            CMSampleBufferRef sample;
            while((sample = [readerOutput copyNextSampleBuffer])) {
                [samples addObject:(__bridge id)sample];
                CFRelease(sample);
            }
            
            NSLog(@"------------");
            NSLog(@"startToWriterClip[%ld]", i);
            CMTimeRangeShow(range);
            
            // write
            for(NSInteger i = 0; i < samples.count; i++) {
                // Get the presentation time for the frame
                CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples[i]);
                CMTime newPresentationTime = CMTimeAdd(clipStartTime, CMTimeSubtract(presentationTime, range.start));
                // take the image/pixel buffer from tail end of the array
                CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer((__bridge CMSampleBufferRef)samples[samples.count - i - 1]);
                while (!writerInput.readyForMoreMediaData) {
                    [NSThread sleepForTimeInterval:0.05];
                }
                NSLog(@"append image at %g", CMTimeGetSeconds(newPresentationTime));
                [pixelBufferAdaptor appendPixelBuffer:imageBufferRef
                                 withPresentationTime:newPresentationTime];
            }
            [samples removeAllObjects];
        }
        
        
    }
    
    while (!writerInput.readyForMoreMediaData) {
        [NSThread sleepForTimeInterval:0.1];
    }
    
    [writerInput markAsFinished];
    [writer finishWritingWithCompletionHandler:^{
        NSLog(@"!%@", writer);
        handler();
    }];
}

+ (NSDictionary *)readerSetting {
    return @{
             (__bridge id) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
             };
}

+ (NSDictionary *)writterSettingWithAVAssetTrack:(AVAssetTrack *)videoTrack {
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
