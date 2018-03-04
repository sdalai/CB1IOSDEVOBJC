//
//  SCHEvent.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 4/25/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCHLookup.h"
#import "SCHAvailability.h"
#import "SCHAppointment.h"
#import "SCHAppointmentActivity.h"

@interface SCHEvent : NSObject


@property (nonatomic, strong) NSDate *eventDay;
@property (nonatomic, strong) NSString *eventType;
@property (nonatomic, strong) id eventObject;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) SCHAppointmentActivity *openActivity;


@end
