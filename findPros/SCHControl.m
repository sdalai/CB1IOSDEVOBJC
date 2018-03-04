//
//  SCHControl.m
//  CounterBean
//
//  Created by Sujit Dalai on 1/11/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHControl.h"

@implementation SCHControl

@dynamic appName;
@dynamic trialPeriodExpirationDate;
@dynamic enablePaymentOption;
@dynamic freeTrialDays;


+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHControlClass;
}

@end
