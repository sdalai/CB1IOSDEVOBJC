//
//  SCHAvailabilityForAppointment.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 6/18/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHService.h"
#import "SCHConstants.h"
#import "SCHUser.h"

@interface SCHAvailabilityForAppointment : PFObject <PFSubclassing>
+ (NSString *)parseClassName;

@property (nonatomic, strong) SCHUser *user;
@property (nonatomic, strong) SCHService *service;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) PFGeoPoint *locationPoint;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;

@end
