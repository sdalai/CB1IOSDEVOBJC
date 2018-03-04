//
//  SCHUser.m
//  CounterBean
//
//  Created by Sujit Dalai on 5/12/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHUser.h"

@implementation SCHUser

@dynamic firstName;
@dynamic lastName;
@dynamic preferredName;
@dynamic profilePicture;
@dynamic email;
@dynamic phoneNumber;
@dynamic facebookId;
@dynamic termsOfUseAgreed;
@dynamic termsOfUse;
@dynamic privacyPolicyAgreed;
@dynamic privacyPolicy;
@dynamic dataSyncRequired;
@dynamic subscriptionType;
@dynamic premiunTrialUsed;
@dynamic paymentFrequency;
@dynamic premiumExpirationDate;
@dynamic premiumStartDate;
@dynamic premiumRenewalDate;
@dynamic freeTrialExpirationDate;
@dynamic suspended;
@dynamic phoneNumberVerified;
@dynamic OTP;
@dynamic verificationSMSCount;
@dynamic suspensionExpirationTime;






+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHUserClass;
}

@end
