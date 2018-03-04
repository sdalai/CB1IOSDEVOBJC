//
//  SCHUserLocation.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 9/22/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "PFObject.h"
#import "SCHConstants.h"
#import <Parse/Parse.h>
#import "SCHUser.h"

@interface SCHUserLocation : PFObject <PFSubclassing>
+ (NSString *)parseClassName;

@property (nonatomic, strong) SCHUser *user;
@property(nonatomic, strong) NSString *location;
@property(nonatomic, strong) PFGeoPoint *locationPoint;


@end
