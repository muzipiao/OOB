//
//  FrameVC.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/7/4.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "FrameVC.h"
#import <AVFoundation/AVFoundation.h>

@interface FrameVC ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    NSInteger frameCount;
    CIFilter *filter;//定义一个滤镜
    BOOL isOneSec;
    NSTimer *timer;
}

@property (nonatomic, strong) CALayer *targetImgLayer;

@property (nonatomic, strong) CIContext *context;

@end

@implementation FrameVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initVideoSet];
    
    isOneSec = NO;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeR) userInfo:nil repeats:YES];
}

-(void)timeR{
    isOneSec = YES;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    CIFilter * sepiaTone = [CIFilter filterWithName:@"CISepiaTone"];
//    filter = sepiaTone;
}

//设置
-(void)initVideoSet{
//    int frame_rate = 15;
    int mWidth = self.view.bounds.size.width - 140;
    int mHeight = mWidth;
    
    //创建一个Session会话，控制输入输出流
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    //设置视频质量
    session.sessionPreset = AVCaptureSessionPresetMedium;
    
    //选择设备类型为视频
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *deviceError;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&deviceError];
    //设置视频输出流
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc]init];
    
    //设置输出
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],                                   kCVPixelBufferPixelFormatTypeKey,
                              [NSNumber numberWithInt: mWidth], (id)kCVPixelBufferWidthKey,
                              [NSNumber numberWithInt: mHeight], (id)kCVPixelBufferHeightKey,
                              nil];
    output.videoSettings = settings;
//    output.minFrameDuration = CMTimeMake(1, frame_rate);
    
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
    CGFloat layerW = self.view.bounds.size.width - 140;
    previewLayer.frame = CGRectMake(70, 70, layerW, layerW);
    //视频大小根据frame大小自动调整
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer];
    
    
    //创建一个处理后的预览图层
    CALayer *targetLayer = [CALayer layer];
    targetLayer.frame = CGRectMake(70, 70 + layerW + 10, layerW, layerW);
    //旋转90度
    targetLayer.affineTransform = CGAffineTransformMakeRotation(M_PI * 0.5);
    [self.view.layer addSublayer:targetLayer];
    self.targetImgLayer = targetLayer;
    
    //启动session
    [session startRunning];
    
}

#pragma mark - 视频输出流的代理
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //输出预览
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *outputImg = [CIImage imageWithCVImageBuffer:imageBuffer];
    
    CGImageRef cgImage =  [self.context createCGImage:outputImg fromRect:outputImg.extent];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.targetImgLayer.contents = CFBridgingRelease(cgImage);
    });
    
    if (isOneSec) {
        NSLog(@"视频帧正在输出..%ld",(long)frameCount++);
        isOneSec = NO;
    }
    
}

-(void)overLayer:(CMSampleBufferRef) sampleBuffer{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    //
    //    //然后提取一些有用的图片信息
    //    size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
    //    size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
    //    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    //    //视频缓冲区中是YUV格式的，要从缓冲区中提取luma部分：
    //    void *lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    //
    //    CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
    //    CGContextRef context = CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace, 0);
    CIImage *outputImg = [CIImage imageWithCVImageBuffer:imageBuffer];
    
    if (filter == nil) {
        filter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [filter setDefaults];
        [filter setValue:[NSNumber numberWithFloat:5.0f] forKey:@"inputRadius"];
    }
    [filter setValue:outputImg forKey:kCIInputImageKey];
    outputImg = filter.outputImage;
    
    CGImageRef cgImage =  [self.context createCGImage:outputImg fromRect:outputImg.extent];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.targetImgLayer.contents = (__bridge id _Nullable)(cgImage);
    });

}

//将Buffer缓存转换为UIImage
-(void)imageFromBuffer:(CMSampleBufferRef) sampleBuffer{
    //sampleBuffer是一个Core Media对象，可以引入Core Video供使用
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    //锁住缓冲区基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
//    //然后提取一些有用的图片信息
//    size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
//    size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
//    //视频缓冲区中是YUV格式的，要从缓冲区中提取luma部分：
//    void *lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
//    
//    //获取
//    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);


    
}

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

-(CIContext *)context{
    if (_context == nil) {
        //创建一个GPU的上下文
        EAGLContext *eaglContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        //关闭颜色管理
//        let options = [kCIContextWorkingColorSpace : NSNull()]
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null],kCIContextWorkingColorSpace, nil];
        _context = [CIContext contextWithEAGLContext:eaglContext options:options];
//        return CIContext(EAGLContext: eaglContext, options: options)
    }
    return _context;
}

@end
