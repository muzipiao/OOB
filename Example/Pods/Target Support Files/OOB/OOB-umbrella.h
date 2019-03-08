#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "OOB.h"
#import "OOBDefine.h"
#import "OOBManager.h"

FOUNDATION_EXPORT double OOBVersionNumber;
FOUNDATION_EXPORT const unsigned char OOBVersionString[];

