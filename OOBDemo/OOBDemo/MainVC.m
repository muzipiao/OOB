//
//  MainVC.m
//  OOBDemo
//
//  Created by lifei on 2019/3/6.
//  Copyright © 2019 lifei. All rights reserved.
//

#import "MainVC.h"
#import "OOB.h"

@interface MainVC ()

@property (nonatomic, strong) UIImageView *markView;

@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createUI];
    
    [self startReco];
}

-(void)createUI{
    UIImageView *markerImgView = [[UIImageView alloc]initWithImage:nil];
    [self.view addSubview:markerImgView];
    self.markView = markerImgView;
    markerImgView.hidden = YES;
}

-(void)startReco{
    // 163,236,237
    [OOB share].markerLineColor =  [UIColor colorWithRed:163.0/255.0 green:236.0/255.0 blue:237.0/255.0 alpha:1.0];
    [OOB share].markerLineWidth = 8.0;
    [OOB share].markerCornerRadius = 8.0;
    self.markView.image = [OOB share].rectMarkerImage;
    [OOB share].similarValue = 0.8;
    [OOB share].preview = self.view;
    // TargetImage1
    [[OOB share] matchTemplate:[UIImage imageNamed:@"TargetImage1"] resultBlock:^(CGRect targetRect, CGFloat similarValue) {
        //OOBLog(@"ss==%f",similarValue);
        if (similarValue > 0.8) {
            self.markView.hidden = NO;
            self.markView.frame = targetRect;
        }else{
            self.markView.hidden = YES;
        }
    }];
}


@end
