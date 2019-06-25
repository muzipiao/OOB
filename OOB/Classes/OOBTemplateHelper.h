//
//  OOBTemplateHelper.h
//  OpenCVDemo
//
//  Created by lifei on 2019/3/4.
//  Copyright © 2019 PacteraLF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "OOBDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface OOBTemplateHelper : NSObject

/**
 * 识别视频中的目标，并返回目标在图片中的位置，实际相似度
 @param sampleBuffer 视频图像流
 @param tImg 待识别的目标图像
 @param similarValue 与视频图像对比的相似度
 @return 结果字典，包含目标坐标，相似度，视频的原始尺寸
 */
+ (nullable NSDictionary *)locInVideo:(CMSampleBufferRef)sampleBuffer TemplateImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue;

/**
 * 识别图像中的目标，并返回目标坐标，相似度
 @param bgImg 背景图像，在背景图像上搜索目标是否存在
 @param tImg 待识别的目标图像
 @param similarValue 要求的相似度，取值在 0 到 1 之间，1 为最大，越接近 1 表示要求越高
 @return 结果字典，分别是目标位置和实际的相似度
 */
+ (nullable NSDictionary *)locInImg:(UIImage *)bgImg TargetImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue;

/**
 * 将 YUV 格式视频流转为 CGImage
 @param sampleBuffer YUV 格式视频流
 @return 当前视频流的 CGImage
 */
+ (nullable CGImageRef)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;

/**
 * 将透明像素填充为白色，对其他像素无影响
 @param originImg 原图像
 @return 填充后的图像
 */
+ (nullable UIImage *)removeAlpha:(UIImage *)originImg;

@end

NS_ASSUME_NONNULL_END
