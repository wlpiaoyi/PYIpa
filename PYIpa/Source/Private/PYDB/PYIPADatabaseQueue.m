//
//  PYIPADatabaseQueue.m
//  PYIPADB
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

#import "PYIPADatabaseQueue.h"
#import "PYIPADatabase.h"

/*
 
 Note: we call [self retain]; before using dispatch_sync, just incase 
 PYIPADatabaseQueue is released on another thread and we're in the middle of doing
 something in dispatch_sync
 
 */

/**
 * A key used to associate the PYIPADatabaseQueue object with the dispatch_queue_t it uses.
 * This in turn is used for deadlock detection by seeing if inDatabase: is called on
 * the queue's dispatch queue, which should not happen and causes a deadlock.
 */
static const void * const kDispatchQueueSpecificKey = &kDispatchQueueSpecificKey;
 
@implementation PYIPADatabaseQueue

@synthesize path = _path;
@synthesize openFlags = _openFlags;

+ (instancetype)databaseQueueWithPath:(NSString*)aPath {
    
    PYIPADatabaseQueue *q = [[self alloc] initWithPath:aPath];
    
    PYIPADBAutorelease(q);
    
    return q;
}

+ (instancetype)databaseQueueWithPath:(NSString*)aPath flags:(int)openFlags {
    
    PYIPADatabaseQueue *q = [[self alloc] initWithPath:aPath flags:openFlags];
    
    PYIPADBAutorelease(q);
    
    return q;
}

+ (Class)databaseClass {
    return [PYIPADatabase class];
}

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags {
    
    self = [super init];
    
    if (self != nil) {
        
        _db = [[[self class] databaseClass] databaseWithPath:aPath];
        PYIPADBRetain(_db);
        
#if SQLITE_VERSION_NUMBER >= 3005000
        BOOL success = [_db openWithFlags:openFlags];
#else
        BOOL success = [_db open];
#endif
        if (!success) {
            NSLog(@"Could not create database queue for path %@", aPath);
            PYIPADBRelease(self);
            return 0x00;
        }
        
        _path = PYIPADBReturnRetained(aPath);
        
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"PYIPADB.%@", self] UTF8String], NULL);
        dispatch_queue_set_specific(_queue, kDispatchQueueSpecificKey, (__bridge void *)self, NULL);
        _openFlags = openFlags;
    }
    
    return self;
}

- (instancetype)initWithPath:(NSString*)aPath {
    
    // default flags for sqlite3_open
    return [self initWithPath:aPath flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE];
}

- (instancetype)init {
    return [self initWithPath:nil];
}

    
- (void)dealloc {
    
    PYIPADBRelease(_db);
    PYIPADBRelease(_path);
    
    if (_queue) {
        PYIPADBDispatchQueueRelease(_queue);
        _queue = 0x00;
    }
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)close {
    PYIPADBRetain(self);
    dispatch_sync(_queue, ^() { 
        [_db close];
        PYIPADBRelease(_db);
        _db = 0x00;
    });
    PYIPADBRelease(self);
}

- (PYIPADatabase*)database {
    if (!_db) {
        _db = PYIPADBReturnRetained([PYIPADatabase databaseWithPath:_path]);
        
#if SQLITE_VERSION_NUMBER >= 3005000
        BOOL success = [_db openWithFlags:_openFlags];
#else
        BOOL success = [db open];
#endif
        if (!success) {
            NSLog(@"PYIPADatabaseQueue could not reopen database for path %@", _path);
            PYIPADBRelease(_db);
            _db  = 0x00;
            return 0x00;
        }
    }
    
    return _db;
}

- (void)inDatabase:(void (^)(PYIPADatabase *db))block {
    /* Get the currently executing queue (which should probably be nil, but in theory could be another DB queue
     * and then check it against self to make sure we're not about to deadlock. */
    PYIPADatabaseQueue *currentSyncQueue = (__bridge id)dispatch_get_specific(kDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    
    PYIPADBRetain(self);
    
    dispatch_sync(_queue, ^() {
        
        PYIPADatabase *db = [self database];
        block(db);
        
        if ([db hasOpenResultSets]) {
            NSLog(@"Warning: there is at least one open result set around after performing [PYIPADatabaseQueue inDatabase:]");
            
#ifdef DEBUG
            NSSet *openSetCopy = PYIPADBReturnAutoreleased([[db valueForKey:@"_openResultSets"] copy]);
            for (NSValue *rsInWrappedInATastyValueMeal in openSetCopy) {
                PYIPAResultSet *rs = (PYIPAResultSet *)[rsInWrappedInATastyValueMeal pointerValue];
                NSLog(@"query: '%@'", [rs query]);
            }
#endif
        }
    });
    
    PYIPADBRelease(self);
}


- (void)beginTransaction:(BOOL)useDeferred withBlock:(void (^)(PYIPADatabase *db, BOOL *rollback))block {
    PYIPADBRetain(self);
    dispatch_sync(_queue, ^() { 
        
        BOOL shouldRollback = NO;
        
        if (useDeferred) {
            [[self database] beginDeferredTransaction];
        }
        else {
            [[self database] beginTransaction];
        }
        
        block([self database], &shouldRollback);
        
        if (shouldRollback) {
            [[self database] rollback];
        }
        else {
            [[self database] commit];
        }
    });
    
    PYIPADBRelease(self);
}

- (void)inDeferredTransaction:(void (^)(PYIPADatabase *db, BOOL *rollback))block {
    [self beginTransaction:YES withBlock:block];
}

- (void)inTransaction:(void (^)(PYIPADatabase *db, BOOL *rollback))block {
    [self beginTransaction:NO withBlock:block];
}

#if SQLITE_VERSION_NUMBER >= 3007000
- (NSError*)inSavePoint:(void (^)(PYIPADatabase *db, BOOL *rollback))block {
    
    static unsigned long savePointIdx = 0;
    __block NSError *err = 0x00;
    PYIPADBRetain(self);
    dispatch_sync(_queue, ^() { 
        
        NSString *name = [NSString stringWithFormat:@"savePoint%ld", savePointIdx++];
        
        BOOL shouldRollback = NO;
        
        if ([[self database] startSavePointWithName:name error:&err]) {
            
            block([self database], &shouldRollback);
            
            if (shouldRollback) {
                // We need to rollback and release this savepoint to remove it
                [[self database] rollbackToSavePointWithName:name error:&err];
            }
            [[self database] releaseSavePointWithName:name error:&err];
            
        }
    });
    PYIPADBRelease(self);
    return err;
}
#endif

@end
