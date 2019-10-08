//
//  OOBTemplateBaseVC.h
//  OOB_Example
//
//  Created by lifei on 2019/6/27.
//  Copyright © 2019 lifei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OOB.h"

#define kSW [UIScreen mainScreen].bounds.size.width
#define kSH [UIScreen mainScreen].bounds.size.height

// iPhoneX系列
#define  HS_iPhoneX     (kSW == 375.f && kSH == 812.f ? YES : NO)
#define  HS_iPhoneXs    (kSW == 375.f && kSH == 812.f ? YES : NO)
#define  HS_iPhoneXsMax (kSW == 414.f && kSH == 896.f ? YES : NO)
#define  HS_iPhoneXR    (kSW == 414.f && kSH == 896.f ? YES : NO)
// 判断iPhoneX系列
#define  HS_XSeries (HS_iPhoneX || HS_iPhoneXs || HS_iPhoneXsMax || HS_iPhoneXR)

NS_ASSUME_NONNULL_BEGIN

@interface OOBTemplateBaseVC : UIViewController

// 目标图片
@property (nonatomic, strong) UIImage *targetImg;
// 相机，视频，图片等背景展示View
@property (nonatomic, strong) UIImageView *bgView;
// 标记目标的图片框
@property (nonatomic, strong) UIImageView *markView;
// 显示相似度标签
@property (nonatomic, strong) UILabel *similarLabel;
// 返回按钮
@property (nonatomic, strong) UIButton *backBtn;

@end

NS_ASSUME_NONNULL_END
