//
//  SCHNonUserClient.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 10/2/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHNonUserClient.h"

@implementation SCHNonUserClient

@dynamic email;
@dynamic phoneNumber;


+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHNonUserClientClass;
}


@end
