//
//  SCHNewAppointmentByClientViewController.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/9/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "XLFormViewController.h"
#import "SCHService.H"
#import "SCHAvailabilityForAppointment.h"

@interface SCHNewAppointmentByClientViewController : XLFormViewController
@property (strong,nonatomic) SCHService* selectedServiceProvider;
@property (strong,nonatomic) SCHAvailabilityForAppointment* selectedAvailability;

@end
