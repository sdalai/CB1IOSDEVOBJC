//
//  SCHServiceOffering.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/23/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHService.h"
#import "SCHConstants.h"

@interface SCHServiceOffering : PFObject <PFSubclassing>
+ (NSString *)parseClassName;

@property (nonatomic, strong) SCHService *service;
@property(nonatomic, assign) BOOL active;
@property (nonatomic, strong) NSString *serviceOfferingName;
@property (nonatomic, strong) NSString *detailDescription;
@property (nonatomic, assign) int defaultDurationInMin;
@property (nonatomic, assign) BOOL fixedDuration;

@end
