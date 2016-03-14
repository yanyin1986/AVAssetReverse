//
//  AVAssetToolsMacros.h
//  YoungCam
//
//  Created by Leon.yan on 3/11/16.
//  Copyright © 2016 wantu. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#define AVT_EXTERN extern "C" __attribute__((visibility ("default")))
#else
#define AVT_EXTERN extern __attribute__((visibility ("default")))
#endif

#define AVT_STATIC_INLINE static inline
