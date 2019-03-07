//
//  OpenCVTemplateVC.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/7/11.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "OpenCVManager.h"
#import "OpenCVTemplateVC.h"

@interface OpenCVTemplateVC ()
{
    cv::Point currentLoc;//当前模板矩阵匹配的位置
}

//当前需要比较的模板矩阵
@property (nonatomic, assign) cv::Mat templateMat;

//提示相似率的label
@property (nonatomic, strong) UILabel *similarLevelLabel;

//提示当前选择图片
@property (nonatomic, strong) UILabel *currentImgLabel;

//旗帜
@property (nonatomic, strong) UIButton *appleBtn;
//福字
@property (nonatomic, strong) UIButton *fuziBtn;
//卡通笔
@property (nonatomic, strong) UIButton *xhrOneBtn;
//卡通大头针
@property (nonatomic, strong) UIButton *xhrTwoBtn;

@end

@implementation OpenCVTemplateVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createUI];
    
    //初始化模板为苹果的logo
    self.templateMat = [self initTemplateImage:@"AppleLogo"];
    self.currentImgLabel.text = @"当前选择为Apple的Logo";
    
}

//创建界面
-(void)createUI{
    //提示匹配率
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 70, self.view.bounds.size.width, 44)];
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    self.similarLevelLabel = label;
    
    //提示当前选择
    UILabel *label2 = [[UILabel alloc]initWithFrame:CGRectMake(0,self.view.bounds.size.height - 50, self.view.bounds.size.width, 44)];
    label2.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label2];
    self.currentImgLabel = label2;
    
    self.appleBtn = [self createBtn:@"AppleLogo"];
    [self.appleBtn addTarget:self action:@selector(appleBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.fuziBtn = [self createBtn:@"fuzi"];
    [self.fuziBtn addTarget:self action:@selector(fuziBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.xhrOneBtn = [self createBtn:@"xhr1"];
    [self.xhrOneBtn addTarget:self action:@selector(xhrOneBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.xhrTwoBtn = [self createBtn:@"xhr2"];
    [self.xhrTwoBtn addTarget:self action:@selector(xhrTwoBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.appleBtn];
    [self.view addSubview:self.fuziBtn];
    [self.view addSubview:self.xhrOneBtn];
    [self.view addSubview:self.xhrTwoBtn];
    
    CGFloat btnY = 70 + self.view.bounds.size.width - 40 + 10;
    CGFloat btnW = 64;
    CGFloat btnX = (self.view.bounds.size.width - 64*2 - 20)*0.5;
    
    self.appleBtn.frame = CGRectMake(btnX, btnY, btnW, btnW);
    self.fuziBtn.frame = CGRectMake(btnX + 20 + btnW, btnY, btnW, btnW);
    self.xhrOneBtn.frame = CGRectMake(btnX, btnY + btnW + 20, btnW, btnW);
    self.xhrTwoBtn.frame = CGRectMake(btnX + 20 + btnW, btnY + btnW + 20, btnW, btnW);
}

-(UIButton *)createBtn:(NSString *)imgName{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    return btn;
}

#pragma mark - 切换要识别的模板
- (void)appleBtnClick:(UIButton *)sender {
    self.templateMat = [self initTemplateImage:@"AppleLogo"];
    self.currentImgLabel.text = @"当前选择为Apple的Logo";
}

- (void)fuziBtnClick:(UIButton *)sender {
    self.templateMat = [self initTemplateImage:@"fuzi"];
    self.currentImgLabel.text = @"当前选择为福字";
}

- (void)xhrOneBtnClick:(UIButton *)sender {
    self.templateMat = [self initTemplateImage:@"xhr1"];
    self.currentImgLabel.text = @"当前选择为小黄人1";
}

- (void)xhrTwoBtnClick:(UIButton *)sender {
    self.templateMat = [self initTemplateImage:@"xhr2"];
    self.currentImgLabel.text = @"当前选择为小黄人2";
}


//将图片转换为灰度的矩阵
-(cv::Mat)initTemplateImage:(NSString *)imgName{
    UIImage *templateImage = [UIImage imageNamed:imgName];
    cv::Mat tempMat;
    UIImageToMat(templateImage, tempMat);
    cv::cvtColor(tempMat, tempMat, CV_BGR2GRAY);
    return tempMat;
}

#pragma mark - 获取视频帧，处理视频
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    [NSThread sleepForTimeInterval:0.5];

    cv::Mat imgMat;
    imgMat = [OpenCVManager bufferToMat:sampleBuffer];
    //判断是否为空，否则返回
    if (imgMat.empty() || self.templateMat.empty()) {
        return;
    }
    
    //转换为灰度图像
    cv::cvtColor(imgMat, imgMat, CV_BGR2GRAY);
    UIImage *tempImg = MatToUIImage(imgMat);
    
    //获取标记的矩形
    NSArray *rectArr = [self compareByLevel:6 CameraInput:imgMat];
    //转换为图片
    UIImage *rectImg = [OpenCVManager imageWithColor:[UIColor redColor] size:tempImg.size rectArray:rectArr];
    
    CGImageRef cgImage = rectImg.CGImage;
    
    //在异步线程中，将任务同步添加至主线程，不会造成死锁
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (cgImage) {
            self.tagLayer.contents = (__bridge id _Nullable)cgImage;
        }
    });
}


//图像金字塔分级放大缩小匹配，最大0.8*相机图像，最小0.3*tep图像
-(NSArray *)compareByLevel:(int)level CameraInput:(cv::Mat) inputMat{
    //相机输入尺寸
    int inputRows = inputMat.rows;
    int inputCols = inputMat.cols;
    
    //模板的原始尺寸
    int tRows = self.templateMat.rows;
    int tCols = self.templateMat.cols;
    
    // 模板图像必须小于待比较的摄像头背景图像，大于则缩小
    while (tRows > inputRows || tCols > inputCols) {
        tCols = tCols * 0.8;
        tRows = tRows * 0.8;
        if (tRows > inputRows || tCols > inputCols) {
            continue;
        }
        cv::Size reSize = cv::Size(tCols,tRows);
        cv::Mat reSizeMat;
        cv::resize(self.templateMat, reSizeMat, reSize);
        self.templateMat = reSizeMat;
    }
    
    NSMutableArray *marr = [NSMutableArray array];
    
    for (int i = 0; i < level; i++) {
        //取循环次数中间值
        int mid = level*0.5;
        //目标尺寸
        cv::Size dstSize;
        if (i<mid) {
            //如果是前半个循环，先缩小处理
            dstSize = cv::Size(tCols*(1-i*0.2),tRows*(1-i*0.2));
        }else{
            //然后再放大处理比较
            int upCols = tCols*(1+i*0.2);
            int upRows = tRows*(1+i*0.2);
            //如果超限会崩，则做判断处理
            if (upCols>=inputCols || upRows>=inputRows) {
                upCols = inputCols;
                upRows = inputRows;
            }
            dstSize = cv::Size(upCols,upRows);
        }
        //重置尺寸后的tmp图像
        cv::Mat resizeMat;
        cv::resize(self.templateMat, resizeMat, dstSize);
        //然后比较是否相同
        BOOL cmpBool = [self compareInput:inputMat templateMat:resizeMat];
        
        if (cmpBool) {
            NSLog(@"匹配缩放级别level==%d",i);
            CGRect rectF = CGRectMake(currentLoc.x, currentLoc.y, dstSize.width, dstSize.height);
            NSValue *rValue = [NSValue valueWithCGRect:rectF];
            [marr addObject:rValue];
            break;
        }
    }
    return marr;
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
    dispatch_async(dispatch_get_main_queue(), ^{
        if (maxVal < 0) {
            maxVal = 0;
        }
        self.similarLevelLabel.text = [NSString stringWithFormat:@"相似度：%.2f",maxVal];
    });
    
    if (maxVal > 0.7) {
        //有相似位置，返回相似位置的第一个点
        currentLoc = maxLoc;
        return YES;
    }else{
        return NO;
    }
}


@end
