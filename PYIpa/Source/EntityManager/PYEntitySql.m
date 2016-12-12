//
//  PYEntitySql.m
//  PYEntityManager
//
//  Created by wlpiaoyi on 15/10/12.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import "PYEntitySql.h"
#import "pyutilea.h"
#import <objc/runtime.h>


const  NSString * _Nonnull  SqlMangerCreateSql = @"CREATE TABLE IF NOT EXISTS \n%@\n(\n\t%@ INTEGER PRIMARY KEY AUTOINCREMENT,\n%@\n)";
const  NSString * _Nonnull  SqlMangerAddColumsSql = @"ALTER TABLE %@ ADD COLUMN %@";
const  NSString * _Nonnull  SqlMangerInsertSql = @"INSERT INTO %@ (\n%@\n) VALUES (%@)";
const  NSString * _Nonnull  SqlMangerUpdateSql = @"UPDATE %@ SET \n%@\n WHERE %@ = ?";
const  NSString * _Nonnull  SqlMangerFindSql = @"SELECT * FROM %@ WHERE %@ = ?";
const  NSString * _Nonnull  SqlMangerDeleteSql = @"DELETE FROM %@ WHERE %@ = ?";
const  NSString * _Nonnull  SqlMangerTableStrutSql = @"pragma table_info ('%@')";
const  NSString * _Nonnull  SqlMangerAlterSql = @"ALTER TABLE %@ ADD COLUMN %@";


static NSString * keyId = @"keyId";

@implementation PYEntitySql
+(nonnull NSString*) getCreateSql:(nonnull Class<PYEntity>) clazz{
    NSMutableString *sqlColum = [NSMutableString new];
    NSArray *caches = [PYEntityAsist getEntityReflectCache:clazz];
    for (NSDictionary *cache in caches) {
        NSString *name = cache[SqlMangerTypeName];
        if ([name isEqual:keyId]) {continue;}
        [sqlColum appendFormat:@"\t%@ %@,\n",name, cache[SqlMangerTypeColum]];
    }
    NSString * sql = [NSString stringWithFormat:(NSString*)SqlMangerCreateSql,NSStringFromClass(clazz),keyId,[sqlColum substringToIndex:sqlColum.length - 2]];
    return sql;
}
+(nonnull NSString*) getFindSql:(nonnull Class<PYEntity>) clazz{
    NSString * sql = [NSString stringWithFormat:(NSString*)SqlMangerFindSql,NSStringFromClass(clazz),keyId];
    return sql;
}
+(nonnull NSString*) getDeleteSql:(nonnull Class<PYEntity>) clazz{
    NSString * sql = [NSString stringWithFormat:(NSString*)SqlMangerDeleteSql,NSStringFromClass(clazz),keyId];
    return sql;
}
+(nonnull NSString*) getMergeSql:(nonnull Class<PYEntity>) clazz columns:(nullable NSArray<NSString*>*) columns{
    NSMutableString *sqlColum = [NSMutableString new];
    NSArray *caches = [PYEntityAsist getEntityReflectCache:clazz];
    if (columns && [columns count] < [caches count] - 1) {
        NSInteger count = 0;
        for (NSDictionary *cache in caches) {
            if (count >= [columns count]) {
                break;
            }
            NSString *name = cache[SqlMangerTypeName];
            NSString *colum = nil;
            for (NSString *_colum in columns) {
                if ([_colum isEqual:name]) {
                    colum = _colum;
                    break;
                }
            }
            if (colum) {
                [sqlColum appendFormat:@"\t%@ = ?,\n",name];
                count ++;
            }
        }
    }else{
        for (NSDictionary *cache in caches) {
            NSString *name = cache[SqlMangerTypeName];
            if ([keyId isEqual:name]) {continue;}
            [sqlColum appendFormat:@"\t%@ = ?,\n",name];
        }
    }
    
    NSString * sql = [NSString stringWithFormat:(NSString*)SqlMangerUpdateSql, NSStringFromClass(clazz),[sqlColum substringToIndex:sqlColum.length - 2],keyId];
    return sql;
}
+(nonnull NSString*) getPersistSql:(nonnull Class<PYEntity>) clazz  columns:(nullable NSArray<NSString*>*) columns{
    NSMutableString *sqlColum = [NSMutableString new];
    NSArray *caches = [PYEntityAsist getEntityReflectCache:clazz];
    NSMutableString *sqlValue = [NSMutableString new];
    if (columns && [columns count] < [caches count] - 1) {
        NSMutableArray<NSString*>* _colums_ = [NSMutableArray arrayWithArray:columns];
        for (NSDictionary *cache in caches) {
            if (![_colums_ count]) {
                break;
            }
            NSString *name = cache[SqlMangerTypeName];
            NSString *colum = nil;
            for (NSString *_colum in _colums_) {
                if ([_colum isEqual:name]) {
                    colum = _colum;
                    break;
                }
            }
            if (colum) {
                [sqlColum appendFormat:@"\t%@,\n",name];
                [sqlValue appendString:@"?,"];
            }
            [_colums_ removeObject:colum];
        }
    }else{
        for (NSDictionary *cache in caches) {
            NSString *name = cache[SqlMangerTypeName];
            if ([keyId isEqual:name]) {continue;}
            [sqlColum appendFormat:@"\t%@,\n",name];
            [sqlValue appendString:@"?,"];
        }
    }
    NSString *sql = [NSString stringWithFormat:(NSString*)SqlMangerInsertSql, NSStringFromClass(clazz),[sqlColum substringToIndex:sqlColum.length - 2],[sqlValue substringToIndex:sqlValue.length - 1]];
    return sql;
}

+(nonnull NSString*) getTableStrutSql:(nonnull Class<PYEntity>) clazz{
    return [NSString stringWithFormat:(NSString*)SqlMangerTableStrutSql,NSStringFromClass(clazz)];
}
+(nonnull NSString*) getTableAlertSql:(nonnull Class<PYEntity>) clazz colums:(nonnull NSArray<NSDictionary*>*) colums{
    NSMutableString *sql = [NSMutableString new];
    for (NSDictionary *colum in colums) {
        NSString *name = colum[SqlMangerTypeName];
        NSString *type = colum[SqlMangerTypeColum];
        [sql appendFormat:@"%@ %@,",name,type];
    }
    return [NSString stringWithFormat:(NSString*)SqlMangerAlterSql,NSStringFromClass(clazz),[sql substringToIndex:sql.length - 1]];
}
@end
