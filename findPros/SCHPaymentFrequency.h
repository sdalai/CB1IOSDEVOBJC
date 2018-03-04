//
//  SCHPaymentFrequency.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 10/15/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"

@interface SCHPaymentFrequency : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property (nonatomic, strong) NSString *paymentFrequency;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, assign) float amount;



@end
