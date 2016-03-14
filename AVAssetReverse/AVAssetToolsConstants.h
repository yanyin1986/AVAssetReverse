//
//  AVAssetToolsConstants.h
//  YoungCam
//
//  Created by Leon.yan on 3/11/16.
//  Copyright © 2016 wantu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVAssetToolsMacros.h"

AVT_EXTERN NSString *const AVTErrorDomain;

typedef NS_ENUM(NSInteger, AVTErrorCode)
{
    /// --- current aasset
    /// current avasset has no video tracks
    AVTErrorCodeHasNoVideoTracks            = 330,
    
    /// --- outputFile
    /// current output file is not set, is nil
    AVTErrorCodeOutputFileNotSet            = 401,
    /// error when check current output file
    AVTErrorCodeOutputFileError             = 402,
    /// error when has no enough space for reversing
    AVTErrorCodeOutputFileNoEnoughSpace     = 403,
    
    /// --- outputFileType
    /// current output file type is not set, is nil
    AVTErrorCodeOutputFileTypeNotSet        = 431,
    /// current output file type is wrong, check
    /// @related [AVAssetReverseSession supportOutputFileTypes]
    AVTErrorCodeOutputFileTypeError         = 432,

    
};