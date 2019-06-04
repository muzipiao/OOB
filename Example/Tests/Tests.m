//
//  OOBTests.m
//  OOBTests
//
//  Created by lifei on 03/08/2019.
//  Copyright (c) 2019 lifei. All rights reserved.
//

@import XCTest;
#import "OOB.h"

@interface Tests : XCTestCase

@property (nonatomic, strong) UIImage *targetImage; // 目标图像
@property (nonatomic, strong) UIViewController *topVC; // 导航控制器的顶VC

@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    self.targetImage = [UIImage imageNamed:@"apple"];
    // 找到顶视图 VC
    UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
    self.topVC = rootViewController;
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)rootViewController;
        self.topVC = nav.topViewController;
    }
}

- (void)tearDown
{
    [[OOB share] stopMatch];
    self.targetImage = nil;
    [self.topVC dismissViewControllerAnimated:NO completion:nil];
    [super tearDown];
}

- (void)testInitialize{
    OOB *OOBShare = [OOB share];
    XCTAssertNil(OOBShare.preview, @"预览图层默认为空");
    XCTAssertNotNil(self.targetImage, @"待识别图像不为空");
    XCTAssertTrue([OOBShare.sessionPreset isEqualToString:AVCaptureSessionPresetHigh], @"图像尺寸");
    XCTAssertTrue(OOBShare.cameraType == OOBCameraTypeBack, @"默认为后置摄像头");
    XCTAssertTrue(OOBShare.markerCornerRadius == 5.0f, @"切圆角半径默认为5");
    XCTAssertTrue(OOBShare.similarValue == 0.7f, @"相似度阈值默认0.7");
    XCTAssertNotNil(OOBShare.rectMarkerImage, @"矩形标记图像");
    XCTAssertNotNil(OOBShare.ovalMarkerImage, @"椭圆标记图像");
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 0.0;
    [OOBShare.markerLineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    XCTAssertTrue(red==1&&green==0&&blue==0&&alpha==1, @"标记图像默认红色");
}

- (void)testOOB
{
    if (TARGET_OS_SIMULATOR != 1) {
        // 未自定义变量时测试
        NSDate *beginDate = [NSDate date];
        XCTestExpectation *expectation = [self expectationWithDescription:@"Camer should not open."];
        [[OOB share] matchTemplate:self.targetImage resultBlock:^(CGRect targetRect, CGFloat similarValue) {
            BOOL similarValueNormal = (similarValue >= 0) && (similarValue <= 1);
            XCTAssertTrue(similarValueNormal, @"相似度在 0 到 1 之间。");
            NSTimeInterval timeDiff = [[NSDate date] timeIntervalSinceDate:beginDate];
            if (timeDiff > 2.0) {
                [expectation fulfill];
            }
        }];
        [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"expectation=%@",error);
            }
        }];
    }
    
    OOB *OOBShare = [OOB share];
    OOBShare.preview = self.topVC.view;
    XCTAssertEqual(OOBShare.preview, self.topVC.view, @"设置预览图层");
    
    UIImage *bbImg = [UIImage imageNamed:@"bobantang"];
    OOBShare.targetImg = bbImg;
    XCTAssertNotEqual(OOBShare.targetImg, bbImg, @"设置目标图像去Alpha");
    
    OOBShare.cameraType = OOBCameraTypeFront;
    XCTAssertTrue(OOBShare.cameraType == OOBCameraTypeFront, @"设置前置摄像头");
    
    OOBShare.sessionPreset = AVCaptureSessionPresetLow;
    XCTAssertTrue([OOBShare.sessionPreset isEqualToString:AVCaptureSessionPresetLow], @"设置图像质量");
    
    OOBShare.similarValue = 0.9;
    XCTAssertEqual(OOBShare.similarValue, 0.9, @"图像对比相似度");
    
    OOBShare.markerLineWidth = 10.0;
    XCTAssertEqual(OOBShare.markerLineWidth, 10.0, @"标记图像线条宽度");
    
    OOBShare.markerCornerRadius = 10.0;
    XCTAssertEqual(OOBShare.markerCornerRadius, 10.0, @"标记图像线条圆角半径");
    
    OOBShare.markerLineColor = [UIColor greenColor];
    CGFloat red = 0.0; // 0 <= red <= 1
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 0.0;
    [OOBShare.markerLineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    XCTAssertTrue(red==0&&green==1&&blue==0&&alpha==1, @"标记图像默认红色");
    XCTAssertNotNil(OOBShare.rectMarkerImage, @"矩形标记图像");
    XCTAssertNotNil(OOBShare.ovalMarkerImage, @"椭圆标记图像");
    
    if (TARGET_OS_SIMULATOR != 1) {
        // 设置变量后测试
        NSDate *beginDate1 = [NSDate date];
        XCTestExpectation *expectation1 = [self expectationWithDescription:@"Camer should not open."];
        [[OOB share] matchTemplate:self.targetImage resultBlock:^(CGRect targetRect, CGFloat similarValue) {
            BOOL similarValueNormal = (similarValue >= 0) && (similarValue <= 1);
            XCTAssertTrue(similarValueNormal, @"相似度在 0 到 1 之间。");
            NSTimeInterval timeDiff = [[NSDate date] timeIntervalSinceDate:beginDate1];
            if (timeDiff > 2.0) {
                [expectation1 fulfill];
            }
        }];
        [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"expectation1=%@",error);
            }
        }];
    }
    
}

@end

