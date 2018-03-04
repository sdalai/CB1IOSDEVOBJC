//
//  SCHService.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/20/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHService.h"

@implementation SCHService

@dynamic user;
@dynamic active;
@dynamic serviceTitle;
@dynamic profilePicture;
@dynamic standardCharge;
@dynamic serviceDescription;
@dynamic serviceClassification;
@dynamic website;
@dynamic profileVisibilityControl;
@dynamic availabilityVisibilityControl;
@dynamic autoConfirmAppointment;
@dynamic businessEmail;
@dynamic businessPhone;
@dynamic suspended;
@dynamic restrictPublicVisibility;
@dynamic publicVisibilityRequested;


+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHServiceClass;
}

@end
