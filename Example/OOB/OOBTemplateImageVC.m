//
//  OOBTemplateImageVC.m
//  OOB_Example
//
//  Created by lifei on 2019/6/21.
//  Copyright © 2019 lifei. All rights reserved.
//

#import "OOBTemplateImageVC.h"
#import "OOB.h"

@interface OOBTemplateImageVC ()

@property (nonatomic, strong) UIImageView *bgImageView;

// 标记目标的图片框，用户可自定义
@property (nonatomic, strong) UIImageView *markView;

// 显示相似度标签
@property (nonatomic, strong) UILabel *similarLabel;

@end

@implementation OOBTemplateImageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createUI];
}

/**
 创建一个标记框标记目标
 */
-(void)createUI{
    self.view.backgroundColor = [UIColor whiteColor];
    UIImageView *bgImgView = [[UIImageView alloc]initWithImage:self.bgImg];
    [bgImgView sizeToFit];
    [self.view addSubview:bgImgView];
    self.bgImageView = bgImgView;
    
    // 标记图片在背景 UIImageView 中
    UIImageView *markerImgView = [[UIImageView alloc]initWithImage:nil];
    [bgImgView addSubview:markerImgView];
    self.markView = markerImgView;
    self.markView.image = [OOBTemplate share].rectMarkerImage; // 设置标记图像为矩形
    markerImgView.hidden = YES;
    
    // 相似度标签
    UILabel *simLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    simLabel.text = @"相似度：0 %（点击屏幕开始识别目标）";
    simLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:simLabel];
    self.similarLabel = simLabel;
    [simLabel sizeToFit];
    
    // 范围按钮
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [backBtn setTitle:@"返回主页" forState:UIControlStateNormal];
    [self.view addSubview:backBtn];
    [backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat margin = 20;
    
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    
    // ImageView 和图片保持宽高比，
    CGSize bgImgSize = self.bgImg.size;
    CGFloat bgW = sw - margin * 4;
    CGFloat bgH = (bgImgSize.height / bgImgSize.width) * bgW;
    bgImgView.frame = CGRectMake(margin * 2, margin, bgW, bgH);
    
    CGFloat labelHeight = simLabel.bounds.size.height;
    simLabel.frame = CGRectMake(0, margin, sw, labelHeight);
    
    backBtn.frame = CGRectMake(15, margin, 50, 30);
    [backBtn sizeToFit];
}

// 返回主页
-(void)backBtnClick:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 点击识别图像中的目标
static BOOL kDoing = NO; // 防止暴力连续点击
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (kDoing) {
        NSLog(@"图像正在识别中...请勿重复点击");
        return;
    }
    
    /**
     * UIImage 设置图片会按照 UIViewContentModeScaleToFill 模式缩放
     * 图片实际尺寸与 UIImageView 尺寸可能不相等
     */
    UIImage *bgImg = self.bgImageView.image;
    CGSize bgViewSize = self.bgImageView.frame.size;
    CGSize bgImgSize = bgImg.size;
    CGFloat scaleX = bgViewSize.width / bgImgSize.width;
    CGFloat scaleY = bgViewSize.height / bgImgSize.height;
    kDoing = YES;
    
    /**
     * 开始识别图像中的目标
     * targetRect 目标在背景图片中的位置，注意不是 UImageView 中的实际位置，需要缩放转换
     * similarValue 要求的相似度，最大值为1，要求越大，精度越高，计算量越大
     */
    [OOBTemplate matchImage:self.targetImg BgImg:bgImg Similar:0.8 resultBlock:^(CGRect targetRect, CGFloat similarValue) {
        kDoing = NO;
        self.similarLabel.text = [NSString stringWithFormat:@"相似度：%.0f %%",similarValue * 100];
        // 根据图片在 X、Y 方向缩放比例，计算目标的实际位置和大小
        CGFloat tgX = targetRect.origin.x * scaleX;
        CGFloat tgY = targetRect.origin.y * scaleY;
        CGFloat tgW = targetRect.size.width * scaleX;
        CGFloat tgH = targetRect.size.height * scaleY;
        
        if (similarValue > 0.7) {
            self.markView.frame = CGRectMake(tgX, tgY, tgW, tgH);
            self.markView.hidden = NO;
        }else{
            self.markView.hidden = YES;
        }
    }];
}



@end
