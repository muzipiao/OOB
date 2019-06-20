//
//  OOBTests.m
//  OOBTests
//
//  Created by lifei on 03/08/2019.
//  Copyright (c) 2019 lifei. All rights reserved.
//

@import XCTest;
#import "OOB.h"
#import <objc/message.h>

@interface Tests : XCTestCase

@property (nonatomic, strong) UIImage *targetImage; // 目标图像
@property (nonatomic, strong) UIViewController *topVC; // 导航控制器的顶VC
@property (nonatomic, strong) AVAssetReader *assetReader; // 读取视频CMSampleBufferRef

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
    [self.assetReader cancelReading];
    self.assetReader = nil;
    self.targetImage = nil;
    [super tearDown];
}

- (void)testInitialize{
    OOB *OOBShare = [OOB share];
    XCTAssertNil(OOBShare.preview, @"预览图层默认为空");
    XCTAssertNotNil(self.targetImage, @"待识别图像不为空");
    XCTAssertNotNil(self.topVC, @"当前控制器不为空");
    XCTAssertNotNil(OOBShare.sessionPreset, @"视频尺寸不为空");
    XCTAssertTrue(OOBShare.cameraType == OOBCameraTypeBack, @"默认为后置摄像头");
    XCTAssertTrue(OOBShare.markerCornerRadius >= 0.0f, @"切圆角半径不为负");
    XCTAssertTrue(OOBShare.markerLineWidth >= 0.0f, @"标记线宽默认不为负");
    XCTAssertTrue(OOBShare.similarValue <= 1.0f, @"相似度阈值小于等于1");
    XCTAssertNotNil(OOBShare.rectMarkerImage, @"矩形标记图像可自动获取");
    XCTAssertNotNil(OOBShare.ovalMarkerImage, @"椭圆标记图像可自动获取");
    XCTAssertNotNil(OOBShare.markerLineColor, @"标记图像默认红色，不为空");
}

// 测试单例
- (void)testShareOOB {
    OOB *OOBShare = [OOB share];
    OOB *OOBAlloc = [[OOB alloc]init];
    OOB *OOBCopy = OOBShare.copy;
    XCTAssertEqualObjects(OOBShare, OOBAlloc, @"Alloc 对象应该为单例");
    XCTAssertEqualObjects(OOBShare, OOBCopy, @"Copy 对象应该为单例");
}

// 测试默认设置
- (void)testDefaultOOB {
    // 测试视频流
    [self samRefTest];
}

// 测试用户自定义设置
- (void)testUserSetOOB
{
    UIViewController *targetVC = [[UIViewController alloc]init];
    targetVC.view.backgroundColor = [UIColor whiteColor];
    [self.topVC presentViewController:targetVC animated:NO completion:nil];
    
    // 设置预览图层
    OOB *OOBShare = [OOB share];
    OOBShare.preview = targetVC.view;
    XCTAssertEqual(OOBShare.preview, targetVC.view, @"设置预览图层");
    
    // 更换目标视图
    UIImage *bbImg = [UIImage imageNamed:@"bobantang"];
    OOBShare.targetImg = bbImg;
    XCTAssertNotEqual(OOBShare.targetImg, bbImg, @"设置目标图像去Alpha");
    
    // 切换摄像头
    OOBShare.cameraType = OOBCameraTypeFront;
    XCTAssertTrue(OOBShare.cameraType == OOBCameraTypeFront, @"设置前置摄像头");
    
    // 设置摄像头预览质量
    OOBShare.sessionPreset = AVCaptureSessionPresetLow;
    XCTAssertTrue([OOBShare.sessionPreset isEqualToString:AVCaptureSessionPresetLow], @"设置图像质量");
    
    OOBShare.similarValue = 0.9;
    XCTAssertEqual(OOBShare.similarValue, 0.9, @"图像对比相似度");
    
    OOBShare.markerLineWidth = 10.0;
    XCTAssertEqual(OOBShare.markerLineWidth, 10.0, @"标记图像线条宽度");
    
    OOBShare.markerCornerRadius = 10.0;
    XCTAssertEqual(OOBShare.markerCornerRadius, 10.0, @"标记图像线条圆角半径");
    
    // 设置标记图像为绿色
    OOBShare.markerLineColor = [UIColor greenColor];
    CGFloat red = 0.0; // 0 <= red <= 1
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 0.0;
    [OOBShare.markerLineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    XCTAssertTrue(red==0&&green==1&&blue==0&&alpha==1, @"标记图像默认绿色");
    XCTAssertNotNil(OOBShare.rectMarkerImage, @"矩形标记图像");
    XCTAssertNotNil(OOBShare.ovalMarkerImage, @"椭圆标记图像");
    // 测试视频流
    [self samRefTest];
}

-(void)samRefTest{
    // 如果是真机
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
        // 回到主页
        UIViewController *presentedVC = self.topVC.presentedViewController;
        [presentedVC dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    
    // 如果是模拟器
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"oob_apple.mp4" withExtension:nil];
    XCTAssertNotNil(url, @"待测视频不能为空");
    // 获取视频CMSampleBufferRef
    AVAsset *asset = [AVAsset  assetWithURL:url];
    // 1. 配置AVAssetReader
    AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;;
    self.assetReader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
    // 设置输出格式kCVPixelBufferWidthKey kCVPixelBufferHeightKey
    NSDictionary *readerOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],                                   kCVPixelBufferPixelFormatTypeKey,nil];
    
    AVAssetReaderTrackOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:readerOutputSettings];
    [self.assetReader addOutput:trackOutput];
    // 开始读取 CMSampleBufferRef
    [self.assetReader startReading];
    // 定义回调 block
    [[OOB share] matchTemplate:self.targetImage resultBlock:^(CGRect targetRect, CGFloat similarValue) {
        BOOL similarValueNormal = (similarValue >= 0.5) && (similarValue <= 1);
        XCTAssertTrue(similarValueNormal, @"相似度在 0 到 1 之间。");
    }];
    
    CMSampleBufferRef samRef = [trackOutput copyNextSampleBuffer];
    SEL delegateSel = NSSelectorFromString(@"captureOutput:didOutputSampleBuffer:fromConnection:");
    ((void (*) (id, SEL, AVCaptureOutput *, CMSampleBufferRef, AVCaptureConnection *)) objc_msgSend) ([OOB share], delegateSel, nil, samRef, nil);
    // 回到主页
    UIViewController *presentedVC = self.topVC.presentedViewController;
    [presentedVC dismissViewControllerAnimated:NO completion:nil];
}

@end

