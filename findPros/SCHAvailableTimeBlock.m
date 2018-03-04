//
//  SCHAvailableTimeBlock.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/31/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAvailableTimeBlock.h"

@implementation SCHAvailableTimeBlock

@dynamic user;
@dynamic startTime;
@dynamic endTime;
@dynamic location;
@dynamic allocationRequested;
@dynamic appointment;
@dynamic requestedAppointments;
@dynamic services;
@dynamic locationPoint;
@dynamic availableForNewRequest;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHAvailableTimeBlockClass;
}

@end
