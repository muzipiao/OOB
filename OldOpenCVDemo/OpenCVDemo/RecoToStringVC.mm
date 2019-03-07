//
//  RecoToStringVC.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2018/8/10.
//  Copyright © 2018年 PacteraLF. All rights reserved.
//

#import "RecoToStringVC.h"
#import <string.h>

@interface RecoToStringVC ()

//创建ImageView
@property (nonatomic, strong) UIImageView *imgView;
//创建bin预览
@property (nonatomic, strong) UIImageView *binPreimgView;

@end

@implementation RecoToStringVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createUI];
}

-(void)createUI{
    // 关闭预览图层
    self.previewLayer.frame = CGRectZero;
    
    // 设置
    CGFloat imgW = self.view.bounds.size.width;
    CGFloat imgH = self.view.bounds.size.height - 64;
    
    // 二值化后的图像预览
    UIImageView *tempImgView0 = [[UIImageView alloc]initWithFrame:CGRectMake(0, 64, imgW, imgH)];
    [self.view addSubview:tempImgView0];
    self.binPreimgView = tempImgView0;
    self.binPreimgView.alpha = 0.5;
    
    // 将图像转换为符号的预览
    UIImageView *tempImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 64, imgW, imgH)];
    [self.view addSubview:tempImgView];
    self.imgView = tempImgView;
}

#pragma mark - 获取视频帧，处理视频
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    // 将视频帧转换为cvmat,默认已经转换为
    cv::Mat imgMat = [OpenCVManager bufferToMat:sampleBuffer];
    if (imgMat.empty()) {
        return;
    }
    // 获取当前环境光亮度
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    
    NSLog(@"环境亮度：%f",brightnessValue);
    
    cv::Mat dstBinMat;
    if (brightnessValue < 1.5) {
        // 局部自适应快速积分二值化方法
        dstBinMat = [OpenCVManager convToBinary:imgMat];
    }else{
        // 转换为灰度图像,加快处理速度
        cv::Mat grayMat = [self coverToGray:imgMat];
        // 二值化，可用来简单滤波
        dstBinMat = [self coverToBinary:grayMat];
    }
    
    UIImage *dstImage = MatToUIImage(dstBinMat);
    // 缩放图片尺寸
    CGFloat imgW = 60;
    CGFloat imgH = (imgW*dstImage.size.height)/dstImage.size.width;
    UIImage *resizeImg = [self imageResize:dstImage andResizeTo:CGSizeMake(imgW, imgH)];
    // 解码为位图
    UIImage *bitImage = [self decodeImg:resizeImg];
    // 转换为字母，绘制到屏幕上
    UIImage *stringImg = [self transStr:bitImage];

    //在异步线程中，将任务同步添加至主线程，不会造成死锁
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.binPreimgView.image = dstImage;
        self.imgView.image = stringImg;
    });
}

//图像二值化
-(cv::Mat)coverToBinary:(cv::Mat) inputMat{
    //定义转换后的矩阵
    cv::Mat targetMat;
    //将图像转换为灰度图像
    cv::threshold(inputMat, targetMat, 100, 255, CV_THRESH_BINARY);
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

// 对像素进行膨胀操作dilation
-(void)dilationData:(unsigned char*)bitData imgH:(size_t)pH imgW:(size_t)pW{
    //腐蚀操作
    for(int i=1;i<pH-2;i=i+2)
    {
        @autoreleasepool{
            for(int j=1;j<pW-2;j=j+2)
            {
                int offset = (i*((int)pW))+j;
                int offsetTop = ((i-1)*((int)pW))+j;
                int offsetBottom = ((i+1)*((int)pW))+j;
                // 膨胀操作，判断周围的8个点
                int pL = bitData[offset - 1];
                int pR = bitData[offset + 1];
                int pT = bitData[offsetTop];
                int pTL = bitData[offsetTop - 1];
                int pTR = bitData[offsetTop + 1];
                int pB = bitData[offsetBottom];
                int pBL = bitData[offsetBottom - 1];
                int pBR = bitData[offsetBottom + 1];
                
                BOOL isBlack = pL==0||pR==0||pT==0||pTL==0||pTR==0||pB==0||pBL==0||pBR==0;
                if (isBlack) {
                    bitData[offset] = 0;
                }
            }
        }
    }
}

// 获取图片像素值，转换为字母，绘制在屏幕上
- (UIImage *)transStr:(UIImage *)img
{
    // 转为CGImage
    CGImageRef cgImg = img.CGImage;
    size_t pW = CGImageGetWidth(cgImg);
    size_t pH = CGImageGetHeight(cgImg);
    // 开辟一片内存空间，保存图片
    unsigned char* bitData = (unsigned char*)malloc(pW * pH);
    // 颜色空间为灰度，
    CGColorSpaceRef gGolorSpace = CGColorSpaceCreateDeviceGray();
    size_t bytesPerRow = pW; // 如果颜色空间为彩色，每行占的bytes则为pW*4
    // 创建图形上下文
    CGContextRef gContext = CGBitmapContextCreate(bitData,pW,pH,8,bytesPerRow,gGolorSpace,kCGImageAlphaNone);
    CGColorSpaceRelease(gGolorSpace);
    if (gContext == NULL) {
        return nil;
    }
    // 将图像绘制到gContext上下文中
    CGContextDrawImage(gContext,CGRectMake(0, 0, pW, pH), cgImg);
    
    // 开启图片的图形上下文
    CGFloat ksW = [UIScreen mainScreen].bounds.size.width;
    CGFloat ksH = [UIScreen mainScreen].bounds.size.height;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(ksW, ksH), NO, 0.0);
    // 2.获取图形上下文
    CGContextRef cxtRef = UIGraphicsGetCurrentContext();
    CGFloat strW = ksW/pW; //每个字宽度
    CGFloat strH = ksH/pH; //每行高度
    
    //对图像进行膨胀操作
//    [self dilationData:bitData imgH:pH imgW:pW];
    
    // 获取每个像素值bitmapData
    for(int i=0;i<pH;i++)
    {
        @autoreleasepool{
            for(int j=0;j<pW;j++)
            {
                // 获取当前像素指针
                int offset = (i*((int)pW))+j;
                int pixel = bitData[offset];
                // 判断当前像素值
                NSString *tempStr = @".";
                NSDictionary *dict =@{NSFontAttributeName:[UIFont systemFontOfSize:11],NSForegroundColorAttributeName: [UIColor blackColor]};
                if (pixel == 255) {
                    tempStr = @".";
                }else{
                    // 随机大写字母，小写字母把65改为97
                    int figure = (arc4random() % 26) + 65;
                    tempStr = [NSString stringWithFormat:@"%c", figure];
                    dict =@{NSFontAttributeName:[UIFont systemFontOfSize:11],NSForegroundColorAttributeName: [UIColor greenColor]};
                }
                // 将字母逐个绘制到屏幕上
                CGFloat yy = i * strH;
                CGFloat xx = j * strW;
                [tempStr drawWithRect:CGRectMake(xx, yy, strW, strH) options:NSStringDrawingUsesFontLeading attributes:dict context:nil];
                // 渲染,kCGPathFillStroke,kCGPathStroke
                CGContextDrawPath(cxtRef, kCGPathFillStroke);
            }
        }
    }
    
    // 从图形上下文获取图片
    UIImage *drawImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGContextRelease(gContext);
    free(bitData);
    return drawImg;
}

// 解码为位图
-(UIImage *)decodeImg:(UIImage *)img{
    CGImageRef imageRef = img.CGImage;
    
    if (!imageRef) return nil;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || height == 0) return nil;
    CGColorSpaceRef space = CGImageGetColorSpace(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    if (bytesPerRow == 0) return nil;
    
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    if (!dataProvider) return nil;
    CFDataRef data = CGDataProviderCopyData(dataProvider); // decode
    if (!data) return nil;
    
    CGDataProviderRef newProvider = CGDataProviderCreateWithCFData(data);
    CFRelease(data);
    if (!newProvider) return nil;
    
    //解码后的图像
    CGImageRef newImageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, space, bitmapInfo, newProvider, NULL, false, kCGRenderingIntentDefault);
    CFRelease(newProvider);
    
    if (!newImageRef) return nil;
    UIImage *newImage = [[UIImage alloc] initWithCGImage:newImageRef scale:img.scale orientation:img.imageOrientation];
    CGImageRelease(newImageRef);
    return newImage;
}


/**
 压缩图片至指定大小

 @param img 待压缩的图片
 @param newSize 指定尺寸
 @return 压缩后指定尺寸的图片
 */
-(UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)newSize
{
    CGFloat scale = [[UIScreen mainScreen]scale];
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    [img drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


@end
