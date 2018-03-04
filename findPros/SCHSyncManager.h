//
//  SCHSyncManager.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/6/15.
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
#import "SCHUtility.h"
#import "SCHUser.h"


@interface SCHSyncManager : NSObject

+(BOOL) syncWithServer;
+(BOOL)syncAvailability;

+(BOOL) removeexpiredObjects;

+(BOOL)syncNotification;
+(BOOL) syncBadge;
+(void) syncUserData:(NSDate *) calendarViewdate;
+(void)syncUserDateNoInternetMode:(NSDate *) calendarViewDate;


//+(void) syncData;

//+(void)syncEventManager;

+(void)callTimer;



@end
