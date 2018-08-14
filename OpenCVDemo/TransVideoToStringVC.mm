//
//  TransVideoToStringVC.m
//  OpenCVDemo
//
//  Created by 李飞 on 2018/8/11.
//  Copyright © 2018年 PacteraLF. All rights reserved.
//

#import "TransVideoToStringVC.h"
#import <AVFoundation/AVFoundation.h>

@interface TransVideoToStringVC ()
{
    int blockSize; //奇数，块大小
    int constValue; //常量
}

// 创建ImageView
@property (nonatomic, strong) UIImageView *imgView;
// 创建bin预览
@property (nonatomic, strong) UIImageView *binPreimgView;
// 定时截图视频图片
@property (nonatomic, strong) NSTimer *videoTimer;
// 截图生成器
@property (nonatomic, strong) AVAssetImageGenerator *imgGenerator;
// 当前视频截图时间
@property (nonatomic, assign) CGFloat currentTime;
// 影片总时长
@property (nonatomic, assign) CGFloat videoDuration;

@end

@implementation TransVideoToStringVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createUI];
    // 初始化，默认值
    blockSize = 17;
    constValue = 4;
    
    [self beginClipVideo];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.videoTimer invalidate];
    self.videoTimer = nil;
}

-(void)createUI{
    self.view.backgroundColor = [UIColor whiteColor];
    //设置预览图层大小
    CGFloat imgW = self.view.bounds.size.width;
    CGFloat imgH = self.view.bounds.size.height - 64;
    // 预览图像图层
    UIImageView *tempImgView0 = [[UIImageView alloc]initWithFrame:CGRectMake(0, 64, imgW, imgH)];
    [self.view addSubview:tempImgView0];
    self.binPreimgView = tempImgView0;
    // 显示字母图像图层
    UIImageView *tempImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 64, imgW, imgH)];
    [self.view addSubview:tempImgView];
    self.imgView = tempImgView;
    // 调整块大小
    UISlider *blockSlider = [[UISlider alloc]initWithFrame:CGRectMake(10, imgH - 80, imgW - 20, 30)];
    blockSlider.minimumValue = 11;
    blockSlider.value = 17;
    blockSlider.maximumValue = 150;
    [self.view addSubview:blockSlider];
    [blockSlider addTarget:self action:@selector(blockSliderClick:) forControlEvents:UIControlEventValueChanged];
    // 调整常量大小
    UISlider *constSlider = [[UISlider alloc]initWithFrame:CGRectMake(10, imgH - 40, imgW - 20, 30)];
    constSlider.minimumValue = 0;
    constSlider.value = 4;
    constSlider.maximumValue = 100;
    [self.view addSubview:constSlider];
    [constSlider addTarget:self action:@selector(constSliderClick:) forControlEvents:UIControlEventValueChanged];
    
}

-(void)blockSliderClick:(UISlider *)sender{
    int vv = (int)sender.value;
    if((vv % 2) == 0){
        blockSize = sender.value + 1;
    }else{
        blockSize = sender.value;
    }
    NSLog(@"block==%d",blockSize);
}

-(void)constSliderClick:(UISlider *)sender{
    constValue = (int)sender.value;
    NSLog(@"min==%d",constValue);
}

// 开始起截屏
-(void)beginClipVideo{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"视频名称.mp4" withExtension:nil];
    if(!url){
        NSLog(@"视频名称或路径不对");
        return;
    }
    // 创建影片剪辑器
    AVURLAsset *urlSet = [AVURLAsset assetWithURL:url];
    Float64 duration = CMTimeGetSeconds([urlSet duration]);
    self.videoDuration = duration; // 获取影片时长
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlSet];
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    self.imgGenerator = imageGenerator;
    // 当前硬盘播放时间位置
    self.currentTime = 0;
    self.videoTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerClipVideo:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.videoTimer forMode:NSRunLoopCommonModes];
}

// 定时截屏
-(void)timerClipVideo:(NSTimer *)timer{
    if (self.currentTime < self.videoDuration - 0.1) {
        self.currentTime = self.currentTime + 0.1;
    }else{
        self.currentTime = 0;
    }
    UIImage *image = [self makeRef:self.imgGenerator Time:self.currentTime];
    if (image) {
        // 缩放图片尺寸
        CGFloat imgW = 50;
        CGFloat imgH = (imgW*image.size.height)/image.size.width;
        UIImage *resizeImg = [self imageResize:image andResizeTo:CGSizeMake(imgW, imgH)];
        //转换为矩阵，并二值化
        cv::Mat tempMat;
        UIImageToMat(resizeImg, tempMat);
        cv::Mat grayMat = [self coverToGray:tempMat];
        cv::Mat dstBinMat = [self coverToBinary:grayMat];
        
        UIImage *dstBinImage = MatToUIImage(dstBinMat);
        // 显示预览图层，注释打开
//        self.binPreimgView.image = dstBinImage;
        // 转换为字母，绘制到屏幕上
        UIImage *stringImg = [self transStr:dstBinImage];
        self.imgView.image = stringImg;
    }
}

// 截取视频的固定位置
-(UIImage *)makeRef:(AVAssetImageGenerator *)imageGenerator Time:(NSTimeInterval)second{
    NSError *error = nil;
    CMTime time = CMTimeMakeWithSeconds(second,600);
    //缩略图实际生成的时间
    CMTime actucalTime;
    //获取单帧图片
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actucalTime error:&error];
    if (error) {
        NSLog(@"截取视频图片失败:%@",error.localizedDescription);
    }
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

//图像二值化
-(cv::Mat)coverToBinary:(cv::Mat) inputMat{
    //定义转换后的矩阵
    cv::Mat targetMat;
    //将图像二值化
//    cv::threshold(inputMat, targetMat, 100, 255, CV_THRESH_BINARY);
    // 自适应二值化,可以很好的处理光线问题
    cv::adaptiveThreshold(inputMat, targetMat, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, blockSize, constValue);
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
                    dict =@{NSFontAttributeName:[UIFont systemFontOfSize:10],NSForegroundColorAttributeName: [UIColor greenColor]};
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
