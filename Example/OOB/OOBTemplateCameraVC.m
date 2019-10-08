//
//  OOBTemplateCameraVC.m
//  OOB_Example
//
//  Created by lifei on 2019/3/8.
//  Copyright © 2019 lifei. All rights reserved.
// 模板匹配法识别图像

#import "OOBTemplateCameraVC.h"
#import "OOB.h"

@interface OOBTemplateCameraVC ()

@end

@implementation OOBTemplateCameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // 创建 UI
    [self createUI];
    [self startReco];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    // 注意：视图销毁必须释放资源
    OOBLog(@"停止图像识别，必须 stopMatch 销毁 OOB");
    [OOBTemplate stop];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 创建 UI
-(void)createUI{
    self.view.backgroundColor = [UIColor whiteColor];
    // 相似度标签
    [self.view addSubview:self.similarLabel];
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat labelHeight = self.similarLabel.bounds.size.height;
    CGFloat topMargin = 20;
    if (HS_XSeries) {
        topMargin = 40;
    }
    self.similarLabel.frame = CGRectMake(0, topMargin, screenWidth, labelHeight);
}

/**
 开始识别目标图像
 */
-(void)startReco{
    // 设置视频预览图层
    OOBTemplate.preview = self.view;
    // 添加标记图像 ImageView 在预览图层中
    [self.view addSubview:self.markView];
    // 调整对比的相似度在 80% 以上
    OOBTemplate.similarValue = 0.9;
    /**
     * 开始图像识别
     @param target: 待识别的目标图像
     @param rect 目标图像在预览图层中的 frame
     @param similar 目标模板与视频图像中图像的相似度
     @return 识别图像在block中回调
     */
    [OOBTemplate match:self.targetImg result:^(CGRect rect, CGFloat similar) {
        OOBLog(@"模板图像与视频目标的相似度：%.0f %%,Rect:%@",similar * 100,NSStringFromCGRect(rect));
        self.similarLabel.text = [NSString stringWithFormat:@"与目标相似度：%.0f %%",similar * 100];
        // 只有当相似度大于 70% 时才标记，否则不标记
        if (similar > 0.8) {
            self.markView.hidden = NO;
            self.markView.frame = rect;
        }else{
            self.markView.hidden = YES;
        }
    }];
}

@end
