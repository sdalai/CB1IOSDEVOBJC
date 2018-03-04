//
//  SCHPaymentFrequency.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 10/15/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHPaymentFrequency.h"

@implementation SCHPaymentFrequency

@dynamic paymentFrequency;
@dynamic currency;
@dynamic amount;


+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHPaymentFrequencyClass;
}


@end
