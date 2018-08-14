//
//  OpenCVToPsImgVC.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/7/12.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "OpenCVToPsImgVC.h"

@interface OpenCVToPsImgVC ()

//创建ImageView，保存其指针
@property (nonatomic, strong) NSMutableArray <UIImageView *>*imgViewArr;

@end

@implementation OpenCVToPsImgVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createUI];
}

-(void)createUI{
    CGFloat viewWidth = (self.view.bounds.size.width - 20 - 10) * 0.5;
    //设置摄像头的预览图层大小
    self.previewLayer.frame = CGRectMake(10, 70, viewWidth, viewWidth);
    
    self.imgViewArr = [NSMutableArray arrayWithCapacity:5];
    
    //创建8个ImageView
    for (NSInteger i = 0; i < 6; i++) {
        if (i==0) continue;
        
        CGFloat vx = 10;
        if (i%2 == 1) vx = 10 + viewWidth + 10;
 
        CGFloat vy = 70 + (i/2)*(viewWidth + 5);
        
        UIImageView *tempImgView = [[UIImageView alloc]initWithFrame:CGRectMake(vx, vy, viewWidth, viewWidth)];
        tempImgView.backgroundColor =  [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
        [self.view addSubview:tempImgView];
        [self.imgViewArr addObject:tempImgView];
    }
}

#pragma mark - 获取视频帧，处理视频
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    [NSThread sleepForTimeInterval:0.5];
    //将视频帧转换为cvmat,默认已经转换为
    cv::Mat imgMat;
    imgMat = [OpenCVManager bufferToMat:sampleBuffer];
    if (imgMat.empty()) {
        return;
    }
    
    // OpenCV中Mat矩阵颜色是按照BGR来储存的，转成UIImage之后，是按照RGB来的。
    // 所以在转换为UIImage之前，需要将Mat中的BGR转换为RGB；
    cv::Mat orginImgMat;
    cv::cvtColor(imgMat, orginImgMat, CV_BGR2RGB);
    
    //转换为灰度图像,加快处理速度
    cv::Mat grayMat = [self coverToGray:imgMat];
    
    //直方图均衡化
    cv::Mat calcHistMat = [self coverToEqualizeHist:grayMat];
    
    //轮廓图
    cv::Mat edgeMat = [self coverToEdge:imgMat];
    
    //二值化，可用来简单滤波
    cv::Mat binaryMat = [self coverToBinary:grayMat];
    
    //添加文字
    cv::putText(edgeMat, "Edge Image", cvPoint(10, 40), 0, 1.0, cvScalar(0,255,0));
    cv::putText(calcHistMat, "EqualizeHist Image", cvPoint(10, 40), 0, 1.0, cvScalar(0,255,0));
    cv::putText(grayMat, "Gray Image", cvPoint(10, 40), 0, 1.0, cvScalar(0,255,0));
    cv::putText(imgMat, "Orgin Image", cvPoint(10, 40), 0, 1.0, cvScalar(0,255,0));
    cv::putText(binaryMat, "Binary Image", cvPoint(10, 40), 0, 1.0, cvScalar(0,255,0));
    
    
    //在异步线程中，将任务同步添加至主线程，不会造成死锁
    dispatch_sync(dispatch_get_main_queue(), ^{
        //原图像
        self.imgViewArr[0].image = MatToUIImage(orginImgMat);
        //直方图均衡化
        self.imgViewArr[1].image = MatToUIImage(grayMat);
        //转换为灰度图像,加快处理速度
        self.imgViewArr[2].image = MatToUIImage(calcHistMat);
        //轮廓图
        self.imgViewArr[3].image = MatToUIImage(edgeMat);
        //二值化
        self.imgViewArr[4].image = MatToUIImage(binaryMat);
        
    });
}

//图像二值化
-(cv::Mat)coverToBinary:(cv::Mat) inputMat{
    //定义转换后的矩阵
    cv::Mat targetMat;
    //将图像转换为灰度图像
    cv::threshold(inputMat, targetMat, 100, 200, CV_THRESH_BINARY);
    return targetMat;
}


//将图像转换为灰度
-(cv::Mat)coverToGray:(cv::Mat) inputMat{
    //定义转换后的矩阵
    cv::Mat targetGrayMat;
    //将图像转换为灰度图像
    cv::cvtColor(inputMat, targetGrayMat, CV_RGB2GRAY);
    return targetGrayMat;
}

//直方图均衡化
-(cv::Mat)coverToEqualizeHist:(cv::Mat) inputMat{
    //定义转换后的矩阵
    cv::Mat targetMat;
    //将图像直方图均衡化
    cv::equalizeHist(inputMat, targetMat);
    return targetMat;
}

//将输入的图像转换为轮廓图
-(cv::Mat)coverToEdge:(cv::Mat) inputMat{
    // 将图像转换为灰度显示
    cv::Mat grayMat = [self coverToGray:inputMat];
    
    // 应用高斯滤波器去除小的边缘
    cv::GaussianBlur(grayMat, grayMat, cv::Size(5,5), 1.2,1.2);
    
    // 计算与画布边缘
    cv::Mat edgesMat;
    cv::Canny(grayMat, edgesMat, 0, 150);
    
    // 先用使用白色填充图像
    grayMat.setTo(cv::Scalar::all(225));
    
    //再画出边界 修改边缘颜色
    grayMat.setTo(cv::Scalar(0,128,255,255),edgesMat);
    return grayMat;
}


@end
