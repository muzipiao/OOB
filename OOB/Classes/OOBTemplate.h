//
//  OOBTemplate.h
//  OpenCVDemo
//
//  Created by lifei on 2019/3/4.
//  Copyright © 2019 PacteraLF. All rights reserved.
/**
 * 模板匹配法，识别摄像头，图片中的目标
 */

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "OOBDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface OOBTemplate : NSObject

/**
 * 停止识别图像。调用摄像头/播放视频，必须手动执行此方法释放资源。
 */
+ (void)stopMatch;

/**
 * 识别相机视频流中目标，并返回目标图像坐标位置，坐标位置与设置的预览视图(preview)相关。
 * 备注：当 targetRect 宽高为 0 时代表未识别到图像，similarValue 值越大代表相似度越高
 @param targetImg 待识别的目标图像
 @param resultBlock 识别结果,targetRect：目标位置，similarValue：目标与视频物体中的相似度
 */
+ (void)matchCamera:(UIImage *)targetImg
        resultBlock:(void (^)(CGRect targetRect, CGFloat similarValue))resultBlock;

/**
 * 识别视频中的目标，并返回目标在图片中的位置，实际相似度
 @param targetImg 待识别的目标图像
 @param vURL 视频文件 URL
 @param resultBlock 识别结果，分别是目标位置和实际的相似度，视频当前帧图像
 */
+ (void)matchVideo:(UIImage *)targetImg VideoURL:(NSURL *)vURL
       resultBlock:(void (^)(CGRect targetRect, CGFloat similarValue, UIImage * _Nullable frameImg))resultBlock;

/**
 * 识别图片中的目标，并返回目标在图片中的位置，实际相似度
 @param targetImg 待识别的目标图像
 @param backgroudImg 背景图像，在背景图像上搜索目标是否存在
 @param minSimilarValue 要求的相似度，取值在 0 到 1 之间，1 为最大，越接近 1 表示要求越高
 @param resultBlock 识别结果，分别是目标位置和实际的相似度
 */
+ (void)matchImage:(UIImage *)targetImg BgImg:(UIImage *)backgroudImg Similar:(CGFloat)minSimilarValue resultBlock:(void (^)(CGRect targetRect, CGFloat similarValue))resultBlock;

/**
 * 摄像头视频流，视频文件，背景图预览视图。
 * 识别摄像头目标时，不设置不显示预览视频，获取的 CGRect 坐标默认为全屏坐标。
 * 识别视频文件或者图片中目标时，若不设置，视频或者图片需 100% 比例展示，即 sizeToFit。
 */
@property (class, nullable, nonatomic, strong) UIView *bgPreview;

/**
 * 待识别的目标图像,可随时切换待识别目标。
 */
@property (class, nonatomic, strong) UIImage *targetImg;

/**
 * 待识别物体与视频对比的相似度。值越大代表相似度越高。
 * 默认值为 0.7，最大为 1.0。值设置的越小误报率高，值设置的越大越难匹配。
 */
@property (class, nonatomic, assign) CGFloat similarValue;

///MARK: - 识别摄像头目标可选属性
/**
 * 前置后置摄像头切换，设置可切换摄像头，默认后置摄像头.
 */
@property (class, nonatomic, assign) OOBCameraType cameraType;

/**
 * 视频预览视图图像质量，默认预览视频尺寸 1920x1080，可自行设置。
 */
@property(class, nonatomic, copy) AVCaptureSessionPreset cameraSessionPreset;

///MARK: - 辅助：标记图像(可选，用户可自定义标记图像)
/**
 * 矩形标记框（辅助功能，例如显示目标位置）
 @param imgSize 标记框图片尺寸
 @param lineColor 标记框的线条颜色
 @param lineWidth 标记框的线条粗细
 @param cornerRadius 矩形标记框的切圆角
 @return 中间透明的矩形标记框
 */
+ (UIImage *)getRectWithSize:(CGSize)imgSize Color:(UIColor *)lineColor Width:(CGFloat)lineWidth Radius:(CGFloat)cornerRadius;

@end

NS_ASSUME_NONNULL_END
