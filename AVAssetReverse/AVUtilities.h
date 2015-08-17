#import <Foundation/Foundation.h>

@class AVAsset;

@interface AVUtilities : NSObject

+ (void)assetByReversingAsset:(AVAsset *)asset outputURL:(NSURL *)outputURL completion:(void (^)(void))handler;

@end
