#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AVAsset;

@interface AVUtilities : NSObject

+ (void)assetByReversingOfTimeRange:(CMTimeRange)timeRange OfAsset:(AVAsset *)asset outputURL:(NSURL *)outputURL completion:(void (^)(void))handler;
+ (void)assetByReversingAsset:(AVAsset *)asset outputURL:(NSURL *)outputURL completion:(void (^)(void))handler;

@end
