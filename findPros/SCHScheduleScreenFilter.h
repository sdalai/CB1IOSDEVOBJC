//
//  SCHScheduleScreenFilter.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 10/25/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"
#import "SCHUser.h"

@interface SCHScheduleScreenFilter : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property (nonatomic, strong) SCHUser *user;
@property (nonatomic, assign) BOOL confirmedAppointmentsForMyServices;
@property (nonatomic, assign) BOOL  pendingAppointmentsForMyServicesAwaitingMyResponse;
@property (nonatomic, assign) BOOL pendingAppointmentsForMyServicesNotAwaitingMyResponse;
@property (nonatomic, assign) BOOL confirmedAppointmentsIHaveBooked;
@property (nonatomic, assign) BOOL pendingAppointmentsIHaveBookedAwaitingMyResponse;
@property (nonatomic, assign) BOOL pendingAppointmentsIHaveBookedNotAwaitingMyResponse;
@property (nonatomic, assign) BOOL expiredAppointments;
@property (nonatomic, assign) BOOL cancelledAppointments;
@property (nonatomic, assign) BOOL availabilities;


@end
