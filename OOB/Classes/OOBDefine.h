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
 * similarity key
 */
#define kSimilarValue @"kSimilarValue"

/**
 * 目标位置 key
 * target location key
 */
#define kTargetRect @"kTargetRect"

/**
 * 视频解码后图像大小 key
 * Image size after video decoding key
 */
#define kVideoSize @"kVideoSize"

/**
 * Log 日志
 * Log log
 */
#ifdef DEBUG
# define OOBLog(fmt, ...) NSLog((@"\nClass:%s\n" "Func:%s\n" "Row:%d \n" fmt), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
# define OOBLog(...);
#endif


/**
 * 摄像头类型
 * Camera type
 */
typedef NS_ENUM(NSInteger, OOBCameraType) {
    /**
     * 后置摄像头
     * rear camera
     */
    OOBCameraTypeBack,
    /**
     * 前置摄像头
     * Front camera
     */
    OOBCameraTypeFront
};


/**
 * 标记图像类型
 * Mark image type
 */
typedef NS_ENUM(NSInteger, OOBMarkerType) {
    /**
     * 不使用标记
     * Do not use tags
     */
    OOBMarkerTypeNone,
    /**
     * 矩形标记
     * Rectangular mark
     */
    OOBMarkerTypeRect,
    /**
     * 椭圆标记
     * Oval mark
     */
    OOBMarkerTypeOval
};

#endif /* OOBDefine_h */
