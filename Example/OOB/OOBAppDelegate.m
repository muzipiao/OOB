//
//  OOBAppDelegate.m
//  OOB
//
//  Created by lifei on 03/08/2019.
//  Copyright (c) 2019 lifei. All rights reserved.
//

#import "OOBAppDelegate.h"
#import "OOBViewController.h"

@implementation OOBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    OOBViewController *mainVC = [[OOBViewController alloc]init];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:mainVC];
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
