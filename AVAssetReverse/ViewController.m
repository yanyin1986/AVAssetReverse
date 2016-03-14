//
//  ViewController.m
//  AVAssetReverse
//
//  Created by Leon.yan on 8/13/15.
//  Copyright (c) 2015 Leon.yan. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import <VideoToolbox/VideoToolbox.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *playerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"IMG_0287" withExtension:@"MOV"];
    AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
    
//    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
//    NSString *outPath = [path stringByAppendingPathComponent:@"video.m4v"];
//    [[NSFileManager defaultManager] removeItemAtPath:outPath error:nil];
//    NSURL *outURL = [NSURL fileURLWithPath:outPath];
//    [AVUtilities assetByReversingOfTimeRange:CMTimeRangeMake(CMTimeMake(1, 1), CMTimeMake(2, 1)) OfAsset:asset outputURL:outURL completion:^{
//        NSLog(@"!!!!!!%@", outURL);
//    }];
    AVAssetTrack *originalVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    float fps = originalVideoTrack.nominalFrameRate;
    CMTime minFrameTime = originalVideoTrack.minFrameDuration;
    CMTime duration = originalVideoTrack.timeRange.duration;
    
    Float64 d = CMTimeGetSeconds(duration);
    Float64 m = CMTimeGetSeconds(minFrameTime);
    NSInteger fc = d / m;
    NSInteger frameCount = duration.value / minFrameTime.value;
    
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
  
    CMTime time = kCMTimeZero;
    for (NSInteger i = 1; i <= frameCount; i++) {
        NSLog(@"%ld", i);
        CMTime timedTime = CMTimeMultiply(minFrameTime, (int32_t)i);
        CMTime startTime = CMTimeSubtract(duration, timedTime);
        [videoTrack insertTimeRange:CMTimeRangeMake(startTime, minFrameTime) ofTrack:originalVideoTrack atTime:time error:nil];
        time = CMTimeAdd(time, minFrameTime);
    }
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:composition];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = _playerView.bounds;
    
    [_playerView.layer addSublayer:playerLayer];
    [player play];
    NSLog(@"%@", videoTrack);
    
}

- (void)decodeVideo
{
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"IMG_0287" withExtension:@"MOV"];
    AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
    
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    NSArray *formatDescriptions = videoTrack.formatDescriptions;
    
    
    VTDecompressionSessionRef session;
    /*
    VTDecompressionSessionCreate(kCFAllocatorDefault, <#CMVideoFormatDescriptionRef  _Nonnull videoFormatDescription#>, <#CFDictionaryRef  _Nullable videoDecoderSpecification#>, <#CFDictionaryRef  _Nullable destinationImageBufferAttributes#>, <#const VTDecompressionOutputCallbackRecord * _Nullable outputCallback#>, <#VTDecompressionSessionRef  _Nullable * _Nonnull decompressionSessionOut#>)*/
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
