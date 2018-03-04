//
//  SCHAppointmentActivity.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 4/2/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHAppointment.h"
#import "SCHLookup.h"
#import "SCHConstants.h"
#import "SCHAppointmentSeries.h"


@interface SCHAppointmentActivity : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property (nonatomic, strong) SCHAppointment *appointment;
@property (nonatomic, strong) SCHAppointmentSeries *appointmentSeries;
@property (nonatomic, strong) SCHLookup *action;
@property (nonatomic, strong) SCHUser *actionInitiator;
@property (nonatomic, strong) SCHUser *actionAssignedTo;
@property (nonatomic, strong) SCHLookup *status;

@end
