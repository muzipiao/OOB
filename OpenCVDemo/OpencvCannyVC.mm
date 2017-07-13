//
//  OpencvCannyVC.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/7/4.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "OpencvCannyVC.h"

using namespace std;
using namespace cv;

@interface OpencvCannyVC ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    NSInteger frameCount;
    CIFilter *filter;//定义一个滤镜
    BOOL isOneSec;
    NSTimer *timer;
    cv::Mat templateMat;
    cv::Point currentLoc;
    cv::CascadeClassifier icon_cascade;
}

@property (nonatomic, strong) UIImageView *imgView;

//标记位置的图层
@property (nonatomic, strong) CAShapeLayer *rectLayer;


@end

@implementation OpencvCannyVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initVideoSet];
    
    //初始化模板图像
    [self initTemplateImage:@"cebicon"];
    
    isOneSec = NO;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeR) userInfo:nil repeats:YES];
    
    //加载训练文件
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_eye_tree_eyeglasses.xml" ofType:nil];
    cv::String fileName = [bundlePath cStringUsingEncoding:NSUTF8StringEncoding];
    
    BOOL isSuccessLoadFile = icon_cascade.load(fileName);
    if (isSuccessLoadFile) {
        NSLog(@"success.......");
    }else{
        NSLog(@"failed......");
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [timer invalidate];
    timer = nil;
}

-(void)timeR{
    isOneSec = YES;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self initTemplateImage:@"fuzi"];
    NSLog(@"切换为扫福！！！");
}


-(void)initTemplateImage:(NSString *)imgName{
    UIImage *templateImage = [UIImage imageNamed:imgName];
//    cv::Mat templateMat;
    UIImageToMat(templateImage, templateMat);
    cv::cvtColor(templateMat, templateMat, CV_BGR2GRAY);
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ){
            return device;
        }
    return nil;
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
//    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //    AVCaptureDevicePositionBack  后置摄像头
    //    AVCaptureDevicePositionFront 前置摄像头
    AVCaptureDevice *device = [self cameraWithPosition:AVCaptureDevicePositionFront];
    
    NSError *deviceError;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&deviceError];
    //设置视频输出流
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc]init];
    
    //设置输出kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    //kCVPixelFormatType_32BGRA
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
//    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(70, 70 + layerW + 10, layerW, layerW)];
//    [self.view addSubview:imageView];
//    self.imgView = imageView;
    
    
    //创建一个处理后的预览图层
    CAShapeLayer *targetLayer = [CAShapeLayer layer];
    targetLayer.frame = previewLayer.frame;
    //旋转90度
//    targetLayer.affineTransform = CGAffineTransformMakeRotation(M_PI * 0.5);
    [self.view.layer addSublayer:targetLayer];
    targetLayer.backgroundColor = [UIColor clearColor].CGColor;
    self.rectLayer = targetLayer;
    
//    //画个矩形
//    UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:CGRectMake(10, 10, 50, 60)];
//    targetLayer.path = rectPath.CGPath;
//    targetLayer.strokeColor = [UIColor redColor].CGColor;
//    targetLayer.fillColor = [UIColor clearColor].CGColor;
    
    
    //启动session
    [session startRunning];
    
}

#pragma mark - 视频输出流的代理
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (isOneSec) {
        
        //转换为mat
//        cv::Mat imgMat = [self bufferToMat:sampleBuffer];
        //比较与模板是否相同
//        [self compareByLevel:10 CameraInput:imgMat];
//        [self eyeGlassess:imgMat];
        
        //转换为UIImage，并输出
        UIImage *img = [self showFullColorImage:sampleBuffer];
        
        CGImageRef cgImage = img.CGImage;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (cgImage) {
                self.rectLayer.contents = (__bridge id _Nullable)cgImage;
            }
        });
        isOneSec = NO;
    }
}

-(UIImage *)showFullColorImage:(CMSampleBufferRef) sampleBuffer{
    CVImageBufferRef imgBuf = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //锁定内存
    CVPixelBufferLockBaseAddress(imgBuf, 0);
    // get the address to the image data
    void *imgBufAddr = CVPixelBufferGetBaseAddress(imgBuf);
    
    // get image properties
    int w = (int)CVPixelBufferGetWidth(imgBuf);
    int h = (int)CVPixelBufferGetHeight(imgBuf);
    
    // create the cv mat
    cv::Mat mat(h, w, CV_8UC4, imgBufAddr, 0);
    //转换为灰度图像
//    cv::Mat edges;
//    cv::cvtColor(mat, edges, CV_BGR2GRAY);
    
    //旋转90度
    cv::Mat transMat;
    cv::transpose(mat, transMat);
    
    //翻转,1是x方向，0是y方向，-1位Both
    cv::Mat flipMat;
    cv::flip(transMat, flipMat, 1);
    //先转换为gray
    cv::Mat grayMat;
    cv::cvtColor(flipMat, grayMat, CV_BGR2GRAY);
    
    CGSize deSize = MatToUIImage(grayMat).size;
    
    //获取眼镜位置
    NSArray *eyeP = [self drawRectInLayer:grayMat];
    UIImage *image = [self imageWithColor:[UIColor clearColor] size:deSize rectArray:eyeP];
    
    CVPixelBufferUnlockBaseAddress(imgBuf, 0);
    return image;
}

//在layer上面画图层
-(NSArray *)drawRectInLayer:(cv::Mat) inputMat{
    cv::equalizeHist(inputMat, inputMat);
    std::vector<cv::Rect> glassess;
    icon_cascade.detectMultiScale(inputMat, glassess, 1.1, 3, 0);
    NSMutableArray *marr = [NSMutableArray arrayWithCapacity:glassess.size()];
    for (NSInteger i = 0; i < glassess.size(); i++) {
//        cv::Point pt1 = cv::Point(glassess[i].x,glassess[i].y);
//        cv::Point pt2 = cv::Point(glassess[i].x + glassess[i].width,glassess[i].y + glassess[i].height);
//        cv::rectangle(inputMat, pt1, pt2, cv::Scalar(0,255,0));
        CGRect rect = CGRectMake(glassess[i].x, glassess[i].y, glassess[i].width,glassess[i].height);
        NSValue *value = [NSValue valueWithCGRect:rect];
        [marr addObject:value];
    }
    return marr.copy;
}

//用分类器分类
-(void)eyeGlassess:(cv::Mat) inputMat{
    cv::equalizeHist(inputMat, inputMat);
    std::vector<cv::Rect> glassess;
    icon_cascade.detectMultiScale(inputMat, glassess, 1.1, 3, 0);
    for (NSInteger i = 0; i < glassess.size(); i++) {
        cv::Point pt1 = cv::Point(glassess[i].x,glassess[i].y);
        cv::Point pt2 = cv::Point(glassess[i].x + glassess[i].width,glassess[i].y + glassess[i].height);
        cv::rectangle(inputMat, pt1, pt2, cv::Scalar(0,255,0));
    }
}


//图像金字塔分级放大缩小匹配，最大0.8*相机图像，最小0.3*tep图像
-(void)compareByLevel:(int)level CameraInput:(cv::Mat) inputMat{
    //相机输入尺寸
    int inputRows = inputMat.rows;
    int inputCols = inputMat.cols;
    
    //模板的原始尺寸
    int tRows = templateMat.rows;
    int tCols = templateMat.cols;
    
    for (int i = 0; i < level; i++) {
        //取循环次数中间值
        int mid = level*0.5;
        //目标尺寸
        cv::Size dstSize;
        if (i<mid) {
            //如果是前半个循环，先缩小处理
            dstSize = cv::Size(tCols*(1-i*0.1),tRows*(1-i*0.1));
        }else{
            //然后再放大处理比较
            int upCols = tCols*(1+i*0.1);
            int upRows = tRows*(1+i*0.1);
            //如果超限会崩，则做判断处理
            if (upCols>=inputCols || upRows>=inputRows) {
                upCols = tCols;
                upRows = tRows;
            }
            dstSize = cv::Size(upCols,upRows);
        }
        //重置尺寸后的tmp图像
        cv::Mat resizeMat;
        cv::resize(templateMat, resizeMat, dstSize);
        //然后比较是否相同
        BOOL cmpBool = [self compareInput:inputMat templateMat:resizeMat];
        
        if (cmpBool) {
            NSLog(@"level==%d",i);
            cv::rectangle( inputMat, cv::Rect(currentLoc, dstSize), cv::Scalar(0, 0, 255), 2, 8, 0 );
            break;
        }
    }
}

/**
 对比两个图像是否有相同区域

 @return 有为Yes
 */
-(BOOL)compareInput:(cv::Mat) inputMat templateMat:(cv::Mat)tmpMat{
    int result_rows = inputMat.rows - tmpMat.rows + 1;
    int result_cols = inputMat.cols - tmpMat.cols + 1;
    
    cv::Mat resultMat = cv::Mat(result_cols,result_rows,CV_32FC1);
    cv::matchTemplate(inputMat, tmpMat, resultMat, cv::TM_CCOEFF_NORMED);
    
    double minVal, maxVal;
    cv::Point minLoc, maxLoc, matchLoc;
    cv::minMaxLoc( resultMat, &minVal, &maxVal, &minLoc, &maxLoc, cv::Mat());
//    matchLoc = maxLoc;
//    NSLog(@"min==%f,max==%f",minVal,maxVal);
    
    if (maxVal > 0.7) {
        currentLoc = maxLoc;
        return YES;
    }else{
        return NO;
    }
}


#pragma mark - 将Buffer转为cv::Mat
-(cv::Mat)bufferToMat:(CMSampleBufferRef) sampleBuffer{
    CVImageBufferRef imgBuf = CMSampleBufferGetImageBuffer(sampleBuffer);

    //锁定内存
    CVPixelBufferLockBaseAddress(imgBuf, 0);
    // get the address to the image data
    void *imgBufAddr = CVPixelBufferGetBaseAddress(imgBuf);
    
    // get image properties
    int w = (int)CVPixelBufferGetWidth(imgBuf);
    int h = (int)CVPixelBufferGetHeight(imgBuf);
    
    // create the cv mat
    cv::Mat mat(h, w, CV_8UC4, imgBufAddr, 0);
    //转换为灰度图像
    cv::Mat edges;
    cv::cvtColor(mat, edges, CV_BGR2GRAY);
    
    //旋转90度
    cv::Mat transMat;
    cv::transpose(edges, transMat);
    
    //翻转,1是x方向，0是y方向，-1位Both
    cv::Mat flipMat;
    cv::flip(transMat, flipMat, 1);
    
    // Use the mat here
    //Canny
//    cv::Canny(flipMat, flipMat, 0, 50);
    
    CVPixelBufferUnlockBaseAddress(imgBuf, 0);
    
    return flipMat;
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

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size rectArray:(NSArray *)rectArray{
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    // 1.开启图片的图形上下文
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    
    // 2.获取
    CGContextRef cxtRef = UIGraphicsGetCurrentContext();
    
    // 3.填充颜色
    //获取眼镜位置
    for (NSInteger i = 0; i < rectArray.count; i++) {
        NSValue *rectValue = rectArray[i];
        CGRect eyeRect = rectValue.CGRectValue;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:eyeRect cornerRadius:5];
        //加路径添加到上下文
        CGContextAddPath(cxtRef, path.CGPath);
        
        UIColor *randomC =  [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
        [randomC setStroke];
        [[UIColor clearColor] setFill];
        //渲染上下文里面的路径
        /**
         kCGPathFill,   填充
         kCGPathStroke, 边线
         kCGPathFillStroke,  填充&边线
         */
        CGContextDrawPath(cxtRef,kCGPathFillStroke);
    }
    
    CGContextSetFillColorWithColor(cxtRef, color.CGColor);
    
    CGContextFillRect(cxtRef, rect);
    
    // 4.获取图片
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    // 5.关闭图形上下文
    UIGraphicsEndImageContext();
    
    // 6.返回图片
    return img;
}


@end
