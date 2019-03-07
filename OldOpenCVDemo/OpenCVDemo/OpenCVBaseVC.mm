//
//  OpenCVBaseVC.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/7/11.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "OpenCVBaseVC.h"

@interface OpenCVBaseVC ()<AVCaptureVideoDataOutputSampleBufferDelegate>

//当前视频会话
@property (nonatomic, strong) AVCaptureSession *session;
//摄像头前面输入
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput;
//摄像头前面输入
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput;

//是否是前置摄像头,默认是no
@property (nonatomic, assign) BOOL isDevicePositionFront;

@end

@implementation OpenCVBaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置导航右侧按钮
    [self createNavBtn];
    //设置视频格式
    [self initVideoSet];
    
}

//设置导航右侧按钮
-(void)createNavBtn{
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *rBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [rBtn setTitle:@"切换摄像头" forState:UIControlStateNormal];
    [rBtn sizeToFit];
    [rBtn addTarget:self action:@selector(navBtnToChangeCammer) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithCustomView:rBtn];
    self.navigationItem.rightBarButtonItem = item;
}

#pragma mark - 切换前后摄像头
-(void)navBtnToChangeCammer{
    if ( self.isDevicePositionFront ){
        [self.session stopRunning];
        [self.session removeInput:self.frontCameraInput];
        if ([self.session canAddInput:self.backCameraInput]) {
            [self.session addInput:self.backCameraInput];
            [self.session startRunning];
        }
    }else{
        [self.session stopRunning];
        [self.session removeInput:self.backCameraInput];
        if ([self.session canAddInput:self.frontCameraInput]) {
            [self.session addInput:self.frontCameraInput];
            [self.session startRunning];
        }
    }
}

#pragma mark - 视频初始化设置
-(void)initVideoSet{
    //创建一个Session会话，控制输入输出流
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    //设置视频质量
    session.sessionPreset = AVCaptureSessionPresetMedium;
    self.session = session;
    
    //选择输入设备,默认是后置摄像头
    AVCaptureDeviceInput *input = self.backCameraInput;
    //设置视频输出流
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc]init];
    
    //设置输出格式
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],                                   kCVPixelBufferPixelFormatTypeKey,nil];
    output.videoSettings = settings;
    
    //设置输出的代理
    dispatch_queue_t videoQueue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    [output setSampleBufferDelegate:self queue:videoQueue];
    
    //将输入输出添加到会话，连接
    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    
    //创建预览图层
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:session];
    //设置layer大小
    CGFloat layerW = self.view.bounds.size.width - 40;
    previewLayer.frame = CGRectMake(20, 70, layerW, layerW);
    //视频大小根据frame大小自动调整
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer];
    self.previewLayer = previewLayer;
    
    //创建一个处理后的预览图层,用来标记
    CAShapeLayer *targetLayer = [CAShapeLayer layer];
    targetLayer.frame = previewLayer.frame;
    [self.view.layer addSublayer:targetLayer];
    targetLayer.backgroundColor = [UIColor clearColor].CGColor;
    self.tagLayer = targetLayer;

    //启动session
    [session startRunning];
    
}

#pragma mark - 摄像头输入
- (AVCaptureDeviceInput *)backCameraInput {
    if (_backCameraInput == nil) {
        NSError *error;
        AVCaptureDevice *device = [self cameraWithPosition:AVCaptureDevicePositionBack];
        _backCameraInput = [[AVCaptureDeviceInput  alloc] initWithDevice:device error:&error];
        if (error) {
            NSLog(@"后置摄像头获取失败");
        }
    }
    self.isDevicePositionFront = NO;
    return _backCameraInput;
}

- (AVCaptureDeviceInput *)frontCameraInput {
    if (_frontCameraInput == nil) {
        NSError *error;
        AVCaptureDevice *device = [self cameraWithPosition:AVCaptureDevicePositionFront];
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        if (error) {
            NSLog(@"前置摄像头获取失败");
        }
    }
    self.isDevicePositionFront = YES;
    return _frontCameraInput;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ){
            return device;
        }
    return nil;
}

@end
