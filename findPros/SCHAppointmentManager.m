//
//  SCHAppointmentManager.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/4/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAppointmentManager.h"
#import "SCHConstants.h"
#import "SCHLookup.h"
#import "SCHAppointment.h"
#import "SCHAppointmentActivity.h"
#import "SCHAppointmentSeries.h"
#import "SCHService.h"
#import "SCHServiceClassification.h"
#import "SCHServiceOffering.h"
#import "SCHAvailableTimeBlock.h"
#import "SCHAvailability.h"
#import <XLForm/XLForm.h>
#import "SCHBackgroundManager.h"
#import "SCHScheduledEventManager.h"
#import "SCHAvailabilityForAppointment.h"
#import "SCHNotification.h"
#import "SCHAvailabilityManager.h"
#import "SCHAvailabilityManager.h"
#import "SCHUtility.h"
#import "SCHBackendCommit.h"
#import "AppDelegate.h"
#import "SCHAvailabilityRefreshQueue.h"
#import "SCHServiceProviderClientList.h"
#import "SCHNonUserClient.h"
#import "SCHUser.h"


static BOOL debug = NO;
NSString *const SCHATBConfirmedToOtherAppointment = @"Not Available for allocation";
NSString *const SCHATBAllocatedToAppointment = @"Allocated To Apointment";
NSString *const SCHATBNotAllocatedToAppointment = @"Not Allocated To Apointment";
NSString *const SCHNotAbleToReachServer = @"Server not Reachable";



@implementation SCHAppointmentManager

/**************************************************************************************************/
/* Creates new appointment/ appointment series request.                                           */
/**************************************************************************************************/


+(id)createAppointmentServiceProvider: (SCHUser *) serviceProvider service:(SCHService *) service serviceOffering: (SCHServiceOffering *) serviceOffering location: (NSString *) location locationPoint:(PFGeoPoint *)locationPoint client: (id) clientObject clientName:(NSString *) name timeFrom: (NSDate *) timeFrom timeTo: (NSDate *) timeTo repeatOption:(NSString *) repeatOption repeatDays:(NSArray *) repeatDays endDate:(NSDate *) endDate notes:(NSString *)  notes {
    // Initialization
    
    BOOL debug = NO;
    BOOL success = YES;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    [appDelegate.refreshQueue refresh];
   
    NSDate *inputTimeFrom = [SCHUtility startOrEndTime:timeFrom];
    NSDate *inputTimeTo = [SCHUtility startOrEndTime:timeTo];
    NSDate *inputEndDate = [SCHUtility startOrEndTime:endDate];
    NSMutableArray *appointmentCreationDays = [[NSMutableArray alloc] init];
    SCHConstants *constants = [SCHConstants sharedManager];
    
    NSInteger numberOfAppointmentRequestWithConflict = 0;
    NSInteger numberOfAppointmentRequestWithAvailabilityConflict = 0;
    NSInteger numberOfAppointmentRequestCreated = 0;
    NSMutableArray *appointmentNotCreated = [[NSMutableArray alloc] init];
    NSMutableArray *appointments = [[NSMutableArray alloc] init];
    
/*
    
    
    if (debug){
        NSLog(@"Processing -Create new appointment Request");
        NSLog(@"Service Provider: %@", serviceProvider);
        NSLog(@"service: %@", service);
        NSLog(@"service Type: %@", serviceOffering);
        NSLog(@"location: %@",location);
        NSLog(@"timefrom: %@",inputTimeFrom);
        NSLog(@"timeto: %@",inputTimeTo);
        NSLog(@"repeatOption: %@",repeatOption);
        NSLog(@"repeatDays: %@",repeatDays);
        NSLog(@"endDate: %@",inputEndDate);
        NSLog(@"Notes: %@", notes);
    }
    
     */
    
    
    // Build Appointment Creation Days
    
    
    if ([repeatOption isEqualToString:SCHSelectorRepeatationOptionNever] || repeatOption.length == 0){
        NSDictionary *appointmentTime = @{@"startTime": inputTimeFrom, @"endTime" : inputTimeTo};
        [appointmentCreationDays addObject:appointmentTime];
        
        
        
    } else {
        
        [appointmentCreationDays addObjectsFromArray:[SCHUtility getDaysforschedulingwithStartTime:inputTimeFrom
                                                                                           endTime:inputTimeTo
                                                                                           endDate:inputEndDate
                                                                                      repeatOption:repeatOption
                                                                                        repeatDays:repeatDays]];
        
        
    }
    
  /*
    
    if (debug){
        NSLog(@"appointment Creation Days: %@", appointmentCreationDays);
        
        for (NSDictionary *appointment in appointmentCreationDays){
            NSLog(@"Start Time: %@ - End Time: %@", [appointment valueForKey:@"startTime"], [appointment valueForKey:@"endTime"]);
        }
        
        
    }
    */
    
    
//    NSInteger numberOfAppointmentsToBeCreated = [appointmentCreationDays count];
    
    /*
    if (debug){
        NSLog(@"Number of Request: %ld", (long)numberOfAppointmentsToBeCreated);
    }
     */
    
    //Determine if client is user or nonUser
    SCHUser *client = nil;
    SCHNonUserClient *nonUserClient = nil;
    
    
    if ([clientObject isKindOfClass:[SCHUser class]]){
        
        client = (SCHUser *)clientObject;
        
    } else if ([clientObject isKindOfClass:[SCHNonUserClient class]]){
        nonUserClient = (SCHNonUserClient *)clientObject;
    }
    
    
    
    
    
    // If it qualifies for appointment series then create a series
    // If number of appointment Days  are more than one then create a appointment series
    
    SCHAppointmentSeries *series = nil;
    BOOL isSries = NO;
    if (appointmentCreationDays.count > 1){
        isSries = YES;
        series = [SCHAppointmentSeries object];
        series.serviceProvider = serviceProvider;
        series.client = client;
        series.nonUserClient = nonUserClient;
        series.clientName = name;
        series.isClientUser = (client) ? YES :NO;
        series.startTime = timeFrom;
        series.endTime = timeTo;
        series.location = location;
        series.note = notes;
        series.service = service;
        series.serviceOffering = serviceOffering;
        series.status = (client) ? constants.SCHappointmentStatusPending: constants.SCHappointmentStatusConfirmed;
        series.repeatOption = repeatOption;
        series.repeatDays = repeatDays;
        series.endDate = endDate;
        [SCHUtility setPublicAllRWACL:series.ACL];
        
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:series];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:series];
        
        /*
        if (debug){
            NSLog(@"series - %@", series);
        }
        */
    }
    
    // Create all appintments one by one
    
    NSInteger iteration = 0;
    
    SCHAppointment *appointment = nil;
    
    
    for (NSDictionary *appointmentDay in appointmentCreationDays){
        iteration++;
        appointment = nil;
        
        if (!appDelegate.serverReachable){
            break;
        }
        /*
        if (debug){
            NSLog(@"Start Time: %@ - EndTime:%@", [appointmentDay valueForKey:@"startTime"], [appointmentDay valueForKey:@"endTime"]);
        }
         
         */
        
       /* self appointmentExistsForClient:client nonUserClient:nonUserClient serviceProvider:serviceProvider startTime:[appointmentDay valueForKey:@"startTime"] endTime:[appointmentDay valueForKey:@"endTime"]excludeAppointment:nil]*/
        
        if ([self timeConflictExistsForClient:client nonUserClient:nonUserClient serviceProvider:serviceProvider startTime:[appointmentDay valueForKey:@"startTime"] endTime:[appointmentDay valueForKey:@"endTime"] excludeAppointment:nil]){
            [appointmentNotCreated addObject:appointmentDay];
            numberOfAppointmentRequestWithConflict++;
            
            if (debug){
                NSLog(@"conflicting with Existing appointment");
            }
            
            
        } else {
            // get timeblock
            
            
          //  NSLog(@"Getting timeBlocks - startTime:%@ - endTime: %@", [appointmentDay valueForKey:@"startTime"], [appointmentDay valueForKey:@"endTime"]);
            
            
            NSArray *timeBlocks = [self getAvailableTimeBlocksForAppointmentWithStartTime:[appointmentDay valueForKey:@"startTime"]
                                                                                  endTime:[appointmentDay valueForKey:@"endTime"]
                                                                                  service:service
                                                                                 location:location
                                                                            locationPoint:locationPoint
                                                                          serviceProvider:serviceProvider
                                                                              appointment:NULL];
            
            
            
            if (debug){
                NSLog(@"timeBlock Count: %lu", (unsigned long)timeBlocks.count);
                for (SCHAvailableTimeBlock *timeBlock in timeBlocks){
                    NSLog(@"timeBlock startTime: %@ - endTime:%@", timeBlock.startTime, timeBlock.endTime);
                }
            }
            
            
            NSInteger timeblocksrequired = [[appointmentDay valueForKey:@"endTime"] timeIntervalSinceDate:[appointmentDay valueForKey:@"startTime"]]/SCHTimeBlockDuration;
            
            if (debug){
                NSLog(@"time blocks required = %ld", (long)timeblocksrequired);
            }
            
            
            if (timeBlocks.count != [[appointmentDay valueForKey:@"endTime"] timeIntervalSinceDate:[appointmentDay valueForKey:@"startTime"]]/SCHTimeBlockDuration){
                
                [appointmentNotCreated addObject:appointmentDay];
                
                
                numberOfAppointmentRequestWithAvailabilityConflict++;
            } else{
                // create Appointment
                
               // NSLog(@"Appointment startTime:%@ - endTime:%@", [appointmentDay valueForKey:@"startTime"],[appointmentDay valueForKey:@"endTime"] );
                
                
                appointment = [self createAppointmentRequestwithtimeBlocks:timeBlocks
                                                           serviceProvider:serviceProvider
                                                                   service:service serviceType:serviceOffering
                                                                    client:client
                                                            nonUserClient:nonUserClient
                                                                clientName:name
                                                                  location:location
                                                                  timeFrom:[appointmentDay valueForKey:@"startTime"]
                                                                    timeTo:[appointmentDay valueForKey:@"endTime"]
                                                                     notes:notes
                                                         appointmentSeries:(isSries) ? series : nil];
                
                
                
                
                if (appointment) {
                    
                    
                    numberOfAppointmentRequestCreated++;
                    [appointments addObject:appointment];
                    
                    
                } else {
                    [appointmentNotCreated addObject:appointmentDay];
                }
                
                
            }
        }
        
      //  NSLog(@"Iteration: %ld", (long)iteration);
        
    }
    
    // Appointment creation process completes here
  // if (appointments.coun
    
    SCHAppointmentActivity *createAppointment = nil;
    SCHAppointmentActivity *responseRequest  = nil;
    SCHAppointmentActivity *createAppointmentRequest = nil;
    
    BOOL autoConfirm = YES;
    for (SCHAppointment *appointment in appointments){
        if ([appointment.status isEqual:constants.SCHappointmentStatusPending]){
            autoConfirm = NO;
            break;
        }
        
        
    }
    
    
    if (isSries){
        if (numberOfAppointmentRequestCreated > 0){
            
            
            if ((client && autoConfirm)|| nonUserClient ){
                
                //Determine Assigned To
                SCHUser *actionAssignedTo = nil;
                if (nonUserClient){
                    actionAssignedTo = serviceProvider;
                }else{
                    actionAssignedTo = ([serviceProvider isEqual:appDelegate.user] ) ? client :serviceProvider;
                }
                
                createAppointment = [self createActivityWithParameters:NULL
                                                     appointmentSeries:series
                                                                action:constants.SCHAppointmentActionAppointmentCreation
                                                       actionInitiator:appDelegate.user
                                                      actionAssignedTo:actionAssignedTo
                                                                status:constants.SCHappointmentActivityStatusComplete];
                [appDelegate.backgroundCommit.objectsStagedForSave addObject:createAppointment];
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:createAppointment];
            } else if (client && !autoConfirm){
                createAppointmentRequest = [self createActivityWithParameters:NULL
                                                     appointmentSeries:series
                                                                action:constants.SCHAppointmentActionAppointmentRequest
                                                       actionInitiator:appDelegate.user
                                                      actionAssignedTo:appDelegate.user
                                                                status:constants.SCHappointmentActivityStatusComplete];
                [appDelegate.backgroundCommit.objectsStagedForSave addObject:createAppointmentRequest];
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:createAppointmentRequest];
                
                responseRequest = [self createActivityWithParameters:NULL
                                                   appointmentSeries:series
                                                              action:constants.SCHAppointmentActionRespondToAppointmentRequest
                                                     actionInitiator:appDelegate.user
                                                    actionAssignedTo:(appDelegate.user == serviceProvider) ? client : serviceProvider
                                                              status:constants.SCHappointmentActivityStatusOpen];
                [appDelegate.backgroundCommit.objectsStagedForSave addObject:responseRequest];
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:responseRequest];

            }
            
            
            success = [self removeOldNotifications:series.objectId];
            
            
        } else success = NO;
    } else{
        if (appointment){
             if ((client && autoConfirm)|| nonUserClient ){
                 
                 //Determine Assigned To
                 SCHUser *actionAssignedTo = nil;
                 if (nonUserClient){
                     actionAssignedTo = serviceProvider;
                 }else{
                     actionAssignedTo = ([serviceProvider isEqual:appDelegate.user] ) ? client :serviceProvider;
                 }
                 
                 createAppointment =[self createActivityWithParameters:appointment
                                                     appointmentSeries:NULL
                                                                action:constants.SCHAppointmentActionAppointmentCreation
                                                       actionInitiator:appDelegate.user
                                                      actionAssignedTo:actionAssignedTo
                                                                status:constants.SCHappointmentActivityStatusComplete];
                 [appDelegate.backgroundCommit.objectsStagedForSave addObject:createAppointment];
                 [appDelegate.backgroundCommit.objectsStagedForPinning addObject:createAppointment];
                 
                 
             } else if (client && !autoConfirm){
                 createAppointmentRequest =[self createActivityWithParameters:appointment
                                                            appointmentSeries:NULL
                                                                       action:constants.SCHAppointmentActionAppointmentRequest
                                                              actionInitiator:appDelegate.user
                                                             actionAssignedTo:appDelegate.user
                                                                       status:constants.SCHappointmentActivityStatusComplete];
                 [appDelegate.backgroundCommit.objectsStagedForSave addObject:createAppointmentRequest];
                 [appDelegate.backgroundCommit.objectsStagedForPinning addObject:createAppointmentRequest];
                 
                 responseRequest = [self createActivityWithParameters:appointment
                                                    appointmentSeries:NULL
                                                               action:constants.SCHAppointmentActionRespondToAppointmentRequest
                                                      actionInitiator:appDelegate.user
                                                     actionAssignedTo:([serviceProvider isEqual:appDelegate.user]) ? client :serviceProvider
                                                               status:constants.SCHappointmentActivityStatusOpen];
                 
                 [appDelegate.backgroundCommit.objectsStagedForSave addObject:responseRequest];
                 [appDelegate.backgroundCommit.objectsStagedForPinning addObject:responseRequest];
                 
             }
            

            
                
        
            
            
            success = [self removeOldNotifications:appointment.objectId];
            
        } else success = NO;
        
    }
    
    // refresh availability
    
    if (success){
        success = ([SCHAvailabilityManager refreshAvailabilitiesForAppointment] && [SCHAvailabilityManager refreshNetAvailabilities]);
        [appDelegate.refreshQueue refresh];
    }
    
    if (success){
        success = [self commit];
    }
    
    if (success && client){
        if (!autoConfirm){
           [self createNotificationForAppointmentActivity:responseRequest];
        } else {
            // add auto confirm appointment
            [self createNotificationForAppointmentActivity:createAppointment];
        }
        
    
    }
    
    if (success && nonUserClient){
        //send email or text
    }
    

    
    
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    
    
    
    
    if (appointmentNotCreated.count > 0 && isSries){
        // send notification to appointment creator for appointments that were not created
        
        NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
        
        // NSDateFormatter *fromTimeFormatter = [SCHUtility dateFormatterForFromTime];
        NSDateFormatter *toTimeFormatter = [SCHUtility dateFormatterForToTime];
        NSMutableString *appoinrmentDays = [[NSMutableString alloc] init];
        
        for (NSDictionary *appointmentDay in appointmentNotCreated){
            NSString *day = [dayformatter stringFromDate:[appointmentDay valueForKey:@"startTime"]];
            NSString *time = [NSString stringWithFormat:@"from %@ to %@", [toTimeFormatter stringFromDate:[appointmentDay valueForKey:@"startTime"]], [toTimeFormatter stringFromDate:[appointmentDay valueForKey:@"endTime"]]];
            [appoinrmentDays appendString:[NSString stringWithFormat:@"%@ on %@ \n", time, day]];
            
        }
        
        NSString *title = [NSString stringWithFormat:@"Appointment couldn't be created"];
        NSString *reason = [NSString stringWithFormat:@"Reason - Avalailability Issue"];
        NSString *suggestation = [NSString stringWithFormat:@"Please create appointment at some other time."];
        
        
        NSString *message = [NSString stringWithFormat:@"for %@ - %@ with %@ at %@ on following %@\n%@\n%@\n%@", service.serviceTitle, serviceOffering.serviceOfferingName, (appDelegate.user == serviceProvider) ? (client? client.preferredName: name) : serviceProvider.preferredName, location,(appointmentNotCreated.count == 1) ? @"day:" : @"days:", appoinrmentDays, reason, suggestation];
        
       // NSLog(@"%@", message);
        
        
        
        SCHNotification *notification = [SCHUtility createNotificationForUser:appDelegate.user
                                                             notificationType:constants.SCHNotificationForAcknowledgement
                                                            notificationTitle:title
                                                                      message:message
                                                              referenceObject:nil
                                                          referenceObjectType:nil];
        
        [notification save];
        [SCHUtility sendNotification:notification];
        
        
        
        
    } else if (appointmentNotCreated.count > 0 && !isSries){
        //showAlert
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Conflicts with other appointments. Please find another time slot.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        });
        
    }
    
    
    

    
    
    // Build Dictonary for output
   /* NSDictionary *output = @{@"numberOfAppointmentRequest" : [NSNumber numberWithUnsignedInteger:numberOfAppointmentsToBeCreated],
                             @"numberOfAppointmentWithConflict" :[NSNumber numberWithUnsignedInteger:numberOfAppointmentRequestWithConflict],
                             @"numberofAppointmentWithAvailabilityConflict" : [NSNumber numberWithUnsignedInteger:numberOfAppointmentRequestWithAvailabilityConflict],
                             @"numberOfAppointmentsCreated" :[NSNumber numberWithUnsignedInteger:numberOfAppointmentRequestCreated]};
    
    */
   // NSLog(@"Output: %@", output);
    
    id returnObject = nil;
    
    if (success){
        if (series){
            
            returnObject = series;
        } else if (appointment){
            returnObject = appointment;
        }
    }
    
    
    
    
    return returnObject;
}

+(BOOL)confirmAppointmentSeries:(SCHAppointmentSeries *) series {
    
    SCHConstants *constants = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    [appDelegate.refreshQueue refresh];
    SCHAppointmentActivity *seriesacceptance = nil;
    BOOL success = YES;
    NSError *error = nil;

    
    NSPredicate *appointmentPredicate = [NSPredicate predicateWithFormat:@"appointmentSeries = %@", series, [NSDate date]];
    PFQuery *appointmentQuery = [PFQuery queryWithClassName:SCHAppointmentClass predicate:appointmentPredicate];
    
    NSArray *appointments = [appointmentQuery findObjects:&error];
    if (error){
        return NO;
    }
    
    
    NSInteger *succesCount = 0;
    NSMutableArray *notConfirmedAppointments = [[NSMutableArray alloc] init];
    
    
    for (SCHAppointment *appintment in appointments){
        BOOL isSeries = YES;
        if ([self confirmAppointmentRequest:appintment series:isSeries refreshAvailability:NO save:NO]) {
            succesCount++;
        } else{
            [notConfirmedAppointments addObject:appintment];
        }
        
    }
    if (succesCount > 0) {
        
        series.status = constants.SCHappointmentStatusConfirmed;
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:series];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:series];
        
        seriesacceptance = [self activityChangeForAppointmentConfirmation:series];
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:series];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:series];
        success = [self removeOldNotifications:series.objectId];
        
        if (success){
            success = ([SCHAvailabilityManager refreshAvailabilitiesForAppointment] && [SCHAvailabilityManager refreshNetAvailabilities]);
            [appDelegate.refreshQueue refresh];
        }
        
        if (success){
            success = [self commit];
            [SCHUtility addClientToServiceProvider:series.serviceProvider
                                            client:series.client
                                              name:nil
                                     nonUserClient:nil
                                       autoConfirm:NO];
        }
        if (success){
            [self createNotificationForAppointmentActivity:seriesacceptance];
        }
        
     }
    
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    [appDelegate.refreshQueue refresh];
    
    return success;
}

+(BOOL)confirmAppointmentRequest:(SCHAppointment *) appointment series:(BOOL) isSeries refreshAvailability:(BOOL) refresh save:(BOOL) save{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (!isSeries || (refresh && save)){
        [appDelegate.refreshQueue refresh];
        [appDelegate.backgroundCommit refreshQueues];
        [appDelegate.backgroundCommit refrshStagedQueue];
    }

    BOOL success = YES;
    BOOL onlyLocationChange = NO;
    NSError *error = nil;
    
    BOOL debug = NO;
    
    if (debug) {
        NSLog(@"Comfirm appointment Process start");
        NSLog(@"Appointment: %@", appointment);
    }

    
    
    SCHConstants *constants = [SCHConstants sharedManager];
    
    
    
    
    // Process for  null proposed time

    
    if (appointment.proposedStartTime == NULL || appointment.proposedEndTime  == NULL){
        
        // This means Appointment has never been confirmed or new location is proposed
        
        if (appointment.proposedLocation){
            //Just location change
            NSString *location = [NSString stringWithString:appointment.proposedLocation];
            appointment.location = location;
            appointment.proposedLocation = nil;
            onlyLocationChange = YES;
            
        } else {
            // Never confirmed appointment to be confirmed
            
            // allocate timeblock to appointment
            
            NSString *ATBAllocation =[self allocateTimeBlockOfUser:appointment.serviceProvider fromTime:appointment.startTime toTime:appointment.endTime appointment:appointment];
            if (debug){
                NSLog(@"Allocation State: %@", ATBAllocation);
            }
            // server not reachable
            if ([ATBAllocation isEqualToString:SCHNotAbleToReachServer]){
                if (!isSeries){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];

                }
                
                return NO;
            }
            // timeblock couldn't be allocated to appointment
            if ([ATBAllocation isEqualToString:SCHATBConfirmedToOtherAppointment] || [ATBAllocation isEqualToString:SCHATBNotAllocatedToAppointment]){
                
                if (!isSeries){
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Conflicts with other appointments. Please find another time slot.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                    });
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.refreshQueue refresh];
                    
                    
                } else {
                    // send notification to reschedule
                    
                    
                    NSString *notificationTitle = [NSString stringWithFormat:@"Appointment couldn't be confirmed"];
                    NSString *message = [NSString stringWithFormat:@"Due to availability conflict. Reschedule Appointment - %@ - %@ with %@", appointment.service.serviceTitle, appointment.serviceOffering.serviceOfferingName, (([appDelegate.user isEqual:appointment.serviceProvider]) ? appointment.client.preferredName : appointment.serviceProvider.preferredName)];
                    SCHNotification *notification =[SCHUtility createNotificationForUser:appDelegate.user
                                                                        notificationType:constants.SCHNotificationForAcknowledgement
                                                                       notificationTitle:notificationTitle
                                                                                 message:message
                                                                         referenceObject:appointment.objectId
                                                                     referenceObjectType:SCHAppointmentClass];
                    
                    [notification save];
                    [SCHUtility sendNotification:notification];
                }
                
                return NO;
            }
        }
        
        // Change appointment status
        appointment.status = constants.SCHappointmentStatusConfirmed;
        
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
        
        // Set appointment activities if not series
        SCHAppointmentActivity *accetanceActivity = nil;

        if (!isSeries){
            
            accetanceActivity = [self activityChangeForAppointmentConfirmation:appointment];
            
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:accetanceActivity];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:accetanceActivity];
            
            success = [self removeOldNotifications:appointment.objectId];
            
            
            if (success && refresh){
                if (!onlyLocationChange){
                    success = [SCHAvailabilityManager refreshAvailabilitiesForAppointment];
                    [appDelegate.refreshQueue refresh];
                }
                
            }
            
            if (success && save){
                success = [self commit];
                [SCHUtility addClientToServiceProvider:appointment.serviceProvider
                                                client:appointment.client
                                                  name:nil
                                         nonUserClient:nil
                                           autoConfirm:NO];
            }
            if (success){
                [self createNotificationForAppointmentActivity:accetanceActivity];
            }
            
            if (!success){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
            } else {
                if (save){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                }
            }
            
            
            
        }
    
        
        return success;
    
        
    } else {
        
        //Appointment was confirmed before
        
        //Free existing schedule
        NSArray *freedTimeBlocks =[self freeConfirmedTimeBlockFrom:appointment.startTime
                         toTime:appointment.endTime
                 forAppointment:appointment
                                      ofUser:appointment.serviceProvider];
        
        if (!freedTimeBlocks){
            
            if (!isSeries){
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.refreshQueue refresh];
            }
            
            return NO;
        } else {
            //change availability picture
            //Get all services of Service Provider
            PFQuery *serviceQuery = [SCHService query];
            [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
            NSArray *services = [serviceQuery findObjects:&error];
            
            if (error){
                if (!isSeries){
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.refreshQueue refresh];
                }
                return  NO;
            } else{
                for (SCHService *service in services) {
                    NSDictionary *availabilityRefresh = @{@"startTime" : appointment.startTime,
                                                          @"endTime" : appointment.endTime,
                                                          @"timeBlocks" : freedTimeBlocks,
                                                          @"user" : appointment.serviceProvider,
                                                          @"service" : service};
                    
                    [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                }
            }
            
        }
        
        
        //allocate proposed time to appointment
        NSString *ATBAllocation = [self allocateTimeBlockOfUser:appointment.serviceProvider
                                                           fromTime:appointment.proposedStartTime
                                                             toTime:appointment.proposedEndTime
                                                        appointment:appointment];
        if ([ATBAllocation isEqualToString:SCHNotAbleToReachServer]){
            if (!isSeries){
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.refreshQueue refresh];
            } else{
                [appDelegate.refreshQueue.availabilityRefreshQueue removeLastObject];

                for (int i = 0; i <freedTimeBlocks.count; i++){
                    [appDelegate.backgroundCommit.objectsStagedForSave removeLastObject];
                }
                
            }
            
                return NO;
            }
        
        // timeblock couldn't be allocated to appointment
        if ([ATBAllocation isEqualToString:SCHATBConfirmedToOtherAppointment] || [ATBAllocation isEqualToString:SCHATBNotAllocatedToAppointment]){
                
                if (!isSeries){
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Conflicts with other appointments. Please find another time slot", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                    });
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.refreshQueue refresh];
                    
                    
                } else {
                    // send notification to reschedule
                    
                    
                    NSString *notificationTitle = [NSString stringWithFormat:@"Appointment couldn't be confirmed"];
                    NSString *message = [NSString stringWithFormat:@"Due to availability conflict. Reschedule Appointment - %@ - %@ with %@", appointment.service.serviceTitle, appointment.serviceOffering.serviceOfferingName, (([appDelegate.user isEqual:appointment.serviceProvider]) ? appointment.client.preferredName : appointment.serviceProvider.preferredName)];
                    SCHNotification *notification =[SCHUtility createNotificationForUser:appDelegate.user
                                                                        notificationType:constants.SCHNotificationForAcknowledgement
                                                                       notificationTitle:notificationTitle
                                                                                 message:message
                                                                         referenceObject:appointment.objectId
                                                                     referenceObjectType:SCHAppointmentClass];
                    
                    [notification save];
                    [SCHUtility sendNotification:notification];
                    
                    [appDelegate.refreshQueue.availabilityRefreshQueue removeLastObject];
                    
                    for (int i = 0; i <freedTimeBlocks.count; i++){
                        [appDelegate.backgroundCommit.objectsStagedForSave removeLastObject];
                    }
                    
                    
                }
            
            
                return NO;
            }
        
        // set appointment to confirmed
        appointment.startTime = appointment.proposedStartTime;
        appointment.endTime = appointment.proposedEndTime;
        appointment.proposedStartTime = nil;
        appointment.proposedEndTime = nil;
        // Change appointment status
        if (appointment.proposedLocation){
            appointment.location = appointment.proposedLocation;
            appointment.proposedLocation = nil;
        }
        appointment.status = constants.SCHappointmentStatusConfirmed;
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
        
        
        // Set appointment activities if not series
        SCHAppointmentActivity *accetanceActivity = nil;
        
        if (!isSeries){
            accetanceActivity = [self activityChangeForAppointmentConfirmation:appointment];
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:accetanceActivity];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:accetanceActivity];
            
            success = [self removeOldNotifications:appointment.objectId];
            
            if (success && refresh){
                success = ([SCHAvailabilityManager refreshAvailabilitiesForAppointment] && [SCHAvailabilityManager refreshNetAvailabilities]);
                [appDelegate.refreshQueue refresh];
                
            }
            
            
            if (success && save){
                success = [self commit];
                [SCHUtility addClientToServiceProvider:appointment.serviceProvider
                                                client:appointment.client
                                                  name:nil
                                         nonUserClient:nil
                                           autoConfirm:NO];
            }
            if (success){
                [self createNotificationForAppointmentActivity:accetanceActivity];
            }
            
            if (!success){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
            } else {
                if (save){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                }
            }
        }
    
        
        return success;

    }
    
}

+(BOOL) declineAppointmentSeriesRequest:(SCHAppointmentSeries *)series{
    

    SCHConstants *constants = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    [appDelegate.refreshQueue refresh];
    SCHAppointmentActivity *seriesDecline = nil;
    BOOL success = YES;
    NSError *error = nil;
    NSPredicate *appointmentPredicate = [NSPredicate predicateWithFormat:@"appointmentSeries = %@", series];
    PFQuery *appointmentQuery = [PFQuery queryWithClassName:SCHAppointmentClass predicate:appointmentPredicate];
    
    NSArray *appointments = [appointmentQuery findObjects:&error];
    if (error){
        return NO;
    }
    NSInteger *succesCount = 0;
    NSMutableArray *notDeclinedAppointments = [[NSMutableArray alloc] init];
    
    
    
    for (SCHAppointment *appintment in appointments){
        BOOL isSeries = YES;
        if ([self declineAppointmentRequest:appintment isseries:isSeries refreshAvailability:NO save:NO]) {
            succesCount++;
        } else{
            [notDeclinedAppointments addObject:appintment];
        }
    }

    if (succesCount > 0) {
        
        
        series.status = constants.SCHappointmentStatusCancelled;
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:series];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:series];
        
        seriesDecline = [self actitvityChangeForAppointmentDecline:series];
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:series];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:series];
        
        success = [self removeOldNotifications:series.objectId];
        
        
        
        if (success){
            success = ([SCHAvailabilityManager refreshAvailabilitiesForAppointment] && [SCHAvailabilityManager refreshNetAvailabilities]);
            [appDelegate.refreshQueue refresh];
            
        }
        
        
        if (success){
            success = [self commit];
        }
        if (success){
            [self createNotificationForAppointmentActivity:seriesDecline];
        }
        
    }
    
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    [appDelegate.refreshQueue refresh];

     
     return success;

}


+(BOOL)declineAppointmentRequest:(SCHAppointment *) appointment isseries:(BOOL) isSeries refreshAvailability:(BOOL) refresh save:(BOOL) save{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!isSeries && (refresh && save)){
        [appDelegate.refreshQueue refresh];
        [appDelegate.backgroundCommit refreshQueues];
        [appDelegate.backgroundCommit refrshStagedQueue];
        
    }
    
    
    BOOL success = YES;
    SCHAppointmentActivity *declineActivity = nil;

  //  NSMutableArray *objectsForDelete = [[NSMutableArray alloc] init];
    SCHConstants *constants = [SCHConstants sharedManager];
    BOOL locationOnly = NO;
    
    
    if ([appointment.status isEqual:constants.SCHappointmentStatusCancelled] || appointment.expired){
        return NO;
    }
    
    
    //Check if there is proposed time
    if (appointment.proposedStartTime == NULL || appointment.proposedEndTime  == NULL){
        
        //there can be 2 cases. 1) Appointment status is pending with a location change 2) New appointment never confirmed
        
        if (appointment.proposedLocation == NULL){
            
            // set appointment to cancelle
            NSArray *releasedBlocks = [self releaseTimeBlcoksFrom:appointment.startTime
                                                           toTime:appointment.endTime
                                                   forAppointment:appointment
                                                           ofUser:appointment.serviceProvider];
            
            if (!releasedBlocks){
                if (!isSeries){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                    
                }
                return NO;
            } else {
                //Get all services of Service Provider
                NSError *error = nil;
                PFQuery *serviceQuery = [SCHService query];
                [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                NSArray *services = [serviceQuery findObjects:&error];
                
                if (error){
                    if (!isSeries){
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.refreshQueue refresh];
                    }
                    return  NO;
                } else{
                    for (SCHService *service in services) {
                        NSDictionary *availabilityRefresh = @{@"startTime" : appointment.startTime,
                                                              @"endTime" : appointment.endTime,
                                                              @"timeBlocks" : releasedBlocks,
                                                              @"user" : appointment.serviceProvider,
                                                              @"service" : service};
                        
                        [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                    }
                }

            }
            appointment.status = constants.SCHappointmentStatusCancelled;
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
            
        } else {
            //only location is proposed
            appointment.proposedLocation = nil;
            appointment.status = constants.SCHappointmentStatusConfirmed;
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
            locationOnly = YES;
        }
        
        if (!isSeries){
            // create Activity
            declineActivity = [self actitvityChangeForAppointmentDecline:appointment];
            if (!declineActivity){
                
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                
                return NO;
            }
            
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:declineActivity];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:declineActivity];
            
            success =[self removeOldNotifications:appointment.objectId];
            if (success && refresh){
                if (!locationOnly){
                    
                    
                   success = [SCHAvailabilityManager refreshNetAvailabilities];
                    [appDelegate.refreshQueue refresh];
                    
                }
            }
            
            
            if (success && save){
              success = [self commit];
            }
            if (success){
               [self createNotificationForAppointmentActivity:declineActivity];
            }
        
            if (!success){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
            } else {
                if (save){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                }
            }

        
            
        }
        
        
        return success;
        
    } else {
        
        NSDate *proposedStartTime = appointment.proposedStartTime;
        NSDate *proposedEndTime = appointment.proposedEndTime;
        
        // set appointment to cancelle
        NSArray *releasedBlocks = [self releaseTimeBlcoksFrom:proposedStartTime
                                                       toTime:proposedEndTime
                                               forAppointment:appointment
                                                       ofUser:appointment.serviceProvider];
        
        if (!releasedBlocks){
            if (!isSeries){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
                
            }
            return NO;
        } else {
            
            NSError *error = nil;
            PFQuery *serviceQuery = [SCHService query];
            [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
            NSArray *services = [serviceQuery findObjects:&error];
            
            if (error){
                if (!isSeries){
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.refreshQueue refresh];
                }
                return  NO;
            } else{
                for (SCHService *service in services) {
                    NSDictionary *availabilityRefresh = @{@"startTime" : appointment.proposedStartTime,
                                                          @"endTime" : appointment.proposedEndTime,
                                                          @"timeBlocks" : releasedBlocks,
                                                          @"user" : appointment.serviceProvider,
                                                          @"service" : service};
                    
                    [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                }
            }
            
            

            
        }
        appointment.proposedEndTime = nil;
        appointment.proposedLocation = nil;
        appointment.proposedStartTime = nil;
        
        appointment.status = constants.SCHappointmentStatusConfirmed;
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
        
        if (!isSeries){
            // create Activity
            declineActivity = [self actitvityChangeForAppointmentDecline:appointment];
            if (!declineActivity){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
                return NO;
            }
            
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:declineActivity];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:declineActivity];
            success =[self removeOldNotifications:appointment.objectId];
            if (success && refresh){
                if (!locationOnly){
                    
                    
                    success = [SCHAvailabilityManager refreshNetAvailabilities];
                    [appDelegate.refreshQueue refresh];
                    
                }
            }
            
            if (success && save){
                success = [self commit];
            }
            if (success){
                [self createNotificationForAppointmentActivity:declineActivity];
            }
            if (!success){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
            } else {
                if (save){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                }
            }

            
        }
        

        
        return success;
        
    }
    
}

+(BOOL)deleteAppointment:(SCHAppointment *)appointment refreshAvailability:(BOOL) refresh save:(BOOL) save{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    if (refresh && save){
        [appDelegate.backgroundCommit refreshQueues];
        [appDelegate.backgroundCommit refrshStagedQueue];
        [appDelegate.refreshQueue refresh];
        
    }
    
    SCHConstants *constants = [SCHConstants sharedManager];

    
    
    BOOL success = YES;
    SCHAppointmentActivity *deleteActivity = nil;
    
    if ([appointment.status isEqual:constants.SCHappointmentStatusCancelled] || appointment.expired){
        return NO;
    }

    
    if ([appointment.status isEqual:constants.SCHappointmentStatusConfirmed]){
        //this is a confirmed appointment
        
        
        // free confirmed timeblocks
        NSArray *freedTimeblocks = [self freeConfirmedTimeBlockFrom:appointment.startTime
                                                             toTime:appointment.endTime
                                                     forAppointment:appointment
                                                             ofUser:appointment.serviceProvider];
        
        if (!freedTimeblocks){
            [appDelegate.backgroundCommit refreshQueues];
            [appDelegate.backgroundCommit refrshStagedQueue];
            return NO;
        } else {

                   //change availability picture
            
            NSError *error = nil;
            PFQuery *serviceQuery = [SCHService query];
            [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
            NSArray *services = [serviceQuery findObjects:&error];
            
            if (error){

                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.refreshQueue refresh];
                return  NO;
            } else{
                for (SCHService *service in services) {
                    NSDictionary *availabilityRefresh = @{@"startTime" : appointment.startTime,
                                                          @"endTime" : appointment.endTime,
                                                          @"timeBlocks" : freedTimeblocks,
                                                          @"user" : appointment.serviceProvider,
                                                          @"service" : service};
                    
                    [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                }
            }
            
            
           
        }
        
        // set appointment status to cancelled
        appointment.status = constants.SCHappointmentStatusCancelled;
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
        
        
        //create Activity for appointment Cancellation
        if (appointment.client){
            deleteActivity = [self activityChangeForAppointmentCancellation:appointment];
            if (!deleteActivity){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
                return NO;
                
            }
            [appDelegate.backgroundCommit.objectsStagedForUnpin addObject:deleteActivity];
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:deleteActivity];
            
            success = [self removeOldNotifications:appointment.objectId];


        }
        
        
        
        
        if (success && refresh){
            success = ([SCHAvailabilityManager refreshAvailabilitiesForAppointment] && [SCHAvailabilityManager refreshNetAvailabilities]);
            [appDelegate.refreshQueue refresh];
        }
        
        if (success && save){
            success = [self commit];
        }
        if (success && appointment.client){
            [self createNotificationForAppointmentActivity:deleteActivity];
        } else if (success && appointment.nonUserClient){
            //send email or text
        }
        
        if (!success){
            [appDelegate.backgroundCommit refreshQueues];
            [appDelegate.backgroundCommit refrshStagedQueue];
            [appDelegate.refreshQueue refresh];
        } else {
            if (save){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
            }
        }
        
        return success;
        
    } else {
        if (![appointment.status isEqual:constants.SCHappointmentStatusPending]){
            return NO;
        }
        if (appointment.proposedStartTime || appointment.proposedEndTime){
            //appointment has been confirmed before
            // free confirmed timeblocks
            NSArray *freedTimeblocks = [self freeConfirmedTimeBlockFrom:appointment.startTime
                                                                 toTime:appointment.endTime
                                                         forAppointment:appointment
                                                                 ofUser:appointment.serviceProvider];
            
            if (!freedTimeblocks){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                return NO;
            } else {

                
                //change availability picture
                
                NSError *error = nil;
                PFQuery *serviceQuery = [SCHService query];
                [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                NSArray *services = [serviceQuery findObjects:&error];
                
                if (error){
                    
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.refreshQueue refresh];
                    return  NO;
                } else{
                    for (SCHService *service in services) {
                        NSDictionary *availabilityRefresh = @{@"startTime" : appointment.startTime,
                                                              @"endTime" : appointment.endTime,
                                                              @"timeBlocks" : freedTimeblocks,
                                                              @"user" : appointment.serviceProvider,
                                                              @"service" : service};
                        
                        [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                    }
                }


                
            }
            
            //free soft allocated time blocks
            
            NSArray *releasedBlocks = [self releaseTimeBlcoksFrom:appointment.proposedStartTime
                                                           toTime:appointment.proposedEndTime
                                                   forAppointment:appointment
                                                           ofUser:appointment.serviceProvider];
            
            if (!releasedBlocks){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
                return NO;
            } else{
                
                //change availability picture
                NSError *error = nil;
                PFQuery *serviceQuery = [SCHService query];
                [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                NSArray *services = [serviceQuery findObjects:&error];
                
                if (error){
                    
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.refreshQueue refresh];
                    return  NO;
                } else{
                    for (SCHService *service in services) {
                        NSDictionary *availabilityRefresh = @{@"startTime" : appointment.proposedStartTime,
                                                              @"endTime" : appointment.proposedEndTime,
                                                              @"timeBlocks" : releasedBlocks,
                                                              @"user" : appointment.serviceProvider,
                                                              @"service" : service};
                        
                        [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                    }
                }
                
                

            }
            
            // set appointment status to cancelled
            appointment.status = constants.SCHappointmentStatusCancelled;
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
            
            
            //create Activity for appointment Cancellation
            
            if (appointment.client){
                deleteActivity = [self activityChangeForAppointmentCancellation:appointment];
                if (!deleteActivity){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                    return NO;
                    
                }
                
                [appDelegate.backgroundCommit.objectsStagedForUnpin addObject:deleteActivity];
                [appDelegate.backgroundCommit.objectsStagedForSave addObject:deleteActivity];
                
                success = [self removeOldNotifications:appointment.objectId];
            }
            
            
            if (success && refresh){
                success = ([SCHAvailabilityManager refreshAvailabilitiesForAppointment] && [SCHAvailabilityManager refreshNetAvailabilities]);
                [appDelegate.refreshQueue refresh];
            }
            
            
            if (success && save){
                success = [self commit];
            }
            if (success && appointment.client){
                [self createNotificationForAppointmentActivity:deleteActivity];
            } else if (success && appointment.nonUserClient){
                //send email or text
            }
            
            if (!success){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
            } else {
                if (save){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                }
            }


            return success;
            
        } else {
            //This appointment has never been confirmed
            
            //free soft allocated time blocks
            
            NSArray *releasedBlocks = [self releaseTimeBlcoksFrom:appointment.startTime
                                                           toTime:appointment.endTime
                                                   forAppointment:appointment
                                                           ofUser:appointment.serviceProvider];
            
            if (!releasedBlocks){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                return NO;
            } else{
                
                //change availability picture
                NSError *error = nil;
                PFQuery *serviceQuery = [SCHService query];
                [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                NSArray *services = [serviceQuery findObjects:&error];
                
                if (error){
                    
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.refreshQueue refresh];
                    return  NO;
                } else{
                    for (SCHService *service in services) {
                        NSDictionary *availabilityRefresh = @{@"startTime" : appointment.startTime,
                                                              @"endTime" : appointment.endTime,
                                                              @"timeBlocks" : releasedBlocks,
                                                              @"user" : appointment.serviceProvider,
                                                              @"service" : service};
                        
                        [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                    }
                }

                


                
            }
            
            // set appointment status to cancelled
            appointment.status = constants.SCHappointmentStatusCancelled;
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
            
            
            //create Activity for appointment Cancellation
            if (appointment.client){
                deleteActivity = [self activityChangeForAppointmentCancellation:appointment];
                if (!deleteActivity){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                    return NO;
                    
                }
                
                [appDelegate.backgroundCommit.objectsStagedForUnpin addObject:deleteActivity];
                [appDelegate.backgroundCommit.objectsStagedForSave addObject:deleteActivity];
                
                success = [self removeOldNotifications:appointment.objectId];
            }
            
            
            
            if (success && refresh){
                success = ([SCHAvailabilityManager refreshAvailabilitiesForAppointment] && [SCHAvailabilityManager refreshNetAvailabilities]);
                [appDelegate.refreshQueue refresh];
            }
            
            if (success && save){
                success = [self commit];
            }
            if (success && appointment.client){
                [self createNotificationForAppointmentActivity:deleteActivity];
            } else if (success && appointment.nonUserClient){
                // send email or text
            }
            
            if (!success){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
            } else {
                if (save){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                }
            }

            
            
            
            return success;
        }
        
    }
    
    
}

+(BOOL) releaseConfirmedTimeForAppointment:(SCHAppointment *) appointment refreshSchedule:(BOOL) refresh save:(BOOL) save{
    
    BOOL success = YES;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
    
    if (save && refresh){
        [appDelegate.backgroundCommit refreshQueues];
        [appDelegate.backgroundCommit refrshStagedQueue];
        [appDelegate.refreshQueue refresh];
    }
    
    if (appointment.startTime && appointment.endTime && appointment.proposedStartTime && appointment.proposedEndTime && [appointment.status isEqual: constants.SCHappointmentStatusPending] && !appointment.expired) {
        // free confirmed timeblocks
        NSArray *freedTimeblocks = [self freeConfirmedTimeBlockFrom:appointment.startTime
                                                             toTime:appointment.endTime
                                                     forAppointment:appointment
                                                             ofUser:appointment.serviceProvider];
        
        if (!freedTimeblocks){
            [appDelegate.backgroundCommit refreshQueues];
            [appDelegate.backgroundCommit refrshStagedQueue];
            return NO;
        } else {
            
            //change availability picture
            NSError *error = nil;
            PFQuery *serviceQuery = [SCHService query];
            [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
            NSArray *services = [serviceQuery findObjects:&error];
            
            if (error){
                
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.refreshQueue refresh];
                return  NO;
            } else{
                for (SCHService *service in services) {
                    NSDictionary *availabilityRefresh = @{@"startTime" : appointment.startTime,
                                                          @"endTime" : appointment.endTime,
                                                          @"timeBlocks" : freedTimeblocks,
                                                          @"user" : appointment.serviceProvider,
                                                          @"service" : service};
                    
                    [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                }
            }
            

            
        }
        
        // setappointment time
        NSDate *startTime = appointment.proposedStartTime;
        NSDate *endTime = appointment.proposedEndTime;
        appointment.startTime = startTime;
        appointment.endTime = endTime;
        appointment.proposedStartTime = nil;
        appointment.proposedEndTime = nil;
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
        
        if (success && refresh){
            success = ([SCHAvailabilityManager refreshAvailabilitiesForAppointment] && [SCHAvailabilityManager refreshNetAvailabilities]);
            [appDelegate.refreshQueue refresh];
        }
        
        if (success && save){
            success = [self commit];
        }
        
        if (!success){
            [appDelegate.backgroundCommit refreshQueues];
            [appDelegate.backgroundCommit refrshStagedQueue];
            [appDelegate.refreshQueue refresh];
        } else {
            if (save){
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                [appDelegate.refreshQueue refresh];
            }
        }
        
    }
    
    return success;
}



+(BOOL)appointmentChangeRequest:(SCHAppointment *) appointment proposedStartTime:(NSDate *) proposedStartTime proposedEndTime:(NSDate *) proposedEndTime proposedLocation:(NSString *) proposedLocation locationPoint:(PFGeoPoint *) locationPoint note:(NSString *) note {
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    [appDelegate.refreshQueue refresh];
    SCHConstants *constants = [SCHConstants sharedManager];
    SCHAppointmentActivity *respondToAppointmentChange = nil;
    BOOL success = YES;

    
   // NSLog(@"appointment: %@", appointment);
    
    
    if ([appointment.status isEqual:constants.SCHappointmentStatusCancelled] || appointment.expired){
        return NO;
    }
    
    if (note.length > 0){
        NSMutableString *noteText = [[NSMutableString alloc] init];
        
        if (appointment.note){
            [noteText appendString:appointment.note];
            [noteText appendString:@"\n"];
        }
        
        NSString *displayName = appDelegate.user.preferredName;
        [noteText  appendString:[NSString stringWithFormat:@"%@:", displayName]];
        [noteText appendString:@"\n"];
        [noteText appendString:note];
        appointment.note = noteText;
        
        
    }
    
    //check if there is any appointment exists for service provider
    
    
    
    if (proposedStartTime && proposedEndTime){
        

        
        if ([self timeConflictExistsForClient:appointment.client
                                nonUserClient:appointment.nonUserClient
                              serviceProvider:appointment.serviceProvider
                                    startTime:proposedStartTime
                                      endTime:proposedEndTime
                           excludeAppointment:appointment]){
            
            //showAlert
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Conflicts with other appointments. Please find another time slot", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            });
            
            return NO;
            
            
        }
        

        
    }
    
    //determine autoconfirm
    
    
    BOOL autoConfirm = NO;
    if (appointment.client){
        if ([appDelegate.user isEqual:appointment.client]){
            //Get time blocks
            NSPredicate *timeBlocksPredicate = nil;
            NSDate *autoConfirmTBStartTime = nil;
            NSDate *autoConfirmTBEndTime = nil;
            NSString *autoConfirmLocation = nil;
            
            //Get the time block start time and end time for predicate
            
            if ([appointment.status isEqual:constants.SCHappointmentStatusConfirmed]){
                if (!proposedStartTime && !proposedEndTime && appointment.location){
                    //this appointment is confirmed and only location  change is requested by client
                    autoConfirmTBStartTime = appointment.startTime;
                    autoConfirmTBEndTime = appointment.endTime;
                    autoConfirmLocation = proposedLocation;
                } else{
                    autoConfirmTBStartTime = proposedStartTime;
                    autoConfirmTBEndTime =proposedEndTime;
                    autoConfirmLocation = (proposedLocation) ? proposedLocation: appointment.location;
                    
                }
            } else if ([appointment.status isEqual:constants.SCHappointmentStatusPending]){
                
                if (proposedLocation){
                    autoConfirmLocation = proposedLocation;
                }else{
                    autoConfirmLocation = (appointment.proposedLocation) ? appointment.proposedLocation : appointment.location;
                }
                
                // Determine final start Time and End Time
                
                if (proposedStartTime && proposedEndTime){
                    autoConfirmTBStartTime = proposedStartTime;
                    autoConfirmTBEndTime = proposedEndTime;
                    
                } else if (appointment.proposedStartTime && appointment.proposedEndTime){
                    autoConfirmTBStartTime = appointment.proposedStartTime;
                    autoConfirmTBEndTime = appointment.proposedEndTime;
                    
                } else{
                    autoConfirmTBStartTime = appointment.startTime;
                    autoConfirmTBEndTime= appointment.endTime;
                }
                

            }
            
            if (autoConfirmTBStartTime && autoConfirmTBEndTime && autoConfirmLocation){
                timeBlocksPredicate = [NSPredicate predicateWithFormat:@"startTime >= %@ AND endTime <= %@ AND user = %@", autoConfirmTBStartTime, autoConfirmTBEndTime,appointment.serviceProvider];
                PFQuery *timeBlocksQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeBlocksPredicate];
                NSArray *timeblocks = [timeBlocksQuery findObjects];
                NSInteger timeblocksrequired = [autoConfirmTBEndTime timeIntervalSinceDate:autoConfirmTBStartTime]/SCHTimeBlockDuration;
                
                if (timeblocks.count == timeblocksrequired){
                    autoConfirm = [self autoConfirmAppointment:appointment.service
                                                        client:appointment.client
                                                    timeBlocks:timeblocks
                                                      location:autoConfirmLocation
                                                    appointment:appointment];
                    
                } else{
                    autoConfirm = NO;
                }

                
            } else {
                autoConfirm = NO;
            }
            
        }
        
    }
    
    
    
    
    
    if (appointment.status == constants.SCHappointmentStatusConfirmed){
        

        
        //This is confirmed appointment being changed
        if (proposedLocation && proposedStartTime == NULL && proposedEndTime == NULL){
            // Just location change. No need to change time blocks.
            //update appointment
            
            if (appointment.client && !autoConfirm){
                appointment.proposedLocation = proposedLocation;
                appointment.status = constants.SCHappointmentStatusPending;
                
            } else{
                appointment.location = proposedLocation;
                appointment.status = constants.SCHappointmentStatusConfirmed;
            }

            

            
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
            

            
            //Update activity
            
            if (appointment.client){
                respondToAppointmentChange = [self activityChangeForAppointmentChangeRequest:appointment];
                
                if (!respondToAppointmentChange){
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    success = NO;
                }
            }
            
            
        } else if (proposedStartTime || proposedEndTime){
           
            
            if (appointment.client && !autoConfirm){
                // reserve timeBlock
                
                NSArray *reservedBlocks =[self reserveTimeBlocksForChangeRequest:appointment
                                                                        location:(proposedLocation == NULL ? appointment.location : proposedLocation)
                                                                   locationPoint:locationPoint
                                                                        timeFrom:proposedStartTime
                                                                          timeTo:proposedEndTime];
                if (reservedBlocks.count == 0 ){
                    success = NO;
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    return NO;
                } else {
                    
                    //change availability picture
                    NSError *error = nil;
                    PFQuery *serviceQuery = [SCHService query];
                    [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                    NSArray *services = [serviceQuery findObjects:&error];
                    
                    if (error){
                        
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.refreshQueue refresh];
                        return  NO;
                    } else{
                        for (SCHService *service in services) {
                            NSDictionary *availabilityRefresh = @{@"startTime" : proposedStartTime,
                                                                  @"endTime" : proposedEndTime,
                                                                  @"timeBlocks" : reservedBlocks,
                                                                  @"user" : appointment.serviceProvider,
                                                                  @"service" : service};
                            
                            [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                        }
                    }
                    

                    
                }
                //update appointment
                
                appointment.status = constants.SCHappointmentStatusPending;
                appointment.expired = NO;
                appointment.proposedStartTime = proposedStartTime;
                appointment.proposedEndTime = proposedEndTime;
                if (proposedLocation){
                    appointment.proposedLocation = proposedLocation;
                }
                [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];

                //Update activity
                respondToAppointmentChange = [self activityChangeForAppointmentChangeRequest:appointment];
                if (!respondToAppointmentChange){
                        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        [appDelegate.refreshQueue refresh];
                        success = NO;
                }
                

                
            } else{
                //non User Client or auto confirm
                
                
                
                //free confirmed timeblock
                NSArray *freedTimeBlocks = [self freeConfirmedTimeBlockFrom:appointment.startTime
                                                                     toTime:appointment.endTime
                                                             forAppointment:appointment
                                                                     ofUser:appointment.serviceProvider];
                
                
                if (freedTimeBlocks.count == 0){
                    success = NO;
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    return NO;
                } else {
                    
                    //change availability picture
                    NSError *error = nil;
                    PFQuery *serviceQuery = [SCHService query];
                    [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                    NSArray *services = [serviceQuery findObjects:&error];
                    
                    if (error){
                        
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.refreshQueue refresh];
                        return  NO;
                    } else{
                        for (SCHService *service in services) {
                            NSDictionary *availabilityRefresh = @{@"startTime" : appointment.startTime,
                                                                  @"endTime" : appointment.endTime,
                                                                  @"timeBlocks" : freedTimeBlocks,
                                                                  @"user" : appointment.serviceProvider,
                                                                  @"service" : service};
                            
                            [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                        }
                    }

                    
                }
                
                //Get timeblocks for appointment
                NSArray *timeblocks = [self getAvailableTimeBlocksForAppointmentWithStartTime:proposedStartTime
                                                                                      endTime:proposedEndTime
                                                                                      service:appointment.service
                                                                                     location:(proposedLocation) ? proposedLocation : appointment.location
                                                                                locationPoint:locationPoint
                                                                              serviceProvider:appointment.serviceProvider
                                                                                  appointment:appointment];
                
                
                //If timeblocks are less than required number of appointment then return no
                NSInteger timeblocksrequired = [proposedEndTime timeIntervalSinceDate:proposedStartTime]/SCHTimeBlockDuration;
                if (timeblocks.count != timeblocksrequired){
                    success = NO;
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    return NO;
                }
                
                
                
                // allocate current timeblick
                NSString *ATBAllocation =[self allocateTimeBlockOfUser:appointment.serviceProvider fromTime:proposedStartTime toTime:proposedEndTime appointment:appointment];
                
                // server not reachable
                if ([ATBAllocation isEqualToString:SCHNotAbleToReachServer]){
                    success = NO;
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    return NO;
                }
                // timeblock couldn't be allocated to appointment
                if ([ATBAllocation isEqualToString:SCHATBConfirmedToOtherAppointment] || [ATBAllocation isEqualToString:SCHATBNotAllocatedToAppointment]){
                    
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Conflicts with other appointments. Please find another time slot", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                        });
                    success = NO;
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    return NO;
                }
                
               //now set status
                //update appointment
                
                appointment.status = constants.SCHappointmentStatusConfirmed;
                appointment.expired = NO;
                appointment.startTime = proposedStartTime;
                appointment.endTime = proposedEndTime;
                if (proposedLocation){
                    appointment.location = proposedLocation;
                }
                [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
                
                if (appointment.client){
                    //Update activity
                    respondToAppointmentChange = [self activityChangeForAppointmentChangeRequest:appointment];
                    if (!respondToAppointmentChange){
                        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        [appDelegate.refreshQueue refresh];
                        success = NO;
                    }
                }

            }
            
            
        }
        
    } else if (appointment.status == constants.SCHappointmentStatusPending){
        if ([appointment.client isEqual:appDelegate.user] && autoConfirm){
            //insert auto confirm logic
            //Determine final location
            NSString *finalLocation = nil;
            NSDate *finalStartTime = nil;
            NSDate *finalEndTime = nil;
            
            //Final Location
            
            if (proposedLocation){
                finalLocation = proposedLocation;
            }else{
                finalLocation = (appointment.proposedLocation) ? appointment.proposedLocation : appointment.location;
            }
            
            // Determine final start Time and End Time
            
            if (proposedStartTime && proposedEndTime){
                finalStartTime = proposedStartTime;
                finalEndTime = proposedEndTime;
                
            } else if (appointment.proposedStartTime && appointment.proposedEndTime){
                finalStartTime = appointment.proposedStartTime;
                finalEndTime = appointment.proposedEndTime;
            
            } else{
                finalStartTime = appointment.startTime;
                finalEndTime = appointment.endTime;
            }
            
            // Free and release soft allocation from time blocks
            
            if (appointment.proposedStartTime && appointment.proposedEndTime){
                // Release soft allocation from proposed time blocks
                NSArray *releasedBlocks =[self releaseTimeBlcoksFrom:appointment.proposedStartTime
                                                              toTime:appointment.proposedEndTime
                                                      forAppointment:appointment
                                                              ofUser:appointment.serviceProvider];
                
                if (releasedBlocks == 0){
                    success = NO;
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    return NO;
                    
                } else {
                    
                    //change availability picture
                    NSError *error = nil;
                    PFQuery *serviceQuery = [SCHService query];
                    [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                    NSArray *services = [serviceQuery findObjects:&error];
                    
                    if (error){
                        
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.refreshQueue refresh];
                        return  NO;
                    } else{
                        for (SCHService *service in services) {
                            NSDictionary *availabilityRefresh = @{@"startTime" : appointment.proposedStartTime,
                                                                  @"endTime" : appointment.proposedEndTime,
                                                                  @"timeBlocks" : releasedBlocks,
                                                                  @"user" : appointment.serviceProvider,
                                                                  @"service" : service};
                            
                            [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                        }
                    }
                    
                    

                }

                //free confirmed timeblock
                NSArray *freedTimeBlocks = [self freeConfirmedTimeBlockFrom:appointment.startTime
                                                                     toTime:appointment.endTime
                                                             forAppointment:appointment
                                                                     ofUser:appointment.serviceProvider];
                
                
                if (freedTimeBlocks.count == 0){
                    success = NO;
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    return NO;
                } else {
                    //change availability picture
                    NSError *error = nil;
                    PFQuery *serviceQuery = [SCHService query];
                    [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                    NSArray *services = [serviceQuery findObjects:&error];
                    
                    if (error){
                        
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.refreshQueue refresh];
                        return  NO;
                    } else{
                        for (SCHService *service in services) {
                            NSDictionary *availabilityRefresh = @{@"startTime" : appointment.startTime,
                                                                  @"endTime" : appointment.endTime,
                                                                  @"timeBlocks" : freedTimeBlocks,
                                                                  @"user" : appointment.serviceProvider,
                                                                  @"service" : service};
                            
                            [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                        }
                    }
                    

                    
                }
                
            } else {
                // Release soft allocation from proposed time blocks
                
                
                
                NSArray *releasedBlocks =[self freeConfirmedTimeBlockFrom:appointment.startTime
                                                                   toTime:appointment.endTime
                                                           forAppointment:appointment
                                                                   ofUser:appointment.serviceProvider];
                
                if (releasedBlocks == 0){
                    success = NO;
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    return NO;
                    
                } else {
                    
                    //change availability picture
                    NSError *error = nil;
                    PFQuery *serviceQuery = [SCHService query];
                    [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                    NSArray *services = [serviceQuery findObjects:&error];
                    
                    if (error){
                        
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.refreshQueue refresh];
                        return  NO;
                    } else{
                        for (SCHService *service in services) {
                            NSDictionary *availabilityRefresh = @{@"startTime" : appointment.startTime,
                                                                  @"endTime" : appointment.endTime,
                                                                  @"timeBlocks" : releasedBlocks,
                                                                  @"user" : appointment.serviceProvider,
                                                                  @"service" : service};
                            
                            [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                        }
                    }

                    

                }

                
            }
            
            // Allocate time to appointment
            //Get timeblocks for appointment
            NSArray *timeblocks = [self getAvailableTimeBlocksForAppointmentWithStartTime:finalStartTime
                                                                                  endTime:finalEndTime
                                                                                  service:appointment.service
                                                                                 location:finalLocation
                                                                            locationPoint:locationPoint
                                                                          serviceProvider:appointment.serviceProvider
                                                                              appointment:appointment];
            
            
            //If timeblocks are less than required number of appointment then return no
            NSInteger timeblocksrequired = [finalEndTime timeIntervalSinceDate:finalStartTime]/SCHTimeBlockDuration;
            if (timeblocks.count != timeblocksrequired){
                success = NO;
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                return NO;
            }
            
            
            
            // allocate current timeblick
            NSString *ATBAllocation =[self allocateTimeBlockOfUser:appointment.serviceProvider fromTime:finalStartTime toTime:finalEndTime appointment:appointment];
            
            // server not reachable
            if ([ATBAllocation isEqualToString:SCHNotAbleToReachServer]){
                success = NO;
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                return NO;
            }
            // timeblock couldn't be allocated to appointment
            if ([ATBAllocation isEqualToString:SCHATBConfirmedToOtherAppointment] || [ATBAllocation isEqualToString:SCHATBNotAllocatedToAppointment]){
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Conflicts with other appointments. Please find another time slot", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                });
                success = NO;
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                return NO;
            }
            
            
            //update appointment
            
            appointment.status = constants.SCHappointmentStatusConfirmed;
            appointment.expired = NO;
            appointment.startTime = finalStartTime;
            appointment.endTime = finalEndTime;
            appointment.location = finalLocation;
            appointment.proposedStartTime = nil;
            appointment.proposedEndTime = nil;
            appointment.proposedLocation = nil;
            
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
            
            if (appointment.client){
                //Update activity
                respondToAppointmentChange = [self activityChangeForAppointmentChangeRequest:appointment];
                if (!respondToAppointmentChange){
                    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    [appDelegate.backgroundCommit refreshQueues];
                    [appDelegate.backgroundCommit refrshStagedQueue];
                    [appDelegate.refreshQueue refresh];
                    success = NO;
                }
            }
            
            
        } else {
            //check proposed time and location are null
            if (appointment.proposedStartTime == NULL && appointment.proposedEndTime == NULL && appointment.proposedLocation == NULL){
                
               // NSLog(@"About to release timeblock");
                
                //Never confirmed appointment being changed
                // There can be two situations 1) only location change or 2) time adn/or location change.
                
                
                if (proposedLocation && proposedStartTime == NULL && proposedEndTime == NULL){
                    //only location changed
                    appointment.location = proposedLocation;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
                    [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
                    
                    
                    
                    //Update activity
                    
                    if (appointment.client){
                        respondToAppointmentChange = [self activityChangeForAppointmentChangeRequest:appointment];
                        
                        if (!respondToAppointmentChange){
                            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                            [appDelegate.backgroundCommit refreshQueues];
                            [appDelegate.backgroundCommit refrshStagedQueue];
                            
                            success = NO;
                        }
                    }
                    
                    
                    
                    
                } else if (proposedStartTime || proposedEndTime){
                    //time and/or location change.
                    
                    
                    
                    NSArray *releasedBlocks =[self releaseTimeBlcoksFrom:appointment.startTime
                                                                  toTime:appointment.endTime
                                                          forAppointment:appointment
                                                                  ofUser:appointment.serviceProvider];
                    
                    if (releasedBlocks == 0){
                        success = NO;
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        return NO;
                        
                    } else {
                        
                        //change availability picture
                        NSError *error = nil;
                        PFQuery *serviceQuery = [SCHService query];
                        [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                        NSArray *services = [serviceQuery findObjects:&error];
                        
                        if (error){
                            
                            [appDelegate.backgroundCommit refrshStagedQueue];
                            [appDelegate.backgroundCommit refreshQueues];
                            [appDelegate.refreshQueue refresh];
                            return  NO;
                        } else{
                            for (SCHService *service in services) {
                                NSDictionary *availabilityRefresh = @{@"startTime" : appointment.startTime,
                                                                      @"endTime" : appointment.endTime,
                                                                      @"timeBlocks" : releasedBlocks,
                                                                      @"user" : appointment.serviceProvider,
                                                                      @"service" : service};
                                
                                [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                            }
                        }
                        
                        

                    }
                    
                    
                    
                    NSArray *reservedBlocks = [self reserveTimeBlocksForChangeRequest:appointment
                                                                             location:(proposedLocation == NULL ? appointment.location : proposedLocation)
                                                                        locationPoint:locationPoint
                                                                             timeFrom:proposedStartTime
                                                                               timeTo:proposedEndTime];
                    if (!(reservedBlocks.count > 0)){
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        [appDelegate.refreshQueue refresh];
                        return NO;
                    } else {
                        
                        //change availability picture
                        NSError *error = nil;
                        PFQuery *serviceQuery = [SCHService query];
                        [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                        NSArray *services = [serviceQuery findObjects:&error];
                        
                        if (error){
                            
                            [appDelegate.backgroundCommit refrshStagedQueue];
                            [appDelegate.backgroundCommit refreshQueues];
                            [appDelegate.refreshQueue refresh];
                            return  NO;
                        } else{
                            for (SCHService *service in services) {
                                NSDictionary *availabilityRefresh = @{@"startTime" : proposedStartTime,
                                                                      @"endTime" : proposedEndTime,
                                                                      @"timeBlocks" : reservedBlocks,
                                                                      @"user" : appointment.serviceProvider,
                                                                      @"service" : service};
                                
                                [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                            }
                        }
                        
                        

                    }
                    
                    // update appointment
                    appointment.startTime = proposedStartTime;
                    appointment.endTime = proposedEndTime;
                    appointment.expired = NO;
                    appointment.location = (proposedLocation != NULL ? proposedLocation : appointment.location) ;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
                    [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
                    
                    
                    
                    //Update activity
                    
                    if (appointment.client){
                        respondToAppointmentChange = [self activityChangeForAppointmentChangeRequest:appointment];
                        
                        if (!respondToAppointmentChange){
                            [appDelegate.backgroundCommit refreshQueues];
                            [appDelegate.backgroundCommit refrshStagedQueue];
                            [appDelegate.refreshQueue refresh];
                            success = NO;
                        }
                    }
                    
                    
                    
                }
                
                
            } else if (appointment.proposedLocation || appointment.proposedStartTime || appointment.proposedEndTime){
                // appointment is confirmed before and changes to pending change is requested
                
                // There can be two situations 1) only location change or 2) time adn/or location change.
                
                
                if (proposedLocation && proposedStartTime == NULL && proposedEndTime == NULL){
                    //only location changed
                    appointment.proposedLocation = proposedLocation;
                    appointment.status = (appointment.client) ?constants.SCHappointmentStatusPending : constants.SCHappointmentStatusConfirmed;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
                    [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
                    
                    
                    
                    //Update activity
                    
                    if (appointment.client){
                        respondToAppointmentChange = [self activityChangeForAppointmentChangeRequest:appointment];
                        
                        if (!respondToAppointmentChange){
                            
                            success = NO;
                        }
                    }
                    
                    
                    
                    
                } else if (proposedStartTime || proposedEndTime){
                    //time and/or location change.
                    
                  //  NSLog(@"About to release timeblock");
                    
                    if (appointment.proposedStartTime&& appointment.proposedEndTime){
                        
                        
                        NSArray *releasedBlocks = [self releaseTimeBlcoksFrom:appointment.proposedStartTime
                                                                       toTime:appointment.proposedEndTime
                                                               forAppointment:appointment
                                                                       ofUser:appointment.serviceProvider];
                        
                        if (!releasedBlocks){
                            success = NO;
                            [appDelegate.backgroundCommit refreshQueues];
                            [appDelegate.backgroundCommit refrshStagedQueue];
                            return NO;
                            
                        } else{
                            
                            //change availability picture
                            NSError *error = nil;
                            PFQuery *serviceQuery = [SCHService query];
                            [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                            NSArray *services = [serviceQuery findObjects:&error];
                            
                            if (error){
                                
                                [appDelegate.backgroundCommit refrshStagedQueue];
                                [appDelegate.backgroundCommit refreshQueues];
                                [appDelegate.refreshQueue refresh];
                                return  NO;
                            } else{
                                for (SCHService *service in services) {
                                    NSDictionary *availabilityRefresh = @{@"startTime" : appointment.proposedStartTime,
                                                                          @"endTime" : appointment.proposedEndTime,
                                                                          @"timeBlocks" : releasedBlocks,
                                                                          @"user" : appointment.serviceProvider,
                                                                          @"service" : service};
                                    
                                    [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                                }
                            }
                            
                            

                            
                        }
                        
                        
                    }
                    
                    
                    
                    NSArray *reservedBlocks = [self reserveTimeBlocksForChangeRequest:appointment
                                                                             location:(proposedLocation == NULL ? appointment.location : proposedLocation)
                                                                        locationPoint:locationPoint
                                                                             timeFrom:proposedStartTime
                                                                               timeTo:proposedEndTime];
                    
                    if (reservedBlocks.count == 0){
                        success = NO;
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        [appDelegate.refreshQueue refresh];
                        return NO;
                        
                    } else {
                        
                        //change availability picture
                        NSError *error = nil;
                        PFQuery *serviceQuery = [SCHService query];
                        [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
                        NSArray *services = [serviceQuery findObjects:&error];
                        
                        if (error){
                            
                            [appDelegate.backgroundCommit refrshStagedQueue];
                            [appDelegate.backgroundCommit refreshQueues];
                            [appDelegate.refreshQueue refresh];
                            return  NO;
                        } else{
                            for (SCHService *service in services) {
                                NSDictionary *availabilityRefresh = @{@"startTime" : proposedStartTime,
                                                                      @"endTime" : proposedEndTime,
                                                                      @"timeBlocks" : reservedBlocks,
                                                                      @"user" : appointment.serviceProvider,
                                                                      @"service" : service};
                                
                                [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                            }
                        }
                        
                        

                    }
                    
                    // update appointment
                    appointment.proposedStartTime = proposedStartTime;
                    appointment.proposedEndTime = proposedEndTime;
                    appointment.status = (appointment.client) ?constants.SCHappointmentStatusPending : constants.SCHappointmentStatusConfirmed;
                    appointment.expired = NO;
                    appointment.proposedLocation = (proposedLocation != NULL ? proposedLocation : appointment.proposedLocation) ;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
                    [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
                    
                    
                    
                    //Update activity
                    
                    if (appointment.client){
                        respondToAppointmentChange = [self activityChangeForAppointmentChangeRequest:appointment];
                        
                        if (!respondToAppointmentChange){
                            [appDelegate.backgroundCommit refreshQueues];
                            [appDelegate.backgroundCommit refrshStagedQueue];
                            [appDelegate.refreshQueue refresh];
                            success = NO;
                        }
                    }
                    
                    
                }
                
            }
            
        }
        
        
 
    }
    if (success){
        
        if (appointment.client){
            success = [self removeOldNotifications:appointment.objectId];
        }
        
        
        
        
        if (success){
            success = ([SCHAvailabilityManager refreshAvailabilitiesForAppointment] && [SCHAvailabilityManager refreshNetAvailabilities]);
            [appDelegate.refreshQueue refresh];
            
        }
        
        
        if (success){
            success = [self commit];
        }
        if (success && appointment.client){
            [self createNotificationForAppointmentActivity:respondToAppointmentChange];
        }else if  (success && appointment.nonUserClient){
            //send email or text
        }
        
        
        
    }
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    [appDelegate.refreshQueue refresh];
    
    if (proposedLocation){
        [SCHUtility createUserLocation:proposedLocation];
    }
    
    
    
    return success;
}



#pragma mark - Helpers


+(BOOL)timeConflictExistsForClient:(SCHUser *) client nonUserClient:(SCHNonUserClient *)nonUserClient serviceProvider:(SCHUser *) serviceProvider startTime:(NSDate *) timeFrom endTime:(NSDate *) timeTo excludeAppointment:(SCHAppointment *) appointment{
    
    BOOL exists = NO;
    NSError *error = nil;
    // Get all time blocks between start time and end time
    NSPredicate *timeBlocksPredicate = [NSPredicate predicateWithFormat:@"startTime >= %@ AND endTime <= %@ AND user = %@", timeFrom, timeTo,serviceProvider];
    PFQuery *timeBlocksQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeBlocksPredicate];
    [timeBlocksQuery includeKey:@"appointment"];
    [timeBlocksQuery includeKey:@"requestedAppointments"];
    
    NSArray *timeBlocks = [timeBlocksQuery findObjects:&error];
    
    if (error){
        return YES;
    }
    
    if (timeBlocks.count == 0){
        return  exists;
    }
    
    NSMutableSet *confirmedAppointmentSet = [[NSMutableSet alloc] init];
    NSMutableSet *pendingAppintmentSet = [[NSMutableSet alloc] init];
    
    for (SCHAvailableTimeBlock *tb in timeBlocks){
        if (tb.appointment){
            [confirmedAppointmentSet addObject:tb.appointment];
        }
        NSArray *requestedAppintments = nil;
    
        if (tb.requestedAppointments){
            requestedAppintments = tb.requestedAppointments;
        }
        if (requestedAppintments){
            [pendingAppintmentSet addObjectsFromArray:requestedAppintments];
        }
        
            
    }
    // Exclude appointments if exists
    if (appointment){
        [confirmedAppointmentSet removeObject:appointment];
        [pendingAppintmentSet removeObject:appointment];
    }
    // If there is confirmed appointment then return YES
    
    if (confirmedAppointmentSet.count > 0){
        return YES;
    }
    
    //If there is a pending appointment for same client, service Provider then  return yes.
    NSPredicate *samePartyPredicate = [NSPredicate predicateWithBlock:^BOOL(SCHAppointment *appointment, NSDictionary<NSString *,id> * _Nullable bindings) {
        if ([appointment.serviceProvider isEqual:serviceProvider] ){
            if (client && appointment.client){
                if ([client isEqual:appointment.client]){
                    return YES;
                }else return NO;
            } else if (nonUserClient && appointment.nonUserClient){
                if ([nonUserClient isEqual:appointment.nonUserClient]){
                    return YES;
                } else return  NO;
            } else return NO;
            
            
        } else return NO;
    }];
    
    NSArray *samePartyArray = [[pendingAppintmentSet filteredSetUsingPredicate:samePartyPredicate] allObjects];
    
    if (samePartyArray.count > 0){
        return  YES;
    } else return exists;
}


//Gives available timeblocks for which appointment will be created
    
+(NSArray *)getAvailableTimeBlocksForAppointmentWithStartTime:(NSDate *) timeFrom endTime:(NSDate *) timeTo service:(SCHService *) service location:(NSString *)location locationPoint:(PFGeoPoint *) locationPoint serviceProvider:(SCHUser *) serviceProvider appointment:(SCHAppointment *) appointment{
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
      //  NSLog(@"Processing get Time Block");
       // NSLog (@"Start Time: %@ - End Time: %@", timeFrom, timeTo);
      //  NSLog(@"appointment: %@", appointment);
        
        
        
        NSError *error;
        
        
        
        NSMutableArray *timeBlocksForAppointment = [[NSMutableArray alloc] init];
        int numberofTimeBlocksRequired = [timeTo timeIntervalSinceDate:timeFrom]/SCHTimeBlockDuration;
       // NSLog(@"Number of TimeBlocks required: %d", numberofTimeBlocksRequired);
        
        
        
        // Get all timeblocks from starttime to end time.
        NSPredicate *timeBlockNotAvailableQueryPredicate = [NSPredicate predicateWithFormat:@"startTime >= %@ AND endTime <= %@ AND user = %@", timeFrom, timeTo,serviceProvider];
        PFQuery *timeBlockeQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeBlockNotAvailableQueryPredicate];
        
        NSMutableArray *timeBlocks = [[NSMutableArray alloc] initWithArray:[timeBlockeQuery findObjects:&error]];
        
        if (error){
            [timeBlocksForAppointment removeAllObjects];
            return timeBlocksForAppointment;
        }
        
       // NSLog(@"Number of TimeBlocks found: %lu", (unsigned long)timeBlocks.count);
        
        
        
        NSPredicate *filterUnavailableTimeBlock = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *timeBlock, NSDictionary *bindings) {
            if (timeBlock.appointment){
                if (appointment){
                    if ([timeBlock.appointment isEqual:appointment]){
                        return NO;
                    } else return YES;
                } else return YES;
            } else return NO;
        }];
        NSSet *unavailableTimeBlock = [[NSSet setWithArray:timeBlocks] filteredSetUsingPredicate:filterUnavailableTimeBlock];
        
     //   NSLog(@"Number of TimeBlocks found: %lu", (unsigned long)unavailableTimeBlock.count);
        
        if (unavailableTimeBlock.count > 0){
            [timeBlocksForAppointment removeAllObjects];
            
            
            
            return timeBlocksForAppointment;
        }
        
        
        //Discard all timeblocks that does not have service
        
        NSMutableArray *timeBlocksWithDifferentService = [[NSMutableArray alloc] init];
        for (SCHAvailableTimeBlock *timeBlock in timeBlocks){
            if (![timeBlock.services containsObject:service]){
                //[timeBlocks removeObject:timeBlock];
                [timeBlocksWithDifferentService addObject:timeBlock];
            }
        }
        
        [timeBlocks removeObjectsInArray:timeBlocksWithDifferentService];
        
      //  NSLog(@"time block count after service removal: %lu", (unsigned long)timeBlocks.count);
        
        
        if ([timeBlocks count] < numberofTimeBlocksRequired && serviceProvider != appDelegate.user){
            [timeBlocksForAppointment removeAllObjects];
            
            return timeBlocksForAppointment;
            
        } else if ([timeBlocks count] < numberofTimeBlocksRequired && serviceProvider == appDelegate.user) {
            // create timeblocks
            //  [self createAvailableTimeWithService:service location:location timeFrom:timeFrom timeTo:timeTo];
            NSMutableArray *availabilityTime = [[NSMutableArray alloc] init];
            NSDictionary *availabilityBlock = @{@"startTime": timeFrom, @"endTime" : timeTo};
            [availabilityTime addObject:availabilityBlock];

            
            [SCHAvailabilityManager createAvailableTimeWithService:service
                                                          location:location
                                                    locationPoint:locationPoint
                                                  availabilityTime:availabilityTime
                                                         startDate:timeFrom
                                                           endDate:timeTo
                                             availableForNewRequest:NO];
            
            //get timeblocks from buffer
            NSPredicate *timeblocksForAppointmentPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                
                
                if ([evaluatedObject isKindOfClass:[SCHAvailableTimeBlock class]]){
                    SCHAvailableTimeBlock *tb = evaluatedObject;
                    
                    if ([tb.user isEqual:serviceProvider] &&[tb.services containsObject:service] && ([tb.startTime compare:timeFrom] == NSOrderedDescending || [tb.startTime compare:timeFrom] == NSOrderedSame) && ([tb.endTime compare:timeTo] == NSOrderedAscending || [tb.endTime compare:timeTo] == NSOrderedSame)){
                        return YES;
                    } else{
                        return NO;
                    }

                } else{
                    return NO;
                }
            }];
            
            
            
            
            
            
            NSArray *timeblocksinBuffer = [appDelegate.backgroundCommit.objectsStagedForSave filteredArrayUsingPredicate:timeblocksForAppointmentPredicate];
            [timeBlocks addObjectsFromArray:timeblocksinBuffer];
            
            NSSet *timeBlocksSet = [[NSSet alloc] initWithArray:timeBlocks];
            
            [timeBlocks removeAllObjects];
            [timeBlocks addObjectsFromArray:[timeBlocksSet allObjects]];
    
        }
    
    
    
    
        
        [timeBlocksForAppointment removeAllObjects];
        if (timeBlocks.count == numberofTimeBlocksRequired){
            
            [timeBlocksForAppointment addObjectsFromArray:timeBlocks];
            
            
        } else {
            NSPredicate *timeblocksForAppointment = [NSPredicate predicateWithFormat:@"startTime >= %@ AND endTime <= %@ AND user = %@ AND appointment = null" , timeFrom, timeTo,serviceProvider];
            
            PFQuery *availableTBQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeblocksForAppointment];
            [timeBlocksForAppointment addObjectsFromArray:[availableTBQuery findObjects:&error]];
            if (error){
                [timeBlocksForAppointment removeAllObjects];
                return timeBlocksForAppointment;
            }
            
        }
        
      //  NSLog(@"time Blocks for Appointment: %lu", (unsigned long)timeBlocksForAppointment.count);
        
        
        //reload table view
        //  [SCHUtility reloadScheduleTableView];
        
        return timeBlocksForAppointment;
    }
    
//Helper Program tha creates appointment
    
+(SCHAppointment *) createAppointmentRequestwithtimeBlocks:(NSArray *) timeBlocks serviceProvider:(SCHUser *) serviceProvider service:(SCHService *) service serviceType: (SCHServiceOffering *) serviceOffering client: (SCHUser *) client nonUserClient:(SCHNonUserClient *) nonUserClient clientName:(NSString *) clientName location:(NSString * ) location timeFrom:(NSDate *) timeFrom timeTo: (NSDate * )timeTo notes:(NSString *)notes appointmentSeries: (SCHAppointmentSeries *) series{
       /*
        
        NSLog(@"Creating Appointment");
        NSLog(@"timeblocks count = %lu", (unsigned long)timeBlocks.count);
        NSLog(@"timefrom: %@", timeFrom);
        NSLog(@"timeTo: %@", timeTo );
        NSLog(@"series: %@", series);
        
        */
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

        SCHConstants *constant = [SCHConstants sharedManager];
    
    //determine auto confirm
    BOOL autoConfirm = NO;
    if (client){
        if ([client isEqual:appDelegate.user]){
            autoConfirm = [self autoConfirmAppointment:service client:client timeBlocks:timeBlocks location:location appointment:nil];
        }
    }
        
        //create appointment
        SCHAppointment *appointment = [SCHAppointment object];
        
        
        BOOL expired = NO;
        BOOL isClientUser = YES;
        // set appointment attributes and save
    
        appointment.expired = expired;
        appointment.serviceProvider = serviceProvider;
        appointment.service = service;
        appointment.serviceOffering = serviceOffering;
    
    if (client && !autoConfirm){
        appointment.isClientUser = isClientUser;
        appointment.client = client;
        appointment.nonUserClient = nil;
        appointment.clientName = nil;
        appointment.status = constant.SCHappointmentStatusPending;
    } else if (nonUserClient){
        appointment.isClientUser = NO;
        appointment.client = nil;
        appointment.nonUserClient = nonUserClient;
        appointment.clientName = clientName;
        appointment.status = constant.SCHappointmentStatusConfirmed;
    } else if (client && autoConfirm){
        appointment.isClientUser = isClientUser;
        appointment.client = client;
        appointment.nonUserClient = nil;
        appointment.clientName = nil;
        appointment.status = constant.SCHappointmentStatusConfirmed;
    }
    
        appointment.location = location;
        appointment.startTime = timeFrom;
        appointment.endTime = timeTo;
    
        //notes
    if (notes.length > 0){
        NSMutableString *noteText = [[NSMutableString alloc] init];
        
        if (appointment.note){
            [noteText appendString:appointment.note];
            [noteText appendString:@"\n"];
        }
        
        NSString *displayName = appDelegate.user.preferredName;
        [noteText  appendString:[NSString stringWithFormat:@"%@:", displayName]];
        [noteText appendString:@"\n"];
        [noteText appendString:notes];
        appointment.note = noteText;
        
        
    }
    
        appointment.appointmentSeries = series;
       [SCHUtility setPublicAllRWACL:appointment.ACL];
    
       // NSLog(@"Appointment start time: %@ - endTime: %@", appointment.startTime, appointment.endTime);
        
        
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment];
        
        
        //Mark the time blocks for appointment request
    
    
    
    if (appointment.client && !autoConfirm){
        for (SCHAvailableTimeBlock *timeBlock in timeBlocks) {
            timeBlock.allocationRequested = YES;
            if (timeBlock.requestedAppointments){
                NSMutableArray *requestedAppointments = [[NSMutableArray alloc] initWithArray:timeBlock.requestedAppointments];
                [requestedAppointments addObject:appointment];
                timeBlock.requestedAppointments = requestedAppointments;
            } else timeBlock.requestedAppointments = @[appointment];
            
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:timeBlock];
            
            if (debug){
                NSLog(@"timeBlock: %@", timeBlock.objectId);
            }
        }
        
        
        //change availability picture
        NSError *error = nil;
        PFQuery *serviceQuery = [SCHService query];
        [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
        NSArray *services = [serviceQuery findObjects:&error];
        
        if (error){
            
            [appDelegate.backgroundCommit refrshStagedQueue];
            [appDelegate.backgroundCommit refreshQueues];
            [appDelegate.refreshQueue refresh];
            return  nil;
        } else{
            for (SCHService *service in services) {
                NSDictionary *availabilityRefresh = @{@"startTime" : timeFrom,
                                                      @"endTime" : timeTo,
                                                      @"timeBlocks" : timeBlocks,
                                                      @"user" : appointment.serviceProvider,
                                                      @"service" : service};
                
                [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
            }
        }
        

        
    } else {
        
        NSString *ATBAllocation =[self allocateTimeBlockOfUser:appointment.serviceProvider fromTime:appointment.startTime toTime:appointment.endTime appointment:appointment];

        // server not reachable
        if ([ATBAllocation isEqualToString:SCHNotAbleToReachServer]){
            
            appointment = nil;
    
        }
        // timeblock couldn't be allocated to appointment
        if ([ATBAllocation isEqualToString:SCHATBConfirmedToOtherAppointment] || [ATBAllocation isEqualToString:SCHATBNotAllocatedToAppointment]){
            appointment = nil;
            
        }
    }
    

  return appointment;
    
    
}


+(SCHAppointmentActivity *)createActivityWithParameters:(SCHAppointment *) appointment appointmentSeries:(SCHAppointmentSeries *) appointemntSeries action:(SCHLookup *) action actionInitiator:(SCHUser *) actionIntiator actionAssignedTo: (SCHUser *) actionAssignedTo status:(SCHLookup *)status{
    
    if ((!appointment ||!appointemntSeries) && (!action ||!actionIntiator ||!actionAssignedTo || !status)){
        return nil;
    }
        
        SCHAppointmentActivity *activity  = [SCHAppointmentActivity object];
        activity.appointment = appointment;
        activity.appointmentSeries = appointemntSeries;
        activity.actionInitiator = actionIntiator;
        activity.actionAssignedTo = actionAssignedTo;
        activity.action = action;
        activity.status = status;
    
    [SCHUtility setPublicAllRWACL:activity.ACL];
    
       // NSLog(@"activity: %@", activity);
        
        
        
        return activity;
        
    }

+(BOOL) removeOldNotifications:(NSString *)refreenceObjectId{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    NSError *error = nil;
    NSPredicate *notificationPredicate = [NSPredicate predicateWithFormat:@"referenceObject = %@", refreenceObjectId];
    PFQuery *existingNotificationQuery = [PFQuery queryWithClassName:SCHNotificationClass predicate:notificationPredicate];
    NSArray *existingNotifications = [existingNotificationQuery findObjects:&error];
    
    if (!error){
        if (existingNotifications.count > 0){
            [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:existingNotifications];
            [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:existingNotifications];
        }
        
    } else return NO;
    
    return YES;
    
}

+(void)createNotificationForAppointmentActivity:(SCHAppointmentActivity *) activity {
    
        SCHConstants *constants = [SCHConstants sharedManager];
        SCHService *service = [SCHService object];
        SCHServiceOffering *serviceOffering = [SCHServiceOffering object];
        if (activity.appointmentSeries == NULL){
            service = activity.appointment.service;
            serviceOffering = activity.appointment.serviceOffering;
            
        } else{
            service = activity.appointmentSeries.service;
            serviceOffering = activity.appointmentSeries.serviceOffering;
        }
        
        if (debug){
            NSLog(@"service: %@", service);
            NSLog(@"serviceOffering: %@", serviceOffering);
        }
        
        
        
        
        
        NSString *referenceObject = (activity.appointmentSeries == NULL) ? activity.appointment.objectId : activity.appointmentSeries.objectId;
        NSString *referenceObjectType = (activity.appointmentSeries == NULL) ? SCHAppointmentClass :SCHAppointmentSeriesClass;
    NSString *notificationTitle = nil;
    NSString *message = nil;
    
        
    
        // Notification
        if ([activity.action isEqual:constants.SCHAppointmentActionRespondToAppointmentRequest ]) {
            if (activity.appointment){
                notificationTitle = [NSString stringWithFormat:@"%@ requested a new appointment", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            } else{
                notificationTitle = [NSString stringWithFormat:@"%@ requested new recurring appointments", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
                
            }
            
            
            SCHNotification *notification = [SCHUtility createNotificationForUser:activity.actionAssignedTo
                                                                 notificationType:constants.SCHNotificationForResponse
                                                                notificationTitle:notificationTitle
                                                                          message:message
                                                                  referenceObject:referenceObject
                                                              referenceObjectType:referenceObjectType];
            
            [notification save];
            [SCHUtility sendNotification:notification];
            
        } else if ([activity.action isEqual:constants.SCHAppointmentActionAcceptance]) {
            if (activity.appointment){
                notificationTitle = [NSString stringWithFormat:@"%@ accepted appointment request", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            } else{
                notificationTitle = [NSString stringWithFormat:@"%@ accepted recurring appointment request", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            }
            
            
            SCHNotification *notification = [SCHUtility createNotificationForUser:activity.actionAssignedTo
                                                                 notificationType:constants.SCHNotificationForAcknowledgement
                                                                notificationTitle:notificationTitle
                                                                          message:message
                                                                  referenceObject:referenceObject
                                                              referenceObjectType:referenceObjectType ];
            
            [notification save];
            [SCHUtility sendNotification:notification];
        } else if ([activity.action isEqual:constants.SCHAppointmentActionRejaction]) {
            
            if (activity.appointment){
                notificationTitle = [NSString stringWithFormat:@"%@ declined appointment request", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            } else{
                notificationTitle = [NSString stringWithFormat:@"%@ declined  recurring appointment request", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            }
            
            
            SCHNotification *notification = [SCHUtility createNotificationForUser:activity.actionAssignedTo
                                                                 notificationType:constants.SCHNotificationForAcknowledgement
                                                                notificationTitle:notificationTitle
                                                                          message:message
                                                                  referenceObject:referenceObject
                                                              referenceObjectType:referenceObjectType];
            
            [notification save];
            [SCHUtility sendNotification:notification];
        } else if ([activity.action isEqual:constants.SCHAppointmentActionAppointmentCancellation]) {
            if (activity.appointment){
                notificationTitle = [NSString stringWithFormat:@"%@ cancelled appointment", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            } else{
                notificationTitle = [NSString stringWithFormat:@"%@ cancelled recurring appointments", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            }
            
            
            SCHNotification *notification = [SCHUtility createNotificationForUser:activity.actionAssignedTo
                                                                 notificationType:constants.SCHNotificationForAcknowledgement
                                                                notificationTitle:notificationTitle
                                                                          message:message
                                                                  referenceObject:referenceObject
                                                              referenceObjectType:referenceObjectType];
            
           [notification save];
            [SCHUtility sendNotification:notification];
        } else if ([activity.action isEqual:constants.SCHAppointmentActionRespondToAppontmentChangeRequest]) {
            NSString *notificationTitle = [NSString stringWithFormat:@"%@ requested appointment Change", activity.actionInitiator.preferredName];
            NSString *message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            
            SCHNotification *notification = [SCHUtility createNotificationForUser:activity.actionAssignedTo
                                                                 notificationType:constants.SCHNotificationForResponse
                                                                notificationTitle:notificationTitle
                                                                          message:message
                                                                  referenceObject:referenceObject
                                                              referenceObjectType:referenceObjectType];
            
            [notification save];
            [SCHUtility sendNotification:notification];
            
        } else if ([activity.action isEqual:constants.SCHAppointmentActionAppointmentCreation]){
            if (activity.appointment){
                notificationTitle = [NSString stringWithFormat:@"%@ booked new appointment", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            } else{
                notificationTitle = [NSString stringWithFormat:@"%@ booked new recurring appointments", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            }
            
            
            SCHNotification *notification = [SCHUtility createNotificationForUser:activity.actionAssignedTo
                                                                 notificationType:constants.SCHNotificationForAcknowledgement
                                                                notificationTitle:notificationTitle
                                                                          message:message
                                                                  referenceObject:referenceObject
                                                              referenceObjectType:referenceObjectType];
            
            [notification save];
            [SCHUtility sendNotification:notification];
        } else if ([activity.action isEqual:constants.SCHAppointmentActionAppointmentChange]){
            if (activity.appointment){
                notificationTitle = [NSString stringWithFormat:@"%@ changed appointment", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            } else{
                notificationTitle = [NSString stringWithFormat:@"%@ changed recurring appointments", activity.actionInitiator.preferredName];
                message = [NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName];
            }
            
            
            SCHNotification *notification = [SCHUtility createNotificationForUser:activity.actionAssignedTo
                                                                 notificationType:constants.SCHNotificationForAcknowledgement
                                                                notificationTitle:notificationTitle
                                                                          message:message
                                                                  referenceObject:referenceObject
                                                              referenceObjectType:referenceObjectType];
            
            [notification save];
            [SCHUtility sendNotification:notification];
        }
        
        
        
    }
    
// Hard Allocates time blocks to appointment
    
+(NSString *)allocateTimeBlockOfUser:(SCHUser *) user fromTime:(NSDate *) fromTime toTime:(NSDate *) toTime appointment:(SCHAppointment *) appointment{
        SCHConstants *constants = [SCHConstants sharedManager];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        NSError *error = nil;
        if (debug) {
            NSLog(@"startTime: %@ - endTime: %@", fromTime, toTime);
        }
    
    if ([[NSDate date] compare:fromTime] == NSOrderedDescending){
        fromTime = [SCHUtility startOrEndTime:[NSDate date]];
    }
        
        
    NSMutableArray *timeBlocks = [[NSMutableArray alloc] init];
    
        
        NSPredicate *timeBlockQueryPredicate = [NSPredicate predicateWithFormat:@"user = %@ AND (startTime >= %@ AND endTime <= %@)", user, fromTime, toTime];
        
        PFQuery *timeBlockQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeBlockQueryPredicate];
        
        [timeBlocks addObjectsFromArray:[timeBlockQuery findObjects:&error]];
        if (error){
            return SCHNotAbleToReachServer;
            
        }
    // If time blocks are not available then search from buffer
    NSInteger timeblocksrequired = [toTime timeIntervalSinceDate:fromTime]/SCHTimeBlockDuration;
    if (timeBlocks.count < timeblocksrequired){
        //get timeblocks from buffer
        NSPredicate *timeblocksForAppointmentPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            
            
            if ([evaluatedObject isKindOfClass:[SCHAvailableTimeBlock class]]){
                SCHAvailableTimeBlock *tb = evaluatedObject;
                
                if ([tb.user isEqual:user] &&[tb.services containsObject:appointment.service] && ([tb.startTime compare:fromTime] == NSOrderedDescending || [tb.startTime compare:fromTime] == NSOrderedSame) && ([tb.endTime compare:toTime] == NSOrderedAscending || [tb.endTime compare:toTime] == NSOrderedSame)){
                    return YES;
                } else{
                    return NO;
                }
                
            } else{
                return NO;
            }
        }];
        
        NSArray *timeblocksinBuffer = [appDelegate.backgroundCommit.objectsStagedForSave filteredArrayUsingPredicate:timeblocksForAppointmentPredicate];
        [timeBlocks addObjectsFromArray:timeblocksinBuffer];
        
        NSSet *timeBlocksSet = [[NSSet alloc] initWithArray:timeBlocks];

        
        [timeBlocks removeAllObjects];
        [timeBlocks addObjectsFromArray:[timeBlocksSet allObjects]];

        
    }
    
    if (timeBlocks.count != timeblocksrequired){
        return SCHNotAbleToReachServer;
    }
    
    
     
        if (debug){
            NSLog(@"timeblock count: %lu", (unsigned long)timeBlocks.count);
            for (SCHAvailableTimeBlock *timeblock in timeBlocks){
                NSLog(@"time block start time: %@ - end Time: %@", timeblock.startTime, timeblock.endTime);
            }
        }
        
        
        
        NSPredicate *confirmTimeBlockPredicate = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *timeBlock, NSDictionary *bindings) {
            if (timeBlock.appointment){
                return YES;
            } else return  NO;
        }];
        
        
        
        NSArray *confirmedTimeBlocks = [timeBlocks filteredArrayUsingPredicate:confirmTimeBlockPredicate];
        
        if (debug) {
            NSLog(@"Confirmed Time Blocks: %@", confirmedTimeBlocks);
        }
        
        
        
        if (confirmedTimeBlocks.count > 0){
            return SCHATBConfirmedToOtherAppointment;
        }
        
        
        // Check if other requests exists
        NSMutableSet *appointmentRequestSet = [[NSMutableSet alloc] init];
        for (SCHAvailableTimeBlock *timeBlock in timeBlocks){
            [appointmentRequestSet addObjectsFromArray:timeBlock.requestedAppointments];
        }
        [appointmentRequestSet removeObject:appointment];
        
        if (appointmentRequestSet.count > 0){
            // Send Notification to SP to reschedule
            for (SCHAppointment *appointmentRequest in appointmentRequestSet) {
                
                if (debug) {
                    NSLog(@"Other request exists");
                }
                
                NSString *notificationTitle = [NSString stringWithFormat:@"Appointment has conflict with other schedule."];
                SCHNotification *notification = [SCHUtility createNotificationForUser:appointmentRequest.serviceProvider
                                     notificationType:constants.SCHNotificationForAcknowledgement
                                    notificationTitle:notificationTitle
                                              message:@"Please reschedule the appointment"
                                      referenceObject:appointmentRequest.objectId
                                  referenceObjectType:SCHAppointmentClass];
                
                [notification save];
                
                
            }
        }
        // remove appointments from request queue and allocate timeBlocks to appointment
        
        for(SCHAvailableTimeBlock *timeBlock in timeBlocks) {
            timeBlock.allocationRequested = NO;
            timeBlock.appointment = appointment;
            timeBlock.requestedAppointments = nil;
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:timeBlock];
            
            if (debug){
                NSLog(@"Time Blocks after modifications");
                NSLog(@"Time Block start time: %@ - end time: %@ - appointment: %@, requests: %@", timeBlock.startTime, timeBlock.endTime, timeBlock.appointment, timeBlock.requestedAppointments);
            }
            
            
            
        }
    
    
    //change availability picture

    PFQuery *serviceQuery = [SCHService query];
    [serviceQuery whereKey:@"user" equalTo:appointment.serviceProvider];
    NSArray *services = [serviceQuery findObjects:&error];
    
    if (error){
        

        return  nil;
    } else{
        for (SCHService *service in services) {
            //change availability picture
            NSDictionary *availabilityRefresh = @{@"startTime" : fromTime,
                                                  @"endTime" : toTime,
                                                  @"timeBlocks" : timeBlocks,
                                                  @"user" : appointment.serviceProvider,
                                                  @"service" : service};
            
            [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
        }
    }
    
    


    
        
        return SCHATBAllocatedToAppointment;

}
    
// removes Hard allocation from appointment
    
+(NSArray *)freeConfirmedTimeBlockFrom:(NSDate *) fromTime toTime:(NSDate *) toTime forAppointment:(SCHAppointment *) appointment ofUser:(SCHUser *) user{
        
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
       // NSLog(@"start Time: %@ - end Time: %@", fromTime, toTime);
        NSError *error = nil;
        
        
        
        NSPredicate *timeBlockQueryPredicate = [NSPredicate predicateWithFormat:@"user = %@ AND (startTime >= %@ AND endTime <= %@)", user, fromTime, toTime];
        
        PFQuery *timeBlockQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeBlockQueryPredicate];
        
        NSArray *timeBlocks = [timeBlockQuery findObjects:&error];
        
        if (error){
            return nil;
        }
        
        for (SCHAvailableTimeBlock *timeBlock in timeBlocks){
            
            
            
            timeBlock.appointment = nil;
            timeBlock.availableForNewRequest = YES;
            NSMutableArray *requestedAppointments = [[NSMutableArray alloc] initWithArray:timeBlock.requestedAppointments];
            [requestedAppointments removeObject:appointment];
            if (requestedAppointments.count > 0){
                timeBlock.requestedAppointments = requestedAppointments;
                timeBlock.allocationRequested = YES;
            } else{
                timeBlock.requestedAppointments =nil;
                timeBlock.allocationRequested = NO;
            }
            
            
            
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:timeBlock];
        }
        

        return timeBlocks;
        
        
        
    }
    
    
//removes soft allocation for timeblock.
    
+(NSArray *) releaseTimeBlcoksFrom:(NSDate *) fromTime toTime:(NSDate *) toTime forAppointment:(SCHAppointment *) appointment ofUser:(SCHUser *) user{
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        
       // NSLog(@"start Time: %@ - end Time: %@", fromTime, toTime);
        NSError *error = nil;
        
        
        NSPredicate *timeBlockQueryPredicate = [NSPredicate predicateWithFormat:@"user = %@ AND (startTime >= %@ AND endTime <= %@)", user, fromTime, toTime];
        
        PFQuery *timeBlockQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeBlockQueryPredicate];
        
        NSArray *timeBlocks = [timeBlockQuery findObjects:&error];
        
        if (error){
            return nil;
        }
        
        for (SCHAvailableTimeBlock *timeBlock in timeBlocks){
            
            if ([timeBlock.appointment isEqual:appointment]){
                // timeBlock.allocationRequested = NO;
                timeBlock.appointment = appointment;
                
                
            }
            
            
            if (timeBlock.requestedAppointments.count > 0){
                
                NSMutableArray *requestedAppointments = [[NSMutableArray alloc] initWithArray:timeBlock.requestedAppointments];
                [requestedAppointments removeObject:appointment];
                if (requestedAppointments.count > 0){
                    timeBlock.requestedAppointments = requestedAppointments;
                    timeBlock.allocationRequested = YES;
                } else{
                    timeBlock.requestedAppointments =nil;
                    timeBlock.allocationRequested = NO;
                }
                
                
               // NSLog(@"timeBlock array: %@", timeBlock.requestedAppointments);
                
                
            }
            
            
            
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:timeBlock];
        }

        return timeBlocks;
        
    }
    
+(SCHAppointmentActivity *) actitvityChangeForAppointmentDecline:(id) appointmentObject{
    
    
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        SCHConstants *constants = [SCHConstants sharedManager];
        NSError *error = nil;
    SCHAppointment *appointment = nil;
    SCHAppointmentSeries *series = nil;
    NSPredicate *openActivityPredicate = nil;
    SCHUser *actionInitiator = nil;
    SCHUser *actionAssignedTo = nil;
        
        
    if ([appointmentObject isKindOfClass:[SCHAppointment class]]){
        appointment = appointmentObject;
        openActivityPredicate = [NSPredicate predicateWithFormat:@"appointment = %@ ", appointment];
        actionInitiator = appDelegate.user;
        actionAssignedTo = ([appDelegate.user isEqual:appointment.serviceProvider]) ? appointment.client : appointment.serviceProvider;
    } else if ([appointmentObject isKindOfClass:[SCHAppointmentSeries class]]){
        series = appointmentObject;
        openActivityPredicate = [NSPredicate predicateWithFormat:@"appointmentSeries = %@", series];
        actionInitiator = appDelegate.user;
        actionAssignedTo = ([appDelegate.user isEqual:series.serviceProvider]) ? series.client : series.serviceProvider;
        
    } else return nil;
    
    PFQuery *openActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openActivityPredicate];
    
    NSArray *activity = [openActivityQuery findObjects:&error];
    if (error){
        return nil;
    }
    
        [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:activity];
        [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:activity];
        
        //add new activity
    return [self createActivityWithParameters:(appointment)? appointment: NULL
                            appointmentSeries:(series) ? series: NULL
                                       action:constants.SCHAppointmentActionRejaction
                              actionInitiator:actionInitiator
                             actionAssignedTo:actionAssignedTo
                                       status:constants.SCHappointmentActivityStatusComplete];
    
        
    }
    
+(SCHAppointmentActivity *)activityChangeForAppointmentChangeRequest:(SCHAppointment *) appointment{
        
        SCHConstants *constants = [SCHConstants sharedManager];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSError *error = nil;
    
        
        // remove all prior activities
        NSPredicate *openActivityPredicate = [NSPredicate predicateWithFormat:@"appointment = %@ ", appointment];
        PFQuery *openActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openActivityPredicate];
        
        NSArray *activity = [openActivityQuery findObjects:&error];
        if (error){
            return nil;
        }
        
        [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:activity];
        [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:activity];
        
        
        
        
        //create activities
        
        // craete activity
    
    if ([appointment.status isEqual:constants.SCHappointmentStatusConfirmed]){
        SCHUser *actionAssignedTo = nil;
        if (appointment.nonUserClient){
            actionAssignedTo = appointment.serviceProvider;
        } else{
            actionAssignedTo = ([appointment.serviceProvider isEqual:appDelegate.user]) ? appointment.client : appointment.serviceProvider;
        }
        
        
        SCHAppointmentActivity *appointmentChange = [self createActivityWithParameters:appointment
                                                                     appointmentSeries:NULL
                                                                                action:constants.SCHAppointmentActionAppointmentChange
                                                                       actionInitiator:appDelegate.user
                                                                      actionAssignedTo:actionAssignedTo
                                                                                status:constants.SCHappointmentActivityStatusComplete];
        
        return appointmentChange;
        
    } else {
        
        SCHAppointmentActivity *changeRequest = [self createActivityWithParameters:appointment
                                                                 appointmentSeries:NULL
                                                                            action:constants.SCHAppointmentActionAppointmentChangeRequest
                                                                   actionInitiator:appDelegate.user
                                                                  actionAssignedTo:appDelegate.user
                                                                            status:constants.SCHappointmentActivityStatusComplete];
        
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:changeRequest];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:changeRequest];
        
        SCHAppointmentActivity *respondToAppointChange =  [self createActivityWithParameters:appointment
                                                                           appointmentSeries:NULL
                                                                                      action:constants.SCHAppointmentActionRespondToAppontmentChangeRequest
                                                                             actionInitiator:appDelegate.user
                                                                            actionAssignedTo:([appointment.serviceProvider isEqual:appDelegate.user]) ? appointment.client : appointment.serviceProvider
                                                                                      status:constants.SCHappointmentActivityStatusOpen];
        
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:respondToAppointChange];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:respondToAppointChange];
        
        return respondToAppointChange;

    }
    
    
}
    
//soft allocates timeblock to appointment
    
+(NSArray *)reserveTimeBlocksForChangeRequest:(SCHAppointment *) appointment location:(NSString *) location locationPoint:(PFGeoPoint *)locaionPoint timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo{
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        //Get time block that falls in proposed time window and add request queue
        
        NSArray *proposedTimeBlocks = [self getAvailableTimeBlocksForAppointmentWithStartTime:timeFrom
                                                                                      endTime:timeTo
                                                                                      service:appointment.service
                                                                                     location:location
                                                                                locationPoint:locaionPoint
                                                                              serviceProvider:appointment.serviceProvider
                                                                                  appointment:appointment];
        
       // NSLog(@"%@", proposedTimeBlocks);
        
        
        
        if (proposedTimeBlocks.count != [timeTo timeIntervalSinceDate:timeFrom]/SCHTimeBlockDuration){
            /// show alert
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Oops! Time reserved by  another client few seconds ago.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            });
            
            return @[];
        }
        
        // add appointment to proposed timeblock request queue
        
        
        for (SCHAvailableTimeBlock *timeBlock in proposedTimeBlocks){
            
            if (!timeBlock.appointment){
                timeBlock.allocationRequested = YES;
                if (timeBlock.requestedAppointments){
                    NSMutableArray *requestedAppointments = [[NSMutableArray alloc] initWithArray:timeBlock.requestedAppointments];
                    [requestedAppointments addObject:appointment];
                    timeBlock.requestedAppointments = requestedAppointments;
                } else timeBlock.requestedAppointments = @[appointment];
                
                [appDelegate.backgroundCommit.objectsStagedForSave addObject:timeBlock];
            }
            
            
            
            
        }
        

    
        return proposedTimeBlocks;
    }
    
+(SCHAppointmentActivity *)activityChangeForAppointmentConfirmation:(id) appointmentObject{
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        SCHConstants *constants = [SCHConstants sharedManager];
        NSError *error = nil;
    SCHAppointment *appointment = nil;
    SCHAppointmentSeries *series = nil;
    NSPredicate *openActivityPredicate = nil;
    SCHUser *actionInitiator = nil;
    SCHUser *actionAssignedTo = nil;
    
    
        
    if ([appointmentObject isKindOfClass:[SCHAppointment class]]){
        appointment = appointmentObject;
        openActivityPredicate = [NSPredicate predicateWithFormat:@"appointment = %@ ", appointment];
        actionInitiator = appDelegate.user;
        actionAssignedTo = ([appDelegate.user isEqual:appointment.serviceProvider]) ? appointment.client : appointment.serviceProvider;
    } else if ([appointmentObject isKindOfClass:[SCHAppointmentSeries class]]){
        series = appointmentObject;
        openActivityPredicate = [NSPredicate predicateWithFormat:@"appointmentSeries = %@", series];
        actionInitiator = appDelegate.user;
        actionAssignedTo = ([appDelegate.user isEqual:series.serviceProvider]) ? series.client : series.serviceProvider;
        
    } else return nil;
    
        PFQuery *openActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openActivityPredicate];
        
        NSArray *activity = [openActivityQuery findObjects:&error];
        if (error){
            return nil;
        }
        
        [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:activity];
        [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:activity];
        
        
        
    return [self createActivityWithParameters:(appointment)? appointment: NULL
                            appointmentSeries:(series) ? series: NULL
                                       action:constants.SCHAppointmentActionAcceptance
                              actionInitiator:actionInitiator
                             actionAssignedTo:actionAssignedTo
                                           status:constants.SCHappointmentActivityStatusComplete];
    }

+(SCHAppointmentActivity *)activityChangeForAppointmentCancellation:(SCHAppointment *) appointment{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
    NSError *error = nil;
    
    
    NSPredicate *openActivityPredicate = [NSPredicate predicateWithFormat:@"appointment = %@ ", appointment];
    PFQuery *openActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openActivityPredicate];
    
    NSArray *activity = [openActivityQuery findObjects:&error];
    if (error){
        return nil;
    }
    
    [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:activity];
    [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:activity];
    
    
     return [self createActivityWithParameters:appointment
                     appointmentSeries:NULL
                                action:constants.SCHAppointmentActionAppointmentCancellation
                       actionInitiator:appDelegate.user
                      actionAssignedTo:([appDelegate.user isEqual:appointment.serviceProvider]) ? appointment.client : appointment.serviceProvider
                                status:constants.SCHappointmentActivityStatusComplete];
    
    
    

}

+(NSDictionary *)appointmentCreationMessageContentForNonUser:(SCHAppointment *) appointment{
    
    NSString *subject = [NSString stringWithFormat:@"%@ booked new appointment with you", appointment.serviceProvider.preferredName];
    NSString *body = [self messageBody:appointment];
    
    
    
    return @{@"subject" : subject, @"body": body};
}
+(NSDictionary *)appointmentChangeMessageContentForNonUser:(SCHAppointment *) appointment{
    
    NSString *subject = [NSString stringWithFormat:@"%@ changed appointment", appointment.serviceProvider.preferredName];
    NSString *body = [self messageBody:appointment];
    
    
    
    return @{@"subject" : subject, @"body": body};
}

+(NSDictionary *)appointmentCancellationMessageContentForNonUser:(SCHAppointment *) appointment{
    
    NSString *subject = [NSString stringWithFormat:@"%@ cancelled appointment with you", appointment.serviceProvider.preferredName];
    NSString *body = [self messageBody:appointment];
    
    
    
    return @{@"subject" : subject, @"body": body};
}


+(NSString *)messageBody:(id) appointmentObject{
    SCHAppointment *appointment = nil;
    SCHAppointmentSeries *series = nil;
    SCHService *service = nil;
    SCHServiceOffering *serviceOffering = nil;
    NSDate *startTime = nil;
    NSDate *endTime = nil;
    NSString *location = nil;
    SCHUser *serviceProvider = nil;

    
    
    if ([appointmentObject isKindOfClass:[SCHAppointment class]]){
        appointment = appointmentObject;
        service = appointment.service;
        serviceOffering = appointment.serviceOffering;
        startTime = appointment.startTime;
        endTime = appointment.endTime;
        location = appointment.location;
        serviceProvider = appointment.serviceProvider;
        
        
    } else if ([appointmentObject isKindOfClass:[SCHAppointmentSeries class]]){
        series = appointmentObject;
        service = series.service;
        serviceOffering = series.serviceOffering;
        startTime = series.startTime;
        endTime = series.endTime;
        location = series.location;
        serviceProvider = series.serviceProvider;
    }
    
    NSMutableString *messageBody = [[NSMutableString  alloc] init];
    
    [messageBody appendString:[NSString stringWithFormat:@"%@ - %@", service.serviceTitle, serviceOffering.serviceOfferingName]];
    
    [messageBody appendString:@"\n"];
    [messageBody appendString:@"\n"];
    //Add time
    // Get Date and Time
    
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
    NSString *appointmentDay = [dayformatter stringFromDate:startTime];
    // NSDateFormatter *fromTimeFormatter = [SCHUtility dateFormatterForFromTime];
    NSDateFormatter *toTimeFormatter = [SCHUtility dateFormatterForToTime];
    NSString *appointmentTime = [NSString stringWithFormat:@"from %@ to %@", [toTimeFormatter stringFromDate:startTime], [toTimeFormatter stringFromDate:endTime]];
    
    if (appointment){
        [messageBody appendString:appointmentTime];
        [messageBody appendString:@"\n"];
        [messageBody appendString:[NSString stringWithFormat:@"On %@", appointmentDay]];
        
        
        [messageBody appendString:@"\n"];
        [messageBody appendString:@"\n"];
    } else if (series){
        
        NSMutableString *repeatOptions = [[NSMutableString alloc] init];
        
        if ([series.repeatOption isEqualToString:SCHSelectorRepeatationOptionSpectficDaysOftheWeek]){
            
            NSMutableString *repeatDays = [[NSMutableString alloc] init];
            for (NSString *repeatDayString in series.repeatDays){
                [repeatDays appendString:[NSString stringWithFormat:@"%@, ", repeatDayString]];
            }
            
           // NSRange range = NSMakeRange([repeatDays length] - 1, [repeatDays length]);
           // [repeatDays deleteCharactersInRange:range];
            NSString *repeatString = nil;
            if ([repeatDays length] > 0) {
                repeatString = [repeatDays substringToIndex:[repeatDays length] - 1];
            }else{
                repeatString = @" ";
            }
            
            [repeatOptions setString:[NSString stringWithFormat:@"Occurs every %@ from %@ till %@", repeatString, [dayformatter stringFromDate:series.startTime], [dayformatter stringFromDate:series.endDate]]];
        } else {
            
            [repeatOptions setString:[NSString stringWithFormat:@"Occurs %@ from %@ till %@", series.repeatOption, [dayformatter stringFromDate:series.startTime], [dayformatter stringFromDate:series.endDate]]];
        }
        
        [messageBody appendString:appointmentTime];
        [messageBody appendString:@"\n"];
        [messageBody appendString:[NSString stringWithFormat:@"%@", repeatOptions]];
        
        
        [messageBody appendString:@"\n"];
        [messageBody appendString:@"\n"];
        

        
    }
    
    
    
    //Add location
    
    [messageBody appendString:@"At"];
    [messageBody appendString:@"\n"];
    [messageBody appendString:location];
    
    [messageBody appendString:@"\n"];
    [messageBody appendString:@"\n"];
    
    //Add contact
    [messageBody appendString:[NSString stringWithFormat:@"%@'s Contact Info", serviceProvider.preferredName]];
    [messageBody appendString:@"\n"];
    [messageBody appendString:service.businessEmail];
    [messageBody appendString:@"\n"];
    [messageBody appendString:[SCHUtility phoneNumberFormate:service.businessPhone]];
    
    [messageBody appendString:@"\n"];
    [messageBody appendString:@"\n"];
    [messageBody appendString:[NSString stringWithFormat:@"Scheduled in CounterBean."]];
    [messageBody appendString:@"\n"];
    [messageBody appendString:@"\n"];
    [messageBody appendString:[NSString stringWithFormat:@"Download CounterBean from Apple App Store to manage your appointments."]];
    [messageBody appendString:@"\n"];
    [messageBody appendString:@"It's free."];
    
    return messageBody;
    
}

+(BOOL)autoConfirmAppointment:(SCHService *) service client:(SCHUser *) client timeBlocks:(NSArray *) timeBlocks location:(NSString *)location appointment:(SCHAppointment *) appointment{
    BOOL autoConfirm = NO;
    NSError *error = nil;
    SCHConstants *constants = [SCHConstants sharedManager];
    
    //proceed only if there is not appointment request in the timeblock
    

    NSPredicate *timeblockWithRequest = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *tb, NSDictionary<NSString *,id> * _Nullable bindings) {
        
        
        NSMutableArray *requestedAppointments = [[NSMutableArray alloc] initWithArray:tb.requestedAppointments];

        if (requestedAppointments && appointment){
            [requestedAppointments removeObject:appointment];
        }
        BOOL returnValue = NO;
        
        if (tb.appointment && appointment){
            if (![tb.appointment isEqual:appointment]){
                returnValue = YES;

    
            }
        }
        
        
        if (requestedAppointments){
            if (requestedAppointments.count >0){
                returnValue =  YES;
            }
        }
        
        if (![tb.location isEqualToString:location]){
            returnValue = YES;
        }
        
        return returnValue;
        
        
    }];
    
    
    NSArray *TBWithRequest = [timeBlocks filteredArrayUsingPredicate:timeblockWithRequest];
    
    if (TBWithRequest.count > 0){
        autoConfirm = NO;
    } else {
        if ([service.autoConfirmAppointment isEqual:constants.SCHAutoConfirmOptionNone]){
            autoConfirm = NO;
        } else if ([service.autoConfirmAppointment isEqual:constants.SCHAutoConfirmOptionSpecificClients]){
            //Get service Provider Client list
            PFQuery *clientListQuery = [SCHServiceProviderClientList query];
            [clientListQuery whereKey:@"client" equalTo:client];
            NSArray *clientLists = [clientListQuery findObjects:&error];
            SCHServiceProviderClientList *clientList = nil;
            if (error){
                autoConfirm = NO;
            } else{
                if (clientLists.count > 0){
                    clientList = clientLists[0];
                }
                if (clientList){
                    if (clientList.autoConfirmAppointment){
                        autoConfirm = YES;

                    } else autoConfirm = NO;
                } else autoConfirm = NO;
                
            }

            
        } else if ([service.autoConfirmAppointment isEqual:constants.SCHAutoConfirmOptionClient]){
            //Get service Provider Client list
            PFQuery *clientListQuery = [SCHServiceProviderClientList query];
            [clientListQuery whereKey:@"client" equalTo:client];
            int clientCount = (int)[clientListQuery countObjects:&error];
            if (error){
                autoConfirm = NO;
            } else{
                if (clientCount > 0){
                    autoConfirm = YES;
                } else autoConfirm = NO;
            }
            
            
        } else if ([service.autoConfirmAppointment isEqual:constants.SCHAutoConfirmOptionPublic]){
            autoConfirm = YES;
        }
  }
    
    return autoConfirm;
    
}
    


+(BOOL)commit{
    
    BOOL success = YES;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit addObjectsToCommitQueue:appDelegate.backgroundCommit.objectsStagedForDelete
                                             commitAction:SCHServerCommitDelete
                                               commitMode:SCHServerCommitModeSynchronous];
    
    success = [appDelegate.backgroundCommit serverCommit];
    
    if (success){
        [appDelegate.backgroundCommit addObjectsoUnpinningQueue:appDelegate.backgroundCommit.objectsStagedForUnpin];
        [appDelegate.backgroundCommit unPinObjects];
        [appDelegate.backgroundCommit addObjectsToCommitQueue:appDelegate.backgroundCommit.objectsStagedForSave
                                                 commitAction:SCHServerCommitSave
                                                   commitMode:SCHServerCommitModeSynchronous];
        
        success =[appDelegate.backgroundCommit serverCommit];
        
    }
    if (success){
        [appDelegate.backgroundCommit addObjectsoPinningQueue:appDelegate.backgroundCommit.objectsStagedForPinning];
        [appDelegate.backgroundCommit pinObjects];
    }
    
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    
    
    return YES;
}






@end
