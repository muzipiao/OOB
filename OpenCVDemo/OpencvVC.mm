//
//  OpencvVC.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/6/29.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "OpencvVC.h"

@interface OpencvVC ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    cv::Mat cvImage;
}

@property (nonatomic, strong) NSMutableArray <UIImageView *>*imgViewArr;

//输入设备（摄像头，拾音器）
@property (nonatomic, strong) AVCaptureDeviceInput *audioDeviceInput;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
//输出设备
@property (nonatomic, strong) AVCaptureMovieFileOutput *fileOutput;

//会话（连接输入设备和输出设备）
@property (nonatomic, strong) AVCaptureSession *session;

//预览的图层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;


@end

@implementation OpencvVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.imgViewArr = [NSMutableArray arrayWithCapacity:10];
    
    for (NSInteger i = 0; i < 10; i++) {
        CGFloat vw = self.view.bounds.size.width * 0.5;
        CGFloat vh = vw;
        CGFloat vx = 0;
        if(i%2==0)vx=vw;
        CGFloat vy = 64 + (i/2)*vw;
        
        UIImageView *tempImgView = [[UIImageView alloc]initWithFrame:CGRectMake(vx, vy, vw, vh)];
        tempImgView.backgroundColor =  [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
        [self.view addSubview:tempImgView];
        [self.imgViewArr addObject:tempImgView];
    }
    
//    [self imgTest];
//    [self findEdges];
//    [self testCreateImg];
    [self testVideo1];
}

-(void)testVideo1{
    NSError *error;
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    session.sessionPreset = AVCaptureSessionPresetMedium;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //设置帧率
    device.activeVideoMinFrameDuration = CMTimeMake(1, 12);
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc]init];
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    // Specify the pixel format
    output.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                            [NSNumber numberWithInt: 320], (id)kCVPixelBufferWidthKey,
                            [NSNumber numberWithInt: 240], (id)kCVPixelBufferHeightKey,nil];
    
    AVCaptureVideoPreviewLayer* preLayer = [AVCaptureVideoPreviewLayer layerWithSession: session];//相机拍摄预览图层
    //preLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    preLayer.frame = CGRectMake(20, 400, 320, 240);
    preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:preLayer];
    // If you wish to cap the frame rate to a known value, such as 15 fps, set
    // minFrameDuration.
//    output.minFrameDuration = CMTimeMake(1, 15);
    
    //获取输入的连接，设置镜像，横竖屏等
    AVCaptureConnection *connect = [output connectionWithMediaType:AVMediaTypeVideo];
    connect.videoMirrored = NO;
    
    
    // Start the session running to start the flow of data
    [session startRunning];
}

// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
//    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    
//    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
//    
//    CGRect rect = CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
//    
//    CIContext *context = [CIContext contextWithOptions:nil];
//    
//    CGImageRef imageRef = [context createCGImage:ciImage fromRect:rect];
    
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    cv::Mat frame;
    UIImageToMat(image, frame);

    //转换为灰度图像
    cv::Mat edges;
    cv::cvtColor(frame, edges, CV_BGR2GRAY);
    cv::Canny(edges, edges, 0, 80);
    
    //转换为UIImage
    UIImage *blankImg = MatToUIImage(edges);
    self.imgViewArr[2].image = blankImg;
    [self.imgViewArr[2] sizeToFit];
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


-(void)testVideo{
    //打开第一个摄像头
//    cv::VideoCapture cap(0);
//    if (!cap.isOpened()) {
//        NSLog(@"摄像头打开失败");
//        return;
//    }
//
//    for(;;){
//        //定义一帧
//        cv::Mat frame;
//        //从摄像头读取一帧
//        cap >> frame;
//        //如果未读取到图像，则结束循环
//        if (frame.empty()) {
//            break;
//        }
//        //转换为灰度图像
//        cv::Mat edges;
//        cv::cvtColor(frame, edges, CV_BGR2GRAY);
//        cv::Canny(edges, edges, 0, 50);
//        
//        //转换为UIImage
//        UIImage *blankImg = MatToUIImage(edges);
//        self.imgViewArr[2].image = blankImg;
//        [self.imgViewArr[2] sizeToFit];
//        
//        [NSThread sleepForTimeInterval:1.0];
//        
//    }
    
}



-(void)baseEditImg{
    //读取图像
    cv::Mat cvImg;
    UIImage *image = [UIImage imageNamed:@"lg"];
    //将UIImage转换为mat矩阵类型
    UIImageToMat(image, cvImg);
    
    //将图像转换为灰度
    cv::Mat cvGrayImg;
    //将图像转换为灰度图像
    cv::cvtColor(cvImg, cvGrayImg, CV_RGB2GRAY);
    
}

-(void)matTest{
    //Mat类默认构造函数
    cv::Mat tempMat;
    tempMat = cv::Mat();
    //常用构造函数1
    tempMat = cv::Mat();
}



-(void)testCreateImg{
    cv::Mat cvBlankImg;
    //二维单通道矩阵
    cvBlankImg = cv::Mat(200,200,CV_8UC1,CvScalar(120,0,0));
    
    //读取单个像素
    uchar *singleData = cvBlankImg.data;
    for (NSInteger i = 0; i < cvBlankImg.rows; i++) {
        for (NSInteger j = 0; j < cvBlankImg.cols; j++) {
            singleData = cvBlankImg.data + j*cvBlankImg.step + i*cvBlankImg.elemSize();
            singleData[0] = (i+j)%255;
        }
        if (cvBlankImg.isContinuous()) {
            NSLog(@"没有填满");
        }else{
            NSLog(@"已经填满");
        }
    }
    
    cv::Vec4b vec;
    vec[0] = 255;
    vec[1] = 100;
    
    
    //转换为UIImage
    UIImage *blankImg = MatToUIImage(cvBlankImg);
    self.imgViewArr[2].image = blankImg;
    [self.imgViewArr[2] sizeToFit];

}



-(void)findEdges{
    //定义矩阵变量
    cv::Mat tempCvImage;
    UIImage *image = [UIImage imageNamed:@"lg"];
    //将UIImage转换为mat矩阵类型
    UIImageToMat(image, tempCvImage);
    //定义转换后的矩阵
    cv::Mat targetResizeMat;
    //变换图像尺寸
    cv::resize(tempCvImage, targetResizeMat, cv::Size(150,150));
    //将矩阵转换为UIImage
    UIImage *resizeImg = MatToUIImage(targetResizeMat);
    self.imgViewArr[0].image = resizeImg;
    [self.imgViewArr[0] sizeToFit];
    
    //------------------
    //定义转换后的矩阵
    cv::Mat targetResizeMat1;
    //将图像转换为灰度图像
    cv::cvtColor(tempCvImage, targetResizeMat1, CV_RGB2GRAY);
    //变换图像尺寸
    cv::resize(tempCvImage, targetResizeMat1, cv::Size(150,150));
    //创建直方图
    cv::Mat histMat;
    
    
    
    //将矩阵转换为UIImage
    UIImage *resizeImg1 = MatToUIImage(targetResizeMat1);
    self.imgViewArr[1].image = resizeImg1;
    [self.imgViewArr[1] sizeToFit];
    
}


//
-(void)imgTest{
    UIImage *image = [UIImage imageNamed:@"lg"];
    
    UIImageToMat(image, cvImage);
    
    if(!cvImage.empty()){
        cv::Mat gray;
        // 将图像转换为灰度显示
        cv::cvtColor(cvImage,gray,CV_RGB2GRAY);
        [self showImg:gray atIndex:0];
        
        // 应用高斯滤波器去除小的边缘
        cv::GaussianBlur(gray, gray, cv::Size(5,5), 1.2,1.2);
        [self showImg:gray atIndex:1];
        
        // 计算与画布边缘
        cv::Mat edges;
        cv::Canny(gray, edges, 0, 150);
        [self showImg:edges atIndex:2];
        
        
        // 使用白色填充
        cvImage.setTo(cv::Scalar::all(225));
        [self showImg:cvImage atIndex:3];
        
        // 修改边缘颜色
        cvImage.setTo(cv::Scalar(0,128,255,255),edges);
        [self showImg:cvImage atIndex:4];
        
        // 在点 (100,100) 和 (200,200) 之间绘制一矩形，边线用红色、宽度为 1
        cv::rectangle(cvImage, cvPoint(100,10), cvPoint(100,100), cvScalar(0,0,255));
        //画矩形
        cv::rectangle(cvImage, cvRect(10, 10, 100, 100), cvScalar(255,0,0));
        
        cv::line(cvImage, cvPoint(10, 100), cvPoint(200, 150), cvScalar(0,255,0));
        
        //文本标注
        cv::putText(cvImage, "wodeceshi", cvPoint(80, 80), 0, 1.0, cvScalar(0,255,0));
        [self showImg:cvImage atIndex:5];
        // 将Mat转换为Xcode的UIImageView显示
//        self.imgView.image = MatToUIImage(cvImage);
//        self.imgViewArr[0].image = MatToUIImage(cvImage);
        
    
    }
}

-(void)showImg:(cv::Mat)img atIndex:(NSInteger)index{
    UIImage *image = MatToUIImage(img);
    self.imgViewArr[index].image = image;
}


@end
