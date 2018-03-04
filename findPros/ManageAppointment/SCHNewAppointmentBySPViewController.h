//
//  SCHNewAppointmentBySPViewController.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 4/4/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//


#import "XLFormViewController.h"
#import "SCHScheduledEventManager.h"
#import <AddressBookUI/AddressBookUI.h>
#import "SCHAvailabilityForAppointment.h"
#import "SCHServiceProviderClientList.h"

@interface SCHNewAppointmentBySPViewController : XLFormViewController<ABPeoplePickerNavigationControllerDelegate>


@property(nonatomic, strong) XLFormRowDescriptor *clientRow;
@property(nonatomic, strong) XLFormRowDescriptor * StartTimeRow;
@property (nonatomic, strong)XLFormRowDescriptor *endTimeRow;
@property (nonatomic, strong) XLFormRowDescriptor *serviceRow;
@property (nonatomic, strong )XLFormRowDescriptor *serviceOfferingRow;
@property (nonatomic, strong)XLFormRowDescriptor *locationRow;
@property (nonatomic, strong)XLFormRowDescriptor *repeatRow;
@property (nonatomic, strong)XLFormRowDescriptor *repeatDaysRow;
@property (nonatomic, strong)XLFormRowDescriptor *endDateRow;
@property (nonatomic, strong) SCHAvailabilityForAppointment *selectedAvailability;



@property(nonatomic, strong) NSDictionary *client_info_Dict;
@property(nonatomic, strong) NSDate *startTime;
@property(nonatomic, strong) NSString *availabilityLocation;
@property(nonatomic, strong) NSArray *availabilityServices;
@property(nonatomic, strong) SCHServiceProviderClientList *client;
-(void)changeScheduleTimeToAvaliableSchedule:(NSDate *)from_time location:(NSString *) location;


@end

