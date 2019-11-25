//
//  PYEntityManager.m
//  PYEntityManager
//
//  Created by wlpiaoyi on 15/10/12.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import "PYEntityManager.h"
#import "PYEntitySql.h"
#import "PYIPADB.h"
#import "pyutilea.h"
#import <objc/runtime.h>



@interface PYDataBaseManager()
@property (nonatomic,strong) PYIPADatabase *dataBase;

@end

@interface PYEntityManager()

@end

@implementation PYDataBaseManager
@synthesize hasTransation,dbName;
+(instancetype) enityWithDataBaseName:(NSString*) dataBaseName{
    PYDataBaseManager *instance = [self new];
    instance->hasTransation = false;
    instance->dbName = dataBaseName;
    instance.dataBase = [PYEntityAsist synEntity:nil dataBaseName:dataBaseName];
    return instance;
}
/**
 执行更新
 */
-(long) executeUpdate:(nonnull NSString*) sql params:(nullable NSArray<NSString*>*) params{
    if (![self open]) {
        return NO;
    }
    if (params) {
        return (long)[self.dataBase executeUpdate:sql withArgumentsInArray:params];
    }else{
        return [self.dataBase executeUpdate:sql];
    }
}
/**
 执行查询
 @resultType Entity
 */
-(int) executeQuery:(nonnull NSString*) sql params:(nullable NSArray<id>*) params resultPoniter:(NSMutableArray<NSDictionary*> * _Nullable * _Nullable) resultPointer{
    if (![self open]) {
        return NO;
    }
    PYIPAResultSet *result;
    if (params&&[params count]) {
        result = [self.dataBase executeQuery:sql withArgumentsInArray:params];
    }else{
        result = [self.dataBase executeQuery:sql];
    }
    NSMutableArray<NSDictionary*> *columValuDics = [NSMutableArray<NSDictionary*> new];
    while ([result next]){
        NSDictionary *resultDictionary =[result resultDictionary];
        [columValuDics addObject:resultDictionary];
    }
    *resultPointer = columValuDics;
    return 1;
}

-(BOOL) open{
    BOOL b =[self.dataBase open];
    NSAssert(b, @"\n database open faild!\n");
    return b;
}
-(BOOL) close{
    BOOL b = [self.dataBase close] ;
    NSAssert(b, @"\n database close faild!\n");
    return b;
}
//==> 事务管理
-(BOOL) beginTransation{
    BOOL b;
    @synchronized(self) {
        hasTransation = true;
        b = [self.dataBase beginTransaction];
        NSAssert(b, @"\n beginTransation faild!\n");
    }
    return b;
}
-(int) commitTarnsation{
    int b = 0;
    @synchronized(self) {
        hasTransation = false;
        b = [self.dataBase commit];
        NSAssert(b, @"\n commitTarnsation faild!\n");
    }
    return b;
}
- (BOOL)rollbackTarnsation {
    BOOL b = false;
    @synchronized(self) {
        hasTransation = false;
        b = [self.dataBase rollback];
        NSAssert(b, @"\nrollbackTarnsation faild!\n");
    }
    return b;
}
///<==

-(void) dealloc{
    [self close];
}

@end


@implementation PYEntityManager

-(nullable id<PYEntity>) persist:(nonnull id<PYEntity>) entity{
    if (!entity) {
        return nil;
    }
    NSMutableArray *columNames;
    NSMutableArray *columValues;
    [PYEntityManager checkEntity:entity columNames:&columNames columValues:&columValues];
    
    if ([columValues count] && ([columValues count] == [columNames count])) {
        NSString *sql = [PYEntitySql getPersistSql:[entity class] columns:columNames];
        NSInteger result = [super executeUpdate:sql params:columValues];
        entity.keyId = result;
        return entity;
    }
    
    return nil;
}
-(nullable id<PYEntity>) merge:(nonnull id<PYEntity>) entity{
    if (!entity) {
        return nil;
    }
    if (entity.keyId == 0) {
        return [self persist:entity];
    }
    
    NSMutableArray *columNames;
    NSMutableArray *columValues;
    [PYEntityManager checkEntity:entity columNames:&columNames columValues:&columValues];
    if ([columValues count] && ([columValues count] == [columNames count])) {
        [columValues addObject:@(entity.keyId)];
        NSString *sql = [PYEntitySql getMergeSql:[entity class] columns:columNames];
        NSInteger result = [super executeUpdate:sql params:columValues];
        if(result <= 0) return nil;
        return entity;
    }

    return nil;
}
-(BOOL) remove:(nonnull id<PYEntity>) entity{
    if (!entity) {
        return false;
    }
    NSUInteger keyId = entity.keyId;
    NSString *sql = [PYEntitySql getDeleteSql:entity.class];
    [super executeUpdate:sql params:@[@(keyId)]];
    return true;
}
-(nullable id<PYEntity>) find:(NSInteger) keyId entityClass:(nonnull Class<PYEntity>) entityClass{
    NSString *sql = [PYEntitySql getFindSql:entityClass];
    NSArray<id<PYEntity>>* resultEntitys;
    resultEntitys = [self queryForEntitys:sql params:@[@(keyId)] entityClass:entityClass];
    if (resultEntitys && [resultEntitys count]) {
        return resultEntitys.firstObject;
    }
    return nil;
}
-(nonnull NSArray<id<PYEntity>>*) queryForEntitys:(nullable NSString*) sql params:(nullable NSArray<id>*) params entityClass:(nonnull Class<PYEntity>) entityClass{
    NSArray<NSDictionary*> * _Nullable resultDics = [self queryForDictionarys:sql params:params];
    NSArray<id<PYEntity>>* resultEntitys;
    [PYEntityManager parsetResultDics:resultDics entityClass:entityClass resultEntitys:&resultEntitys];
    if (resultEntitys && [resultEntitys count]) {
        return resultEntitys;
    }
    return nil;
}
-(nonnull NSArray<NSDictionary*>*) queryForDictionarys:(nullable NSString*) sql params:(nullable NSArray<id>*) params {
    NSMutableArray<NSDictionary*> * _Nullable resultDics;
    [super executeQuery:sql params:params resultPoniter:&resultDics];
    return resultDics;
}



+(void) checkEntity:(id<PYEntity>) entity columNames:(NSArray**) columNamesPointer columValues:(NSArray**) columValuesPionter{
    NSMutableArray *columNames = [NSMutableArray new];
    NSMutableArray *columValues = [NSMutableArray new];
    NSArray *caches = [PYEntityAsist getEntityReflectCache:[entity class]];
    for (NSDictionary *cache in caches) {
        NSString *name = [cache objectForKey:SqlMangerTypeName];
        NSString *type = [cache objectForKey:SqlMangerTypeColum];
        static NSString *keyIdName = @"keyId";
        if ([name isEqual:keyIdName]) {
            continue;
        }
        
        NSInvocation *invocation = [PYInvoke startInvoke:entity action:sel_getUid([name UTF8String])];
        if (!invocation) {
            continue;
        }
        
        id value = nil;
        if ([type isEqual:PYEntityColumTypeInt]) {
            NSInteger resultValue;
            [PYInvoke excuInvoke:&resultValue returnType:nil invocation:invocation];
            value = @(resultValue);
        }else if ([type isEqual:PYEntityColumTypeFloat]) {
            CGFloat resultValue;
            [PYInvoke excuInvoke:&resultValue returnType:nil invocation:invocation];
            value = @(resultValue);
        }else if ([type isEqual:PYEntityColumTypeString]) {
            void *resultValue;
            [PYInvoke excuInvoke:&resultValue returnType:nil invocation:invocation];
            value  = (__bridge id)(resultValue);
        }else if ([type isEqual:PYEntityColumTypeDate]) {
            void *resultValue;
            [PYInvoke excuInvoke:&resultValue returnType:nil invocation:invocation];
            NSDate *date = (__bridge NSDate *)(resultValue);
            if ([date isKindOfClass:[NSDate class]]) {
                value = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
            }
        }else if ([type isEqual:PYEntityColumTypeData]) {
            void *resultValue;
            [PYInvoke excuInvoke:&resultValue returnType:nil invocation:invocation];
            NSData *data = (__bridge NSData *)(resultValue);
            if ([data isKindOfClass:[NSData class]]) {
                value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
        }
        if (value) {
            [columNames addObject:name];
            [columValues addObject:value];
        }
    }
    *columNamesPointer = columNames;
    *columValuesPionter = columValues;
}
+(void)parsetResultDics:(NSArray<NSDictionary*> *) resultDics entityClass:(Class<PYEntity>)entityClass resultEntitys:(NSArray<id<PYEntity>>**) resultEntitysPointer{
    NSMutableArray<id<PYEntity>>* resultEntitys = [NSMutableArray <id<PYEntity>> new];
    if (resultDics && [resultDics count]) {
        for (NSMutableDictionary *resultDic in resultDics) {
            
            NSArray *caches = [PYEntityAsist getEntityReflectCache:entityClass];
            for (NSDictionary *cache in caches) {
                NSString *type = cache[SqlMangerTypeKey];
                NSString *name = cache[SqlMangerTypeName];
                NSObject *value = resultDic[name];
                if (value &&  [type isEqual:PYEntityIvarTypeDate]) {
                    if ([value isKindOfClass:[NSNumber class]]) {
                        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[((NSNumber*)value) doubleValue]];
                        resultDic[name] = date;
                    }else{
                        printf("[%s] value's type should be NSNumber but it's type is %s", [name UTF8String], class_getName([value class]));
                    }
                }else if([type isEqual:PYEntityIvarTypeData]){
                    if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [((NSString*)value) dataUsingEncoding:NSUTF8StringEncoding];
                        resultDic[name] = data;
                    }else{
                        printf("[%s]value's type should be NSString but it's type is %s", [name UTF8String], class_getName([value class]));
                    }
                    
                }
            }
            
            id<PYEntity> entity = (id<PYEntity>)[((Class)entityClass) objectWithDictionary:resultDic];
            [resultEntitys addObject:entity];
        }
    }
    *resultEntitysPointer = resultEntitys;
}

@end
