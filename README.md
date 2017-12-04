#### **注意：OpenCV框架(opencv2.framework)超过100M，无法提交，请至[OpenCV官网](http://opencv.org)自行下载，拖入项目`ThirdFramework`文件下即可**

## iOS通过摄像头动态识别图像

### 前言：

> **目前的计算机图像识别，透过现象看本质，主要分为两大类:**
> 
> * 基于规则运算的图像识别，例如颜色形状等模板匹配方法
> * 基于统计的图像识别。例如机器学习ML，神经网络等人工智能方法
> 
> **区别：**模板匹配方法适合固定的场景或物体识别，机器学习方法适合大量具有共同特征的场景或物体识别。
> 
> **对比：**无论从识别率，准确度，还是适应多变场景变换来讲，机器学习ML都是优于模板匹配方法的；前提你有`大量的数据`来训练分类器。如果是仅仅是识别特定场景、物体或者形状，使用模板匹配方法更简单更易于实现。
> 
> **目标：**实现在iOS客户端，通过摄像头发现并标记目标。
> 

### 实现效果图

![效果图](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OpenCVBlogImage/OpenCVBlogMergeImg.png)

![logo](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OpenCVBlogImage/MLMerge.png)

![OpenCV处理图像](https://raw.githubusercontent.com/muzipiao/GitHubImages/master/OpenCVImg/OpenCVBlogImage/OpenCVToPsImg.PNG)


### 可能出现的异常：

1. 将从官网下载的opencv2.framework拖入项目后，出现找不到opencv2库的错误：**`ld: framework not found opencv2    clang:error: linker command failed with...`**。原因估计是打开项目用的XCode 9，而拖入的opencv2.framework版本为3.2版本；看`opencv2.framework的3.3版本`更新说明，估计XCode 9与3.2版本不兼容，**下载最新3.3版本**[https://opencv.org/opencv-3-3.html](https://opencv.org/opencv-3-3.html)，拖入ThirdFramework文件夹下，编译即可通过。
2. 拖入`opencv2.framework的3.3版本`后，编译出现大量类似警告：

* Direct access in function '\_\_\_cxx\_global\_var\_init' from file ...
* Direct access in function '\_\_\_cxx\_global\_var\_init.2' from file ... 
* Direct access in function '\_\_\_cxx\_global\_var\_init.3' from file ...  

Google搜索，以及在stackoverflow上发现很多人遇到同样问题，暂时未找到解决办法，但不影响功能使用，暂时忽略即可，估计下一版本会修复。
