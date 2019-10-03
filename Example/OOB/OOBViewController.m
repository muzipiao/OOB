//
//  OOBViewController.m
//  OOB
//
//  Created by lifei on 03/08/2019.
//  Copyright (c) 2019 lifei. All rights reserved.
//

#import "OOBViewController.h"
#import "OOBTemplateImageVC.h" // 识别图像中的目标
#import "OOBTemplateVideoVC.h" // 识别视频中的目标
#import "OOBTemplateCameraVC.h" // 识别相机视频流中的目标
#import "OOB.h"

@interface OOBViewController ()

// OOB 摄像头图像识别
@property (nonatomic, strong) UIButton *objCameraBtn;

// OOB 摄像头图像识别
@property (nonatomic, strong) UIButton *objVideoBtn;

// OOB 图片图像识别
@property (nonatomic, strong) UIButton *objImageBtn;

// 图像列表
@property (nonatomic, strong) NSArray<NSString *> *imgNameArray;

// 待识别的图像
@property (nonatomic, strong) UIImage *targetImage;

@end

@implementation OOBViewController

///MARK: - Life Circle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self createUI];
}

///MARK: - UI

-(void)createUI{
    self.navigationItem.title = @"iOS 图像识别";
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    CGFloat sh = [UIScreen mainScreen].bounds.size.height;
    
    [self.view addSubview:self.objCameraBtn];
    [self.view addSubview:self.objVideoBtn];
    [self.view addSubview:self.objImageBtn];
    
    // 相似度标签
    UILabel *tipLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    tipLabel.text = @"点击图片选择目标图像，点击下方按钮开始识别";
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.font = [UIFont systemFontOfSize:10];
    [self.view addSubview:tipLabel];
    [tipLabel sizeToFit];
    CGFloat labelHeight = tipLabel.bounds.size.height;
    tipLabel.frame = CGRectMake(0, 68, sw, labelHeight);
    
    // 默认是识别 apple 图片
    self.targetImage = [UIImage imageNamed:@"apple"];
    // Demo 图片名称数组
    self.imgNameArray = @[@"apple",@"bobantang",@"caomeicui",@"jitui",@"xiaofangdangao",@"yinliao"];
    
    // 创建 6 个切换图片按钮
    CGFloat margin = 40;
    CGFloat btnH = 80;
    
    CGFloat nextMargin = 15;
    CGFloat nextBtnW = (sw - nextMargin * 4) / 3.0;
    self.objCameraBtn.frame = CGRectMake(nextMargin, sh - margin - btnH, nextBtnW, btnH);
    self.objVideoBtn.frame = CGRectMake(nextMargin * 2 + nextBtnW, sh - margin - btnH, nextBtnW, btnH);
    self.objImageBtn.frame = CGRectMake(nextMargin * 3 + nextBtnW * 2, sh - margin - btnH, nextBtnW, btnH);
    
    for (NSInteger i = 0; i < 6; i++) {
        if (self.imgNameArray.count <= i) {
            break;
        }
        CGFloat btnW = (sw - margin * 3) * 0.5;
        btnH = btnW;
        CGFloat btnX = margin;
        if (i%2 == 1) {
            btnX = margin * 2 + btnW;
        }
        CGFloat btnY = 100 + (btnH + margin * 0.5) * (i/2);
        UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *btnImg = [UIImage imageNamed:self.imgNameArray[i]];
        [tempBtn setImage:btnImg forState:UIControlStateNormal];
        if (i==0) {
            tempBtn.backgroundColor = [UIColor lightGrayColor];
        }else{
            tempBtn.backgroundColor = [UIColor whiteColor];
        }
        tempBtn.frame = CGRectMake(btnX, btnY, btnW, btnH);
        tempBtn.layer.cornerRadius = 15;
        tempBtn.layer.masksToBounds = YES;
        tempBtn.tag = 1000 + i;
        [self.view addSubview:tempBtn];
        [tempBtn addTarget:self action:@selector(targetBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

///MARK: - Btn Click

// 摄像头目标识别
-(void)objCameraBtnClick:(UIButton *)sender{
    OOBTemplateCameraVC *vc = [[OOBTemplateCameraVC alloc]init];
    vc.targetImg = self.targetImage;
    [self presentViewController:vc animated:YES completion:^{
        NSLog(@"跳转摄像头识别界面");
    }];
}

// 视频文件中目标识别
-(void)objVideoBtnClick:(UIButton *)sender{
    OOBTemplateVideoVC *vc = [[OOBTemplateVideoVC alloc]init];
    vc.targetImg = self.targetImage;
    [self presentViewController:vc animated:YES completion:^{
        NSLog(@"跳转视频文件识别界面");
    }];
}

// 图片中目标识别
-(void)objImageBtnClick:(UIButton *)sender{
    for (UIView *sub in self.view.subviews) {
        if ([sub isKindOfClass:[UIButton class]] && sub.tag >= 1000) {
            sub.backgroundColor = [UIColor whiteColor];
        }
    }
    // 截取当前屏幕图片作为待识别的背景图
    UIImage *bgImg = [self snapshotView:self.view];
    OOBTemplateImageVC *imgVC = [[OOBTemplateImageVC alloc]init];
    imgVC.targetImg = self.targetImage;
    imgVC.bgImg = bgImg;
    [self presentViewController:imgVC animated:YES completion:^{
        NSLog(@"跳转图片识别界面");
    }];
}

// 点击切换图像
-(void)targetBtnClick:(UIButton *)sender{
    for (UIView *sub in self.view.subviews) {
        if ([sub isKindOfClass:[UIButton class]] && sub.tag >= 1000) {
            sub.backgroundColor = [UIColor whiteColor];
        }
    }
    sender.backgroundColor = [UIColor lightGrayColor];
    if (sender.tag - 1000 >= self.imgNameArray.count) {
        return;
    }
    NSString *imgName = self.imgNameArray[sender.tag - 1000];
    self.targetImage = [UIImage imageNamed:imgName];
}

// 截图，截取屏幕
-(UIImage *)snapshotView:(UIView *)view{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *tempImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tempImg;
}

///MARK: - Lazy Load

-(UIButton *)objCameraBtn{
    if (_objCameraBtn == nil) {
        UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [tempBtn setTitle:@"视频目标识别" forState:UIControlStateNormal];
        tempBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [tempBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [tempBtn setBackgroundColor:[UIColor colorWithRed:0.0/255.0 green:199.0/255.0 blue:140.0/255.0 alpha:1.0]];
        tempBtn.tag = 1;
        [tempBtn sizeToFit];
        tempBtn.layer.cornerRadius = 5;
        tempBtn.layer.masksToBounds = YES;
        [tempBtn addTarget:self action:@selector(objCameraBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _objCameraBtn = tempBtn;
    }
    return _objCameraBtn;
}

-(UIButton *)objVideoBtn{
    if (_objVideoBtn == nil) {
        UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [tempBtn setTitle:@"视频图像识别" forState:UIControlStateNormal];
        tempBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [tempBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [tempBtn setBackgroundColor:[UIColor colorWithRed:0.0/255.0 green:199.0/255.0 blue:140.0/255.0 alpha:1.0]];
        tempBtn.tag = 2;
        [tempBtn sizeToFit];
        tempBtn.layer.cornerRadius = 5;
        tempBtn.layer.masksToBounds = YES;
        [tempBtn addTarget:self action:@selector(objVideoBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _objVideoBtn = tempBtn;
    }
    return _objVideoBtn;
}

-(UIButton *)objImageBtn{
    if (_objImageBtn == nil) {
        UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [tempBtn setTitle:@"图片图像识别" forState:UIControlStateNormal];
        tempBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [tempBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [tempBtn setBackgroundColor:[UIColor colorWithRed:0.0/255.0 green:199.0/255.0 blue:140.0/255.0 alpha:1.0]];
        tempBtn.tag = 3;
        [tempBtn sizeToFit];
        tempBtn.layer.cornerRadius = 5;
        tempBtn.layer.masksToBounds = YES;
        [tempBtn addTarget:self action:@selector(objImageBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _objImageBtn = tempBtn;
    }
    return _objImageBtn;
}


@end

