//
//  SCHAppointmentActivity.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 4/2/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAppointmentActivity.h"

@implementation SCHAppointmentActivity

@dynamic appointment;
@dynamic appointmentSeries;
@dynamic action;
@dynamic actionInitiator;
@dynamic actionAssignedTo;
@dynamic status;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHAppointmentActivityClass;
}


@end
