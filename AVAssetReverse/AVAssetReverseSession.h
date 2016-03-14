//
//  AVAssetReverseSession.h
//
//  AVAssetReverse
//
//  Created by Leon.yan on 3/11/16.
//  Copyright © 2016 wantu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/*!
 * @typedef AVAssetReverseSessionStatus
 * @brief A list of reverse session status.
 */
typedef enum {
    /// unknow, mostly init
    AVAssetReverseSessionStatusUnknown,
    /// Reverse session is preparing.
    AVAssetReverseSessionStatusWaiting,
    /// reversing
    AVAssetReverseSessionStatusReversing,
    /// reverse completed
    AVAssetReverseSessionStatusCompleted,
    /// reverse failed, call error get error information
    AVAssetReverseSessionStatusFailed,
    /// reverse is canceled by user
    AVAssetReverseSessionStatusCancelled
} AVAssetReverseSessionStatus;

@interface AVAssetReverseSession : NSObject

@property (nonatomic, readonly,  strong) AVAsset *asset;
@property (nonatomic, readonly,  assign) AVAssetReverseSessionStatus status;
@property (nonatomic, readwrite, assign) CMTimeRange timeRange;
@property (nonatomic, readwrite, strong) NSURL *outputURL;
@property (nonatomic, readwrite, strong) NSString *outputFileType;
@property (nonatomic, readwrite, strong) NSError *error;
@property (nonatomic, readonly,  assign) float progress;

+ (NSArray<NSString *> *)supportOutputFileTypes;

- (instancetype)initWithAsset:(AVAsset *)asset;
- (void)reverseAsynchronouslyWithCompletionHandler:(void (^)(void))handler;
- (void)cancelReverse;

@end
