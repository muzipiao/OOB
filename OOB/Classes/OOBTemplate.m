//
//  OOBTemplate.m
//  OpenCVDemo
//
//  Created by lifei on 2019/3/4.
//  Copyright © 2019 PacteraLF. All rights reserved.
//

#import "OOBTemplate.h"
#import "OOBTemplateHelper.h"

#define kDefaultSimilarValue 0.7

/**
 * 当前识别类型
 */
typedef NS_ENUM(NSInteger, OOBType) {
    /**
     * 摄像头
     */
    OOBTypeCamera,
    /**
     * 视频
     */
    OOBTypeVideo,
    /**
     * 图片
     */
    OOBTypeImage
};

/**
 * 识别结果 Block
 */
typedef void (^CameraResultBlock) (CGRect, CGFloat);
typedef void (^VideoResultBlock) (CGRect, CGFloat, UIImage *);

@interface OOBTemplate ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) UIView *preview;
@property (nonatomic, strong) UIImage *targetImg;
@property (nonatomic, assign) CGFloat similarValue;
@property (nonatomic, assign) OOBCameraType cameraType;
// 视频预览视图图像质量，默认预览视频尺寸 1920x1080，可自行设置。
@property(nonatomic, copy) AVCaptureSessionPreset sessionPreset;
// 当前识别类型，相机、视频或图片
@property (nonatomic, assign) OOBType oobType;
// 读取视频CMSampleBufferRef
@property (nonatomic, strong) AVAssetReader *assetReader;
// 预览视频图层,如果没有设置 bgPreview,则不显示，获取的坐标默认为全屏坐标。
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput;
@property (nonatomic, copy) CameraResultBlock cameraResultBlock;
@property (nonatomic, copy) VideoResultBlock videoResultBlock;

@end

@implementation OOBTemplate

///MARK: - 定位单例对象
static OOBTemplate *instance;
+(nonnull instancetype )share{
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken,^{
        instance = [[OOBTemplate alloc] init];
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
        _oobType = OOBTypeCamera; // 当前识别类型
        _sessionPreset = AVCaptureSessionPresetHigh; // 默认视频图像尺寸 1920x1080
        _cameraType = OOBCameraTypeBack; // 默认后置摄像头
        _similarValue = kDefaultSimilarValue; // 相似度阈值
    }
    return self;
}

///MARK: - 类方法重写 Setter 和 Getter
+ (UIImage *)targetImg{
    return [OOBTemplate share].targetImg;
}
+ (void)setTargetImg:(UIImage *)targetImg{
    if (!targetImg) {
        OOBLog(@"目标图像 targetImg 不应为 nil。");
    }
    [OOBTemplate share].targetImg = targetImg;
}

+ (CGFloat)similarValue{
    return [OOBTemplate share].similarValue;
}
+ (void)setSimilarValue:(CGFloat)similarValue{
    if (similarValue <=1 && similarValue >=0) {
        [OOBTemplate share].similarValue = similarValue;
    }else{
        OOBLog(@"匹配相似度 similarValue 取值区间应在 0 到 1 之间。");
        [OOBTemplate share].similarValue = 0.7;
    }
}

+ (UIView *)bgPreview{
    return [OOBTemplate share].preview;
}
+ (void)setBgPreview:(UIView *)bgPreview{
    [OOBTemplate share].preview = bgPreview;
}

+ (OOBCameraType)cameraType{
    return [OOBTemplate share].cameraType;
}
+ (void)setCameraType:(OOBCameraType)cameraType{
    if ([OOBTemplate share].oobType != OOBTypeCamera) {
        OOBLog(@"非识别摄像头目标，不支持设置 cameraType。");
        return;
    }
    [OOBTemplate share].cameraType = cameraType;
}

+ (AVCaptureSessionPreset)cameraSessionPreset{
    return [OOBTemplate share].sessionPreset;
}
+ (void)setCameraSessionPreset:(AVCaptureSessionPreset)cameraSessionPreset{
    if ([OOBTemplate share].oobType != OOBTypeCamera) {
        OOBLog(@"非识别摄像头目标，不支持设置 cameraSessionPreset。");
        return;
    }
    [OOBTemplate share].sessionPreset = cameraSessionPreset;
}

///MARK: - 单例重写 Setter
-(void)setTargetImg:(UIImage *)targetImg{
    UIImage *removeAlphaImg = [OOBTemplateHelper removeAlpha:targetImg];
    _targetImg = removeAlphaImg;
}

-(void)setCameraType:(OOBCameraType)cameraType{
    _cameraType = cameraType;
    [self.session stopRunning];
    if (cameraType == OOBCameraTypeBack){
        [self.session removeInput:self.frontCameraInput];
        if ([self.session canAddInput:self.backCameraInput]) {
            [self.session addInput:self.backCameraInput];
            //前置摄像头是镜像的
            for (AVCaptureVideoDataOutput *tempOutput in self.session.outputs) {
                for (AVCaptureConnection *avCon in tempOutput.connections) {
                    if (avCon.supportsVideoOrientation) {
                        avCon.videoOrientation = AVCaptureVideoOrientationPortrait;
                    }
                    if (avCon.supportsVideoMirroring) {
                        avCon.videoMirrored = NO;
                    }
                }
            }
            [self.session startRunning];
        }
    }else if (cameraType == OOBCameraTypeFront){
        [self.session removeInput:self.backCameraInput];
        if ([self.session canAddInput:self.frontCameraInput]) {
            [self.session addInput:self.frontCameraInput];
            //前置摄像头是镜像的
            for (AVCaptureVideoDataOutput *tempOutput in self.session.outputs) {
                for (AVCaptureConnection *avCon in tempOutput.connections) {
                    if (avCon.supportsVideoOrientation) {
                        avCon.videoOrientation = AVCaptureVideoOrientationPortrait;
                    }
                    if (avCon.supportsVideoMirroring) {
                        avCon.videoMirrored = YES;
                    }
                }
            }
            [self.session startRunning];
        }
    }
}

/**
 * 设置预览视频质量
 */
-(void)setSessionPreset:(AVCaptureSessionPreset)sessionPreset{
    _sessionPreset = sessionPreset;
    if ([self.session canSetSessionPreset:sessionPreset]) {
        self.session.sessionPreset = sessionPreset;
    }else{
        OOBLog(@"当前相机不支持此模式：%@",sessionPreset);
    }
}

///MARK: - 对比图像
/**
 * 停止识别图像。如果调用摄像头或播放视频，必须手动执行此方法释放资源。
 */
+ (void)stopMatch{
    [[OOBTemplate share] stopMatch];
}

/**
 * 识别相机视频流中目标，并返回目标图像坐标位置，坐标位置与设置的预览视图(preview)相关。
 * 备注：当 targetRect 宽高为 0 时代表未识别到图像，similarValue 值越大代表相似度越高
 @param targetImg 待识别的目标图像
 @param resultBlock 识别结果,targetRect：目标位置，similarValue：目标与视频物体中的相似度
 */
+ (void)matchCamera:(UIImage *)targetImg resultBlock:(void (^)(CGRect, CGFloat))resultBlock{
    [OOBTemplate share].oobType = OOBTypeCamera; // 标记为相机
    [OOBTemplate share].targetImg = targetImg;
    if (![OOBTemplate share].targetImg) {
        resultBlock(CGRectZero, 0);
        return;
    }
    [OOBTemplate share].cameraResultBlock = resultBlock;
    [[OOBTemplate share] matchCamera];
}

// 开始识别相机视频流中目标
- (void)matchCamera{
    [self.session stopRunning];
    if (_previewLayer) {
        [_previewLayer removeFromSuperlayer];
    }
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    if (self.preview) {
        previewLayer.frame = self.preview.bounds;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        // 预览图层添加到最底部
        [self.preview.layer insertSublayer:previewLayer atIndex:0];
    }else{
        previewLayer.frame = CGRectZero;
    }
    _previewLayer = previewLayer;
    [self.session startRunning];
}

/**
 * 识别视频中的目标，并返回目标在图片中的位置，实际相似度
 @param targetImg 待识别的目标图像
 @param vURL 视频文件 URL
 @param resultBlock 识别结果，分别是目标位置和实际的相似度，视频当前帧图像
 */
+ (void)matchVideo:(UIImage *)targetImg VideoURL:(NSURL *)vURL resultBlock:(void (^)(CGRect, CGFloat, UIImage * _Nullable))resultBlock{
    [OOBTemplate share].oobType = OOBTypeVideo; // 标记为视频
    [OOBTemplate share].targetImg = targetImg; // 移除Alpha通道
    if (![OOBTemplate share].targetImg) {
        resultBlock(CGRectZero, 0, nil);
        return;
    }
    [OOBTemplate share].videoResultBlock = resultBlock;
    [[OOBTemplate share] matchVideoWithURL:vURL];
}

/**
 * 识别视频中的目标
 @param vURL 视频文件 URL
 */
- (void)matchVideoWithURL:(NSURL *)vURL{
    if (self.assetReader) {
        [self.assetReader cancelReading];
    }
    AVAsset *asset = [AVAsset assetWithURL:vURL];
    // 配置AVAssetReader
    NSArray *trackArray = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (trackArray.count == 0) {
        OOBLog(@"视频地址错误：%@", vURL);
        return;
    }
    AVAssetTrack *track = trackArray.firstObject;
    AVAssetReader *tmpAssetReader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
    self.assetReader = tmpAssetReader;
    // 设置输出格式 kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    NSDictionary *readerOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],                                   kCVPixelBufferPixelFormatTypeKey,nil];
    
    AVAssetReaderTrackOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:readerOutputSettings];
    [tmpAssetReader addOutput:trackOutput];
    // 开始读取 CMSampleBufferRef
    [tmpAssetReader startReading];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGFloat frameTime = 0.035; // 读取速率
        if (track.nominalFrameRate > 0) {
            frameTime = 1.0/track.nominalFrameRate;
        }
        // 循环读取
        while (tmpAssetReader.status == AVAssetReaderStatusReading && track.nominalFrameRate > 0) {
            if (!self.assetReader) {
                 break; // 停止播放
            }
            CMSampleBufferRef samBufRef = [trackOutput copyNextSampleBuffer];
            if (!samBufRef) {
                break;
            }
            UIImage *frameImg = [OOBTemplateHelper imageFromSampleBuffer:samBufRef];
            NSDictionary *tgDict = [OOBTemplateHelper locInVideo:samBufRef TemplateImg:self.targetImg SimilarValue:self.similarValue];
            CGRect tgRect = CGRectFromString([tgDict objectForKey:kTargetRect]);
            CGFloat realSimilarValue = [[tgDict objectForKey:kSimilarValue] floatValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                /**
                 * 显示返回的视频图像，载体视图和视频图像宽度不同会变形，需要矫正
                 */
                CGRect reTgRect = tgRect;
                if (self.preview) {
                    CGSize frameSize = frameImg.size;
                    CGSize bgViewSize = self.preview.frame.size;
                    CGFloat scaleX = bgViewSize.width / frameSize.width;
                    CGFloat scaleY = bgViewSize.height / frameSize.height;
                    CGFloat tgX = tgRect.origin.x * scaleX;
                    CGFloat tgY = tgRect.origin.y * scaleY;
                    CGFloat tgW = tgRect.size.width * scaleX;
                    CGFloat tgH = tgRect.size.height * scaleY;
                    reTgRect = CGRectMake(tgX, tgY, tgW, tgH);
                }
                if (self.videoResultBlock) {
                    self.videoResultBlock(reTgRect, realSimilarValue, frameImg);
                }
                // 释放 CMSampleBufferRef
                if (samBufRef) {
                    CMSampleBufferInvalidate(samBufRef);
                    CFRelease(samBufRef);
                }
            });
            [NSThread sleepForTimeInterval:frameTime];
        }
        [tmpAssetReader cancelReading];
    });
}

/**
 * 识别图片中的目标，并返回目标在图片中的位置，实际相似度
 * 注意：返回的 Frame 是相对于图片的，如果要做标记，根据图片在 UImageView 中的 X、Y 方向缩放比例换算，具体参考 Demo 中 OOBTemplateImageVC 的示例。
 @param targetImg 待识别的目标图像
 @param backgroudImg 背景图像，在背景图像上搜索目标是否存在
 @param minSimilarValue 要求的相似度，取值在 0 到 1 之间，1 为最大，越接近 1 表示要求越高
 @param resultBlock 识别结果，分别是目标位置和实际的相似度
 */
+ (void)matchImage:(UIImage *)targetImg BgImg:(UIImage *)backgroudImg Similar:(CGFloat)minSimilarValue resultBlock:(void (^)(CGRect, CGFloat))resultBlock{
    [OOBTemplate share].oobType = OOBTypeImage; // 标记为图片
    if (minSimilarValue > 1 || minSimilarValue < 0) {
        minSimilarValue = kDefaultSimilarValue; // 取默认值
    }
    if (!targetImg || !backgroudImg) {
        resultBlock(CGRectZero, 0);
        return;
    }
    NSDictionary *targetDict = [OOBTemplateHelper locInImg:backgroudImg TargetImg:targetImg SimilarValue:minSimilarValue];
    CGRect targetRect = CGRectFromString([targetDict objectForKey:kTargetRect]);
    // 根据背景视图的 Scale 将像素变换为苹果坐标系
    CGFloat bgScale = backgroudImg.scale;
    // 校正背景视图变形引起的坐标变换
    CGFloat tgScaleX = 1.0;
    CGFloat tgScaleY = 1.0;
    if (OOBTemplate.bgPreview) {
        CGSize bgImgSize = backgroudImg.size;
        CGSize bgViewSize = OOBTemplate.bgPreview.frame.size;
        tgScaleX = bgViewSize.width / bgImgSize.width;
        tgScaleY = bgViewSize.height / bgImgSize.height;
    }
    CGFloat tgX = targetRect.origin.x * tgScaleX / bgScale;
    CGFloat tgY = targetRect.origin.y * tgScaleY / bgScale;
    CGFloat tgW = targetRect.size.width * tgScaleX / bgScale;
    CGFloat tgH = targetRect.size.height * tgScaleY / bgScale;
    CGRect scaleRect = CGRectMake(tgX, tgY, tgW, tgH);
    CGFloat similarValue = [[targetDict objectForKey:kSimilarValue] floatValue];
    if (resultBlock) {
        resultBlock(scaleRect, similarValue);
    }
    [OOBTemplate stopMatch]; // 恢复初始值
}

///MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    // 识别相机图像
    NSDictionary *targetDict = [OOBTemplateHelper locInVideo:sampleBuffer TemplateImg:self.targetImg SimilarValue:self.similarValue];
    CGRect targetRect = CGRectFromString([targetDict objectForKey:kTargetRect]);
    CGFloat similarValue = [[targetDict objectForKey:kSimilarValue] floatValue];
    CGSize videoSize = CGSizeFromString([targetDict objectForKey:kVideoSize]);
    // 将图像字节对齐造成的误差修正
    CGFloat videoFillWidth =  [[targetDict objectForKey:kVideoFillWidth] floatValue];
    if (!targetDict || CGRectIsEmpty(targetRect)) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        // 目标坐标转换到缩放图像上的坐标
        CGSize viewSize = self.previewLayer.bounds.size;
        if (CGRectIsEmpty(self.previewLayer.frame)) {
            viewSize = [UIScreen mainScreen].bounds.size;
        }
        // 视频默认根据 UIViewContentModeScaleAspectFill 模式进行缩放裁剪
        CGFloat scaleValueX = viewSize.width / videoSize.width;
        CGFloat scaleValueY = viewSize.height / videoSize.height;
        CGFloat scaleValue = scaleValueY > scaleValueX ? scaleValueY : scaleValueX;
        // 坐标转换，图像可能显示不全
        CGFloat w = targetRect.size.width * scaleValue - videoFillWidth * scaleValue * 0.5;
        CGFloat h = targetRect.size.height * scaleValue;
        CGFloat leftMargin =  (videoSize.width * scaleValue - viewSize.width - videoFillWidth * scaleValue) * 0.5;
        CGFloat topMargin =  (videoSize.height * scaleValue - viewSize.height) * 0.5;
        CGFloat x = targetRect.origin.x * scaleValue - leftMargin;
        CGFloat y = targetRect.origin.y * scaleValue - topMargin;
        if (self.cameraType == OOBCameraTypeFront) {
            // 前置摄像头水平方向镜像处理
            x = viewSize.width - w - x;
        }
        CGRect reLocationRect = CGRectMake(x, y, w, h);
        
        if (self.cameraResultBlock) {
            self.cameraResultBlock(reLocationRect, similarValue);
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
                                  [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],                                   kCVPixelBufferPixelFormatTypeKey,nil];
        
        output.videoSettings = settings;
        
        // 设置输出的代理
        dispatch_queue_t videoQueue = dispatch_queue_create("OOB_VIDEO_QUEUE", DISPATCH_QUEUE_SERIAL);
        [output setSampleBufferDelegate:self queue:videoQueue];
        
        // 将输入输出添加到会话，连接
        if ([tempSession canAddInput:input]) {
            [tempSession addInput:input];
        }
        if ([tempSession canAddOutput:output]) {
            [tempSession addOutput:output];
        }
        //前置摄像头是镜像的
        for (AVCaptureVideoDataOutput *tempOutput in tempSession.outputs) {
            for (AVCaptureConnection *avCon in tempOutput.connections) {
                if (avCon.supportsVideoOrientation) {
                    avCon.videoOrientation = AVCaptureVideoOrientationPortrait;
                }
            }
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
            OOBLog(@"后置摄像头获取失败，error:%@", error);
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
            OOBLog(@"前置摄像头获取失败，error:%@", error);
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

/**
 * 矩形标记框（辅助功能，例如显示目标位置）
 @param imgSize 标记框图片尺寸
 @param lineColor 标记框的线条颜色
 @param lineWidth 标记框的线条粗细
 @param cornerRadius 矩形标记框的切圆角
 @return 中间透明的矩形标记框
 */
+ (UIImage *)getRectWithSize:(CGSize)imgSize Color:(UIColor *)lineColor Width:(CGFloat)lineWidth Radius:(CGFloat)cornerRadius{
    CGFloat imgWidth = imgSize.width;
    CGFloat imgHeight = imgSize.height;
    // 画布大小
    CGRect contextRect = CGRectMake(0, 0, imgWidth + lineWidth * 2, imgHeight + lineWidth * 2);
    // 标记图像大小
    CGRect targetRect = CGRectMake(lineWidth, lineWidth, imgWidth, imgHeight);
    UIGraphicsBeginImageContextWithOptions(contextRect.size, NO, 0);
    // 设置线条颜色
    [lineColor set];
    // 默认是矩形
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:targetRect cornerRadius:cornerRadius];
    path.lineWidth = lineWidth;
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
    _oobType = OOBTypeCamera; // 默认为相机
    _sessionPreset = AVCaptureSessionPresetHigh; // 默认视频图像尺寸 1920x1080
    _cameraType = OOBCameraTypeBack; // 默认后置摄像头
    _similarValue = kDefaultSimilarValue; // 相似度阈值
    
    // 释放 session
    [_session stopRunning];
    [_assetReader cancelReading];
    [_previewLayer removeFromSuperlayer];
    _session = nil;
    _assetReader = nil;
    // 释放内存
    _preview = nil;
    _previewLayer = nil;
    _targetImg = nil;
    _frontCameraInput = nil;
    _backCameraInput = nil;
    _cameraResultBlock = nil;
    _videoResultBlock = nil;
}

@end
