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

@end

@implementation OOBTemplateImageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createUI];
}

/// UI
-(void)createUI{
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat margin = 20;
    
    [self.view addSubview:self.bgView];
    self.bgView.image = self.bgImg;
    // ImageView 和图片保持宽高比
    CGSize bgImgSize = self.bgImg.size;
    CGFloat bgW = kSW - margin * 4;
    CGFloat bgH = (bgImgSize.height / bgImgSize.width) * bgW;
    self.bgView.frame = CGRectMake(margin * 2, margin * 4, bgW, bgH);
    
    // 标记图片在背景 UIImageView 中
    [self.bgView addSubview:self.markView];
    // 相似度标签
    [self.view addSubview:self.similarLabel];
    // 返回按钮
    [self.view addSubview:self.backBtn];
    
    CGFloat labelHeight = self.similarLabel.bounds.size.height;
    self.similarLabel.frame = CGRectMake(0, margin * 3, kSW, labelHeight + 5);
    CGFloat topMargin = 44;
    if (HS_XSeries) {
        topMargin = 64;
    }
    self.backBtn.frame = CGRectMake(15, topMargin, 50, 30);
    [self.backBtn sizeToFit];
}

// 点击识别图像中的目标
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    // 传入背景预览图层，视频图像若100%不缩放展示(sizeToFit)，则不需要传入
    OOBTemplate.preview = self.bgView;
    // 值设置的越小误报率高，值设置的越大计算量越大
    OOBTemplate.similarValue = 0.9;
    /**
     * 开始识别图像中的目标
     * target 目标在背景图片中的位置，注意不是 UImageView 中的实际位置，需要缩放转换
     * similar 要求的相似度，最大值为1，要求越大，精度越高，计算量越大
     */
    [OOBTemplate match:self.targetImg bgImg:self.bgImg result:^(CGRect rect, CGFloat similar) {
        self.similarLabel.text = [NSString stringWithFormat:@"相似度：%.0f %%",similar * 100];
        if (similar > 0.7) {
            self.markView.frame = rect;
            self.markView.hidden = NO;
        }else{
            self.markView.hidden = YES;
        }
    }];
}

@end
