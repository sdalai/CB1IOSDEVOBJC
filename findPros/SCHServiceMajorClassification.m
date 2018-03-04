//
//  SCHServiceMajorClassification.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 11/26/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHServiceMajorClassification.h"

@implementation SCHServiceMajorClassification
@dynamic majorClassification;
@dynamic visible;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHServiceMajorClassificationClass;
}



@end
