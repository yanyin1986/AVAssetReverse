# AVAssetReverse
reverse a video

# Useage

```objectivec

+ (void)assetByReversingAsset:(AVAsset *)asset 
                    outputURL:(NSURL *)outputURL 
                   completion:(void (^)(void))handler;

```
reverse an asset to outputURL, now only support mp4 file.

```objectivec

+ (void)assetByReversingOfTimeRange:(CMTimeRange)timeRange 
                            OfAsset:(AVAsset *)asset 
                          outputURL:(NSURL *)outputURL 
                        completion:(void (^)(void))handler;

```
reverse a clip timeRange to an outputURL.

# Feature
you can reverse a special timeRange of the asset.
Won't crash if the asset is too long time.

# Will do

1. speed changable

