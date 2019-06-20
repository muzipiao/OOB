//
//  OOBExampleTests.m
//  OOB_Tests
//
//  Created by lifei on 2019/6/20.
//  Copyright © 2019 lifei. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OOBViewController.h"
#import "OOBTemplateVC.h"
#import <objc/message.h>

@interface OOBExampleTests : XCTestCase

@property (nonatomic, strong) UIViewController *topVC; // 导航控制器的顶VC

@end

@implementation OOBExampleTests

- (void)setUp {
    // 找到顶视图 VC
    UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
    self.topVC = rootViewController;
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)rootViewController;
        self.topVC = nav.topViewController;
    }
}

- (void)tearDown {
    self.topVC = nil;
    [super tearDown];
}

- (void)testExampleUI {
    XCTAssertNotNil(self.topVC, @"当前顶控制器不为空");
    XCTAssertTrue([self.topVC isKindOfClass:[OOBViewController class]], @"topVC 类型");
    UIButton *cmBtn = nil;
    for (UIView *sub in self.topVC.view.subviews) {
        if (sub.tag == 1002 && [sub isKindOfClass:[UIButton class]]) {
            cmBtn = (UIButton *)sub;
            break;
        }
    }
    XCTAssertNotNil(cmBtn, @"找不到草莓按钮");
    // 选择草莓
    SEL cmBtnSel = NSSelectorFromString(@"targetBtnClick:");
    ((void (*) (id, SEL, UIButton *)) objc_msgSend) (self.topVC, cmBtnSel, cmBtn);
    // 跳转图像识别
    SEL sureBtnSel = NSSelectorFromString(@"objRecoBtnClick:");
    ((void (*) (id, SEL, UIButton *)) objc_msgSend) (self.topVC, sureBtnSel, nil);
    // 判断当前控制器
    UIViewController *presentedVC = self.topVC.presentedViewController;
    XCTAssertTrue([presentedVC isKindOfClass:[OOBTemplateVC class]], @"当前为 OOBTemplateVC");
    // 判断调用相机
    if (TARGET_OS_SIMULATOR != 1) {
        XCTestExpectation *expectationUI = [self expectationWithDescription:@"模拟器无法调用相机."];
        [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
            [expectationUI fulfill];
            if (error) {
                NSLog(@"expectation_testExampleUI=%@",error);
            }
            [presentedVC dismissViewControllerAnimated:NO completion:nil];
        }];
    }else{
        [presentedVC dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
