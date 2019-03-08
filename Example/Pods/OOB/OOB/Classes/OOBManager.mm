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

@implementation OOBManager

/**
 * 识别目标图像
 */
+(NSDictionary *)recoObjLocation:(CMSampleBufferRef)sampleBuffer TemplateImg:(UIImage *)tImg SimilarValue:(CGFloat)similarValue{
    // 视频图像矩阵
    cv::Mat videoMat;
    videoMat = [self bufferToMat:sampleBuffer];
    CGSize orginVideoSize = CGSizeMake(videoMat.cols, videoMat.rows);
    // 初始化矩阵
    NSDictionary *tempDict = @{kTargetRect:NSStringFromCGRect(CGRectZero),
                               kVideoSize:NSStringFromCGSize(orginVideoSize),
                               kSimilarValue:@(0)};
    if (!tImg) {
        OOBLog(@"目标图像为空");
        return tempDict;
    }
    // 将视频原图像缩小
    /*
     * AVCaptureSessionPreset3840x2160
     * AVCaptureSessionPreset1920x1080
     * AVCaptureSessionPreset1280x720
     * AVCaptureSessionPresetiFrame960x540
     * AVCaptureSessionPreset640x480
     * AVCaptureSessionPreset352x288
     */
    CGFloat videoScale = 0.2;
    switch (videoMat.rows) {
        case 3840:
            videoScale = 0.1;
            break;
        case 1920:
            videoScale = 0.2;
            break;
        case 1280:
            videoScale = 0.3;
            break;
        case 960:
            videoScale = 0.4;
            break;
        case 640:
            videoScale = 0.5;
            break;
        case 352:
            videoScale = 1.0;
            break;
        default:
            videoScale = 0.2;
            break;
    }
    
    int videoRows = videoMat.rows * videoScale;
    int videoCols = videoMat.cols * videoScale;
    cv::Size videoReSize = cv::Size(videoCols,videoRows);
    cv::resize(videoMat, videoMat, videoReSize);
    cv::cvtColor(videoMat, videoMat, CV_BGR2GRAY);
    
    // 待比较的图像
    cv::Mat tempMat;
    UIImageToMat(tImg, tempMat);
    cv::cvtColor(tempMat, tempMat, CV_BGR2GRAY);
    
    //判断是否为空，为空直接返回
    if (videoMat.empty() || tempMat.empty()) {
        OOBLog(@"图像矩阵为空");
        return tempDict;
    }
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithDictionary:[self compareInput:videoMat templateMat:tempMat VideoScale:videoScale SimilarValue:similarValue]];
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
 @return 对比结果，包含目标坐标，相似度(comparison result, including target coordinates, similarity)
 */
+(NSDictionary *)compareInput:(cv::Mat) inputMat templateMat:(cv::Mat)tmpMat VideoScale:(CGFloat)scale SimilarValue:(CGFloat)similarValue{
    // 将待比较的图像缩放至视频宽度的 30% 至 50%
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
        cv::Mat tmpReMat;
        cv::Size tmpReSize = cv::Size(tmpCols,tmpRows);
        cv::resize(tmpMat, tmpReMat, tmpReSize);
        // 比较结果
        int result_rows = inputMat.rows - tmpReMat.rows + 1;
        int result_cols = inputMat.cols - tmpReMat.cols + 1;
        cv::Mat resultMat = cv::Mat(result_cols,result_rows,CV_32FC1);
        cv::matchTemplate(inputMat, tmpReMat, resultMat, cv::TM_CCOEFF_NORMED);
        
        double minVal_temp, maxVal_temp;
        cv::Point minLoc_temp, maxLoc_temp, matchLoc_temp;
        cv::minMaxLoc( resultMat, &minVal_temp, &maxVal_temp, &minLoc_temp, &maxLoc_temp, cv::Mat());
        if (maxVal_temp > 0.7) {
            maxVal = maxVal_temp;
            maxLoc = maxLoc_temp;
            currentTmpWidth = tmpCols;
            currentTmpHeight = tmpRows;
            break;
        }
    }
    
    if (maxVal > similarValue) {
        // 目标图像按照缩放比例恢复
        CGFloat zoomScale = 1.0 / scale;
        CGRect rectF = CGRectMake(maxLoc.x * zoomScale, maxLoc.y * zoomScale, currentTmpWidth * zoomScale, currentTmpHeight * zoomScale);
        NSDictionary *tempDict = @{kTargetRect:NSStringFromCGRect(rectF),kSimilarValue:@(maxVal)};
        return tempDict;
    }else{
        NSDictionary *tempDict = @{kTargetRect:NSStringFromCGRect(CGRectZero),kSimilarValue:@(maxVal)};
        return tempDict;
    }
}

/**
 * 将视频流转换为图像矩阵
 * Convert video stream to image matrix
 @param sampleBuffer 视频流(video stream)
 @return OpenCV 可用的图像矩阵(OpenCV available image matrix)
 */
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
    
    //旋转90度
    cv::Mat transMat;
    cv::transpose(mat, transMat);
    
    //翻转,1是x方向，0是y方向，-1位Both
    cv::Mat flipMat;
    cv::flip(transMat, flipMat, 1);
    
    CVPixelBufferUnlockBaseAddress(imgBuf, 0);
    
    return flipMat;
}

@end
