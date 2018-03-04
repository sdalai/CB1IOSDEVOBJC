//
//  SCHAppointment.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 4/2/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHLookup.h"
#import "SCHService.h"
#import "SCHServiceOffering.h"
#import "SCHConstants.h"
#import "SCHAppointmentSeries.h"
#import "SCHNonUserClient.h"
#import "SCHUser.h"


@interface SCHAppointment : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property(nonatomic, strong) SCHLookup *status;
@property (nonatomic, assign) BOOL expired;
@property (nonatomic, strong) SCHUser *serviceProvider;
@property (nonatomic, strong) SCHService *service;
@property (nonatomic, strong) SCHServiceOffering *serviceOffering;
@property (nonatomic, assign) BOOL isClientUser;
@property (nonatomic, strong) SCHUser *client;
@property (nonatomic, strong) SCHNonUserClient *nonUserClient;
@property (nonatomic, strong) NSString *clientName;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, strong) NSString *note;
@property (nonatomic, strong) NSString *proposedLocation;
@property (nonatomic, strong) NSDate *proposedStartTime;
@property (nonatomic, strong) NSDate *proposedEndTime;
@property (nonatomic, strong) SCHAppointmentSeries *appointmentSeries;




@end
