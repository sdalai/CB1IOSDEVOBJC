//
//  SCHServiceClassification.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/20/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHServiceClassification.h"

@implementation SCHServiceClassification
@dynamic majorClassification;
@dynamic backgroundPicture;
@dynamic visible;
@dynamic serviceTypeName;
+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHServiceClassificationClass;
}

@end
