//
//  SCHManageAvailabilityViewController.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/29/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "XLFormViewController.h"
#import "SCHService.h"
#import "SCHAvailability.h"

@interface SCHManageAvailabilityViewController : XLFormViewController

@property(nonatomic, strong) SCHService *serviceForAvailability;
@property(nonatomic, strong) SCHAvailability *selectedAvailabiity;
@property(nonatomic, strong) NSString *presetAvailabilityAction;

@end
