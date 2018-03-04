//
//  SCHControl.h
//  CounterBean
//
//  Created by Sujit Dalai on 1/11/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"

@interface SCHControl : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property(strong, nonatomic) NSString *appName;
@property(strong, nonatomic) NSDate *trialPeriodExpirationDate;
@property (nonatomic, assign) BOOL enablePaymentOption;
@property(nonatomic, assign) int freeTrialDays;

@end
