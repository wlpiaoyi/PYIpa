//
//  PYConfigManager.m
//  PYEntityManager
//
//  Created by wlpiaoyi on 15/10/19.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import "PYConfigManager.h"
#import "pyutilea.h"


const NSString *PY_CONFIGDATA_KEY = @"PYConfigManger_KeyArg";
const NSString *PY_CONFIGDATA_VALUE = @"PYConfigManger_ValueArg";

@interface PYConfigManager ()
@property (class, readonly, strong) NSUserDefaults *classUsrDefaults;
@end

@implementation PYConfigManager{
@private NSUserDefaults *usrDefaults;
}

-(nullable instancetype) init{
    self = [super init];
    usrDefaults = [PYConfigManager classUsrDefaults];
    return self;
}

-(void) setValue:(nullable id) value forKey:(nonnull NSString*) key{
    [usrDefaults setValue:[PYConfigManager parseValueForSet:value] forKey:key];
}

-(nullable id) valueForKey:(nonnull NSString*) key{
    id value =  [usrDefaults valueForKey:key];
    return [PYConfigManager parseValueForGet:value];
}

-(void) removeValueForKey:(nonnull NSString*) key{
    [usrDefaults removeObjectForKey:key];
}
-(BOOL) removeAll{
    return [PYConfigManager removeAllConfig];
}

-(BOOL) synchronize{
    return [usrDefaults synchronize];
}

-(void) dealloc{
    [self synchronize];
}

+(BOOL) setConfigValue:(nullable id) value forKey:(nonnull NSString*) key{
    NSUserDefaults *usrDefaults = [PYConfigManager classUsrDefaults];
    [usrDefaults setValue:[self parseValueForSet:value] forKey:key];
    return [usrDefaults synchronize];
}
+(nullable id) configValueForKey:(nonnull NSString*) key{
    NSUserDefaults *usrDefaults=[PYConfigManager classUsrDefaults];
    id value =  [usrDefaults valueForKey:key];
    return [self parseValueForGet:value];
}
+(void) removeConfigValueForKey:(nonnull NSString*) key{
    NSUserDefaults *usrDefaults=[PYConfigManager classUsrDefaults];
    [usrDefaults removeObjectForKey:key];
}
+(BOOL) removeAllConfig{
    NSUserDefaults *usrDefaults=[PYConfigManager classUsrDefaults];
    [usrDefaults removePersistentDomainForName:kAppBundleIdentifier];
    if(![usrDefaults synchronize]) return NO;
    NSDictionary *datas = [usrDefaults dictionaryRepresentation];
    NSArray *keys = [datas allKeys];
    for (NSString *key in keys) {
        [usrDefaults removeObjectForKey:key];
    }
    return YES;
}


+(nonnull NSUserDefaults *) classUsrDefaults{
    static NSUserDefaults * __STATIC_USERDEFAULTS;
    static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{
        __STATIC_USERDEFAULTS = [NSUserDefaults standardUserDefaults];
    });
    return __STATIC_USERDEFAULTS;
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
        return @{PY_CONFIGDATA_KEY:NSStringFromClass([((NSObject*)value) class]),PY_CONFIGDATA_VALUE:[value objectToDictionary] };
    }
}

+(id) parseValueForGet:(id) value{
    if (!value)  return nil;
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSString * tempKeyArg = value[PY_CONFIGDATA_KEY];
        id tempValueArg = value[PY_CONFIGDATA_VALUE];
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


@end
