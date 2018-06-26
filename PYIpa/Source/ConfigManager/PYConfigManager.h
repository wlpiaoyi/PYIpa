//
//  PYConfigManager.h
//  PYEntityManager
//
//  Created by wlpiaoyi on 15/10/19.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 可以存储NSDictionary ,NSArray ,NSString ,NSNumber ,NSData ,NSDate class ,(实体对象)
 */
@interface PYConfigManager : NSObject

+(BOOL) setValue:(id) value key:(NSString*) key;
+(id) getValue:(NSString*) key;
+(void) removeValue:(NSString*) key;
+(void) removeAll;

+(id) getConfigValue:(NSString*) key  NS_DEPRECATED_IOS(2_0, 7_0, "Use setConfigValue:key");
+(BOOL) setConfigValue:(id) value Key:(NSString*) key  NS_DEPRECATED_IOS(2_0, 7_0, "Use setConfigValue:key");
+(void) removeConfigValue:(NSString*) key   NS_DEPRECATED_IOS(2_0, 7_0, "Use setConfigValue:key");
+(void) removeALL   NS_DEPRECATED_IOS(2_0, 7_0, "Use setConfigValue:key");
@end
