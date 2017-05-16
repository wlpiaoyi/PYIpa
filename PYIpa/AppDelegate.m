//
//  AppDelegate.m
//  PYIpa
//
//  Created by wlpiaoyi on 2016/12/11.
//  Copyright © 2016年 wlpiaoyi. All rights reserved.
//

#import "AppDelegate.h"
#import "PYConfigManager.h"
#import "PYEntityAsist.h"
#import "PYTestEntity.h"
#import "PYEntityManager.h"
@interface test1:NSObject
@property (nonatomic) CGRect r;
@property (nonatomic,strong) NSArray<test1 *> * t;
@end
@implementation test1
@end

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    test1 * t1 = [self createTest];
    test1 * t2 = [self createTest];
    NSArray * a = @[t1, t2];
    [PYConfigManager setConfigValue:a Key:@"a"];
    a = [PYConfigManager getConfigValue:@"a"];
    [PYEntityAsist synEntity:@[[PYTestEntity class]] dataBaseName:@"test.db"];
    PYTestEntity * te = [PYTestEntity new];
    te.name = @"我的测试";
    PYEntityManager * em = [PYEntityManager enityWithDataBaseName:@"test.db"];
    te = [em persist:te];
    te.name = @"我的修改";
    te  = [em merge:te];
    te = [em find:te.keyId entityClass:[PYTestEntity class]];
    return YES;
}
-(test1 *) createTest{
    test1 * t = [test1 new];
    t.r = CGRectMake(2, 2, 2, 2);
    test1 * t2 = [test1 new];
    t.t = @[t2];
    return t;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
