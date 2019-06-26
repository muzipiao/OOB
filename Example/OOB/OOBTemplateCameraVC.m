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

// 标记目标的图片框，用户可自定义
@property (nonatomic, strong) UIImageView *markView;

// 显示相似度标签
@property (nonatomic, strong) UILabel *similarLabel;

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
    [OOBTemplate stopMatch];
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
    self.similarLabel.frame = CGRectMake(0, 20, screenWidth, labelHeight);
}

/**
 开始识别目标图像
 */
-(void)startReco{
    // 设置视频预览图层
    OOBTemplate.cameraPreview = self.view;
    // 添加标记图像 ImageView 在预览图层中
    [self.view addSubview:self.markView];
    // 调整对比的相似度在 80% 以上
    OOBTemplate.similarValue = 0.8;
    /**
     * 开始图像识别
     * targetImg: 待识别的目标图像
     @param targetRect 目标图像在预览图层中的 frame
     @param similarValue 目标模板与视频图像中图像的相似度
     @return 识别图像在block中回调
     */
    [OOBTemplate matchCamera:self.targetImg resultBlock:^(CGRect targetRect, CGFloat similarValue) {
        OOBLog(@"模板图像与视频目标的相似度：%.0f %%,Rect:%@",similarValue * 100,NSStringFromCGRect(targetRect));
        self.similarLabel.text = [NSString stringWithFormat:@"与目标相似度：%.0f %%",similarValue * 100];
        // 只有当相似度大于 70% 时才标记，否则不标记
        if (similarValue > 0.8) {
            self.markView.hidden = NO;
            self.markView.frame = targetRect;
        }else{
            self.markView.hidden = YES;
        }
    }];
}

// 标记图像
-(UIImageView *)markView{
    if (!_markView) {
        // 更改矩形框颜色为深红色：R=254 G=67 B=101
        UIColor *darkRed = [UIColor colorWithRed:254.0/255.0 green:67.0/255.0 blue:101.0/255.0 alpha:1.0];
        UIImage *img = [OOBTemplate getRectWithSize:_targetImg.size Color:darkRed Width:3 Radius:5]; // 设置标记图像为矩形
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
        simLabel.text = @"与目标相似度：0 %";
        simLabel.textAlignment = NSTextAlignmentCenter;
        simLabel.font = [UIFont systemFontOfSize:14];
        [simLabel sizeToFit];
        _similarLabel = simLabel;
    }
    return _similarLabel;
}

@end
