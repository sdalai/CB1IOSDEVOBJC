//
//  SCHAppointment.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 4/2/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAppointment.h"

@implementation SCHAppointment

@dynamic status;
@dynamic expired;
@dynamic serviceProvider;
@dynamic service;
@dynamic serviceOffering;
@dynamic isClientUser;
@dynamic nonUserClient;
@dynamic clientName;
@dynamic client;
@dynamic location;
@dynamic startTime;
@dynamic endTime;
@dynamic note;
@dynamic proposedLocation;
@dynamic proposedStartTime;
@dynamic proposedEndTime;
@dynamic appointmentSeries;



+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHAppointmentClass;
}


@end
