//
//  OOBViewController.m
//  OOB
//
//  Created by lifei on 03/08/2019.
//  Copyright (c) 2019 lifei. All rights reserved.
//

#import "OOBViewController.h"
#import "OOBTemplateVC.h"

@interface OOBViewController ()

// OOB 图像识别按钮
@property (nonatomic, strong) UIButton *objRecoBtn;

// 图像列表
@property (nonatomic, strong) NSArray *imgNameArray;

// 待识别的图像
@property (nonatomic, strong) UIImage *targetImage;

@end

@implementation OOBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self createUI];
}

-(void)createUI{
    self.navigationItem.title = @"iOS 图像识别";
    [self.view addSubview:self.objRecoBtn];
    
    // 默认是识别 apple 图片
    self.targetImage = [UIImage imageNamed:@"apple"];
    // Demo 图片名称数组
    self.imgNameArray = @[@"apple",@"bobantang",@"caomeicui",@"jitui",@"xiaofangdangao",@"yinliao"];
    
    // 创建 6 个切换图片按钮
    CGFloat margin = 40;
    CGFloat btnH = 80;
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    CGFloat sh = [UIScreen mainScreen].bounds.size.height;
    
    self.objRecoBtn.frame = CGRectMake(margin, sh - margin - btnH, sw - margin * 2, btnH);
   
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
        tempBtn.backgroundColor = [UIColor whiteColor];
        tempBtn.frame = CGRectMake(btnX, btnY, btnW, btnH);
        tempBtn.layer.cornerRadius = 15;
        tempBtn.layer.masksToBounds = YES;
        tempBtn.tag = 1000 + i;
        [self.view addSubview:tempBtn];
        [tempBtn addTarget:self action:@selector(targetBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
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


// 跳转到图像识别
-(void)objRecoBtnClick:(UIButton *)sender{
    OOBTemplateVC *vc = [[OOBTemplateVC alloc]init];
    vc.targetImg = self.targetImage;
    [self presentViewController:vc animated:YES completion:^{
        NSLog(@"跳转全屏的图像识别界面");
    }];
}


-(UIButton *)objRecoBtn{
    if (_objRecoBtn == nil) {
        UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [tempBtn setTitle:@"点击按钮开始图像识别" forState:UIControlStateNormal];
        tempBtn.titleLabel.font = [UIFont systemFontOfSize:18];
        [tempBtn setBackgroundColor:[UIColor magentaColor]];
        tempBtn.tag = 1;
        [tempBtn sizeToFit];
        tempBtn.layer.cornerRadius = 15;
        tempBtn.layer.masksToBounds = YES;
        [tempBtn addTarget:self action:@selector(objRecoBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _objRecoBtn = tempBtn;
    }
    return _objRecoBtn;
}


@end
