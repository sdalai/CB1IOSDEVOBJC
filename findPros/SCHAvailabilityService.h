//
//  SCHAvailabilityService.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 4/26/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCHService.h"


@interface SCHAvailabilityService : NSObject

@property (nonatomic, strong) SCHService *service;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;


@end
