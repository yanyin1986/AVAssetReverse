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
@property (weak, nonatomic) IBOutlet UIView *playerView;

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

@end
