//
//  PYEventManager.m
//  PYIpa
//
//  Created by wlpiaoyi on 2018/9/25.
//  Copyright © 2018年 wlpiaoyi. All rights reserved.
//

#import "PYEventManager.h"
#import "PYUtile.h"

static PYEventManager * xPYEventManager;

@implementation PYEventManager{
@private EKEventStore *_eventDB;
    dispatch_semaphore_t semaphore;
}
+(instancetype) singleInstance{
    if(xPYEventManager == nil){
        @synchronized([PYEventManager class]){
            if(xPYEventManager == nil){
                xPYEventManager = [PYEventManager new];
            }
        }
    }
    return xPYEventManager;
}

-(instancetype) init{
    
    kDISPATCH_ONCE_BLOCK(^{semaphore = dispatch_semaphore_create(1);});
    if(self = [super init]){
        _eventDB = [[EKEventStore alloc] init];
    }
    return self;
}

-(void) presisitEvent:(nonnull NSString *) title
                startDate:(nonnull NSDate *) startDate
                endDate:(nonnull NSDate *) endDate
                alarmDate:(nonnull NSDate *) alarmDate
                completion:(PYEventStoreRequestAccessCompletionHandler)completion{
    kAssign(self);
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [_eventDB requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
        kStrong(self);
        if(granted){
            NSError *error;
            EKEvent * event  = [EKEvent eventWithEventStore:self->_eventDB]; //创建一个日历事件
            event.title = title;  //标题
            event.startDate = startDate; //开始date   required
            event.endDate = endDate;  //结束date    required
            [event addAlarm:[EKAlarm alarmWithAbsoluteDate:alarmDate]]; //添加一个闹钟  optional
            [event setCalendar:[self->_eventDB defaultCalendarForNewEvents]]; //添加calendar  required
            [self->_eventDB saveEvent:event span:EKSpanThisEvent error:&error];
            if(completion) completion(error ? : event);
        }else if(completion) completion(error);
        dispatch_semaphore_signal(semaphore);
    }];
}
-(nullable NSError *) removeEvent:(nonnull NSString *) identify{
    
    EKEvent * event = [self findEvent:identify];
    if(event == nil) return nil;
    NSError * error;
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [_eventDB removeEvent:event span:EKSpanThisEvent error:&error];
    dispatch_semaphore_signal(semaphore);
    return error;
    
}
-(nullable EKEvent *) findEvent:(nonnull NSString *) identify{
    return [_eventDB eventWithIdentifier:identify];
}

-(void) presisitReminder:(nonnull NSString *) title
                    startDate:(nonnull NSDate *) startDate
                    endDate:(nonnull NSDate *) endDate
                    alarmDate:(nonnull NSDate *) alarmDate
                    priority:(NSUInteger) priority
                    completion:(PYEventStoreRequestAccessCompletionHandler)completion{
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    kAssign(self);
    [_eventDB requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError * _Nullable error) {
        kStrong(self);
        if (granted) {
            EKReminder *reminder = [EKReminder reminderWithEventStore:self->_eventDB];
            reminder.title = title;
            [reminder setCalendar:[self->_eventDB defaultCalendarForNewReminders]];
            
            NSCalendar *cal = [NSCalendar currentCalendar];
            [cal setTimeZone:[NSTimeZone systemTimeZone]];
            NSInteger flags = NSCalendarUnitYear | NSCalendarUnitMonth |
            NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
            
            NSDateComponents* dateComp = [cal components:flags fromDate:startDate];
            dateComp.timeZone = [NSTimeZone systemTimeZone];
            reminder.startDateComponents = dateComp; //开始时间
            
            dateComp = [cal components:flags fromDate:endDate];
            dateComp.timeZone = [NSTimeZone systemTimeZone];
            reminder.dueDateComponents = dateComp; //到期时间
            
            reminder.priority = priority; //优先级
            
            EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:alarmDate]; //添加一个车闹钟
            
            [reminder addAlarm:alarm];
            
            NSError *error;
            [self->_eventDB saveReminder:reminder commit:YES error:&error];
            if(completion) completion(error ? : reminder);
            
        }else  if(completion) completion(error);
        
        dispatch_semaphore_signal(semaphore);
    }];
}

-(nullable NSError *) removeReminder:(nonnull EKReminder *) reminder{
    NSError * error;
    [_eventDB removeReminder:reminder commit:YES error:&error];
    return error;
}

@end
