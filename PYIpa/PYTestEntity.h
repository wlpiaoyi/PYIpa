//
//  PYTestEntity.h
//  PYIpa
//
//  Created by wlpiaoyi on 2017/5/10.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PYEntityAsist.h"

@interface PYTestEntity : NSObject<PYEntity>
@property (nonatomic) NSUInteger keyId;
@property (nonatomic) NSString * name;
@property (nonatomic) NSString * nouse;
@end
