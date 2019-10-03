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

@end

@implementation OOBTemplateVideoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createUI];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    // 注意：视图销毁必须释放资源
    OOBLog(@"停止图像识别，必须 stopMatch 销毁 OOB");
    [OOBTemplate stop];
}

/**
 创建一个标记框标记目标
 */
-(void)createUI{
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    CGFloat sh = [UIScreen mainScreen].bounds.size.height;
    
    // 显示视频的view 图层
    [self.view addSubview:self.bgView];
    self.bgView.frame = CGRectMake(20, 80, sw - 40, sh - 100);
    
    // 标记图片在背景 videoView 中
    [self.bgView addSubview:self.markView];
    
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
    [OOBTemplate stop];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 点击识别图像中的目标
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    // 待识别的视频
    NSURL *vdUrl = [[NSBundle mainBundle] URLForResource:@"oob_apple.m4v" withExtension:nil];
    // similarValue 要求的相似度，最大值为1，要求越大，精度越高，计算量越大
    OOBTemplate.similarValue = 0.8;
    // 传入视频预览图层，视频图像若100%不缩放展示(sizeToFit)，则不需要传入
    OOBTemplate.preview = self.bgView;
    
    /**
    * 识别视频中的目标，并返回目标在图片中的位置，实际相似度
    @param target 待识别的目标图像
    @param url 视频文件 URL
    @param result 识别结果，分别是目标位置和实际的相似度，视频当前帧图像
    */
    [OOBTemplate match:self.targetImg videoURL:vdUrl result:^(CGRect rect, CGFloat similar, UIImage * _Nullable frame) {
        self.similarLabel.text = [NSString stringWithFormat:@"相似度：%.0f %%",similar * 100];
        if (similar > 0.8) {
            self.markView.frame = rect;
            self.markView.hidden = NO;
        }else{
            self.markView.hidden = YES;
        }
        // 视频预览
        self.bgView.image = frame;
    }];
}

@end
