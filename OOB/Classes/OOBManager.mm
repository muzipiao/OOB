//
//  OOBManager.m
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
#import "OOBManager.h"

using namespace cv;

@implementation OOBManager
// 全局变量
static UIImage *globalTemplateImg = nil;
static Mat globalTemplateMat;
static CGFloat videoRenderWidth = 0;
static CIContext *globalContext = nil;
static CIDetector *globalLowDetector = nil;
static CIDetector *globalHighDetector = nil;

/**
 * 识别目标图像并返回目标坐标，相似度，视频的原始尺寸
 * Identify the target image and return the target coordinates, similarity, the original size of the video
 @param sampleBuffer 视频图像流(sampleBuffer video image stream)
 @param tImg 待识别的目标图像(target image to be recognized)
 @param similarValue 与视频图像对比的相似度(Similarity to video image comparison)
 @return 结果字典，包含目标坐标，相似度，视频的原始尺寸(result dictionary containing target coordinates, similarity, original size of the video)
 */
+(NSDictionary *)recoObjLocation:(CMSampleBufferRef)sampleBuffer TemplateImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue{
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
    Mat tempMat = globalTemplateMat;;
    if (![tImg isEqual:globalTemplateImg] || globalTemplateMat.empty()) {
        globalTemplateImg = tImg;
        Mat colorMat;
        UIImageToMat(tImg, colorMat);
        cvtColor(colorMat, globalTemplateMat, CV_BGR2GRAY);
    }
    
    //判断是否为空，为空直接返回
    if (videoMat.empty() || tempMat.empty()) {
        OOBLog(@"图像矩阵为空");
        return tempDict;
    }
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithDictionary:[self compareInput:videoMat templateMat:tempMat VideoScale:videoScale SimilarValue:similarValue VideoFillWidth:videoFillWidth]];
    [resultDict setObject:NSStringFromCGSize(orginVideoSize) forKey:kVideoSize];
    return resultDict.copy;
}

/**
 * 对比两个图像是否有相同区域
 * Compare whether two images have the same area
 @param inputMat 缩放后的视频图像矩阵(Scaled video image matrix)
 @param tmpMat 待识别的目标图像矩阵(Target image matrix to be identified)
 @param scale 视频缩放比例(video scaling)
 @param similarValue 设置的对比相似度阈值(set contrast similarity threshold)
 @param videoFillWidth 视频图像字节补齐宽度(Video image byte fill width)
 @return 对比结果，包含目标坐标，相似度(comparison result, including target coordinates, similarity)
 */
+(NSDictionary *)compareInput:(Mat) inputMat templateMat:(Mat)tmpMat VideoScale:(CGFloat)scale SimilarValue:(CGFloat)similarValue VideoFillWidth:(CGFloat)videoFillWidth{
    // 将待比较的图像缩放至视频宽度的 20% 至 50%
    NSArray *tmpArray = @[@(0.2),@(0.3),@(0.4),@(0.5)];
    int currentTmpWidth = 0; // 匹配的模板图像宽度
    int currentTmpHeight = 0; // 匹配的模板图像高度
    double maxVal = 0; // 相似度
    cv::Point maxLoc; // 匹配的位置
    for (NSNumber *tmpNum in tmpArray) {
        CGFloat tmpScale = tmpNum.floatValue;
        // 待比较图像宽度，将待比较图像宽度缩放至视频图像的一半左右
        int tmpCols = inputMat.cols * tmpScale;
        // 待比较图像高度，保持宽高比
        int tmpRows = (tmpCols * tmpMat.rows) / tmpMat.cols;
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
        CGFloat zoomScale = 1.0 / scale;
        CGRect rectF = CGRectMake(maxLoc.x * zoomScale, maxLoc.y * zoomScale, currentTmpWidth * zoomScale, currentTmpHeight * zoomScale);
        NSDictionary *tempDict = @{kTargetRect:NSStringFromCGRect(rectF),
                                   kSimilarValue:@(maxVal),
                                   kVideoFillWidth:@(videoFillWidth)};
        return tempDict;
    }else{
        NSDictionary *tempDict = @{kTargetRect:NSStringFromCGRect(CGRectZero),
                                   kSimilarValue:@(maxVal),
                                   kVideoFillWidth:@(videoFillWidth)};
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

@end
