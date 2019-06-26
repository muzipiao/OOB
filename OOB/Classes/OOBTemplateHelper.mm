//
//  OOBTemplateHelper.m
//  OpenCVDemo
//
//  Created by lifei on 2019/3/4.
//  Copyright © 2019 PacteraLF. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>
#endif
#pragma clang pop
#import "OOBTemplateHelper.h"

using namespace cv;

@implementation OOBTemplateHelper

/**
 * 识别视频中的目标，并返回目标在图片中的位置，实际相似度
 @param sampleBuffer 视频图像流
 @param tImg 待识别的目标图像
 @param similarValue 与视频图像对比的相似度
 @return 结果字典，包含目标坐标，相似度，视频的原始尺寸
 */
// 视频识别全局变量
static UIImage *gVideoTgImg = nil;
static Mat gVideoTgMat;
static CGFloat videoRenderWidth = 0;
+ (nullable NSDictionary *)locInVideo:(CMSampleBufferRef)sampleBuffer TemplateImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue{
    // 视频图像矩阵
    Mat videoMat;
    videoMat = [self bufferToGrayMat:sampleBuffer];
    if (!sampleBuffer || !tImg || videoMat.empty()) {
        OOBLog(@"视频或目标图像为空");
        return nil;
    }
    // 储存原始尺寸
    CGSize originVideoSize = CGSizeMake(videoRenderWidth, videoMat.rows);
    CGFloat videoFillWidth = videoMat.cols - videoRenderWidth;
    
    // 待比较的图像, 转为灰度图像
    if (![tImg isEqual:gVideoTgImg] || gVideoTgMat.empty()) {
        gVideoTgImg = tImg;
        Mat colorMat;
        UIImageToMat(tImg, colorMat);
        cvtColor(colorMat, gVideoTgMat, CV_BGR2GRAY);
        // 将目标大图缩小为和背景大小相差不大的图像
        int reTgCols1st = 120;
        int reTgRows1st = (int)(((CGFloat)reTgCols1st * (CGFloat)gVideoTgMat.rows)/(CGFloat)gVideoTgMat.cols);
        cv::Size reTgSize1st = cv::Size(reTgCols1st,reTgRows1st);
        resize(gVideoTgMat, gVideoTgMat, reTgSize1st);
    }
    //判断是否为空，为空直接返回
    if (gVideoTgMat.empty()) {
        OOBLog(@"目标图像矩阵为空");
        return nil;
    }
    NSDictionary *compDict = [self compareBgMat:videoMat TargetMat:gVideoTgMat SimilarValue:similarValue];
    
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithDictionary:compDict];
    [resultDict setObject:NSStringFromCGSize(originVideoSize) forKey:kVideoSize];
    [resultDict setObject:@(videoFillWidth) forKey:kVideoFillWidth];
    return resultDict.copy;
}

///MARK: - 对比图片
/**
 * 识别图像中的目标，并返回目标坐标，相似度
 @param bgImg 背景图像，在背景图像上搜索目标是否存在
 @param tImg 待识别的目标图像
 @param similarValue 要求的相似度，取值在 0 到 1 之间，1 为最大，越接近 1 表示要求越高
 @return 结果字典，分别是目标位置和实际的相似度
 */
+ (NSDictionary *)locInImg:(UIImage *)bgImg TargetImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue{
    if (!bgImg || !tImg) {
        return nil;
    }
    // 图像矩阵
    UIImage *noAlphaImg = [self removeAlpha:tImg];
    Mat bgImgMat;
    Mat tImgMat;
    UIImageToMat(bgImg, bgImgMat);
    UIImageToMat(noAlphaImg, tImgMat);
    if (bgImgMat.empty() || tImgMat.empty()) {
        return nil;
    }
    Mat bgImgGrayMat;
    Mat tImgGrayMat;
    cvtColor(bgImgMat, bgImgGrayMat, CV_BGR2GRAY);
    cvtColor(tImgMat, tImgGrayMat, CV_BGR2GRAY);
    // 对比
    NSDictionary *compDict = [self compareBgMat:bgImgGrayMat TargetMat:tImgGrayMat SimilarValue:similarValue];
    return compDict;
}

/**
 * 对比两个图像矩阵是否有相似区域
 @param bgMat 背景图像，在背景图像上搜索目标是否存在
 @param tgMat 待识别的目标图像矩阵
 @param similarValue 要求的相似度
 @return 结果字典，包含目标坐标，相似度
 */
static CGFloat scaleMid = 0.5; // 缩放，将目标图像从 0.5 倍背景图像尺寸，向两边缩放，先减后加。
+ (nullable NSDictionary *)compareBgMat:(Mat)bgMat TargetMat:(Mat)tgMat SimilarValue:(CGFloat)similarValue{
    // 将背景大图像缩放为小图
    int reBgCols = 160; // 宽度固定为160像素
    CGFloat reBgScale = (CGFloat)bgMat.cols/160.0;
    // 保持大图宽高比
    int reBgRows = (int)(((CGFloat)reBgCols * (CGFloat)bgMat.rows)/(CGFloat)bgMat.cols);
    cv::Size reBgSize = cv::Size(reBgCols,reBgRows);
    resize(bgMat, bgMat, reBgSize);
    
    int currentTgWidth = 0; // 匹配的模板图像宽度
    int currentTgHeight = 0; // 匹配的模板图像高度
    double maxVal = 0; // 相似度
    cv::Point maxLoc; // 匹配的位置
    // 缩放的尺度，要求精度越高，则每次缩放越小
    CGFloat subValue = (1.1 - similarValue) * 0.1;
    CGFloat scaleSign = -1; // 放大缩小标记
    scaleMid += subValue; // 从上次匹配的值开始
    if (scaleMid >= 1 || scaleMid <= 0.1) {
        scaleMid = 0.5; // 超限重置
    }
    do {
        if (scaleMid >= 1) {
            break;
        }
        // 向下遍历不到，则向上遍历，放大
        if (scaleMid <= 0.1) {
            scaleMid = 0.5;
            scaleSign = 1;
        }
        scaleMid += (subValue * scaleSign);
        // 计算缩放后的尺寸
        CGFloat reTgCols = bgMat.cols * scaleMid;
        CGFloat reTgRows = (reTgCols * tgMat.rows) / tgMat.cols;
        if (reTgCols >= bgMat.cols || reTgRows >= bgMat.rows) {
            if (scaleSign == 1) {
                break; // 如果是放大，结束，没必要再放大
            }else{
                continue; // 如果是缩小，则继续
            }
        }
        // 缩放后的图像
        cv::Size reTgSize = cv::Size((int)reTgCols, (int)reTgRows);
        Mat reTgMat;
        resize(tgMat, reTgMat, reTgSize);
        // 比较结果
        int result_rows = bgMat.rows - reTgMat.rows + 1;
        int result_cols = bgMat.cols - reTgMat.cols + 1;
        if (result_rows < 0 || result_cols < 0) {
            break;
        }
        Mat resultMat = Mat(result_cols,result_rows,CV_32FC1);
        matchTemplate(bgMat, reTgMat, resultMat, TM_CCOEFF_NORMED);
        double minVal_temp, maxVal_temp;
        cv::Point minLoc_temp, maxLoc_temp;
        minMaxLoc( resultMat, &minVal_temp, &maxVal_temp, &minLoc_temp, &maxLoc_temp, Mat());
        // 储存最大值
        if (maxVal_temp > maxVal) {
            maxVal = maxVal_temp;
            maxLoc = maxLoc_temp;
            currentTgWidth = reTgCols;
            currentTgHeight = reTgRows;
        }
        if (maxVal_temp >= similarValue) {
            break;
        }
    } while (TRUE);
    // 将作为恢复为背景大图的坐标
    CGRect rectF = CGRectMake(maxLoc.x * reBgScale, maxLoc.y * reBgScale, currentTgWidth * reBgScale, currentTgHeight * reBgScale);
    NSDictionary *tempDict = @{kTargetRect:NSStringFromCGRect(rectF),
                               kSimilarValue:@(maxVal)};
    return tempDict;
}

/**
 * 高效将视频流转换为 Mat 图像矩阵
 * Efficiently convert video streams to Mat image matrices
 @param sampleBuffer 视频流(video stream)
 @return OpenCV 可用的图像矩阵(OpenCV available image matrix)
 */
+ (Mat)bufferToGrayMat:(CMSampleBufferRef) sampleBuffer{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (format != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        OOBLog(@"Only YUV is supported"); // Y 是亮度，UV 是颜色
        return Mat();
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    videoRenderWidth = width; // 保存渲染宽度
    CGFloat colCount = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    if (width != colCount) {
        width = colCount; // 如果有字节对齐
    }
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);
    Mat mat(height, width, CV_8UC1, baseaddress, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return mat;
}

/**
 * 将 YUV 格式视频流转为 CGImage
 @param sampleBuffer YUV 格式视频流
 @return 当前视频流的 CGImage
 */
+ (nullable UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    if (!sampleBuffer) {
        return nil;
    }
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    uint8_t *yBuffer = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t yPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    uint8_t *cbCrBuffer = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    size_t cbCrPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
    
    int bytesPerPixel = 4;
    uint8_t *rgbBuffer = (uint8_t *)malloc(width * height * bytesPerPixel);
    // YUV 转 RGB
    for(int y = 0; y < height; y++) {
        uint8_t *rgbBufferLine = &rgbBuffer[y * width * bytesPerPixel];
        uint8_t *yBufferLine = &yBuffer[y * yPitch];
        uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];
        
        for(int x = 0; x < width; x++) {
            int16_t y = yBufferLine[x];
            int16_t cb = cbCrBufferLine[x & ~1] - 128;
            int16_t cr = cbCrBufferLine[x | 1] - 128;
            
            uint8_t *rgbOutput = &rgbBufferLine[x*bytesPerPixel];
            
            int16_t r = (int16_t)roundf( y + cr *  1.4 );
            int16_t g = (int16_t)roundf( y + cb * -0.343 + cr * -0.711 );
            int16_t b = (int16_t)roundf( y + cb *  1.765);
            
            rgbOutput[0] = 0xff;
            rgbOutput[1] = b>255?255:(b<0?0:b);
            rgbOutput[2] = g>255?255:(g<0?0:g);
            rgbOutput[3] = r>255?255:(r<0?0:r);
        }
    }
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(rgbBuffer, width, height, 8,
                                                 width * bytesPerPixel, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    //根据这个位图 context 中的像素创建一个 Quartz image 对象
    CGImageRef quartzImageRef = CGBitmapContextCreateImage(context);
    UIImage *quartzImg = [UIImage imageWithCGImage:quartzImageRef];
    CGImageRelease(quartzImageRef);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(rgbBuffer);
    
    return quartzImg;
}

/**
 * 将透明像素填充为白色，对其他像素无影响
 @param originImg 原图像
 @return 填充后的图像
 */
+ (nullable UIImage *)removeAlpha:(UIImage *)originImg{
    CGSize tSize = originImg.size;
    CGRect tRect = CGRectMake(0, 0, tSize.width, tSize.height);
    UIGraphicsBeginImageContextWithOptions(tSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, tRect);
    [originImg drawInRect:tRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
