//
//  SCHAvailabilityManager.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/3/15.
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

@interface SCHAvailabilityManager : NSObject
/*
+(BOOL)manageAvailableTimeWithAction:(NSString *) action service:(SCHService *) service location:(NSString *) location timeFrom: (NSDate *) timeFrom timeTo:(NSDate *) timeTo repeatOption:(NSString *) repeatOption repeatDays:(NSArray *) repeatDays endDate:(NSDate *) endDate;
 
 */

+(BOOL)manageAvailableTimeWithAction:(NSString *) action service:(SCHService *) service location:(NSString *) location locationPoint:(PFGeoPoint *) locationPoint timeFrom: (NSDate *) timeFrom timeTo:(NSDate *) timeTo repeatOption:(NSString *)  repeatOption cancelAppointments:(BOOL) cancelAppointments repeatDays:(NSArray *) repeatDays endDate:(NSDate *) endDate;

+(BOOL) createAvailableTimeWithService:(SCHService *) service location:(NSString *) location locationPoint:(PFGeoPoint *) locatioPoint availabilityTime:(NSArray *) availabilityTime startDate:(NSDate *) startDate endDate:(NSDate *) endDate availableForNewRequest:(BOOL) availableForNewRequest;


+(BOOL)removeAvailableTimeWithService:(SCHService *) service location:(NSString *) location timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo cancelAppointments:(BOOL) cancelAppointments;

//+(BOOL) refreshAllAvailabilitiesWithTime:(NSArray *) availabilityTimes timeBocks:(NSArray *) timeBlock user:(SCHUser *) user service:(SCHService *) service;
+(BOOL) refreshAvailabilityWithTimeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo timeBlocks:(NSArray *)timeBlocks user:(SCHUser *) user ;
+(BOOL) refreshAvailabilityForAppointmentWithTimeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo timeBlocks:(NSArray *) timeBlocks service:(SCHService *)service user:(SCHUser *) user;

+(BOOL) refreshNetAvailabilities;
+(BOOL) refreshAvailabilitiesForAppointment;













@end
