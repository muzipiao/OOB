#### **注意：OpenCV 框架( opencv2.framework )超过 100M，无法提交，请至[ OpenCV 官网](http://opencv.org)自行下载，拖入项目` ThirdFramework `文件下即可**

* [iOS图像识别博客](http://cocoafei.top/2017/07/iOS%E5%9B%BE%E5%83%8F%E8%AF%86%E5%88%AB/)

* [iOS集成OpenCV博客](http://cocoafei.top/2017/07/iOS%E9%9B%86%E6%88%90OpenCV/)

备注：

原来的简书地址失效了，更新了一下博客地址，简书的博客已经被封了，这次更新把所有博客挪到依赖 GitPage 的[自建Blog](http://cocoafei.top/)上。

至于为什么被封，直接封了，然后给你一个链接让你自己猜，发邮件投诉没人理；面壁思过，想了半天，可能文中出现了一个 QQ 群号吧！

简书不适合喜欢自由的程序员！

## iOS通过摄像头动态识别图像

### 前言：

> **目前的计算机图像识别，透过现象看本质，主要分为两大类:**
> 
> * 基于规则运算的图像识别，例如颜色形状等模板匹配方法
> * 基于统计的图像识别。例如机器学习ML，神经网络等人工智能方法
> 
> 区别：模板匹配方法适合固定的场景或物体识别，机器学习方法适合大量具有共同特征的场景或物体识别。
> 
> 对比：无论从识别率，准确度，还是适应多变场景变换来讲，机器学习ML都是优于模板匹配方法的；前提你有`大量的数据`来训练分类器。如果是仅仅是识别特定场景、物体或者形状，使用模板匹配方法更简单更易于实现。
> 
> 目标：实现在iOS客户端，通过摄像头发现并标记目标。
> 

### 实现效果图

![效果图](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OpenCVBlogImage/OpenCVBlogMergeImg.png)

![logo](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OpenCVBlogImage/MLMerge.png)

![OpenCV处理图像](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OpenCVBlogImage/OpenCVToPsImg.PNG)


### 可能出现的异常：

1. 将从官网下载的 opencv2.framework 拖入项目后，出现找不到 opencv2 库的错误：**`ld: framework not found opencv2    clang:error: linker command failed with...`**。原因估计是打开项目用的 XCode 9，而拖入的 opencv2.framework 版本为 3.2 版本；看`opencv2.framework 的 3.3 版本`更新说明，估计 XCode 与 3.2 版本不兼容，**下载最新4.0版本**[https://jaist.dl.sourceforge.net/project/opencvlibrary/4.0.0/opencv-4.0.0-ios-framework.zip](https://jaist.dl.sourceforge.net/project/opencvlibrary/4.0.0/opencv-4.0.0-ios-framework.zip)，拖入ThirdFramework文件夹下，编译即可通过。
2. 如果为3.3版本，拖入`opencv2.framework的3.3版本`后，编译出现大量类似警告：

* Direct access in function '\_\_\_cxx\_global\_var\_init' from file ...
* Direct access in function '\_\_\_cxx\_global\_var\_init.2' from file ... 
* Direct access in function '\_\_\_cxx\_global\_var\_init.3' from file ...  

Google 搜索，以及在 stackoverflow 上发现很多人遇到同样问题，暂时未找到解决办法，但不影响功能使用，暂时忽略即可。(备注：3.4.1 以上版本，现在是 4.0.0 版本已经修复此问题，拖入后不再出现这些警告)
