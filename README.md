# ReleaseNote
* v1.1 - adjust the code struct. everything is changed, it's simpler to use.
* v1.0 - first version.

# AVAssetReverse
It's a simple way to reverse a video. I did a big adjustment in last version. Just use it like AVAssetExportSession.

# Feature
1. reverse a video
2. special a time range
3. special output file type and URL
4. most effective

# Useage

Here is a example:

```objective-c
    AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
    AVAssetReverseSession *session = [[AVAssetReverseSession alloc] initWithAsset:asset];

    NSURL *outputURL = ...;

    session.outputFileType = AVFileTypeMPEG4; // special output file type
    session.outputURL = outputURL; // special output file URL
    session.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(1200, 600)); // special special reverse clip
    [session reverseAsynchronouslyWithCompletionHandler:^{
        // finished
    }];

```

# Will do

1. speed changable

# Related
1. [VideoReverse](https://github.com/KayWong/VideoReverse)
2. [ReverseClip](https://github.com/mikaelhellqvist/ReverseClip)
3. [ReverseAVAsset](https://github.com/whydna/ReverseAVAsset)


# Contact
Email me to: [yanyin1986@gmail.com](mailto:yanyin1986@gmail.com)
