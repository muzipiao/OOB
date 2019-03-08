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
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    CGFloat sh = [UIScreen mainScreen].bounds.size.height;
    
    self.objRecoBtn.frame = CGRectMake(sw * 0.5 - 75, sh * 0.5 - 40, 150, 80);
    
}

// 跳转到图像识别
-(void)objRecoBtnClick:(UIButton *)sender{
    OOBTemplateVC *vc = [[OOBTemplateVC alloc]init];
    UIImage *targetImg = [UIImage imageNamed:@"TargetImage1"];
    vc.targetImg = targetImg;
    [self presentViewController:vc animated:YES completion:^{
        NSLog(@"跳转全屏的图像识别界面");
    }];
}


-(UIButton *)objRecoBtn{
    if (_objRecoBtn == nil) {
        UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [tempBtn setTitle:@"图像识别" forState:UIControlStateNormal];
        tempBtn.titleLabel.font = [UIFont systemFontOfSize:18];
        [tempBtn setBackgroundColor:[UIColor magentaColor]];
        [tempBtn sizeToFit];
        tempBtn.layer.cornerRadius = 15;
        tempBtn.layer.masksToBounds = YES;
        [tempBtn addTarget:self action:@selector(objRecoBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _objRecoBtn = tempBtn;
    }
    return _objRecoBtn;
}


@end
