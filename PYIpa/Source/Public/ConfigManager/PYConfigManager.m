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

+(BOOL) setValue:(id) value key:(NSString*) key{
    NSUserDefaults *usrDefauls=[NSUserDefaults standardUserDefaults];
    [usrDefauls setValue:[self parseValueForSet:value] forKey:key];
    return [usrDefauls synchronize];
}
+(id) getValue:(NSString*) key{
    NSUserDefaults *usrDefauls=[NSUserDefaults standardUserDefaults];
    id value =  [usrDefauls valueForKey:key];
    return [self parseValueForGet:value];
}
+(void) removeValue:(NSString*) key{
    NSUserDefaults *usrDefauls=[NSUserDefaults standardUserDefaults];
    [usrDefauls removeObjectForKey:key];
}
+(void) removeAll{
    NSUserDefaults *usrDefauls=[NSUserDefaults standardUserDefaults];
    NSDictionary *datas = [usrDefauls dictionaryRepresentation];
    NSArray *keys = [datas allKeys];
    for (NSString *key in keys) {
        [usrDefauls removeObjectForKey:key];
    }
}

+(BOOL) canPersisitForValue:(Class) value{
    if ([value isKindOfClass:[NSString class]] ||
        [value isKindOfClass:[NSNumber class]] ||
        [value isKindOfClass:[NSData class]] ||
        [value isKindOfClass:[NSDate class]]) {
        return true;
    }
    return false;
}

+(id) parseValueForSet:(id) value{
    if ([self canPersisitForValue:value]) {
        return value;
    }else if([value isKindOfClass:[NSArray class]]){
        NSMutableArray * array = [NSMutableArray new];
        for (NSObject * obj in value ) {
            id objDict = [self parseValueForSet:obj];
            [array addObject:objDict];
        }
        return array;
    }else if([value isKindOfClass:[NSSet class]]){
        NSMutableSet * array = [NSMutableSet new];
        for (NSObject * obj in value ) {
            id objDict = [self parseValueForSet:obj];
            [array addObject:objDict];
        }
        return array;
    }else if([value isKindOfClass:[NSDictionary class]]){
        NSMutableDictionary * dict = [NSMutableDictionary new];
        for (NSString * key in ((NSDictionary *) value)) {
            id objDict = [self parseValueForSet:value[key]];
            if(objDict) dict[key] = objDict;
        }
        return dict;
    }else{
        return @{PYConfigManger_KeyArg:NSStringFromClass([((NSObject*)value) class]),PYConfigManger_ValueArg:[value objectToDictionary] };
    }
}
+(id) parseValueForGet:(id) value{
    if (!value)  return nil;
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSString * tempKeyArg = value[PYConfigManger_KeyArg];
        id tempValueArg = value[PYConfigManger_ValueArg];
        if(tempKeyArg && tempValueArg){
            Class clazz;
            if (tempKeyArg && tempKeyArg.length && (clazz = NSClassFromString(tempKeyArg))) {
                return [clazz objectWithDictionary: tempValueArg];
            }
        }else{
            NSMutableDictionary * dict = [NSMutableDictionary new];
            for (NSString * key in ((NSDictionary *)value)) {
                id pValue = [self parseValueForGet:value[key]];
                if(pValue) dict[key] = pValue;
            }
            return dict;
        }
    }else if([value isKindOfClass:[NSArray class]]){
        NSMutableArray * array = [NSMutableArray new];
        for (NSDictionary * obj in value ) {
            id pValue = [self parseValueForGet:obj];
            if(pValue) [array addObject:pValue];
        }
        return array;
    }else if([value isKindOfClass:[NSSet class]]){
        NSMutableSet * set = [NSMutableSet new];
        for (NSDictionary * obj in value ) {
            id pValue = [self parseValueForGet:obj];
            if(pValue) [set addObject:pValue];
        }
        return set;
    }
    return value;
    
}


+(BOOL) setConfigValue:(id) value Key:(NSString*) key{
    return [self setValue:value key:key];
}
+(id) getConfigValue:(NSString*) key{
    return [self getValue:key];
}
+(void) removeConfigValue:(NSString*) key{
    [self removeValue:key];
}
+(void) removeALL{
    [self removeAll];
}

@end
