# OOB

[![CI Status](https://img.shields.io/travis/muzipiao/OOB.svg?style=flat)](https://travis-ci.org/muzipiao/OOB)
[![codecov](https://codecov.io/gh/muzipiao/OOB/branch/master/graph/badge.svg)](https://codecov.io/gh/muzipiao/OOB)
[![Version](https://img.shields.io/cocoapods/v/OOB.svg?style=flat)](https://cocoapods.org/pods/OOB)
[![License](https://img.shields.io/cocoapods/l/OOB.svg?style=flat)](https://cocoapods.org/pods/OOB)
[![Platform](https://img.shields.io/cocoapods/p/OOB.svg?style=flat)](https://cocoapods.org/pods/OOB)

![识别图片](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OOB/caomei.PNG)
![识别图片](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OOB/jitui.PNG)
![识别视频](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OOB/apple_video.gif)

## 快速开始

在终端运行以下命令:

```ruby
git clone https://github.com/muzipiao/OOB.git

cd OOB/Example 

pod install 

open OOB.xcworkspace
```

注意：由于 opencv2.framework 压缩包较大（约 146MB），网速比较慢的情况下，下载时间会较长；个别网络（如长城宽带）会一直下载失败，这种情况可切换至其他网络下载或手动集成。

## 环境需求

* OpenCV2
* UIKit.framework
* AVFoundation.framework

## 集成

### CocoaPods

CocoaPods 是最简单方便的集成方法，编辑 Podfile 文件，添加

```ruby
pod 'OOB'
```

然后执行 `pod install` 即可。

### 直接集成

1. 直接集成 `OOB` 前，请先集成 `OpenCV`，参考我的一篇博客：[iOS集成OpenCV博客](http://cocoafei.top/2017/07/iOS-%E9%9B%86%E6%88%90-OpenCV/)
2. 从 Git 下载最新代码，找到和 README 同级的 OOB 文件夹，将 OOB 文件夹拖入项目即可。
3. 在需要使用的地方导入 `#import "OOB.h"` 即可。

## 用法

### 设置预览图层

设置预览图层很简单，添加代码：

```objc
// 设置视频预览图层
OOBTemplate.preview = self.view;
```

注意：

1. 识别摄像头目标，设置预览图层，展示摄像头视频流。不设置预览图层，不展示摄像头视频流，返回的目标 Frame 按照全屏展示计算。
2. 识别视频文件目标，传入展示当前视频帧图像的 View。不设置预览图层，返回目标 Frame 按照视频帧图像 100% 不缩放计算（即视频帧图像 sizeToFit 展示）。
3. 识别背景图片目标，传入展示当前背景图片的 View。不设置预览图层，返回目标 Frame 按照背景图片 100% 不缩放计算（即背景图片 sizeToFit 展示）。

### 识别摄像头中目标

识别摄像头视频流中的目标，传入目标图片，Block 中回调获取结果，刷新频率和视频帧率相同，示例代码：

```objc
/**
 * 开始图像识别
 @param target: 待识别的目标图像
 @param rect 目标图像在预览图层中的 frame
 @param similar 目标模板与视频图像中图像的相似度
 @return 识别图像在block中回调
 */
[OOBTemplate match:self.targetImg result:^(CGRect rect, CGFloat similar) {
    OOBLog(@"与背景中目标的相似度：%.0f %%",similar * 100);
    OOBLog(@"摄像头视频流中目标 Rect：%@",NSStringFromCGRect(rect));
}];
```

### 识别视频文件中目标

识别摄像头视频流中的目标，传入目标图片，视频文件的 URL，Block 中回调获取结果。

视频文件分辨率较小时，刷新频率和视频帧率相同；分辨率较大时，Block 回调速度会变慢，示例代码：

```objc
// 待识别的视频文件 URL
NSURL *vdUrl = [[NSBundle mainBundle] URLForResource:@"oob_apple.m4v" withExtension:nil];
/**
* 识别视频中的目标，并返回目标在图片中的位置，实际相似度
@param target 待识别的目标图像
@param url 视频文件 URL
@param result 识别结果，分别是目标位置和实际的相似度，视频当前帧图像
*/
[OOBTemplate match:self.targetImg videoURL:vdUrl result:^(CGRect rect, CGFloat similar, UIImage * _Nullable frame) {
    OOBLog(@"与背景中目标的相似度：%.0f %%",similar * 100);
    OOBLog(@"摄像头视频流中目标 Rect：%@",NSStringFromCGRect(rect));
    OOBLog(@"当前视频帧图像：%@",frame);
}];
```

### 识别背景图片中目标

识别背景图片中的目标，传入目标图片，背景图片，Block 中回调获取结果。示例代码：

```objc
/**
 * 开始识别图像中的目标
 * target 目标在背景图片中的位置，注意不是 UImageView 中的实际位置，需要缩放转换
 * similar 要求的相似度，最大值为1，要求越大，精度越高，计算量越大
 */
[OOBTemplate match:self.targetImg bgImg:self.bgImg result:^(CGRect rect, CGFloat similar) {
    OOBLog(@"与背景中目标的相似度：%.0f %%",similar * 100);
    OOBLog(@"摄像头视频流中目标 Rect：%@",NSStringFromCGRect(rect));
}];
```

### 结束图像识别

若识别摄像头视频流，或视频文件流，必须**手动结束**匹配，调用 `[OOBTemplate stop];` 释放资源。

### 其他设置

可随时切换目标图像，调整目标与背景目标的相似度。其中相似度阈值，默认是 0.7，最大为 1。值设置的小速度快，误报率高；值设置的大，匹配速度越慢，准确率高。

```objc
// 调整对比的相似度在 80% 以上，最大为1
OOBTemplate.similarValue = 0.8;
// 切换目标图片
OOBTemplate.targetImage = [UIImage imageNamed:@"apple"];
```

如果视频摄像头视频流中目标，还可随时切换摄像头，调整视频预览质量。

```objc
// 切换为后置摄像头
OOBTemplate.cameraType = OOBCameraTypeBack;
// 切换为前置摄像头
OOBTemplate.cameraType = OOBCameraTypeFront;
// 设置视频预览质量为高，默认预览视频尺寸 1920x1080
OOBTemplate.sessionPreset = AVCaptureSessionPresetHigh;
// 设置视频预览尺寸为 640x480
OOBTemplate.sessionPreset = AVCaptureSessionPreset640x480;
```

生成一张标记目标的 UIImage 图片，中间透明，边框为切圆角的矩形图片。

```objc
// 生成一张和目标图片一样大小的矩形框图片，标记目标位置。颜色红色，线宽为 3，切圆角 5
UIImage *markImage = [OOBTemplate createRect:_targetImg.size borderColor:[UIColor redColor] borderWidth:3 cornerRadius:5]; // 设置标记图像为矩形
```

## 其他

如果您觉得有所帮助，请在 [GitHub OOBDemo](https://github.com/muzipiao/OOB) 上赏个Star ⭐️，您的鼓励是我前进的动力
