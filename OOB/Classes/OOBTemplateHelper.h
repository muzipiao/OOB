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
 * 识别目标图像并返回目标坐标，相似度，视频的原始尺寸
 * Identify the target image and return the target coordinates, similarity, the original size of the video
 @param sampleBuffer 视频图像流(sampleBuffer video image stream)
 @param tImg 待识别的目标图像(target image to be recognized)
 @param similarValue 与视频图像对比的相似度(Similarity to video image comparison)
 @return 结果字典，包含目标坐标，相似度，视频的原始尺寸(result dictionary containing target coordinates, similarity, original size of the video)
 */
+ (NSDictionary *)locInCamera:(CMSampleBufferRef)sampleBuffer TemplateImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue;

/**
 * 识别图像中的目标，并返回目标坐标，相似度
 @param bgImg 背景图像，在背景图像上搜索目标是否存在
 @param tImg 待识别的目标图像
 @param similarValue 要求的相似度，取值在 0 到 1 之间，1 为最大，越接近 1 表示要求越高
 @return 结果字典，分别是目标位置和实际的相似度
 */
+ (NSDictionary *)locInImg:(UIImage *)bgImg TargetImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue;

/**
 * 将透明像素填充为白色，对其他像素无影响
 @param originImg 原图像
 @return 填充后的图像
 */
+ (UIImage *)removeAlpha:(UIImage *)originImg;

@end

NS_ASSUME_NONNULL_END
