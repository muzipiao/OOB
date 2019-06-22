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
// 全局变量
static UIImage *globalTemplateImg = nil;
static Mat globalTemplateMat;
static CGFloat videoRenderWidth = 0;

/**
 * 识别目标图像并返回目标坐标，相似度，视频的原始尺寸
 * Identify the target image and return the target coordinates, similarity, the original size of the video
 @param sampleBuffer 视频图像流(sampleBuffer video image stream)
 @param tImg 待识别的目标图像(target image to be recognized)
 @param similarValue 与视频图像对比的相似度(Similarity to video image comparison)
 @return 结果字典，包含目标坐标，相似度，视频的原始尺寸(result dictionary containing target coordinates, similarity, original size of the video)
 */
+(NSDictionary *)locInCamera:(CMSampleBufferRef)sampleBuffer TemplateImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue{
    // 视频图像矩阵
    Mat videoMat;
    videoMat = [self bufferToGrayMat:sampleBuffer];
    CGSize orginVideoSize = CGSizeMake(videoRenderWidth, videoMat.rows);
    CGFloat videoFillWidth = videoMat.cols - videoRenderWidth;
    // 初始化矩阵
    NSDictionary *tempDict = @{kTargetRect:NSStringFromCGRect(CGRectZero),
                               kVideoSize:NSStringFromCGSize(orginVideoSize),
                               kSimilarValue:@(0),
                               kVideoFillWidth:@(videoFillWidth)};
    if (!tImg) {
        OOBLog(@"目标图像为空");
        return tempDict;
    }
    CGFloat orginVideoWidth = videoMat.cols;
    CGFloat orginVideoHeight = videoMat.rows;
    int videoReCols = 160; // 宽度固定为160
    CGFloat videoScale = 160.0/orginVideoWidth;
    int videoReRows = (int)((CGFloat)videoReCols * orginVideoHeight)/orginVideoWidth; // 保持宽高比
    cv::Size videoReSize = cv::Size(videoReCols,videoReRows);
    resize(videoMat, videoMat, videoReSize);
    // 待比较的图像
    if (![tImg isEqual:globalTemplateImg] || globalTemplateMat.empty()) {
        globalTemplateImg = tImg;
        Mat colorMat;
        UIImageToMat(tImg, colorMat);
        cvtColor(colorMat, globalTemplateMat, CV_BGR2GRAY);
    }
    
    //判断是否为空，为空直接返回
    if (videoMat.empty() || globalTemplateMat.empty()) {
        OOBLog(@"图像矩阵为空");
        return tempDict;
    }
    // 目标可缩放范围
    NSArray *targetScaleArray = @[@(0.2),@(0.3),@(0.4),@(0.5)];
    NSDictionary *compDict = [self compareInput:videoMat templateMat:globalTemplateMat SimilarValue:similarValue BgScale:videoScale TScale:targetScaleArray];
    
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithDictionary:compDict];
    [resultDict setObject:NSStringFromCGSize(orginVideoSize) forKey:kVideoSize];
    [resultDict setObject:@(videoFillWidth) forKey:kVideoFillWidth];
    
    return resultDict.copy;
}

/**
 * 对比两个图像是否有相同区域
 * Compare whether two images have the same area
 @param inputMat 缩放后的视频图像矩阵(Scaled video image matrix)
 @param tmpMat 待识别的目标图像矩阵(Target image matrix to be identified)
 @param similarValue 设置的对比相似度阈值(set contrast similarity threshold)
 @param bgScale 背景缩放比例(background scaling)
 @param tScaleArr 目标缩放比例范围(target scaling range)
 @return 对比结果，包含目标坐标，相似度(comparison result, including target coordinates, similarity)
 */
+(NSDictionary *)compareInput:(Mat)inputMat templateMat:(Mat)tmpMat SimilarValue:(CGFloat)similarValue BgScale:(CGFloat)bgScale TScale:(NSArray *)tScaleArr{
    // 将待比较的图像缩放至视频宽度的 20% 至 50%
    int currentTmpWidth = 0; // 匹配的模板图像宽度
    int currentTmpHeight = 0; // 匹配的模板图像高度
    double maxVal = 0; // 相似度
    cv::Point maxLoc; // 匹配的位置
    for (NSNumber *tmpNum in tScaleArr) {
        CGFloat tmpScale = tmpNum.floatValue;
        // 待比较图像宽度，将待比较图像宽度缩放至视频图像的一定比例
        CGFloat fTmpCols = inputMat.cols * tmpScale;
        // 待比较图像高度，保持宽高比
        int tmpRows = (fTmpCols * tmpMat.rows) / (CGFloat)tmpMat.cols;
        int tmpCols = (int)fTmpCols;
        // 缩放后的图像
        Mat tmpReMat;
        cv::Size tmpReSize = cv::Size(tmpCols,tmpRows);
        resize(tmpMat, tmpReMat, tmpReSize);
        // 比较结果
        int result_rows = inputMat.rows - tmpReMat.rows + 1;
        int result_cols = inputMat.cols - tmpReMat.cols + 1;
        if (result_rows < 0 || result_cols < 0) {
            break;
        }
        Mat resultMat = Mat(result_cols,result_rows,CV_32FC1);
        matchTemplate(inputMat, tmpReMat, resultMat, TM_CCOEFF_NORMED);
        
        double minVal_temp, maxVal_temp;
        cv::Point minLoc_temp, maxLoc_temp, matchLoc_temp;
        minMaxLoc( resultMat, &minVal_temp, &maxVal_temp, &minLoc_temp, &maxLoc_temp, Mat());
        maxVal = maxVal_temp;
        if (maxVal >= similarValue) {
            maxLoc = maxLoc_temp;
            currentTmpWidth = tmpCols;
            currentTmpHeight = tmpRows;
            break;
        }
    }
    
    if (maxVal >= similarValue) {
        // 目标图像按照缩放比例恢复
        CGFloat zoomScale = 1.0 / bgScale;
        CGRect rectF = CGRectMake(maxLoc.x * zoomScale, maxLoc.y * zoomScale, currentTmpWidth * zoomScale, currentTmpHeight * zoomScale);
        NSDictionary *tempDict = @{kTargetRect:NSStringFromCGRect(rectF),
                                   kSimilarValue:@(maxVal)};
        return tempDict;
    }else{
        NSDictionary *tempDict = @{kTargetRect:NSStringFromCGRect(CGRectZero),
                                   kSimilarValue:@(maxVal)};
        return tempDict;
    }
}

/**
 * 高效将视频流转换为 Mat 图像矩阵
 * Efficiently convert video streams to Mat image matrices
 @param sampleBuffer 视频流(video stream)
 @return OpenCV 可用的图像矩阵(OpenCV available image matrix)
 */
+(Mat)bufferToGrayMat:(CMSampleBufferRef) sampleBuffer{
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
+ (NSDictionary *)compareBgMat:(Mat)bgMat TargetMat:(Mat)tgMat SimilarValue:(CGFloat)similarValue{
    int currentTgWidth = 0; // 匹配的模板图像宽度
    int currentTgHeight = 0; // 匹配的模板图像高度
    double maxVal = 0; // 相似度
    cv::Point maxLoc; // 匹配的位置
    // 缩放，将目标图像从 0.5 倍背景图像尺寸，向两边缩放，先减去后加。
    CGFloat mid = 0.5;
    // 缩放的尺度，要求精度越高，则每次缩放越小
    CGFloat subValue = (1.1 - similarValue) * 0.1;
    CGFloat sign = -1;
    do {
        if (mid >= 1) {
            break;
        }
        // 向下遍历不到，则向上遍历，放大
        if (mid <= 0.1) {
            mid = 0.5;
            sign = 1;
        }
        mid += (subValue * sign);
        // 计算缩放后的尺寸
        CGFloat reTgCols = bgMat.cols * mid;
        CGFloat reTgRows = (reTgCols * tgMat.rows) / tgMat.cols;
        if (reTgCols >= bgMat.cols || reTgRows >= bgMat.rows) {
            if (sign == 1) {
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
        cv::Point minLoc_temp, maxLoc_temp, matchLoc_temp;
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
    // 目标图像按照屏幕缩放比例恢复
    CGFloat zoomScale = 1.0 / [UIScreen mainScreen].scale;
    CGRect rectF = CGRectMake(maxLoc.x * zoomScale, maxLoc.y * zoomScale, currentTgWidth * zoomScale, currentTgHeight * zoomScale);
    NSDictionary *tempDict = @{kTargetRect:NSStringFromCGRect(rectF),
                               kSimilarValue:@(maxVal)};
    return tempDict;
}

/**
 * 将透明像素填充为白色，对其他像素无影响
 @param originImg 原图像
 @return 填充后的图像
 */
+ (UIImage *)removeAlpha:(UIImage *)originImg{
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
