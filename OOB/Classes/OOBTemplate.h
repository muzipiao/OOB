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
#import "OOBTemplateUtils.h"

NS_ASSUME_NONNULL_BEGIN

///MARK: - OOBTemplate

@interface OOBTemplate : NSObject

/// 停止识别图像。调用摄像头/播放视频，必须手动执行此方法释放资源。
+ (void)stop;

/// 识别相机视频流中目标，并返回目标图像坐标位置，坐标系在预览视图(preview)内。
/// 备注：当返回 rect 宽高为 0 时代表未识别到图像，similar 值越大代表相似度越高。
/// @param target 待识别的目标图像
/// @param resultBlock 识别结果，分别是目标位置和实际的相似度
+ (void)match:(UIImage *)target result:(ResultBlock)resultBlock;

/// 识别视频中的目标，并返回目标在图片中的位置，实际相似度
/// @param target 待识别的目标图像
/// @param url 视频文件 URL
/// @param resultBlock 识别结果，分别是目标位置和实际的相似度，视频当前帧图像
+ (void)match:(UIImage *)target videoURL:(NSURL *)url result:(VideoBlock)resultBlock;

/// 识别图片中的目标，并返回目标在图片中的位置，实际相似度
/// @param target 待识别的目标图像
/// @param bg 背景图像，在背景图像上搜索目标是否存在
/// @param resultBlock 识别结果，分别是目标位置和实际的相似度
+ (void)match:(UIImage *)target bgImg:(UIImage *)bg result:(ResultBlock)resultBlock;

///--------------------
/// @name 属性设置
///--------------------

///MARK: - OOBProperty

/**
 * 摄像头视频流，视频文件，背景图预览视图。
 * 识别摄像头目标时，不设置不显示预览视频，获取的 CGRect 坐标默认为全屏坐标。
 * 识别视频文件或者图片中目标时，若不设置，视频或者图片需 100% 比例展示，即 sizeToFit。
 */
@property (class, nullable, nonatomic, strong) UIView *preview;

/// 待识别的目标图像,可随时切换待识别目标。
@property (class, nonatomic, strong) UIImage *targetImg;

/// 待识别物体与视频对比的相似度。值越大代表相似度越高。
/// 默认值为 0.7，最大为 1.0。值设置的越小误报率高，值设置的越大计算量越大。
@property (class, nonatomic, assign) CGFloat similarValue;

///--------------------
/// @name 可选属性
///--------------------

///MARK: - optional

/// 前置后置摄像头切换，设置可切换摄像头，默认后置摄像头。
@property (class, nonatomic, assign) OOBCameraType cameraType;

/// 视频预览视图图像质量，默认预览视频尺寸 1920x1080，可自行设置。
@property(class, nonatomic, copy) AVCaptureSessionPreset cameraSessionPreset;

///MARK: - 辅助：标记图像(可选，用户可自定义标记图像)

/// 矩形标记框（辅助功能，例如显示目标位置）
/// @param rectSize 标记框图片尺寸
/// @param color 标记框的线条颜色
/// @param width 标记框的线条粗细
/// @param radius 矩形标记框的切圆角
+ (UIImage *)createRect:(CGSize)rectSize borderColor:(UIColor *)color borderWidth:(CGFloat)width cornerRadius:(CGFloat)radius;

@end

NS_ASSUME_NONNULL_END
