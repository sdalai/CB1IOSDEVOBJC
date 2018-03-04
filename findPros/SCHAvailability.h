//
//  SCHAvailability.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 4/21/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//


#import <parse/Parse.h>
#import "SCHConstants.h"
#import "SCHUser.h"
@interface SCHAvailability : PFObject <PFSubclassing>

+ (NSString *)parseClassName;


@property (strong, nonatomic) SCHUser *user;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSDate *endTime;
@property (strong, nonatomic) NSArray *services;
@property (strong, nonatomic) NSString *location;



@end
