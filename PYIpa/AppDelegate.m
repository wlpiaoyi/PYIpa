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
#import "PYEventManager.h"
#import "PYUtile.h"
#import "pyutilea.h"
@interface GFDownloadCacheModel : NSObject
@property (nonatomic,copy) NSString *name;

@property (nonatomic,assign) NSInteger uuid;

@property (nonatomic,copy) NSString *fileName;

/// 标明是城市类型 还是poi类型
@property (nonatomic,copy) NSString *type;

@property (nonatomic,assign) long downloadTime;

@property (nonatomic,assign) CLLocationCoordinate2D centerLocation;

@property (nonatomic,assign) CGFloat size;

@end

@implementation GFDownloadCacheModel


@end

@interface test1:NSObject
@property (nonatomic) CGRect r;
@property (nonatomic) CLLocationCoordinate2D ld;
@property (nonatomic) NSInteger i;
@property (nonatomic, copy) void (^block) (void);
@property (nonatomic,strong) NSArray<test1 *> * t;
@property (nonatomic,strong) test1 * property_t;
@end
@implementation test1
@end

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    test1 * tt = [self createTest];
    NSArray<test1 *> * a;// = @[tt];
//    a.firstObject.block();
    [PYConfigManager setConfigValue:a forKey:@"ff"];
    a = [PYConfigManager configValueForKey:@"ff"];
//    a.firstObject.block();
    
    GFDownloadCacheModel * cacheModel = [GFDownloadCacheModel new];
    cacheModel.centerLocation = CLLocationCoordinate2DMake(3, 3);
    NSString * arg = [[((NSDictionary *)[cacheModel objectToDictionary]) toData] toString];
    
    [PYConfigManager setConfigValue:@[cacheModel] forKey:@"12312"];
    id obj = [PYConfigManager configValueForKey:@"12312"];
    if([PYConfigManager configValueForKey:@"testd"]){
        threadJoinGlobal(^{
            sleep(2);
            threadJoinMain(^{
                [[[UIAlertView alloc] initWithTitle:@"--" message:@"--" delegate:nil cancelButtonTitle:@"CACENCLE" otherButtonTitles:nil] show];
            });
        });
    }
//    [[PYEventManager singleInstance] presisitEvent:@"我的测试" startDate:[NSDate dateWithTimeIntervalSinceNow:60 * 3] endDate:[NSDate dateWithTimeIntervalSinceNow:60 * 4] alarmDate:[NSDate dateWithTimeIntervalSinceNow:60 * 1] completion:^(id data) {
//        
//    }];
//    test1 * t1 = [self createTest];
//    test1 * t2 = [self createTest];
//    NSDictionary * tempd =@{@"t1":t1, @"t2":t2, @"v":@(3)};
//    [PYConfigManager setConfigValue:@[tempd] forKey:@"testd"];
//    id tempd2 = [PYConfigManager configValueForKey:@"testd"];
//    NSArray * a = @[t1, t2];
//    [PYConfigManager setConfigValue:a forKey:@"a"];
//    a = [PYConfigManager configValueForKey:@"a"];
//    [PYConfigManager removeAllConfig];
//    [PYEntityAsist synEntity:@[[PYTestEntity class]] dataBaseName:@"test.db"];
//    PYTestEntity * te = [PYTestEntity new];
//    te.name = @"我的测试";
//    PYEntityManager * em = [PYEntityManager enityWithDataBaseName:@"test.db"];
//    te = [em persist:te];
//    te.name = @"我的修改";
//    te  = [em merge:te];
//    te = [em find:te.keyId entityClass:[PYTestEntity class]];
    return YES;
}
-(test1 *) createTest{
    test1 * t = [test1 new];
    t.i =3;
    t.ld = CLLocationCoordinate2DMake(20, 20);
    t.block = ^{NSLog(@"sss");};
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
