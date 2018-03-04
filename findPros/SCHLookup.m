//
//  SCHLookup.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 4/2/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHLookup.h"
#import "SCHConstants.h"

@implementation SCHLookup

@dynamic lookupType;
@dynamic lookupCode;
@dynamic lookupText;



+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"SCHLookup";
}


@end
