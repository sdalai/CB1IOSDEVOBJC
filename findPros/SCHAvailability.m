//
//  SCHAvailability.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 4/21/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAvailability.h"

@implementation SCHAvailability
@dynamic user;
@dynamic startTime;
@dynamic endTime;
@dynamic location;
@dynamic services;



+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHAvailabilityClass;
}

@end
