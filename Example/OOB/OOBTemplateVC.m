//
//  OOBTemplateVC.m
//  OOB_Example
//
//  Created by lifei on 2019/3/8.
//  Copyright © 2019 lifei. All rights reserved.
// 模板匹配法识别图像

#import "OOBTemplateVC.h"
#import "OOB.h"

@interface OOBTemplateVC ()

// 标记目标的图片框，用户可自定义
@property (nonatomic, strong) UIImageView *markView;

@end

@implementation OOBTemplateVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // 创建 UI
    [self createUI];
    [self startReco];
}

- (void)viewDidDisappear:(BOOL)animated{
    // 注意：视图销毁必须释放资源
    OOBLog(@"停止图像识别，必须 stopMatch 销毁 OOB");
    [[OOB share] stopMatch];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    OOBLog(@"退出图像识别");
    [self dismissViewControllerAnimated:YES completion:nil];
}


/**
 创建一个标记框标记目标
 */
-(void)createUI{
    self.view.backgroundColor = [UIColor whiteColor];
    UIImageView *markerImgView = [[UIImageView alloc]initWithImage:nil];
    [self.view addSubview:markerImgView];
    self.markView = markerImgView;
    self.markView.image = [OOB share].rectMarkerImage; // 设置标记图像为矩形
    markerImgView.hidden = YES;
    
    // 设置可选属性
    [self optionalProperty];
}


/**
 开始识别目标图像
 */
-(void)startReco{
    // 设置视频预览图层
    [OOB share].preview = self.view;
    
    /**
     * 开始图像识别
     * targetImg: 待识别的目标图像
     @param targetRect 目标图像在预览图层中的 frame
     @param similarValue 目标模板与视频图像中图像的相似度
     @return 识别图像在block中回调
     */
    [[OOB share] matchTemplate:self.targetImg resultBlock:^(CGRect targetRect, CGFloat similarValue) {
        OOBLog(@"模板图像与视频目标的相似度：%.0f %%,Rect:%@",similarValue * 100,NSStringFromCGRect(targetRect));
        // 只有当相似度大于 80% 时才标记，否则不标记
        if (similarValue > 0.7) {
            self.markView.hidden = NO;
            self.markView.frame = targetRect;
        }else{
            self.markView.hidden = YES;
        }
    }];
}


/**
 可选属性：标记图像默认红色，宽度为5，矩形切圆角为5，对比相似度默认 0.7（70%）
 */
-(void)optionalProperty{
    // 更改矩形框颜色为深红色：R=254 G=67 B=101
    [OOB share].markerLineColor =  [UIColor colorWithRed:254.0/255.0 green:67.0/255.0 blue:101.0/255.0 alpha:1.0];
    // 更改矩形框线宽为 8.0
    [OOB share].markerLineWidth = 8.0;
    // 更改矩形框切圆角半径为 8.0
    [OOB share].markerCornerRadius = 8.0;
    // 图像改变后必须重新设置Imageview的图像
    self.markView.image = [OOB share].rectMarkerImage;
    
    // 调整对比的相似度为 80%
    [OOB share].similarValue = 0.8;
}

@end
