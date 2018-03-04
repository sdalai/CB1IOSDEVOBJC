//
//  SCHService.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/20/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHServiceClassification.h"
#import "SCHConstants.h"
#import "SCHUser.h"


@interface SCHService : PFObject <PFSubclassing>

+ (NSString *)parseClassName;
@property (nonatomic, strong) SCHUser *user;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, strong) SCHServiceClassification *serviceClassification;
@property (nonatomic, strong) NSString *serviceTitle;
@property (nonatomic, strong) NSString *businessEmail;
@property (nonatomic, strong) NSString *businessPhone;
@property (nonatomic, assign) int standardCharge;
@property (nonatomic, strong) PFFile *profilePicture;
@property (nonatomic, strong) NSString *serviceDescription;
@property (nonatomic, strong) NSString *website;
@property (nonatomic, strong) SCHLookup *profileVisibilityControl;
@property (nonatomic, strong) SCHLookup *availabilityVisibilityControl;
@property (nonatomic, strong) SCHLookup *autoConfirmAppointment;
@property (nonatomic, assign) BOOL suspended;
@property (nonatomic, assign) BOOL restrictPublicVisibility;
@property (nonatomic, assign) BOOL publicVisibilityRequested;



@end
