//
//  SCHUser.h
//  CounterBean
//
//  Created by Sujit Dalai on 5/12/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"
#import "SCHLegalDocument.h"
#include "SCHPaymentFrequency.h"
#include "SCHLookup.h"


@interface SCHUser : PFObject<PFSubclassing>
+ (NSString *)parseClassName;


@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *preferredName;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) PFFile *profilePicture;
@property (nonatomic, strong) NSString *facebookId;
@property (nonatomic, assign) BOOL termsOfUseAgreed;
@property (nonatomic, strong) SCHLegalDocument *termsOfUse;
@property (nonatomic, assign) BOOL privacyPolicyAgreed;
@property (nonatomic, strong) SCHLegalDocument *privacyPolicy;
@property (nonatomic, assign) BOOL dataSyncRequired;
@property (nonatomic, strong) SCHLookup *subscriptionType;
@property (nonatomic, assign) BOOL premiunTrialUsed;
@property (nonatomic, strong) SCHPaymentFrequency *paymentFrequency;
@property (nonatomic, strong) NSDate *premiumStartDate;
@property (nonatomic, strong) NSDate *premiumExpirationDate;
@property (nonatomic, strong) NSDate *premiumRenewalDate;
@property (nonatomic, strong) NSDate *freeTrialExpirationDate;
@property (nonatomic, assign) BOOL suspended;
@property (nonatomic, assign) BOOL phoneNumberVerified;
@property (nonatomic, strong) NSString *OTP;
@property (nonatomic, assign) int verificationSMSCount;
@property (nonatomic, strong) NSDate *suspensionExpirationTime;




@end
