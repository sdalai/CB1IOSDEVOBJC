//
//  SCHAvailableTimeBlock.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/31/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"
#import "SCHAppointment.h"
#import "SCHUser.h"

@interface SCHAvailableTimeBlock : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property(nonatomic, strong) SCHUser *user;
@property(nonatomic, strong) NSDate *startTime;
@property(nonatomic, strong) NSDate *endTime;
@property(nonatomic, strong) NSString *location;
@property(nonatomic, assign) SCHAppointment *appointment;
@property(nonatomic, strong) NSArray *requestedAppointments;
@property(nonatomic, assign) BOOL allocationRequested;
@property(nonatomic, assign) NSArray *services;
@property (nonatomic, strong) PFGeoPoint *locationPoint;
@property (nonatomic, assign) BOOL availableForNewRequest;

@end
