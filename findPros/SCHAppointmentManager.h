//
//  SCHAppointmentManager.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/4/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "SCHService.h"
#import "SCHServiceOffering.h"
#import "SCHAppointment.h"
#import "SCHNotification.h"
#import <AddressBook/AddressBook.h>
#import "SCHAppointmentSeries.h"
#import <KVNProgress/KVNProgress.h>
#import "SCHUser.h"

@interface SCHAppointmentManager : NSObject
+(id)createAppointmentServiceProvider: (SCHUser *) serviceProvider service:(SCHService *) service serviceOffering: (SCHServiceOffering *) serviceOffering location: (NSString *) location locationPoint:(PFGeoPoint *)locationPoint client: (id) clientObject clientName:(NSString *) name timeFrom: (NSDate *) timeFrom timeTo: (NSDate *) timeTo repeatOption:(NSString *) repeatOption repeatDays:(NSArray *) repeatDays endDate:(NSDate *) endDate notes:(NSString *)  notes;

+(BOOL)confirmAppointmentSeries:(SCHAppointmentSeries *) series;

+(BOOL)confirmAppointmentRequest:(SCHAppointment *) appointment series:(BOOL) isSeries refreshAvailability:(BOOL) refresh save:(BOOL) save;

+(BOOL) declineAppointmentSeriesRequest:(SCHAppointmentSeries *)series;


+(BOOL)declineAppointmentRequest:(SCHAppointment *) appointment isseries:(BOOL) isSeries refreshAvailability:(BOOL) refresh save:(BOOL) save;


+(BOOL)deleteAppointment:(SCHAppointment *)appointment refreshAvailability:(BOOL) refresh save:(BOOL) save;


+(BOOL)appointmentChangeRequest:(SCHAppointment *) appointment proposedStartTime:(NSDate *) proposedStartTime proposedEndTime:(NSDate *) proposedEndTime proposedLocation:(NSString *) proposedLocation locationPoint:(PFGeoPoint *) locationPoint note:(NSString *) note;
+(BOOL) releaseConfirmedTimeForAppointment:(SCHAppointment *) appointment refreshSchedule:(BOOL) refresh save:(BOOL) save;

+(NSString *)messageBody:(id) appointmentObject;

+(BOOL)commit;


@end
