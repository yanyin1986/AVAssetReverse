//
//  ViewController.m
//  AVAssetReverse
//
//  Created by Leon.yan on 8/13/15.
//  Copyright (c) 2015 Leon.yan. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AVUtilities.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"IMG_0287" withExtension:@"MOV"];
    AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
    
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *outPath = [path stringByAppendingPathComponent:@"video.m4v"];
    [[NSFileManager defaultManager] removeItemAtPath:outPath error:nil];
    NSURL *outURL = [NSURL fileURLWithPath:outPath];
    [AVUtilities assetByReversingAsset:asset outputURL:outURL completion:^{
        NSLog(@"!!!%@", outURL);
    }];
//    [AVUtilities assetByReversingAsset:asset outputURL:; completion:;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
