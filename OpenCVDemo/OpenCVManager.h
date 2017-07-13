//
//  OpenCVManager.h
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/7/11.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "OpenCVDemoConfig.h"
#import <AVFoundation/AVFoundation.h>

@interface OpenCVManager : NSObject

/**
 生成一张用矩形框标记目标的图片

 @param rectColor 矩形的颜色
 @param size 图片大小，一般和视频帧大小相同
 @param rectArray 需要标记的CGRect数组
 @return 返回一张图片
 */
+ (UIImage *)imageWithColor:(UIColor *)rectColor size:(CGSize)size rectArray:(NSArray *)rectArray;

//将CMSampleBufferRef转为UIImage
+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;

//将CMSampleBufferRef转为cv::Mat
+ (cv::Mat)bufferToMat:(CMSampleBufferRef) sampleBuffer;

@end
