//
//  OOB.m
//  OpenCVDemo
//
//  Created by lifei on 2019/3/4.
//  Copyright © 2019 PacteraLF. All rights reserved.
//

#import "OOB.h"
#import "OOBManager.h"

/**
 * 识别结果 Block
 * Identify the result
 */
typedef void (^ResultBlock) (CGRect, CGFloat);

@interface OOB ()<AVCaptureVideoDataOutputSampleBufferDelegate>
// 预览视频图层(Preview the video layer)
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
// 当前视频会话(current video session)
@property (nonatomic, strong) AVCaptureSession *session;
// 前置摄像头输入(Front camera input)
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput;
// 后置摄像头输入(Rear camera input)
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput;
// 识别结果(Identify the result)
@property (nonatomic, copy) ResultBlock resultBlock;

@end

@implementation OOB

///MARK: - 定位单例对象
//mark: - Position singleton object
static OOB *instance;
+(nonnull instancetype )share{
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken,^{
        instance = [[OOB alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    
    return instance;
}
- (id)copyWithZone:(NSZone *)zone
{
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _sessionPreset = AVCaptureSessionPreset1920x1080; // 默认视频图像尺寸 1920x1080(Default video image size)
        _cameraType = OOBCameraTypeBack; // 默认后置摄像头(default rear camera)
        _markerLineColor = [UIColor redColor]; // 标记图像默认是红色(The tag image is red by default)
        _markerCornerRadius = 5.0f; // 如果是矩形，默认切圆角半径(If it is a rectangle, the default corner radius)
        _markerLineWidth = 5.0f; // 标记图像线宽默认是 1.0(Marker image line width defaults to 1.0)
        _similarValue = 0.7f; // 相似度阈值(similarity threshold)
    }
    return self;
}

///MARK: - 重写 Setter
//mark: - overwrite
-(void)setCameraType:(OOBCameraType)cameraType{
    _cameraType = cameraType;
    [self.session stopRunning];
    if (cameraType == OOBCameraTypeBack){
        [self.session removeInput:self.frontCameraInput];
        if ([self.session canAddInput:self.backCameraInput]) {
            [self.session addInput:self.backCameraInput];
            [self.session startRunning];
        }
    }else if (cameraType == OOBCameraTypeFront){
        [self.session removeInput:self.backCameraInput];
        if ([self.session canAddInput:self.frontCameraInput]) {
            [self.session addInput:self.frontCameraInput];
            [self.session startRunning];
        }
    }
}

/**
 * 设置预览视图
 * set the preview view
 */
-(void)setPreview:(UIView *)preview{
    _preview = preview;
    [self.session stopRunning];
    if (_previewLayer) {
        [_previewLayer removeFromSuperlayer];
    }
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    if (preview) {
        previewLayer.frame = preview.bounds;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        // 预览图层添加到最底部
        [preview.layer insertSublayer:previewLayer atIndex:0];
    }else{
        previewLayer.frame = CGRectZero;
    }
    _previewLayer = previewLayer;
    [self.session startRunning];
}

/**
 * 设置预览视频质量
 * Set preview video quality
 */
-(void)setSessionPreset:(AVCaptureSessionPreset)sessionPreset{
    _sessionPreset = sessionPreset;
    if ([self.session canSetSessionPreset:sessionPreset]) {
        self.session.sessionPreset = sessionPreset;
    }else{
        OOBLog(@"当前相机不支持此模式：%@",sessionPreset);
    }
}

/**
 * 设置目标图像，并将 Alpha 通道置为白色
 * Set the target image and set the alpha channel to white
 */
-(void)setTargetImg:(UIImage *)targetImg{
    CGSize tSize = targetImg.size;
    CGRect tRect = CGRectMake(0, 0, tSize.width, tSize.height);
    UIGraphicsBeginImageContextWithOptions(tSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, tRect);
    [targetImg drawInRect:tRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _targetImg = newImage;
}

/**
 * 标记框的线宽，默认宽度 5.0f。
 * Marker box line width, default width 5.0f.
 */
-(void)setMarkerLineWidth:(CGFloat)markerLineWidth{
    _markerLineWidth = markerLineWidth;
    [self updateMarkerImage];
}

/**
 * 标记框为矩形时，切圆角，默认 5.0f。
 * When the mark box is rectangular, it is rounded, default 5.0f.
 */
-(void)setMarkerCornerRadius:(CGFloat)markerCornerRadius{
    _markerCornerRadius = markerCornerRadius;
    [self updateMarkerImage];
}

/**
 * 标记框的颜色，默认红色。
 * The color of the marker box, default red.
 */
-(void)setMarkerLineColor:(UIColor *)markerLineColor{
    _markerLineColor = markerLineColor;
    [self updateMarkerImage];
}

/**
 * 更新标记图像。
 * update the marker image.
 */
-(void)updateMarkerImage{
    UIImage *tempImg = nil;
    if (_rectMarkerImage) {
        _rectMarkerImage = nil;
        tempImg = self.rectMarkerImage;
    }
    if (_ovalMarkerImage) {
        _ovalMarkerImage = nil;
        tempImg = self.ovalMarkerImage;
    }
}

///MARK: - 对比图像
//mark: - Contrast image
-(void)matchTemplate:(UIImage *)targetImg resultBlock:(void (^)(CGRect, CGFloat))resultBlock{
    self.targetImg = targetImg;
    self.resultBlock = resultBlock;
    // 更新标记图像
    [self updateMarkerImage];
    [self.session startRunning];
}

///MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    NSDictionary *targetDict = [OOBManager recoObjLocation:sampleBuffer TemplateImg:self.targetImg SimilarValue:self.similarValue];
    CGRect targetRect = CGRectFromString([targetDict objectForKey:kTargetRect]);
    CGFloat similarValue = [[targetDict objectForKey:kSimilarValue] floatValue];
    CGSize videoSize = CGSizeFromString([targetDict objectForKey:kVideoSize]);
    dispatch_async(dispatch_get_main_queue(), ^{
        // 目标坐标转换到缩放图像上的坐标
        CGSize viewSize = self.previewLayer.bounds.size;
        if (CGRectIsEmpty(self.previewLayer.frame)) {
            viewSize = [UIScreen mainScreen].bounds.size;
        }
        if (CGRectIsEmpty(targetRect)) {
            if (self.resultBlock) {
                self.resultBlock(CGRectZero, similarValue);
            }
            return;
        }
        // 视频默认根据 UIViewContentModeScaleAspectFill 模式进行缩放裁剪
        CGFloat scaleValueX = viewSize.width / videoSize.width;
        CGFloat scaleValueY = viewSize.height / videoSize.height;
        CGFloat scaleValue = scaleValueY > scaleValueX ? scaleValueY : scaleValueX;
        // 坐标转换，图像可能显示不全
        CGFloat w = targetRect.size.width * scaleValue;
        CGFloat h = targetRect.size.height * scaleValue;
        CGFloat leftMargin =  (videoSize.width * scaleValue - viewSize.width) * 0.5;
        CGFloat topMargin =  (videoSize.height * scaleValue - viewSize.height) * 0.5;
        CGFloat x = targetRect.origin.x * scaleValue - leftMargin;
        CGFloat y = targetRect.origin.y * scaleValue - topMargin;
        if (self.cameraType == OOBCameraTypeFront) {
            // 前置摄像头水平方向镜像处理
            x = viewSize.width - w - x;
        }
        CGRect reLocationRect = CGRectMake(x, y, w, h);
        
        if (self.resultBlock) {
            self.resultBlock(reLocationRect, similarValue);
        }
    });
}

///MARK: - LazyLoad
// 当前视频对象 session
- (AVCaptureSession *)session{
    if (_session == nil) {
        AVCaptureSession *tempSession = [[AVCaptureSession alloc]init];
        _session = tempSession;
        
        // 预览视频默认大小
        if (![tempSession canSetSessionPreset:_sessionPreset]) {
            _sessionPreset = AVCaptureSessionPreset640x480;
        }
        tempSession.sessionPreset = _sessionPreset;
        
        // 选择输入设备,默认是后置摄像头
        AVCaptureDeviceInput *input = self.backCameraInput;
        // 设置视频输出流
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc]init];
        
        // 设置输出格式kCVPixelBufferWidthKey kCVPixelBufferHeightKey
        NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],                                   kCVPixelBufferPixelFormatTypeKey,nil];
        
        output.videoSettings = settings;
        
        // 设置输出的代理
        dispatch_queue_t videoQueue = dispatch_queue_create("OBJRECO_VIDEO_QUEUE", DISPATCH_QUEUE_SERIAL);
        [output setSampleBufferDelegate:self queue:videoQueue];
        
        // 将输入输出添加到会话，连接
        if ([tempSession canAddInput:input]) {
            [tempSession addInput:input];
        }
        if ([tempSession canAddOutput:output]) {
            [tempSession addOutput:output];
        }
    }
    return _session;
}

// 获取后置摄像头
- (AVCaptureDeviceInput *)backCameraInput {
    if (_backCameraInput == nil) {
        NSError *error;
        AVCaptureDevice *device = [self cameraWithPosition:AVCaptureDevicePositionBack];
        _backCameraInput = [[AVCaptureDeviceInput  alloc] initWithDevice:device error:&error];
        if (error) {
            OOBLog(@"后置摄像头获取失败");
        }
    }
    return _backCameraInput;
}

// 获取前置摄像头
- (AVCaptureDeviceInput *)frontCameraInput {
    if (_frontCameraInput == nil) {
        NSError *error;
        AVCaptureDevice *device = [self cameraWithPosition:AVCaptureDevicePositionFront];
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        if (error) {
            OOBLog(@"前置摄像头获取失败");
        }
    }
    return _frontCameraInput;
}

// 获取摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices ){
        if ( device.position == position ){
            return device;
        }
    }
    return nil;
}

// 获取矩形标记图像
-(UIImage *)rectMarkerImage{
    if (_rectMarkerImage == nil) {
        // 绘制矩形图像
        _rectMarkerImage = [self drawRectWithColor:OOBMarkerTypeRect];
    }
    return _rectMarkerImage;
}

// 获取椭圆标记图像
-(UIImage *)ovalMarkerImage{
    if (_ovalMarkerImage == nil) {
        // 绘制椭圆图像
        _ovalMarkerImage = [self drawRectWithColor:OOBMarkerTypeOval];
    }
    return _ovalMarkerImage;
}

// 绘制标记图片
-(UIImage *)drawRectWithColor:(OOBMarkerType)markerType{
    CGFloat imgWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat imgHeight = imgWidth;
    if (_targetImg && (_targetImg.size.width != _targetImg.size.height)) {
        imgHeight = imgWidth * _targetImg.size.height / _targetImg.size.width;
    }
    CGFloat kBorderWidth = self.markerLineWidth;
    // 画布大小
    CGRect contextRect = CGRectMake(0, 0, imgWidth + kBorderWidth * 2, imgHeight + kBorderWidth * 2);
    // 标记图像大小
    CGRect targetRect = CGRectMake(kBorderWidth, kBorderWidth, imgWidth, imgHeight);
    UIGraphicsBeginImageContextWithOptions(contextRect.size, NO, 0);
    // 设置线条颜色
    [self.markerLineColor set];
    // 默认是矩形
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:targetRect cornerRadius:self.markerCornerRadius];
    if (markerType == OOBMarkerTypeOval) {
        path = [UIBezierPath bezierPathWithOvalInRect:targetRect];
    }
    path.lineWidth = kBorderWidth;
    // 绘制线条
    [path stroke];
    // 获取图片
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

///MARK: - 停止识别并释放资源
-(void)stopMatch{
    // 恢复默认值（Restore Defaults）
    _sessionPreset = AVCaptureSessionPreset1920x1080; // 默认视频图像尺寸 1920x1080(Default video image size)
    _cameraType = OOBCameraTypeBack; // 默认后置摄像头(default rear camera)
    _markerLineColor = [UIColor redColor]; // 标记图像默认是红色(The tag image is red by default)
    _markerCornerRadius = 5.0f; // 如果是矩形，默认切圆角半径(If it is a rectangle, the default corner radius)
    _markerLineWidth = 5.0f; // 标记图像线宽默认是 1.0(Marker image line width defaults to 1.0)
    _similarValue = 0.7f; // 相似度阈值(similarity threshold)
    
    // 释放 session
    [_session stopRunning];
    [_previewLayer removeFromSuperlayer];
    _session = nil;
    // 释放内存
    _rectMarkerImage = nil;
    _ovalMarkerImage = nil;
    _preview = nil;
    _previewLayer = nil;
    _frontCameraInput = nil;
    _backCameraInput = nil;
    _resultBlock = nil;
}

@end
