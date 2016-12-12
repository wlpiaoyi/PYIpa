//
//  PYConfigManager.m
//  PYEntityManager
//
//  Created by wlpiaoyi on 15/10/19.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import "PYConfigManager.h"
#import "pyutilea.h"


const NSString *PYConfigManger_KeyArg = @"PYConfigManger_KeyArg";
const NSString *PYConfigManger_ValueArg = @"PYConfigManger_ValueArg";


@implementation PYConfigManager
+(BOOL) setConfigValue:(id) value Key:(NSString*) key{
    
    NSUserDefaults *usrDefauls=[NSUserDefaults standardUserDefaults];
    id cache;
    if ([value isKindOfClass:[NSDictionary class]] ||
        [value isKindOfClass:[NSString class]] ||
        [value isKindOfClass:[NSNumber class]] ||
        [value isKindOfClass:[NSData class]] ||
        [value isKindOfClass:[NSDate class]]) {
        cache = value;
    }else if([value isKindOfClass:[NSArray class]]){
        NSMutableArray * array = [NSMutableArray new];
        for (NSObject * obj in value ) {
            id objDict = @{PYConfigManger_KeyArg:NSStringFromClass([((NSObject*)obj) class]),PYConfigManger_ValueArg:[obj objectToDictionary] };
            [array addObject:objDict];
        }
        cache = array;
    } else{
        cache = @{PYConfigManger_KeyArg:NSStringFromClass([((NSObject*)value) class]),PYConfigManger_ValueArg:[value objectToDictionary] };
    }
    [usrDefauls setValue:cache forKey:key];
   return [usrDefauls synchronize];
}
+(id) getConfigValue:(NSString*) key{
    
    NSUserDefaults *usrDefauls=[NSUserDefaults standardUserDefaults];
    id value =  [usrDefauls valueForKey:key];
    if (!value) {
        return nil;
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSString *tempKeyArg = value[PYConfigManger_KeyArg];
        Class clazz;
        if (tempKeyArg && tempKeyArg.length && (clazz = NSClassFromString(tempKeyArg))) {
            value = [clazz objectWithDictionary:value[PYConfigManger_ValueArg]];
        }
    }else if([value isKindOfClass:[NSArray class]]){
        NSMutableArray * array = [NSMutableArray new];
        for (NSDictionary * obj in value ) {
            NSString *tempKeyArg = obj[PYConfigManger_KeyArg];
            Class clazz = NSClassFromString(tempKeyArg);
            [array addObject:[clazz objectWithDictionary:obj[PYConfigManger_ValueArg]]];
        }
        value = array;
    }
    return value;
}
+(void) removeConfigValue:(NSString*) key{
    NSUserDefaults *usrDefauls=[NSUserDefaults standardUserDefaults];
    [usrDefauls removeObjectForKey:key];
}
+(void) removeALL{
    NSUserDefaults *usrDefauls=[NSUserDefaults standardUserDefaults];
    NSDictionary *datas = [usrDefauls dictionaryRepresentation];
    NSArray *keys = [datas allKeys];
    for (NSString *key in keys) {
        [usrDefauls removeObjectForKey:key];
    }
}

@end
