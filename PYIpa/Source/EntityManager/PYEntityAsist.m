//
//  PYEntityAsist.m
//  PYEntityManager
//
//  Created by wlpiaoyi on 15/10/13.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import "PYEntityAsist.h"
#import "PYEntitySql.h"
#import "FMDB.h"
#import "pyutilea.h"
#import <objc/runtime.h>

@protocol PYEntityHookTag<NSObject>
@end

const NSString * SqlMangerTypeKey = @"type";
const NSString * SqlMangerTypeName = @"name";
const NSString * SqlMangerTypeColum = @"colum";

const NSString * _Nonnull PYEntityIvarNameKey = @"adsfads";
const NSString * _Nonnull PYEntityIvarTypeKey = @"adfddde";
const NSString * _Nonnull PYEntityIvarAnnotationKey = @"aodkiud";

const NSString * _Nonnull PYEntityIvarTypeInt = @"NSInteger";
const NSString * _Nonnull PYEntityIvarTypeFloat = @"CGFloat";
const NSString * _Nonnull PYEntityIvarTypeString = @"NSString";
const NSString * _Nonnull PYEntityIvarTypeDate = @"NSDate";
const NSString * _Nonnull PYEntityIvarTypeData = @"NSData";

const NSString * _Nonnull PYEntityColumTypeInt = @"INTEGER";
const NSString * _Nonnull PYEntityColumTypeFloat = @"REAL";
const NSString * _Nonnull PYEntityColumTypeString = @"TEXT";
const NSString * _Nonnull PYEntityColumTypeDate = @"NUMBERIC";
const NSString * _Nonnull PYEntityColumTypeData = @"BLOB";

const NSString * _Nonnull PYEntityClassIvarSuffix = @"@property (nonatomic) ";
const NSString * _Nonnull PYEntityClassIvarSuffixStrong = @"@property (nonatomic, strong) ";

@implementation PYEntityAsist


+(nonnull NSArray<NSString*>*) createEntityClassDataWithInfos:(nonnull NSArray<NSDictionary*>*) infos className:(nonnull NSString*) className classAnnotation:(nullable NSString*) classAnnotation{
    static  NSString* _Nonnull  (^blockCreateAnnotation)( NSString* _Nonnull , NSUInteger) = ^ NSString* _Nonnull  ( NSString* _Nonnull  annotation, NSUInteger count) {
        
        NSMutableString *tempArg = [[NSMutableString alloc] initWithString:annotation];
        static NSString *tempSuffix1 = @"\n";
        static NSString *tempSuffix2= @"__n__";
        NSMutableString *tempSuffix3 = [[NSMutableString alloc] initWithString:tempSuffix2];
        for (int i = 0; i < count; i++) {
            [tempSuffix3 appendString:@" "];
        }
        while ([tempArg containsString:tempSuffix1]) {
            [tempArg replaceCharactersInRange:[tempArg rangeOfString:tempSuffix1] withString:tempSuffix3];
            
        }
        while ([tempArg containsString:tempSuffix2]) {
            [tempArg replaceCharactersInRange:[tempArg rangeOfString:tempSuffix2] withString:tempSuffix1];
        }
        return tempArg;
    };
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy年MM月dd日"];
    NSString * time =  [formatter stringFromDate:[NSDate date]];
    [formatter setDateFormat:@"yyyy年"];
    NSString * year = [formatter stringFromDate:[NSDate date]];
    NSString * headClassData = [NSString stringWithFormat:@"// \n// %@.h\n// \n//\n//  Created by wlpiaoyi on %@\n//  Copyright © %@ wlpiaoyi. All rights reserved.\n//\n\n", className, time, year];
    
    NSMutableString *entityClassArg = [NSMutableString new];
    [entityClassArg appendString: headClassData];
    if (classAnnotation && classAnnotation.length) {
        [entityClassArg appendFormat:@"/*\n  %@  \n*/\n",blockCreateAnnotation(classAnnotation,2)];
    }
    [entityClassArg appendFormat:@"#import \"%@.h\"\n\n",NSStringFromClass(self.class)];
    [entityClassArg appendFormat:@"@interface %@ : NSObject<PYEntity>\n", className];
    
    
    [entityClassArg appendFormat:@"/*\n 关键值,唯一标示  \n*/\n%@NSUInteger keyId;\n",PYEntityClassIvarSuffix];
    for (NSDictionary* info in infos) {
        NSString *ivarAnnotation = info[PYEntityIvarAnnotationKey];
        NSString *ivarName = info[PYEntityIvarNameKey];
        NSString *ivarType = info[PYEntityIvarTypeKey];
        if (ivarAnnotation && ivarAnnotation.length) {
            [entityClassArg appendFormat:@"/*\n  %@  \n*/\n",blockCreateAnnotation(ivarAnnotation,2)];
        }
        if ([ivarType isEqual:PYEntityIvarTypeInt] || [ivarType isEqual:PYEntityIvarTypeFloat]) {
            [entityClassArg appendString:(NSString*)PYEntityClassIvarSuffix];
            [entityClassArg appendFormat:@"%@ %@;", ivarType, ivarName];
        }else{
            [entityClassArg appendString:(NSString*)PYEntityClassIvarSuffixStrong];
            [entityClassArg appendFormat:@"%@ * %@;", ivarType, ivarName];
        }
        [entityClassArg appendString:@"\n"];
    }
    [entityClassArg appendString:@"\n@end\n"];
    NSString *interfaceData = entityClassArg;
    
    entityClassArg = [NSMutableString new];
    [entityClassArg appendString:headClassData];
    [entityClassArg appendFormat:@"#import \"%@.h\"\n\n",className];
    [entityClassArg appendFormat:@"@implementation %@\n\n\n",className];
    [entityClassArg appendString:@"@end"];
    NSString * implementationData = entityClassArg;
    
    return @[interfaceData, implementationData];
}



/**
 获取反射数据
 */
+(nonnull NSArray*) getEntityReflectCache:(nonnull Class<PYEntity>) clazz{
    NSMutableArray<NSDictionary*> *cache;
    @synchronized(self) {
        static NSMutableDictionary *caches;
        if (!caches) {
            caches = [NSMutableDictionary new];
        }
        cache = caches[NSStringFromClass(clazz)];
        if (cache == nil) {
            NSMutableArray<NSDictionary*> * tempReflet = (NSMutableArray<NSDictionary*>*)[PYInvoke getPropertyInfosWithClass:clazz];
            static NSString * keyDebugDescription;
            static NSString * keyDescription;
            static NSString * keySuperclass;
            static NSString * keyHash;
            
            static dispatch_once_t onceToken01;
            dispatch_once(&onceToken01, ^{
                keyDebugDescription = @"debugDescription";
                keyDescription = @"description";
                keySuperclass = @"superclass";
                keyHash = @"hash";
            });
            
            NSMutableArray<NSDictionary*> * tempRefletRemove = [NSMutableArray<NSDictionary*>  new];
            for (NSDictionary *temp in tempReflet) {
                if ([temp[SqlMangerTypeName] isEqual:keyDebugDescription]) {
                    [tempRefletRemove addObject:temp];
                }else if ([temp[SqlMangerTypeName] isEqual:keyDescription]) {
                    [tempRefletRemove addObject:temp];
                }else if ([temp[SqlMangerTypeName] isEqual:keySuperclass]) {
                    [tempRefletRemove addObject:temp];
                }else if ([temp[SqlMangerTypeName] isEqual:keyHash]) {
                    [tempRefletRemove addObject:temp];
                }
            }
            [tempReflet removeObjectsInArray:tempRefletRemove];
            
            [self checkCaches:&tempReflet clazz:clazz];
            cache =  (NSMutableArray*)tempReflet;
            
            static NSString *typeInt;
            static NSString *typeFloat;
            static NSString *typeDouble;
            static NSString *typeString;
            static NSString *typeDate;
            static NSString *typeData;
            
            static dispatch_once_t onceToken02;
            dispatch_once(&onceToken02, ^{
                typeInt = @"Int";
                typeFloat = @"Float";
                typeDouble = @"Double";
                typeString = @"NSString";
                typeDate = @"NSDate";
                typeData = @"NSData";
            });
            
            for (NSInteger index = 0; index< [cache count]; index++) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:cache[index]];
                NSString *type = dic[SqlMangerTypeKey];
                if (type.length >= typeInt.length && [[type substringToIndex:typeInt.length] isEqual:typeInt]) {
                    dic[SqlMangerTypeColum] = PYEntityColumTypeInt;
                    dic[SqlMangerTypeKey] = PYEntityIvarTypeInt;
                }else if ((type.length >= typeFloat.length && [[type substringToIndex:typeFloat.length] isEqual:typeFloat]) || (type.length >= typeDouble.length && [[type substringToIndex:typeDouble.length] isEqual:typeDouble])) {
                    dic[SqlMangerTypeColum] = PYEntityColumTypeFloat;
                    dic[SqlMangerTypeKey] = PYEntityIvarTypeFloat;
                }else if ([type isEqual:typeString]) {
                    dic[SqlMangerTypeColum] = PYEntityColumTypeString;
                    dic[SqlMangerTypeKey] = PYEntityIvarTypeString;
                }else if ([type  isEqual:typeDate]) {
                    dic[SqlMangerTypeColum] = PYEntityColumTypeDate;
                    dic[SqlMangerTypeKey] = PYEntityIvarTypeDate;
                }else if([type isEqual:typeData]){
                    dic[SqlMangerTypeColum] = PYEntityColumTypeData;
                    dic[SqlMangerTypeKey] = PYEntityIvarTypeData;
                }
                cache[index] = dic;
            }
            caches[NSStringFromClass(clazz)] = cache;
        }
    }
    return cache;
}
/**
 移除不需要的字段
 */
+(void) checkCaches:(NSArray**) cachesPointer clazz:(nonnull Class<PYEntity>) clazz{
    if (!cachesPointer || !(*cachesPointer) || ![(*cachesPointer) count]) {
        return;
    }
    if (!class_getClassMethod(clazz, @selector(notColums))) {
        return;
    }
    NSArray<NSString*>* notColums = [clazz notColums];
    if (!notColums ||  ![notColums count]) {
        return;
    }
    NSMutableArray *caches = [NSMutableArray arrayWithArray:*cachesPointer];
    NSMutableArray *remves = [NSMutableArray new];
    NSInteger count = [notColums count];
    for (NSDictionary *cache in caches) {
        if ([remves count] >= count) {
            break;
        }
        NSString *name = cache[SqlMangerTypeName];
        for (NSString *colum in notColums) {
            if ([colum isEqual:name]) {
                [remves addObject:colum];
                break;
            }
        }
    }
    [caches removeObjectsInArray:remves];
    *cachesPointer = caches;
}

+(id) synEntity:(nullable NSArray<Class<PYEntity>>*) clazzs dataBaseName:(nonnull NSString*) dataBaseName{
    FMDatabase *dataBase;
    @synchronized(self) {
        NSString *dataBasePath = [NSString stringWithFormat:@"%@/%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject, dataBaseName];
        dataBase = [FMDatabase databaseWithPath:dataBasePath];
        if (clazzs && [clazzs count]) {
            
            if(![dataBase open]){
                printf("open database faild!\n");
            }else{
                NSMutableString *sqls = [NSMutableString new];
                Protocol *p = @protocol(PYEntityHookTag);
                for (Class<PYEntity> clazz in clazzs) {
                    if (class_conformsToProtocol(clazz, p)) {
                        printf("it has inject  in database that name is %s",[NSStringFromClass(clazz) UTF8String]);
                        continue;
                    }
                    class_addProtocol(clazz, p);
                    [sqls appendString: [PYEntitySql getCreateSql:clazz]];
                    [sqls appendString:@"\n"];
                }
                if (sqls.length) {
                    [dataBase executeUpdate:sqls];
                }
                
                sqls = [NSMutableString new];
                for (Class<PYEntity> clazz in clazzs) {
                    if (!class_conformsToProtocol(clazz, p)) {
                        continue;
                    }
                    FMResultSet *result;
                    result = [dataBase executeQuery:[PYEntitySql getTableStrutSql:clazz]];
                    NSMutableArray<NSDictionary*> *struts = [NSMutableArray<NSDictionary*> new];
                    while ([result next]){
                        NSDictionary *strut =[result resultDictionary];
                        [struts addObject:strut];
                    }
                    NSMutableArray *copyCaches =[NSMutableArray arrayWithArray: [PYEntityAsist getEntityReflectCache:clazz]];
                
                    for (NSDictionary *strut in struts) {
                        NSString *name = strut[SqlMangerTypeName];
                        for (NSDictionary * cache in copyCaches) {
                            NSString *_name = cache[SqlMangerTypeName];
                            if ([name isEqual:_name]) {
                                [copyCaches removeObject:cache];
                                break;
                            }
                        }
                    }
                    if ([copyCaches count]) {
                        [sqls appendString:[PYEntitySql getTableAlertSql:clazz colums:copyCaches]];
                        [sqls appendString:@"\n"];
                    }
                }
                if (sqls.length) {
                    [dataBase executeUpdate:sqls];
                }
                
                [dataBase close];
            }
        }
    }
    return dataBase;
}
@end
