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

// 局部自适应快速积分二值化方法 https://blog.csdn.net/realizetheworld/article/details/46971143
+(cv::Mat)convToBinary:(cv::Mat) src{
    cv::Mat dst;
    cvtColor(src,dst,CV_BGR2GRAY);
    int x1, y1, x2, y2;
    int count=0;
    long long sum=0;
    int S=src.rows>>3;  //划分区域的大小S*S
    int T=15;         /*百分比，用来最后与阈值的比较。原文：If the value of the current pixel is t percent less than this average
                       then it is set to black, otherwise it is set to white.*/
    int W=dst.cols;
    int H=dst.rows;
    long long **Argv;
    Argv=new long long*[dst.rows];
    for(int ii=0;ii<dst.rows;ii++)
    {
        Argv[ii]=new long long[dst.cols];
    }
    
    for(int i=0;i<W;i++)
    {
        sum=0;
        for(int j=0;j<H;j++)
        {
            sum+=dst.at<uchar>(j,i);
            if(i==0)
                Argv[j][i]=sum;
            else
                Argv[j][i]=Argv[j][i-1]+sum;
        }
    }
    
    for(int i=0;i<W;i++)
    {
        for(int j=0;j<H;j++)
        {
            x1=i-S/2;
            x2=i+S/2;
            y1=j-S/2;
            y2=j+S/2;
            if(x1<0)
                x1=0;
            if(x2>=W)
                x2=W-1;
            if(y1<0)
                y1=0;
            if(y2>=H)
                y2=H-1;
            count=(x2-x1)*(y2-y1);
            sum=Argv[y2][x2]-Argv[y1][x2]-Argv[y2][x1]+Argv[y1][x1];
            
            
            if((long long)(dst.at<uchar>(j,i)*count)<(long long)sum*(100-T)/100)
                dst.at<uchar>(j,i)=0;
            else
                dst.at<uchar>(j,i)=255;
        }
    }
    for (int i = 0 ; i < dst.rows; ++i)
    {
        delete [] Argv[i];
    }
    delete [] Argv;
    return dst;
}

@end
