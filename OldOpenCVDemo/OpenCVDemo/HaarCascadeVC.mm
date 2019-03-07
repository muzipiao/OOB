//
//  HaarCascadeVC.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/7/11.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "OpenCVManager.h"
#import "HaarCascadeVC.h"

@interface HaarCascadeVC ()
{
    cv::CascadeClassifier icon_cascade;//分类器
    BOOL isSuccessLoadXml;
}

@end

@implementation HaarCascadeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //加载训练文件
    [self loadTemplate];
    
}

//加载训练好的文件
-(void)loadTemplate{
    //加载训练文件
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_eye_tree_eyeglasses.xml" ofType:nil];
    cv::String fileName = [bundlePath cStringUsingEncoding:NSUTF8StringEncoding];
    
    BOOL isSuccessLoadFile = icon_cascade.load(fileName);
    isSuccessLoadXml = isSuccessLoadFile;
    if (isSuccessLoadFile) {
        NSLog(@"Load success.......");
    }else{
        NSLog(@"Load failed......");
    }

}

#pragma mark - 获取视频帧，处理视频
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if(!isSuccessLoadXml)return;
    [NSThread sleepForTimeInterval:0.5];
    
    cv::Mat imgMat;
    imgMat = [OpenCVManager bufferToMat:sampleBuffer];
    //转换为灰度图像
    cv::cvtColor(imgMat, imgMat, CV_BGR2GRAY);
    UIImage *tempImg = MatToUIImage(imgMat);
    
    //获取标记的矩形
    NSArray *rectArr = [self getTagRectInLayer:imgMat];
    //转换为图片
    UIImage *rectImg = [OpenCVManager imageWithColor:[UIColor redColor] size:tempImg.size rectArray:rectArr];
    
    CGImageRef cgImage = rectImg.CGImage;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (cgImage) {
            self.tagLayer.contents = (__bridge id _Nullable)cgImage;
        }
    });
}

//获取计算出的标记的位置，保存在数组中
-(NSArray *)getTagRectInLayer:(cv::Mat) inputMat{
    if (inputMat.empty()) {
        return nil;
    }
    //图像均衡化
    cv::equalizeHist(inputMat, inputMat);
    //定义向量，存储识别出的位置
    std::vector<cv::Rect> glassess;
    //分类器识别
    icon_cascade.detectMultiScale(inputMat, glassess, 1.1, 3, 0);
    //转换为Frame，保存在数组中
    NSMutableArray *marr = [NSMutableArray arrayWithCapacity:glassess.size()];
    for (NSInteger i = 0; i < glassess.size(); i++) {
        CGRect rect = CGRectMake(glassess[i].x, glassess[i].y, glassess[i].width,glassess[i].height);
        NSValue *value = [NSValue valueWithCGRect:rect];
        [marr addObject:value];
    }
    return marr.copy;
}


@end
