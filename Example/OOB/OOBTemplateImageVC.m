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
// 待识别的背景视图
@property (nonatomic, strong) UIImageView *bgImageView;
// 标记目标的图片框，用户可自定义
@property (nonatomic, strong) UIImageView *markView;
// 显示相似度标签
@property (nonatomic, strong) UILabel *similarLabel;
// 返回按钮
@property (nonatomic, strong) UIButton *backBtn;

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
    [self.view addSubview:self.bgImageView];
    
    // 标记图片在背景 UIImageView 中
    [self.bgImageView addSubview:self.markView];
    self.markView.image = [OOBTemplate share].rectMarkerImage; // 设置标记图像为矩形
    
    // 相似度标签
    [self.view addSubview:self.similarLabel];
    
    // 返回按钮
    [self.view addSubview:self.backBtn];
    
    CGFloat margin = 20;
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    
    // ImageView 和图片保持宽高比，
    CGSize bgImgSize = self.bgImg.size;
    CGFloat bgW = sw - margin * 4;
    CGFloat bgH = (bgImgSize.height / bgImgSize.width) * bgW;
    self.bgImageView.frame = CGRectMake(margin * 2, margin, bgW, bgH);
    
    CGFloat labelHeight = self.similarLabel.bounds.size.height;
    self.similarLabel.frame = CGRectMake(0, margin, sw, labelHeight + 5);
    
    self.backBtn.frame = CGRectMake(15, margin, 50, 30);
    [self.backBtn sizeToFit];
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

// 返回主页
-(void)backBtnClick:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

///MARK: - Lazy Load
-(UIButton *)backBtn{
    if (!_backBtn) {
        UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [tempBtn setTitle:@"返回主页" forState:UIControlStateNormal];
        [tempBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [tempBtn sizeToFit];
        _backBtn = tempBtn;
    }
    return _backBtn;
}

// 标记图像
-(UIImageView *)markView{
    if (!_markView) {
        UIImage *img = [OOBTemplate share].rectMarkerImage; // 设置标记图像为矩形
        UIImageView *markerImgView = [[UIImageView alloc]initWithImage:img];
        [markerImgView sizeToFit];
        markerImgView.hidden = YES;
        _markView = markerImgView;
    }
    return _markView;
}

// 相似度标签
-(UILabel *)similarLabel{
    if (!_similarLabel) {
        UILabel *simLabel = [[UILabel alloc]init];
        simLabel.text = @"点击屏幕开始识别目标";
        simLabel.textAlignment = NSTextAlignmentCenter;
        simLabel.font = [UIFont systemFontOfSize:14];
        [simLabel sizeToFit];
        _similarLabel = simLabel;
    }
    return _similarLabel;
}

// 显示背景图的图层
-(UIImageView *)bgImageView{
    if (!_bgImageView) {
        UIImageView *bgImgView = [[UIImageView alloc]initWithImage:_bgImg];
        [bgImgView sizeToFit];
        _bgImageView = bgImgView;
    }
    return _bgImageView;
}




@end
