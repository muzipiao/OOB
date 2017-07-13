#### **注意：OpenCV框架(opencv2.framework)超过100M，无法提交，请至[OpenCV官网](http://opencv.org)自行下载，拖入项目即可**

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

