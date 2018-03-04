//
//  SCHScheduleScreenFilter.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 10/25/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHScheduleScreenFilter.h"

@implementation SCHScheduleScreenFilter

@dynamic user;
@dynamic confirmedAppointmentsForMyServices;
@dynamic confirmedAppointmentsIHaveBooked;
@dynamic pendingAppointmentsForMyServicesAwaitingMyResponse;
@dynamic pendingAppointmentsForMyServicesNotAwaitingMyResponse;
@dynamic pendingAppointmentsIHaveBookedAwaitingMyResponse;
@dynamic pendingAppointmentsIHaveBookedNotAwaitingMyResponse;
@dynamic cancelledAppointments;
@dynamic expiredAppointments;
@dynamic availabilities;


+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHScheduleScreenFilterClass;
}


@end
