//
//  SCHServiceOffering.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/23/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHServiceOffering.h"

@implementation SCHServiceOffering

@dynamic service;
@dynamic active;
@dynamic serviceOfferingName;
@dynamic detailDescription;
@dynamic defaultDurationInMin;
@dynamic fixedDuration;


+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHServiceOfferingClass;
}


@end
