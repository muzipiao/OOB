//
//  OOBTemplateVideoVC.m
//  OOB_Example
//
//  Created by 李飞 on 2019/6/22.
//  Copyright © 2019 lifei. All rights reserved.
//

#import "OOBTemplateVideoVC.h"
#import <AVFoundation/AVFoundation.h>
#import "OOB.h"

@interface OOBTemplateVideoVC ()

// 读取视频CMSampleBufferRef
@property (nonatomic, strong) AVAssetReader *assetReader;
// 视频文件展示View
@property (nonatomic, strong) UIImageView *videoView;
// 标记目标的图片框，用户可自定义
@property (nonatomic, strong) UIImageView *markView;
// 显示相似度标签
@property (nonatomic, strong) UILabel *similarLabel;
// 返回按钮
@property (nonatomic, strong) UIButton *backBtn;

@end

@implementation OOBTemplateVideoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createUI];
}

/**
 创建一个标记框标记目标
 */
-(void)createUI{
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    CGFloat sh = [UIScreen mainScreen].bounds.size.height;
    
    // 显示视频的view 图层
    [self.view addSubview:self.videoView];
    self.videoView.frame = CGRectMake(20, 80, sw - 40, sh - 100);
    
    // 标记图片在背景 videoView 中
    [self.videoView addSubview:self.markView];
    
    // 相似度标签
    [self.view addSubview:self.similarLabel];
    CGFloat labelHeight = self.similarLabel.bounds.size.height;
    self.similarLabel.frame = CGRectMake(0, 80 - labelHeight - 10, sw, labelHeight);
    
    // 范围按钮
    [self.view addSubview:self.backBtn];
    CGSize btnSize = self.backBtn.bounds.size;
    self.backBtn.frame = CGRectMake(15, 25, btnSize.width, btnSize.height);
}

// 返回主页
-(void)backBtnClick:(UIButton *)sender{
    [OOBTemplate stopMatch];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 点击识别图像中的目标
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    // 待识别的视频
    NSURL *vdUrl = [[NSBundle mainBundle] URLForResource:@"oob_apple.m4v" withExtension:nil];
    /**
     * 开始识别图像中的目标
     * targetRect 目标在背景图片中的位置，注意不是 UImageView 中的实际位置，需要缩放转换
     * similarValue 要求的相似度，最大值为1，要求越大，精度越高，计算量越大
     */
    OOBTemplate.similarValue = 0.8;
    [OOBTemplate matchVideo:self.targetImg VideoURL:vdUrl resultBlock:^(CGRect targetRect, CGFloat similarValue, UIImage * _Nullable frameImg) {
        self.similarLabel.text = [NSString stringWithFormat:@"相似度：%.0f %%",similarValue * 100];
        /**
         * 显示返回的视频图像，载体视图和视频图像宽度不同会变形，需要矫正
         */
        CGSize frameSize = frameImg.size;
        CGSize vdViewSize = self.videoView.frame.size;
        CGFloat scaleX = vdViewSize.width / frameSize.width;
        CGFloat scaleY = vdViewSize.height / frameSize.height;
        // 缩放变换
        CGFloat tgX = targetRect.origin.x * scaleX;
        CGFloat tgY = targetRect.origin.y * scaleY;
        CGFloat tgW = targetRect.size.width * scaleX;
        CGFloat tgH = targetRect.size.height * scaleY;
        if (similarValue > 0.8) {
            self.markView.frame = CGRectMake(tgX, tgY, tgW, tgH);
            self.markView.hidden = NO;
        }else{
            self.markView.hidden = YES;
        }
        // 视频预览
        self.videoView.image = frameImg;
    }];
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
        UIImage *img = [OOBTemplate getRectWithSize:_targetImg.size Color:[UIColor redColor] Width:3 Radius:5]; // 设置标记图像为矩形
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

// 显示视频的图层
-(UIImageView *)videoView{
    if (!_videoView) {
        UIImageView *vdView = [[UIImageView alloc]initWithFrame:CGRectZero];
        vdView.backgroundColor = [UIColor lightGrayColor];
        _videoView = vdView;
    }
    return _videoView;
}

@end
