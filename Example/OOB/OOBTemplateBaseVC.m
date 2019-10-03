//
//  OOBTemplateBaseVC.m
//  OOB_Example
//
//  Created by lifei on 2019/6/27.
//  Copyright © 2019 lifei. All rights reserved.
//

#import "OOBTemplateBaseVC.h"

@interface OOBTemplateBaseVC ()

@end

@implementation OOBTemplateBaseVC

///MARK: - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.modalPresentationStyle = UIModalPresentationFullScreen;
}

// 返回
-(void)backBtnClick:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

///MARK: - Lazy Load

-(UIButton *)backBtn{
    if (!_backBtn) {
        UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [tempBtn setTitle:@"      返   回     " forState:UIControlStateNormal];
        tempBtn.backgroundColor = [UIColor brownColor];
        tempBtn.layer.cornerRadius = 5;
        tempBtn.layer.masksToBounds = YES;
        [tempBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [tempBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [tempBtn sizeToFit];
        _backBtn = tempBtn;
    }
    return _backBtn;
}

// 标记图像
-(UIImageView *)markView{
    if (!_markView) {
        // 更改矩形框颜色为深红色：R=254 G=67 B=101
        UIColor *darkRed = [UIColor colorWithRed:254.0/255.0 green:67.0/255.0 blue:101.0/255.0 alpha:1.0];
        // 标记框图片大小，宽为屏幕宽，宽高比和目标图片相同
        CGSize tgImgSize = _targetImg.size;
        CGFloat markWidth = kSW * 0.5;
        CGFloat markHeight = (tgImgSize.height / tgImgSize.width) * markWidth;
        if (markHeight <= 0) {
            markHeight = markWidth;
        }
        CGSize markSize = CGSizeMake(markWidth, markHeight);
        UIImage *markImg = [OOBTemplate createRect:markSize borderColor:darkRed borderWidth:5 cornerRadius:5]; // 设置标记图像为矩形
        UIImageView *markerImgView = [[UIImageView alloc]initWithImage:markImg];
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
        simLabel.text = @"点击屏幕开始识别目标";
        simLabel.textAlignment = NSTextAlignmentCenter;
        simLabel.font = [UIFont systemFontOfSize:14];
        [simLabel sizeToFit];
        _similarLabel = simLabel;
    }
    return _similarLabel;
}

// 相机，视频，图片等背景展示View
- (UIImageView *)bgView{
    if (!_bgView) {
        UIImageView *tempImgView = [[UIImageView alloc]initWithFrame:CGRectZero];
        tempImgView.backgroundColor = [UIColor lightGrayColor];
        _bgView = tempImgView;
    }
    return _bgView;
}

@end
