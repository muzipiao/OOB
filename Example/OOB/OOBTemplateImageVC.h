//
//  OOBTemplateImageVC.h
//  OOB_Example
//
//  Created by lifei on 2019/6/21.
//  Copyright © 2019 lifei. All rights reserved.
/**
 * 识别图片中目标
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OOBTemplateImageVC : UIViewController

// 需要识别的目标图像
@property (nonatomic, strong) UIImage *targetImg;

// 在背景图像上查找目标图像
@property (nonatomic, strong) UIImage *bgImg;

@end

NS_ASSUME_NONNULL_END
