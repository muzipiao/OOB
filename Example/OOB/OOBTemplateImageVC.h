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
#import "OOBTemplateBaseVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface OOBTemplateImageVC : OOBTemplateBaseVC

// 在背景图像上查找目标图像
@property (nonatomic, strong) UIImage *bgImg;

@end

NS_ASSUME_NONNULL_END
