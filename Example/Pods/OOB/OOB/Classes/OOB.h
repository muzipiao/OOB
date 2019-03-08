//
//  OOB.h
//  OpenCVDemo
//
//  Created by lifei on 2019/3/4.
//  Copyright © 2019 PacteraLF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "OOBDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface OOB : NSObject

+ (instancetype)share;

/**
 * 识别图像并返回目标图像坐标位置，坐标位置与设置的预览视图(preview)相关。
 * Identify the image and return to the target image coordinate position, which is related to the set preview view.
 @param targetImg 待识别的目标图像(target image to be recognized)
 @param resultBlock 识别结果(recognition result),targetRect：目标位置(target position)，similarValue：目标与视频物体中的相似度(similarity between the target and the video object)
 * 备注：当 targetRect 宽高为 0 时代表未识别到图像，similarValue 值越大代表相似度越高
 * Note: When the targetRect width and height is 0, it means that the image is not recognized. The larger the similarValue value, the higher the similarity.
 */
-(void)matchTemplate:(UIImage *)targetImg
   resultBlock:(nullable void (^)(CGRect targetRect, CGFloat similarValue))resultBlock;

/**
 * 停止识别图像
 * Stop recognizing images
 * 视图消失或销毁时必须执行此方法释放资源。
 * This method must be executed to release resources when the view disappears or is destroyed.
 */
-(void)stopMatch;


///MARK: - 其他可选属性（Other optional attributes）
/**
 * 视频预览视图，不设置不显示预览视频，获取的坐标默认为全屏坐标。
 * Video preview view, no setting does not display preview video, the acquired coordinates default to full screen coordinates.
 */
@property (nonatomic, strong) UIView *preview;

/**
 * 待识别的目标图像,可随时切换待识别目标。
 * The target image to be identified can be switched at any time to be identified.
 */
@property (nonatomic, strong) UIImage *targetImg;

/**
 * 前置后置摄像头切换，设置可切换摄像头，默认后置摄像头.
 * Front rear camera switch, setting can switch camera, default rear camera
 */
@property (nonatomic, assign) OOBCameraType cameraType;

/**
 * 视频预览视图图像质量，默认预览视频尺寸 1920x1080，可自行设置。
 * Video preview size, the default is 1920x1080, Apple's output video size can only choose several kinds of enumeration.
 */
@property(nonatomic, copy) AVCaptureSessionPreset sessionPreset;

/**
 * 待识别物体与视频对比的相似度。值越大代表相似度越高。
 * The similarity between the object to be identified and the video. The larger the value, the higher the similarity.
 * 默认值为 0.7，最大为 1.0。值设置的越小误报率高，值设置的越大越难匹配。
 * The default value is 0.7, maximum value is 1.0. The smaller the value is set, the higher the false alarm rate is. The larger the value is set, the harder it is to match.
 */
@property (nonatomic, assign) CGFloat similarValue;


///MARK: - 标记图像(可选，用户可自定义标记图像)
//mark: - tag image (optional, user-customizable tag image)
/**
 * 标记框的线宽，默认宽度 5.0f。
 * Marker box line width, default width 5.0f.
 */
@property (nonatomic, assign) CGFloat markerLineWidth;

/**
 * 标记框为矩形时，切圆角，默认 5.0f。
 * When the mark box is rectangular, it is rounded, default 5.0f.
 */
@property (nonatomic, assign) CGFloat markerCornerRadius;

/**
 * 标记框的颜色，默认红色。
 * The color of the marker box, default red.
 */
@property (nonatomic, strong) UIColor *markerLineColor;

/**
 * 矩形标记框
 * Rectangular marker box
 */
@property (nonatomic, strong) UIImage *rectMarkerImage;

/**
 * 椭圆标记框
 * Elliptical marker box
 */
@property (nonatomic, strong) UIImage *ovalMarkerImage;


@end

NS_ASSUME_NONNULL_END
