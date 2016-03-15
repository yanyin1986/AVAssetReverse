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
#import "AVAssetReverseSession.h"

@interface ViewController ()

@property (nonatomic, weak  ) IBOutlet UIButton *reverseButton;
@property (nonatomic, weak  ) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak  ) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak  ) IBOutlet UILabel *infoLabel;

@property (nonatomic, strong) AVAssetReverseSession *reverseSession;
@property (nonatomic, strong) NSTimer *reverseTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"IMG_0287" withExtension:@"MOV"];
    AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
    AVAssetReverseSession *session = [[AVAssetReverseSession alloc] initWithAsset:asset];
    NSString *outputURL = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputURL]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputURL error:nil];
    }
    session.outputFileType = AVFileTypeMPEG4;
    session.outputURL = [NSURL fileURLWithPath:outputURL];
    [session reverseAsynchronouslyWithCompletionHandler:^{
        NSLog(@"finished");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)reverse:(id)sender
{
    if (!_reverseSession) {
        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"IMG_2246" withExtension:@"MOV"];
        AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
        AVAssetReverseSession *session = [[AVAssetReverseSession alloc] initWithAsset:asset];
        NSString *outputURL = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.mp4"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:outputURL]) {
            [[NSFileManager defaultManager] removeItemAtPath:outputURL error:nil];
        }
        session.outputFileType = AVFileTypeMPEG4;
        session.outputURL = [NSURL fileURLWithPath:outputURL];
        NSDate *startTime = [NSDate new];
        NSTimer *checkTimer = [NSTimer
                               scheduledTimerWithTimeInterval:1.0 / 10.0
                               target:self
                               selector:@selector(checkStatus:)
                               userInfo:nil
                               repeats:YES];
        _reverseTimer = checkTimer;
        [session reverseAsynchronouslyWithCompletionHandler:^{
            if (session.status == AVAssetReverseSessionStatusCompleted) {
                NSLog(@"finished");
            } else {
                NSLog(@"rever failed");
            }
            [self finishedWithTime:(-[startTime timeIntervalSinceNow])];
        }];
        
        _reverseSession = session;
        _cancelButton.enabled = YES;
    }
}

- (IBAction)cancel:(id)sender
{
    if (_reverseSession) {
        _cancelButton.enabled = NO;
        [_reverseSession cancelReverse];
    }
}

- (void)checkStatus:(id)sender
{
    if (_reverseSession) {
        _progressView.progress = _reverseSession.progress;
    }
}

- (void)finishedWithTime:(NSTimeInterval)time
{
    NSString *message = [NSString stringWithFormat:@"time spent: %g", time];
    _infoLabel.text = message;
    _reverseSession = nil;
    [_reverseTimer invalidate];
    _reverseTimer = nil;
    _cancelButton.enabled = NO;
}


@end
