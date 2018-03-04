//
//  SCHAvailabilityForAppointment.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 6/18/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAvailabilityForAppointment.h"

@implementation SCHAvailabilityForAppointment
@dynamic user;
@dynamic service;
@dynamic location;
@dynamic locationPoint;
@dynamic startTime;
@dynamic endTime;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHAvailabilityForAppointmentClass;
}


@end
