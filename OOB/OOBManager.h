//
//  OOBManager.h
//  OpenCVDemo
//
//  Created by lifei on 2019/3/4.
//  Copyright © 2019 PacteraLF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "OOBDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface OOBManager : NSObject

/**
 * 识别目标图像并返回目标坐标，相似度，视频的原始尺寸
 * Identify the target image and return the target coordinates, similarity, the original size of the video
 @param sampleBuffer 视频图像流(sampleBuffer video image stream)
 @param tImg 待识别的目标图像(target image to be recognized)
 @param similarValue 与视频图像对比的相似度(Similarity to video image comparison)
 @return 结果字典，包含目标坐标，相似度，视频的原始尺寸(result dictionary containing target coordinates, similarity, original size of the video)
 */
+(NSDictionary *)recoObjLocation:(CMSampleBufferRef)sampleBuffer TemplateImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue;


@end

NS_ASSUME_NONNULL_END
