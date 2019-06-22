//
//  OOBDefine.h
//  OpenCVDemo
//
//  Created by lifei on 2019/3/1.
//  Copyright © 2019 PacteraLF. All rights reserved.
//

#ifndef OOBDefine_h
#define OOBDefine_h

/**
 * 相似度 key
 */
#define kSimilarValue @"kSimilarValue"

/**
 * 目标位置 key
 */
#define kTargetRect @"kTargetRect"

/**
 * 视频解码后图像大小 key
 */
#define kVideoSize @"kVideoSize"

/**
 * 视频图像字节补齐宽度
 */
#define kVideoFillWidth @"kVideoFillWidth"

/**
 * Log 日志
 */
#ifdef DEBUG
# define OOBLog(fmt, ...) NSLog((@"\nClass:%s\n" "Func:%s\n" "Row:%d \n" fmt), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
# define OOBLog(...);
#endif


/**
 * 摄像头类型
 */
typedef NS_ENUM(NSInteger, OOBCameraType) {
    /**
     * 后置摄像头
     */
    OOBCameraTypeBack,
    /**
     * 前置摄像头
     */
    OOBCameraTypeFront
};


/**
 * 标记图像类型
 */
typedef NS_ENUM(NSInteger, OOBMarkerType) {
    /**
     * 不使用标记
     */
    OOBMarkerTypeNone,
    /**
     * 矩形标记
     */
    OOBMarkerTypeRect,
    /**
     * 椭圆标记
     */
    OOBMarkerTypeOval
};

#endif /* OOBDefine_h */
