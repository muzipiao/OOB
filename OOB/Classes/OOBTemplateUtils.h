//
//  OOBTemplateUtils.h
//  OpenCVDemo
//
//  Created by lifei on 2019/3/4.
//  Copyright © 2019 PacteraLF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

///--------------------
/// @name 常量定义
///--------------------

/// 相似度 key
FOUNDATION_EXPORT NSString * const kOOBTemplateSimilarValue;
/// 目标位置 key
FOUNDATION_EXPORT NSString * const kOOBTemplateTargetRect;
/// 视频解码后图像Size key
FOUNDATION_EXPORT NSString * const kOOBTemplateVideoSize;
/// 视频图像补齐宽度尺寸 key
FOUNDATION_EXPORT NSString * const kOOBTemplatePaddingWidth;

#ifdef DEBUG
    # define OOBLog(fmt, ...) NSLog((@"\nClass:%s\n" "Func:%s\n" "Row:%d \n" fmt), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
    # define OOBLog(...);
#endif

typedef NS_ENUM(NSInteger, OOBCameraType) {
    OOBCameraTypeBack, /// 后置摄像头
    OOBCameraTypeFront /// 前置摄像头
};

///--------------------
/// @name block
///--------------------

/// 识别相机或图片中目标，识别结果回调
/// @param rect 目标位置
/// @param similar 相似度
typedef void(^ResultBlock)(CGRect rect, CGFloat similar);

/// 识别视频中目标，识别结果回调
/// @param rect 目标位置
/// @param similar 相似度
/// @param frame 视频帧图像
typedef void(^VideoBlock)(CGRect rect, CGFloat similar, UIImage * _Nullable frame);

///--------------------
/// @name OOBTemplateUtils
///--------------------

@interface OOBTemplateUtils : NSObject

/// 识别视频中的目标，返回目标坐标，相似度，视频的原始尺寸
/// @param sampleBuffer 视频图像流
/// @param tImg 待识别的目标图像
/// @param similarValue 与视频图像对比的相似度
+ (nullable NSDictionary *)locInVideo:(CMSampleBufferRef)sampleBuffer TemplateImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue;

/// 识别图像中的目标，返回目标位置和实际的相似度
/// @param bgImg 背景图像，在背景图像上搜索目标是否存在
/// @param tImg 待识别的目标图像
/// @param similarValue 要求的相似度，取值在 0 到 1 之间，1 为最大，越接近 1 表示要求越高
+ (nullable NSDictionary *)locInImg:(UIImage *)bgImg TargetImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue;

/// 将 YUV 格式视频流转为 CGImage，返回当前视频流的 CGImage
/// @param sampleBuffer YUV 格式视频流
+ (nullable UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;

/// 将透明像素填充为白色，对其他像素无影响，返回填充后的图像
/// @param originImg 原始图像
+ (nullable UIImage *)removeAlpha:(UIImage *)originImg;

@end

NS_ASSUME_NONNULL_END
