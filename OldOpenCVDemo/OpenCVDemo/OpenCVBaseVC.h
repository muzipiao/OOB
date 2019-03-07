//
//  OpenCVBaseVC.h
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/7/11.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//
//因为都要用到摄像头，所以抽取基类，摄像头设置放在这里

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface OpenCVBaseVC : UIViewController

//预览视频图层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

//标记位置的图层
@property (nonatomic, strong) CAShapeLayer *tagLayer;

@end
