//
//  CIFilterVC.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/7/11.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "CIFilterVC.h"
#import <AVFoundation/AVFoundation.h>

@interface CIFilterVC ()

//处理后预览图层
@property (nonatomic, strong) CALayer *targetImgLayer;

//定义GPU环境
@property (nonatomic, strong) CIContext *context;

//定义滤镜
@property (nonatomic, strong) CIFilter *filter;

@end

@implementation CIFilterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //初始化目标图层
    [self initTargetLayer];
    
}

//初始化目标图层
-(void)initTargetLayer{
    //宽高与上面的相同
    CGFloat layerW = self.view.bounds.size.width - 100;
    CGFloat layerTop = 70 + layerW + 10;

    //创建一个处理后的预览图层
    CALayer *targetLayer = [CALayer layer];
    //图层旋转90度
    targetLayer.affineTransform = CGAffineTransformMakeRotation(M_PI * 0.5);
    [self.view.layer addSublayer:targetLayer];
    targetLayer.frame = CGRectMake(50, layerTop, layerW, layerW);
    self.targetImgLayer = targetLayer;
    
    //提示1
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 70, self.view.bounds.size.width, 44)];
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    label.text = @"视频源图像";
    
    //提示2
    UILabel *label2 = [[UILabel alloc]initWithFrame:CGRectMake(0, layerTop, self.view.bounds.size.width, 44)];
    label2.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label2];
    label2.text = @"高斯模糊处理后";
    
}

#pragma mark - 视频输出流的代理
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //输出预览
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *outputImg = [CIImage imageWithCVImageBuffer:imageBuffer];
    
    //视频添加高斯滤镜
    [self.filter setValue:outputImg forKey:kCIInputImageKey];
    outputImg = self.filter.outputImage;
    
    CGImageRef cgImage =  [self.context createCGImage:outputImg fromRect:outputImg.extent];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (cgImage) {
            self.targetImgLayer.contents = (__bridge id _Nullable)cgImage;
        }
    });

}

//环境
-(CIContext *)context{
    if (_context == nil) {
        //创建一个GPU的上下文
        EAGLContext *eaglContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        //关闭颜色管理
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null],kCIContextWorkingColorSpace, nil];
        _context = [CIContext contextWithEAGLContext:eaglContext options:options];
    }
    return _context;
}

//高斯滤镜
-(CIFilter *)filter{
    if (_filter == nil) {
        _filter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [_filter setDefaults];
        [_filter setValue:[NSNumber numberWithFloat:2.0f] forKey:@"inputRadius"];
    }
    return _filter;
}


@end
