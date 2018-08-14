//
//  ViewController.m
//  OpenCVDemo
//
//  Created by PacteraLF on 2017/6/29.
//  Copyright © 2017年 PacteraLF. All rights reserved.
//

#import "ViewController.h"
#import "CIFilterVC.h" //系统自带滤镜处理视频
#import "OpenCVTemplateVC.h" //模板匹配法识别图像
#import "HaarCascadeVC.h" //训练分类器方法识别图像


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)cifilterBtnClick:(UIButton *)sender {
     [self pushVC:@"CIFilterVC" withBtn:sender];
}

- (IBAction)templateBtnClick:(UIButton *)sender {
    //OpenCVTemplateVC.h
    [self pushVC:@"OpenCVTemplateVC" withBtn:sender];
}

- (IBAction)cascadeBtnClick:(UIButton *)sender {
    [self pushVC:@"HaarCascadeVC" withBtn:sender];
}

- (IBAction)cannyBtnClick:(UIButton *)sender {
    [self pushVC:@"OpenCVToPsImgVC" withBtn:sender];
}
- (IBAction)recoToStringBtnClick:(UIButton *)sender {
    [self pushVC:@"RecoToStringVC" withBtn:sender];
}
- (IBAction)videoToStringBtnClick:(UIButton *)sender {
    [self pushVC:@"TransVideoToStringVC" withBtn:sender];
}

-(void)pushVC:(NSString *)vcName withBtn:(UIButton *)sender{
    id viewController = [[NSClassFromString(vcName) alloc] init];
    UIViewController *vc = (UIViewController *)viewController;
    [self.navigationController pushViewController:vc animated:YES];
    vc.title = sender.currentTitle;
}

@end
