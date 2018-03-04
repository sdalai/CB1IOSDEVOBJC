//
//  SCHEditAppointmentViewController.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/28/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "XLFormViewController.h"
#import "SCHAppointment.h"
#import "SCHAvailabilityForAppointment.h"
@interface SCHEditAppointmentViewController : XLFormViewController<XLFormViewControllerDelegate>
@property(nonatomic, strong) SCHAppointment *appointment;
@property(nonatomic, strong) SCHAvailabilityForAppointment *selectedAvailabilityForAppointment;
-(void)changeScheduleTimeToAvaliableSchedule:(NSDate *)from_time;
-(void)resetWhenNewAvailabilityIsSelected;


@end
