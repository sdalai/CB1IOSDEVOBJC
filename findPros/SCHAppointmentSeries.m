//
//  SCHAppointmentSeries.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 6/24/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAppointmentSeries.h"

@implementation SCHAppointmentSeries

@dynamic serviceProvider;
@dynamic client;
@dynamic nonUserClient;
@dynamic clientName;
@dynamic isClientUser;
@dynamic startTime;
@dynamic endTime;
@dynamic location;
@dynamic note;
@dynamic proposedStartTime;
@dynamic proposedEndTime;
@dynamic proposedLocation;
@dynamic service;
@dynamic serviceOffering;
@dynamic status;
@dynamic repeatOption;
@dynamic repeatDays;
@dynamic endDate;
@dynamic expired;




+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHAppointmentSeriesClass;
}


@end
