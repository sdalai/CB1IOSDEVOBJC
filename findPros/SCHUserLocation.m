//
//  SCHUserLocation.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 9/22/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHUserLocation.h"

@implementation SCHUserLocation

@dynamic user;
@dynamic location;
@dynamic locationPoint;


+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHUserLocationClass;
}


@end
