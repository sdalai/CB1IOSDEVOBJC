//
//  SCHAppointmentSeries.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 6/24/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"
#import "SCHService.h"
#import "SCHLookup.h"
#import "SCHServiceOffering.h"
#import "SCHNonUserClient.h"

@interface SCHAppointmentSeries : PFObject <PFSubclassing>

+ (NSString *)parseClassName;


@property (strong, nonatomic) SCHUser *serviceProvider;
@property (strong, nonatomic) SCHUser *client;
@property (nonatomic, strong) SCHNonUserClient *nonUserClient;
@property (nonatomic, strong) NSString *clientName;
@property (nonatomic, assign) BOOL isClientUser;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) NSString *note;
@property (strong, nonatomic) NSDate *proposedStartTime;
@property (strong, nonatomic) NSDate *proposedEndTime;
@property (strong, nonatomic) NSString *proposedLocation;
@property (strong, nonatomic) SCHService *service;
@property (strong, nonatomic) SCHServiceOffering *serviceOffering;
@property (strong, nonatomic) SCHLookup *status;
@property (strong, nonatomic) NSString *repeatOption;
@property (strong, nonatomic) NSArray *repeatDays;
@property (strong, nonatomic) NSDate *endDate;
@property (nonatomic, assign) BOOL expired;






@end
