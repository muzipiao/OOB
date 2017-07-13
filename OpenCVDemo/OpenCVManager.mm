//
//  OpenCVManager.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/7/11.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "OpenCVManager.h"

@implementation OpenCVManager

#pragma mark - 生成一张标记目标的图片
+ (UIImage *)imageWithColor:(UIColor *)rectColor size:(CGSize)size rectArray:(NSArray *)rectArray{
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    // 1.开启图片的图形上下文
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    
    // 2.获取
    CGContextRef cxtRef = UIGraphicsGetCurrentContext();
    
    // 3.矩形框标记颜色
    //获取目标位置
    for (NSInteger i = 0; i < rectArray.count; i++) {
        NSValue *rectValue = rectArray[i];
        CGRect targetRect = rectValue.CGRectValue;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:targetRect cornerRadius:5];
        //加路径添加到上下文
        CGContextAddPath(cxtRef, path.CGPath);
        [rectColor setStroke];
        [[UIColor clearColor] setFill];
        //渲染上下文里面的路径
        /**
         kCGPathFill,   填充
         kCGPathStroke, 边线
         kCGPathFillStroke,  填充&边线
         */
        CGContextDrawPath(cxtRef,kCGPathFillStroke);
    }
    
    //填充透明色
    CGContextSetFillColorWithColor(cxtRef, [UIColor clearColor].CGColor);
    
    CGContextFillRect(cxtRef, rect);
    
    // 4.获取图片
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    // 5.关闭图形上下文
    UIGraphicsEndImageContext();
    
    // 6.返回图片
    return img;
}

#pragma mark - 将CMSampleBufferRef转为cv::Mat
+(cv::Mat)bufferToMat:(CMSampleBufferRef) sampleBuffer{
    CVImageBufferRef imgBuf = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //锁定内存
    CVPixelBufferLockBaseAddress(imgBuf, 0);
    // get the address to the image data
    void *imgBufAddr = CVPixelBufferGetBaseAddress(imgBuf);
    
    // get image properties
    int w = (int)CVPixelBufferGetWidth(imgBuf);
    int h = (int)CVPixelBufferGetHeight(imgBuf);
    
    // create the cv mat
    cv::Mat mat(h, w, CV_8UC4, imgBufAddr, 0);
//    //转换为灰度图像
//    cv::Mat edges;
//    cv::cvtColor(mat, edges, CV_BGR2GRAY);
    
    //旋转90度
    cv::Mat transMat;
    cv::transpose(mat, transMat);
    
    //翻转,1是x方向，0是y方向，-1位Both
    cv::Mat flipMat;
    cv::flip(transMat, flipMat, 1);
    
    CVPixelBufferUnlockBaseAddress(imgBuf, 0);
    
    return flipMat;
}

#pragma mark - 将CMSampleBufferRef转为UIImage
+ (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    //先获取imgBuffer
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0,
                                                 CVPixelBufferGetWidth(imageBuffer),
                                                 CVPixelBufferGetHeight(imageBuffer))];
    //再旋转90度
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, 0, height);
    transform = CGAffineTransformRotate(transform, -M_PI_2);
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(context, CGRectMake(0,0,height,width), videoImage);
    CGImageRelease(videoImage);
    
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}



@end
