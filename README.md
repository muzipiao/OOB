# OOB

[![CI Status](https://img.shields.io/travis/muzipiao/OOB.svg?style=flat)](https://travis-ci.org/muzipiao/OOB)
[![codecov](https://codecov.io/gh/muzipiao/OOB/branch/master/graph/badge.svg)](https://codecov.io/gh/muzipiao/OOB)
[![Version](https://img.shields.io/cocoapods/v/OOB.svg?style=flat)](https://cocoapods.org/pods/OOB)
[![License](https://img.shields.io/cocoapods/l/OOB.svg?style=flat)](https://cocoapods.org/pods/OOB)
[![Platform](https://img.shields.io/cocoapods/p/OOB.svg?style=flat)](https://cocoapods.org/pods/OOB)

![](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OOB/caomei.PNG)
![](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OOB/jitui.PNG)
![](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OOB/apple_video.gif)

## 示例

下载分支后，先 `cd` 切换到当前 Example 文件夹目录下，然后执行 `pod install` ，完成后打开 `OOB.xcworkspace` 文件运行。

注意：由于 opencv2.framework 压缩包较大（约 146MB），网速比较慢的情况下，下载时间会较长；个别网络（如长城宽带）会一直下载失败，这种情况可手动集成。

## 环境需求

* OpenCV2
* Foundation.framework
* UIKit.framework
* AVFoundation.framework

## 安装

### CocoaPods

CocoaPods 是最简单方便的安装方法，编辑 Podfile 文件，添加

```ruby
pod 'OOB'
```
然后执行 `pod install` 即可。

### 直接安装

1. 直接安装 `OOB` 前，请先安装 `OpenCV`，参考我的一篇博客：[iOS集成OpenCV博客](http://cocoafei.top/2017/07/iOS%E9%9B%86%E6%88%90OpenCV/)
2. 从 Git 下载最新代码，找到和 README 同级的 OOB 文件夹，将 OOB 文件夹拖入项目即可。
3. 在需要使用的地方导入 `#import "OOB.h"` 即可。

## 用法

### 设置视频预览图层

设置视频预览图层，如果不设置则不展示预览视频，返回的目标坐标默认是全屏时的坐标。设置视频预览图层很简单，添加代码：

```objc
// 设置视频预览图层
[OOBTemplate share].preview = self.view;
```
### 调用图像识别

使用 OOB 很简单，在需要进行图像识别的地方，添加代码：

```objc
/**
* 开始图像识别
* targetImg: 待识别的目标图像
@param targetRect 目标图像在预览图层中的 frame
@param similarValue 目标模板与视频图像中图像的相似度
@return 识别图像在block中回调
*/
[[OOBTemplate share] matchCamera:self.targetImg resultBlock:^(CGRect targetRect, CGFloat similarValue) {
OOBLog(@"相似度：%.0f %%，目标位置：Rect:%@",similarValue * 100,NSStringFromCGRect(targetRect));
}];
```
Block 回调会返回目标位置，和对比的相似度，Block 刷新频率和视频帧率相同。

### 结束图像识别

识别任务结束，或当期视图销毁时，调用 `[[OOBTemplate share] stopMatch];` 释放资源即可。

### 其他设置

切换目标图像，可随时切换

```objc
[OOBTemplate share].targetImage = [UIImage imageNamed:@"apple"];
```

切换前置后置摄像头

```objc
// 切换为后置摄像头
[OOBTemplate share].cameraType = OOBCameraTypeBack;
// 切换为前置摄像头
[OOBTemplate share].cameraType = OOBCameraTypeFront;
```

设置预览视频图像质量，默认预览视频尺寸 1920x1080

```objc
// 设置视频预览质量为高
[OOBTemplate share].sessionPreset = AVCaptureSessionPresetHigh;
// 设置视频预览尺寸为 640x480
[OOBTemplate share].sessionPreset = AVCaptureSessionPreset640x480;
```
设置相似度阈值，默认是 0.7，最大为 1。值设置的越小误报率高，值设置的越大越难匹配。

```objc
// 设置阈值为 0.8，识别更精确一些。
[OOBTemplate share].similarValue = 0.8;
```

生成一张标记目标的 UIImage 图片，自带一张矩形和一张圆形的标记图片。

```objc
// 更改标记框框颜色为深红色：R=254 G=67 B=101
[OOBTemplate share].markerLineColor =  [UIColor colorWithRed:254.0/255.0 green:67.0/255.0 blue:101.0/255.0 alpha:1.0];
// 更改标记框线宽为 8.0
[OOBTemplate share].markerLineWidth = 8.0;
// 更改矩形框切圆角半径为 8.0
[OOBTemplate share].markerCornerRadius = 8.0;
// 生成一张矩形标记框
UIImage *rectImage = [OOBTemplate share].rectMarkerImage;
// 生成一张椭圆标记框
UIImage *ovalImage = [OOBTemplate share].ovalMarkerImage;
```

## 其他

如果您觉得有所帮助，请在 [GitHub OOBDemo](https://github.com/muzipiao/OOB) 上赏个Star ⭐️，您的鼓励是我前进的动力
