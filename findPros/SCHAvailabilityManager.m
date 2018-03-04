//
//  SCHAvailabilityManager.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/3/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAvailabilityManager.h"
#import "SCHUtility.h"
#import "SCHConstants.h"
#import "SCHLookup.h"
#import "SCHAppointment.h"
#import "SCHAppointmentActivity.h"
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
#import "SCHUtility.h"
#import "SCHBackendCommit.h"
#import "SCHBackendCommit.h"
#import "AppDelegate.h"
#import "SCHAvailabilityRefreshQueue.h"
#import "SCHAppointmentManager.h"
#import "SCHNotification.h"

static BOOL debug = NO;
static NSInteger statement = 0;


@implementation SCHAvailabilityManager



+(BOOL)manageAvailableTimeWithAction:(NSString *) action service:(SCHService *) service location:(NSString *) location locationPoint:(PFGeoPoint *) locationPoint timeFrom: (NSDate *) timeFrom timeTo:(NSDate *) timeTo repeatOption:(NSString *)  repeatOption cancelAppointments:(BOOL) cancelAppointments repeatDays:(NSArray *) repeatDays endDate:(NSDate *) endDate {
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate *inputTimeFrom = [SCHUtility startOrEndTime:timeFrom];
    NSDate *inputTimeTo = [SCHUtility startOrEndTime:timeTo];
    NSDate *inputEndDate = [SCHUtility startOrEndTime:endDate];

    
    
    
//    NSLog(@"Processing - manageAvailableTimeWithAction");
//    NSLog(@"a/*ction: %@", action);
//    NSLog(@"service: %@", service);
//    NSLog(@"location: %@",location);
//    NSLog(@"timefrom: %@",inputTimeFrom);
//    NSLog(@"timeto: %@",inputTimeTo);
//    NSLog(@"repeatOption: %@",repeatOption);
//    NSLog(@"repeatDays: %@",repeatDays);
//    NSLog(@"endDate: %@",inputEndDate);
//    NSLog(@"timefrom: %@",inputTimeFrom);
//    NSLog(@"timeto: %@",inputTimeTo);
//    NSLog(@"endDate: %@",inputEndDate);
    
    
    
    
    BOOL success = NO;
    
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    [appDelegate.refreshQueue refresh];
    
    
    


    NSMutableArray *availabilityTime = [[NSMutableArray alloc] init];
    
    if ([action  isEqual:SCHSelectorAvailabilityActionOptionAvailable ]) {
        // Create/ update Time Block
        if ([repeatOption isEqualToString:SCHSelectorRepeatationOptionNever]){
            
            NSDictionary *availabilityBlock = @{@"startTime": inputTimeFrom, @"endTime" : inputTimeTo};
            [availabilityTime addObject:availabilityBlock];
            
            success =[self createAvailableTimeWithService:service
                                            location:location
                                       locationPoint:locationPoint
                                    availabilityTime:availabilityTime
                                           startDate:timeFrom
                                             endDate:timeTo
                                availableForNewRequest:YES];
            
            
                
            
            
        } else {
            
            NSArray *availabilityCreationDays = [SCHUtility getDaysforschedulingwithStartTime:inputTimeFrom
                                                                                      endTime:inputTimeTo
                                                                                      endDate:inputEndDate
                                                                                 repeatOption:repeatOption
                                                                                   repeatDays:repeatDays];
            
            
            
            success = [self createAvailableTimeWithService:service
                                            location:location
                                       locationPoint:locationPoint
                                    availabilityTime:availabilityCreationDays
                                           startDate:inputTimeFrom
                                             endDate:inputEndDate
                               availableForNewRequest:YES];

                
                
            
        }
        
        if (success){
            success = ([self refreshNetAvailabilities] && [self refreshAvailabilitiesForAppointment]);
        } else {
            [appDelegate.backgroundCommit refreshQueues];
            [appDelegate.backgroundCommit refrshStagedQueue];
            [appDelegate.refreshQueue refresh];
            return success;
                           
        }
        
        if (success){
            [SCHUtility commit];
        } else{
            [appDelegate.backgroundCommit refreshQueues];
            [appDelegate.backgroundCommit refrshStagedQueue];
            [appDelegate.refreshQueue refresh];
            return success;
        }
                       
        [appDelegate.backgroundCommit refreshQueues];
        [appDelegate.backgroundCommit refrshStagedQueue];
        [appDelegate.refreshQueue refresh];
        

        
        
    } else if  ([action isEqual:SCHSelectorAvailabilityActionOptionUnavailable]) {
        
        if (debug) {
            NSLog(@"Hello Not Avaliable");
        }
        statement = 40;
        if ([self removeAvailableTimeWithService:service location:location timeFrom:timeFrom timeTo:timeTo cancelAppointments:cancelAppointments]) {
            
            NSMutableDictionary *availabilityRefresh = [[NSMutableDictionary alloc] init];
            [availabilityRefresh setObject:timeFrom forKey:@"startTime"];
            [availabilityRefresh setObject:timeTo forKey: @"endTime"];
            [availabilityRefresh setObject:@[] forKey:@"timeBlocks" ];
            [availabilityRefresh setObject:appDelegate.user forKey:@"user" ];

            
            if (service != NULL){
                [availabilityRefresh setObject:service forKey:@"service"];
            }
            
            
            [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
        
            [self refreshNetAvailabilities];
            
            if (service != NULL){
                
                [self refreshAvailabilitiesForAppointment];
            }
            
  
            [SCHAppointmentManager commit];
            [appDelegate.refreshQueue refresh];
            [appDelegate.backgroundCommit refreshQueues];
            [appDelegate.backgroundCommit refrshStagedQueue];
            
            if (service == NULL){
                
                NSPredicate *serviceQueryPredicate = [NSPredicate predicateWithFormat:@"user = %@", appDelegate.user];
                PFQuery *serviceQuery = [PFQuery queryWithClassName:SCHServiceClass predicate:serviceQueryPredicate];
                 for (SCHService *userService in [serviceQuery findObjects]){
                     NSDictionary *availabilityRefresh = @{@"startTime" : timeFrom,
                                                           @"endTime" : timeTo,
                                                           @"timeBlocks" : @[],
                                                           @"user" :appDelegate.user,
                                                           @"service" : userService};
                     
                     
                     
                     
                     [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                     [self refreshAvailabilitiesForAppointment];
                     [SCHAppointmentManager commit];
                     [appDelegate.refreshQueue refresh];
                     [appDelegate.backgroundCommit refreshQueues];
                     [appDelegate.backgroundCommit refrshStagedQueue];
                     
                     
                     
                 }
                
            
            }
            
            
            
        

            
        }
        
        
    } else if ([action isEqualToString:SCHSelectorAvailabilityActionOptionChange]){
        
        // Cancel Existing Availability
        NSDate *cancellationStartTime = nil;
        NSDate *cancellationEndTime = nil;
        NSCalendar *preferredCalendar =[NSCalendar currentCalendar];
        NSCalendarUnit units = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay| NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitTimeZone;
            
        if (![repeatOption isEqualToString:SCHSelectorRepeatationOptionNever]){
            NSDateComponents *cancellationStartComponents = [preferredCalendar components:units fromDate:timeFrom];
            [cancellationStartComponents setHour:0];
            [cancellationStartComponents setMinute:0];
            [cancellationStartComponents setSecond:1];
            [cancellationStartComponents setTimeZone:[NSTimeZone localTimeZone]];
            cancellationStartTime = [preferredCalendar dateFromComponents:cancellationStartComponents];
            
            NSDateComponents *cancellationEndComponents = [preferredCalendar components:units fromDate:endDate];
            [cancellationEndComponents setHour:24];
            [cancellationEndComponents setMinute:0];
            [cancellationEndComponents setSecond:0];
            [cancellationStartComponents setTimeZone:[NSTimeZone localTimeZone]];
            cancellationEndTime = [preferredCalendar dateFromComponents:cancellationEndComponents];
            
            
            
        } else{
            
            
            NSDateComponents *cancellationStartComponents = [preferredCalendar components:units fromDate:timeFrom];
            [cancellationStartComponents setHour:0];
            [cancellationStartComponents setMinute:0];
            [cancellationStartComponents setSecond:0];
            [cancellationStartComponents setTimeZone:[NSTimeZone localTimeZone]];
            cancellationStartTime = [preferredCalendar dateFromComponents:cancellationStartComponents];
            
            NSDateComponents *cancellationEndComponents = [preferredCalendar components:units fromDate:timeTo];
            [cancellationEndComponents setHour:24];
            [cancellationEndComponents setMinute:0];
            [cancellationEndComponents setSecond:0];
            [cancellationStartComponents setTimeZone:[NSTimeZone localTimeZone]];
            cancellationEndTime = [preferredCalendar dateFromComponents:cancellationEndComponents];
            

            
        }

        
        // Cancel Avaailability
        
        if (cancellationStartTime && cancellationEndTime){
            if ([self removeAvailableTimeWithService:service location:location timeFrom:cancellationStartTime timeTo:cancellationEndTime cancelAppointments:cancelAppointments]) {
                
                NSMutableDictionary *availabilityRefresh = [[NSMutableDictionary alloc] init];
                [availabilityRefresh setObject:cancellationStartTime forKey:@"startTime"];
                [availabilityRefresh setObject:cancellationEndTime forKey: @"endTime"];
                [availabilityRefresh setObject:@[] forKey:@"timeBlocks" ];
                [availabilityRefresh setObject:appDelegate.user forKey:@"user" ];
                
                
                if (service != NULL){
                    [availabilityRefresh setObject:service forKey:@"service"];
                }
                
                
                [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                
                [self refreshNetAvailabilities];
                
                if (service != NULL){
                    
                    [self refreshAvailabilitiesForAppointment];
                }
                
                
                [SCHAppointmentManager commit];
                [appDelegate.refreshQueue refresh];
                [appDelegate.backgroundCommit refreshQueues];
                [appDelegate.backgroundCommit refrshStagedQueue];
                
                if (service == NULL){
                    
                    NSPredicate *serviceQueryPredicate = [NSPredicate predicateWithFormat:@"user = %@", appDelegate.user];
                    PFQuery *serviceQuery = [PFQuery queryWithClassName:SCHServiceClass predicate:serviceQueryPredicate];
                    for (SCHService *userService in [serviceQuery findObjects]){
                        NSDictionary *availabilityRefresh = @{@"startTime" : cancellationStartTime,
                                                              @"endTime" : cancellationEndTime,
                                                              @"timeBlocks" : @[],
                                                              @"user" : appDelegate.user,
                                                              @"service" : userService};
                        
                        
                        [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
                        [self refreshAvailabilitiesForAppointment];
                        [SCHAppointmentManager commit];
                        [appDelegate.refreshQueue refresh];
                        [appDelegate.backgroundCommit refreshQueues];
                        [appDelegate.backgroundCommit refrshStagedQueue];
                        
                        
                        
                    }
                    
                    
                }
                
            }
            

        }
        
        
        
        // Now publish availability for changed time
        if ([repeatOption isEqualToString:SCHSelectorRepeatationOptionNever]){
            
            NSDictionary *availabilityBlock = @{@"startTime": inputTimeFrom, @"endTime" : inputTimeTo};
            [availabilityTime addObject:availabilityBlock];
            
            success =[self createAvailableTimeWithService:service
                                                 location:location
                                            locationPoint:locationPoint
                                         availabilityTime:availabilityTime
                                                startDate:timeFrom
                                                  endDate:timeTo
                                   availableForNewRequest:YES];
            
            
            
            
            
        } else {
            
            NSArray *availabilityCreationDays = [SCHUtility getDaysforschedulingwithStartTime:inputTimeFrom
                                                                                      endTime:inputTimeTo
                                                                                      endDate:inputEndDate
                                                                                 repeatOption:repeatOption
                                                                                   repeatDays:repeatDays];
            
            
            
            success = [self createAvailableTimeWithService:service
                                                  location:location
                                            locationPoint:locationPoint
                                          availabilityTime:availabilityCreationDays
                                                 startDate:inputTimeFrom
                                                   endDate:inputEndDate
                                     availableForNewRequest:YES];
            
            
            
            
        }
        
        if (success){
            success = ([self refreshNetAvailabilities] && [self refreshAvailabilitiesForAppointment]);
        } else {
            [appDelegate.backgroundCommit refreshQueues];
            [appDelegate.backgroundCommit refrshStagedQueue];
            [appDelegate.refreshQueue refresh];
            return success;
            
        }
        
        if (success){
            [SCHUtility commit];
        } else{
            [appDelegate.backgroundCommit refreshQueues];
            [appDelegate.backgroundCommit refrshStagedQueue];
            [appDelegate.refreshQueue refresh];
            return success;
        }
        
        [appDelegate.backgroundCommit refreshQueues];
        [appDelegate.backgroundCommit refrshStagedQueue];
        [appDelegate.refreshQueue refresh];
        
        
    } else return NO;  //End of available & unavailable if clause
    
    
    
    
    
    return success;
}



+(BOOL) createAvailableTimeWithService:(SCHService *) service location:(NSString *) location locationPoint:(PFGeoPoint *) locatioPoint availabilityTime:(NSArray *) availabilityTime startDate:(NSDate *) startDate endDate:(NSDate *) endDate availableForNewRequest:(BOOL) availableForNewRequest{
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
   // BOOL debug = YES;
    
    /*
     NSLog(@"cretaeAvailableTimeWithService");
     NSLog(@"service: %@", service);
     NSLog(@"location: %@",location);
     NSLog(@"availabilityTime: %@",availabilityTime);
     NSLog(@"startDate: %@",startDate);
     NSLog(@"endDate: %@",endDate);
     
     */
    
    
    
    NSMutableArray *timeBlocks = [[NSMutableArray alloc] init];
    //[appDelegate.backgroundCommit refreshQueues];
   // [appDelegate.backgroundCommit refrshStagedQueue];
    SCHUser *user = appDelegate.user;
    NSMutableSet *existingTimeBlocks = [[NSMutableSet alloc] init];
    BOOL allocationRequested = NO;
    SCHAppointment *appointment = nil;
    NSArray *requestedAppointments = nil;
    NSError *error = nil;
    
    BOOL success = YES;
    
    
    //Get all availabletime Blocks in server
    
    
    
    for (NSDictionary *availabilityBlock in availabilityTime ) {
        
        
        NSPredicate *getTimeBlockPredicate = [NSPredicate predicateWithFormat:@"(startTime >= %@) AND endTime <= %@ AND (user = %@)",[availabilityBlock valueForKey:@"startTime"], [availabilityBlock valueForKey:@"endTime"], user];
        PFQuery *getTimeBlocks = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:getTimeBlockPredicate];
        
        [existingTimeBlocks addObjectsFromArray:[getTimeBlocks findObjects:&error]];
        
        if (error){
            success = NO;
            break;
        }
        
        
    }
    if (!success){
        return success;
    }
     

    
    for (NSDictionary *availabilityBlock in availabilityTime ){
        
        NSDate *availabilityBlockStartTime = [availabilityBlock valueForKey:@"startTime"];
        NSDate *availabilityBlockEndTime = [availabilityBlock valueForKey:@"endTime"];
        
        //NSLog(@"Processing for availability Block - startTime: %@ - End Time: %@", availabilityBlockStartTime, availabilityBlockEndTime);
        
        NSDate *timeBlockStartTime = availabilityBlockStartTime;
        
       // NSLog(@"Initial TimeBlock Start Time: %@", timeBlockStartTime);
        
        
        while ([timeBlockStartTime compare:availabilityBlockEndTime] == NSOrderedAscending) {
            NSDate *timeBlockEndTime = [NSDate dateWithTimeInterval:SCHTimeBlockDuration sinceDate:timeBlockStartTime];
          //  NSLog(@"TimeBlock Start Time: %@", timeBlockStartTime);
          //  NSLog(@"TimeBlock end Time: %@", timeBlockEndTime);
            
            NSPredicate *timeBlockExists = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *timeBlock, NSDictionary *bindings) {
                if (([timeBlock.startTime compare:timeBlockStartTime] == NSOrderedSame) && ([timeBlock.endTime compare:timeBlockEndTime] == NSOrderedSame)){
                    return YES;
                } else return NO;
            }];
            
            NSSet *matchedTimeBlock = [existingTimeBlocks filteredSetUsingPredicate:timeBlockExists];
            
            
            if ([matchedTimeBlock count] == 0) {
                
               // NSLog(@"timeBlock match is zero");
                
                // Time Block is not available. Create.
                
                SCHAvailableTimeBlock *timeblock = [SCHAvailableTimeBlock object];
                timeblock.user = user;
                timeblock.startTime = timeBlockStartTime;
                timeblock.endTime = timeBlockEndTime;
                timeblock.location = location;
                timeblock.locationPoint = locatioPoint;
                timeblock.appointment = appointment;
                timeblock.requestedAppointments = requestedAppointments;
                timeblock.allocationRequested = allocationRequested;
                timeblock.services = @[service];
                timeblock.availableForNewRequest = availableForNewRequest;
                [SCHUtility setPublicAllRWACL:timeblock.ACL];

                
                
                [appDelegate.backgroundCommit.objectsStagedForSave addObject:timeblock];
                [timeBlocks addObject:timeblock];
                
                
                
            } else if ([matchedTimeBlock count] == 1){
               
                
               // NSLog(@"timeBlock match is 1");
                
                NSArray *matchedTimeBlocks = [matchedTimeBlock allObjects];
                SCHAvailableTimeBlock *timeblock = [matchedTimeBlocks firstObject];
                [timeBlocks addObject:timeblock];
                BOOL addforUpdate = NO;
                
                
                // Update location if different
                
                
                if (!timeblock.availableForNewRequest && availableForNewRequest){
                    timeblock.availableForNewRequest = availableForNewRequest;
                    addforUpdate = YES;
                }
                
                
                
                if ((location != nil) && (![location isEqualToString:timeblock.location])) {
                    timeblock.location = location;
                    timeblock.locationPoint = locatioPoint;
                    
                    addforUpdate = YES;
                    
                }
                if (![timeblock.services containsObject:service]){
                    NSMutableSet *timeBlockServices = [[NSMutableSet alloc] initWithArray:timeblock.services];
                    [timeBlockServices addObject:service];
                    timeblock.services = [timeBlockServices allObjects];
                    addforUpdate = YES;
                }
                if (addforUpdate){
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:timeblock];
                    
                }
            }
            
            
            // set next block start time
            timeBlockStartTime = timeBlockEndTime;
           // NSLog(@"Next timeblock startTime: %@", timeBlockStartTime);
            
        }  // end of while block
        
        
        
        NSDictionary *availabilityRefresh = @{@"startTime" : availabilityBlockStartTime,
                                              @"endTime" : availabilityBlockEndTime,
                                              @"timeBlocks" : [[NSArray alloc] initWithArray:timeBlocks],
                                              @"user" : user,
                                              @"service" : service};
        
        [appDelegate.refreshQueue.availabilityRefreshQueue addObject:availabilityRefresh];
        [timeBlocks removeAllObjects];
        
    } // End of for Loop
    
    return success;

}





+(BOOL) refreshAllAvailabilitiesWithTime:(NSArray *) availabilityTimes timeBocks:(NSArray *) timeBlock user:(SCHUser *) user service:(SCHService *) service {
    BOOL success = YES;
    
    
    for (NSDictionary *availabilityTime in availabilityTimes){
        
        
       // NSLog(@"Availability Time - Start Time: %@ - End Time: %@", [availabilityTime valueForKey:@"startTime"], [availabilityTime valueForKey:@"endTime"] );
        
        
        success = [self refreshAvailabilityWithTimeFrom:[availabilityTime valueForKey:@"startTime"]
                                                 timeTo:[availabilityTime valueForKey:@"endTime"]
                                                 timeBlocks:timeBlock
                                                   user:user];
        
        if (success){
            
            success = [self refreshAvailabilityForAppointmentWithTimeFrom:[availabilityTime valueForKey:@"startTime"]
                                                                   timeTo:[availabilityTime valueForKey:@"endTime"]
                                                                  timeBlocks:timeBlock
                                                                  service:service
                                                                     user:user];
        }
        
        if(!success){
            break;
        }
        
        

    }
    
    
    return success;
}

+(BOOL) refreshAvailabilityWithTimeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo timeBlocks:(NSArray *)timeBlocks user:(SCHUser *) user {
    BOOL debug = NO;
    BOOL success = YES;
    NSError *error = nil;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *objectsForDelete = [[NSMutableArray alloc] init];
    NSMutableArray *objectsForSave = [[NSMutableArray alloc] init];
    
    
    
    NSPredicate *GetAvailabilitiesPredicate = [NSPredicate predicateWithFormat:@"((startTime BETWEEN  %@ OR endTime BETWEEN %@) OR (startTime <= %@ AND endTime >= %@)) AND user = %@", @[timeFrom, timeTo],@[timeFrom, timeTo], timeFrom, timeTo, user ];
    
    PFQuery *getAvailabilitiesQuery = [PFQuery queryWithClassName:SCHAvailabilityClass predicate:GetAvailabilitiesPredicate];
    [getAvailabilitiesQuery orderByAscending:@"startTime"];
    
    
    NSArray *existingAvailabilities  = [getAvailabilitiesQuery findObjects:&error];
    if (error){
        success = NO;
        return  NO;
    }
    
    
    if (debug){
       // NSLog(@"refresh Availability: availability count %lu", (unsigned long)existingAvailabilities.count);
        for (SCHAvailability *availability in existingAvailabilities){
            NSLog(@" availability start time:%@", availability.startTime );
        }
    }
    
    [objectsForDelete addObjectsFromArray:existingAvailabilities];
    
    NSDate *availabilityRefreshStartTime = [[NSDate alloc] init];
    NSDate *availabilityRefreshEndtime =  [[NSDate alloc] init];
    
    if (existingAvailabilities.count == 0){
        availabilityRefreshStartTime = timeFrom;
        availabilityRefreshEndtime = timeTo;
    }else {
        availabilityRefreshStartTime = [[(SCHAvailability *)[existingAvailabilities firstObject] startTime] compare: timeFrom] == NSOrderedAscending ? [(SCHAvailability *)[existingAvailabilities firstObject] startTime ]: timeFrom;
        availabilityRefreshEndtime = ([[(SCHAvailability *)[existingAvailabilities lastObject] endTime] compare: timeTo] == NSOrderedDescending) ? [(SCHAvailability *)[existingAvailabilities lastObject] endTime] : timeTo;
    }
    
    if (debug) {
        NSLog(@"input time from: %@ - input time to: %@", timeFrom, timeTo);
        NSLog(@"first availability time from: %@ -- last availability time to: %@", [(SCHAvailability *)[existingAvailabilities firstObject] startTime ], [(SCHAvailability *)[existingAvailabilities lastObject] endTime]);
        NSLog(@"refresh avail: availability Start Time: %@ - availability end Time: %@", availabilityRefreshStartTime, availabilityRefreshEndtime);
    }
    
    
    
    
   
    //Get all timeblocks in refresh time interval
    NSMutableArray *existingTBIds = [[NSMutableArray alloc] init];
    if (timeBlocks.count > 0){
        for (SCHAvailableTimeBlock *tb in timeBlocks){
            if(tb.objectId){
                [existingTBIds addObject:tb.objectId];
            }
            
        }
        
    }
    
    
    
    NSPredicate *timeBlocksForRefreshPredicate = [NSPredicate predicateWithFormat:@"startTime >= %@ AND endTime <= %@ AND appointment = null AND user = %@", availabilityRefreshStartTime, availabilityRefreshEndtime, user ];
    
    PFQuery *timeBlocksForRefreshQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeBlocksForRefreshPredicate];
    [timeBlocksForRefreshQuery whereKey:@"availableForNewRequest" equalTo:@YES];
    if (existingTBIds.count > 0){
        [timeBlocksForRefreshQuery whereKey:@"objectId" notContainedIn:existingTBIds];
    }
    
    [timeBlocksForRefreshQuery includeKey:@"services"];
    
    //  NSMutableSet *timeBlockForRefreshSet = [[NSMutableSet alloc] init];
    
    NSMutableSet *timeBlockForRefreshSet = [[NSMutableSet alloc] initWithArray:[timeBlocksForRefreshQuery findObjects:&error]];
    if (error){
        success = NO;
        return  NO;
    }
    
    if (debug){
        for(SCHAvailableTimeBlock *timeblock in timeBlockForRefreshSet){
            NSLog(@"timeblock - start Time: %@ - end time: %@", timeblock.startTime, timeblock.endTime);
        }
        
    }
    
    // addtimeblocks being processed
    if (timeBlocks.count > 0){
        [timeBlockForRefreshSet addObjectsFromArray:timeBlocks];
    }
    
    
    
    // fileter the timeblocks with absolute availability
    
    NSPredicate *filterTBWithabsoluteAvailability = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *timeBlock, NSDictionary *bindings) {
        if (timeBlock.allocationRequested || timeBlock.appointment){
            return NO;
        } else return  YES;
    }];
    
    NSSortDescriptor *sortTBwithAbsoluteAvailability = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    
    NSArray *TBwithAbsoluteAvailabiity = [[[timeBlockForRefreshSet allObjects] filteredArrayUsingPredicate:filterTBWithabsoluteAvailability] sortedArrayUsingDescriptors:@[sortTBwithAbsoluteAvailability]];
    
    if (debug){
        
        NSLog(@"TimeBlock with absolute availability: %lu", (unsigned long)TBwithAbsoluteAvailabiity.count);
        for(SCHAvailableTimeBlock *timeblock in TBwithAbsoluteAvailabiity){
            NSLog(@"timeblock with absolute availability - start Time: %@ - end time: %@", timeblock.startTime, timeblock.endTime);
        }
        
    }
    
    
    // create availability
    [objectsForSave addObjectsFromArray:[self createAvailabilityForTimeBlocks:TBwithAbsoluteAvailabiity user:user]];
    
/*
    for (SCHAvailability *availability in objectsForSave){
        //NSLog(@"availability Detail - start Time: %@, End Time: %@, Location: %@", availability.startTime, availability.endTime, availability.location);
        
        
        for (NSDictionary *availabilityservice in availability.services){
            NSLog(@"service: %@ - start time: %@ - end time: %@", [(SCHService *)[availabilityservice valueForKey:@"service"] serviceTitle], [availabilityservice valueForKey:@"startTime"], [availabilityservice valueForKey:@"endTime"]);
        }
        
        
    }
 
    
    
    NSLog(@"delete object count: %lu", (unsigned long)objectsForDelete.count);
    NSLog(@"saveObject Count: %lu", (unsigned long)objectsForSave.count);
    
    
    */
    
    

    if (objectsForDelete.count > 0){
        
        [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:objectsForDelete];
        [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:objectsForDelete];
        
    }
    if (objectsForSave.count > 0){
        [appDelegate.backgroundCommit.objectsStagedForSave addObjectsFromArray:objectsForSave];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:objectsForSave];
        
        
    }
    
    return success;
}

+(BOOL) refreshAvailabilityForAppointmentWithTimeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo timeBlocks:(NSArray *) timeBlocks service:(SCHService *)service user:(SCHUser *) user{
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL debug = NO;
    BOOL success = YES;
    NSError *error = nil;
    NSMutableArray *objectsForDelete = [[NSMutableArray alloc] init];
    NSMutableArray *objectsForSave = [[NSMutableArray alloc] init];
    
    
    
    
    NSPredicate *GetAvailabilitiesPredicate = [NSPredicate predicateWithFormat:@"((startTime BETWEEN  %@ OR endTime BETWEEN %@) OR (startTime <= %@ AND endTime >= %@)) AND service = %@ AND user = %@", @[timeFrom, timeTo],@[timeFrom, timeTo], timeFrom, timeTo, service, user ];
    
    PFQuery *getAvailabilitiesQuery = [PFQuery queryWithClassName:SCHAvailabilityForAppointmentClass predicate:GetAvailabilitiesPredicate];
    [getAvailabilitiesQuery orderByAscending:@"startTime"];
    
    NSArray *existingAvailabilities = [getAvailabilitiesQuery findObjects:&error];
    if (error){
        success = NO;
        return success;
    }
    
    if (debug){
        NSLog(@"refresh Availabilityforappointment: availability count %lu", (unsigned long)existingAvailabilities.count);
        for (SCHAvailabilityForAppointment *availability in existingAvailabilities){
            NSLog(@" availability availability for appointment start time:%@", availability.startTime );
        }
    }
    
    
    
    [objectsForDelete addObjectsFromArray:existingAvailabilities];
    NSDate *availabilityRefreshStartTime = [[NSDate alloc] init];
    NSDate *availabilityRefreshEndtime =  [[NSDate alloc] init];
    
    if (existingAvailabilities.count == 0){
        availabilityRefreshStartTime = timeFrom;
        availabilityRefreshEndtime = timeTo;
    }else {
        availabilityRefreshStartTime = [[(SCHAvailabilityForAppointment *)[existingAvailabilities firstObject] startTime] compare: timeFrom] == NSOrderedAscending ? [(SCHAvailabilityForAppointment *)[existingAvailabilities firstObject] startTime ]: timeFrom;
        availabilityRefreshEndtime = ([[(SCHAvailabilityForAppointment *)[existingAvailabilities lastObject] endTime] compare: timeTo] == NSOrderedDescending) ? [(SCHAvailabilityForAppointment *)[existingAvailabilities lastObject] endTime] : timeTo;
    }
    
    if (debug) {
        NSLog(@"input time from: %@ - input time to: %@", timeFrom, timeTo);
        NSLog(@"first availability time from: %@ -- last availability time to: %@", [(SCHAvailabilityForAppointment *)[existingAvailabilities firstObject] startTime ], [(SCHAvailabilityForAppointment *)[existingAvailabilities lastObject] endTime]);
        NSLog(@"refresh avail: availability Start Time: %@ - availability end Time: %@", availabilityRefreshStartTime, availabilityRefreshEndtime);
    }
    
    
    
    //Get all timeblocks in refresh time interval
    //Get all timeblocks in refresh time interval
    NSMutableArray *existingTBIds = [[NSMutableArray alloc] init];
    
    if (timeBlocks.count > 0){
        for (SCHAvailableTimeBlock *tb in timeBlocks){
            if(tb.objectId){
                [existingTBIds addObject:tb.objectId];
            }
        }
        
    }
    
    
    NSPredicate *timeBlocksForRefreshPredicate = [NSPredicate predicateWithFormat:@"startTime >= %@ AND endTime <= %@ AND appointment = null AND user = %@", availabilityRefreshStartTime, availabilityRefreshEndtime, user ];
    
    PFQuery *timeBlocksForRefreshQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeBlocksForRefreshPredicate];
    [timeBlocksForRefreshQuery whereKey:@"availableForNewRequest" equalTo:@YES];
    if (existingTBIds.count > 0){
        [timeBlocksForRefreshQuery whereKey:@"objectId" notContainedIn:existingTBIds];
    }
    [timeBlocksForRefreshQuery includeKey:@"services"];
    
    NSMutableSet *timeBlockForRefreshSet = [[NSMutableSet alloc] initWithArray:[timeBlocksForRefreshQuery findObjects:&error]];
    
    if (error){
        success = NO;
        return success;
    }
    if (timeBlocks.count > 0){
        [timeBlockForRefreshSet addObjectsFromArray:timeBlocks];
    }
    
    
    
    if (debug){
        for(SCHAvailableTimeBlock *timeblock in timeBlockForRefreshSet){
            NSLog(@"timeblock - start Time: %@ - end time: %@", timeblock.startTime, timeblock.endTime);
        }
        
    }
    
    
    // filter out all timeblocks that doesnot have service
    
    
    NSPredicate *filterTBWithService = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *timeBlock, NSDictionary *bindings) {
        if ([timeBlock.services containsObject:service] ){
            return YES;
        } else return  NO;
    }];
    
    NSSortDescriptor *sortTBwithService = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    
    NSArray *TBwithService = [[[timeBlockForRefreshSet allObjects] filteredArrayUsingPredicate:filterTBWithService] sortedArrayUsingDescriptors:@[sortTBwithService]];
    
    if (debug){
        for(SCHAvailableTimeBlock *timeblock in TBwithService){
            NSLog(@"timeblock with service - start Time: %@ - end time: %@", timeblock.startTime, timeblock.endTime);
        }
        
    }
    
    
    
    if (TBwithService.count > 0){
        //assemble blocks to create time blocks
        NSDate *availabilityStartTime = nil;
        NSDate *availabilityEndTime = nil;
        NSString *availabilityLoation = @"";
        PFGeoPoint *availabilityLocationPoint = nil;
        int iterationNumber = 1;
        
        for (SCHAvailableTimeBlock *timeBlock in  TBwithService){
            
            if (availabilityStartTime == nil){
                
                availabilityStartTime = timeBlock.startTime;
                availabilityEndTime = timeBlock.endTime;
                availabilityLoation = timeBlock.location;
                availabilityLocationPoint = timeBlock.locationPoint;
                
                if (debug){
                    NSLog(@"iteration Number: %d", iterationNumber);
                    NSLog(@"availability for appointment start time: %@ - availability end time: %@", availabilityStartTime, availabilityEndTime);
                }
                
                
            } else {
                if (([timeBlock.startTime compare:availabilityEndTime] == NSOrderedSame) && [availabilityLoation isEqualToString:timeBlock.location])
                {
                    //This means this is a conjucative block
                    availabilityEndTime = timeBlock.endTime;
                    if(debug) {
                        NSLog(@"iteration Number: %d", iterationNumber);
                        NSLog(@"availability for appointmentstart time: %@ - availability end time: %@", availabilityStartTime, availabilityEndTime);
                    }
                    
                    
                    
                } else {
                    //it is not conjucative block or different location
                    // create availability for appointment
                    [objectsForSave addObject:[self createAvailabilityForAppointmentWithuser:user
                                                                                    location:availabilityLoation
                                                                                 locationPoint:availabilityLocationPoint
                                                                                     service:service
                                                                                    timeForm:availabilityStartTime
                                                                                      timeTo:availabilityEndTime]];
                    //reset availability time
                    availabilityStartTime = timeBlock.startTime;
                    availabilityEndTime = timeBlock.endTime;
                    availabilityLoation = timeBlock.location;
                    availabilityLocationPoint = timeBlock.locationPoint;
                    
                } //if clause (timeBlock.startTime == availabilityEndTime)
                
            } //if clause (availabilityStartTime == nil)
            iterationNumber++;
        } //End of for loop
        
        
        // create availability - last one
        [objectsForSave addObject:[self createAvailabilityForAppointmentWithuser:user
                                                                        location:availabilityLoation
                                                                   locationPoint:availabilityLocationPoint
                                                                         service:service
                                                                        timeForm:availabilityStartTime
                                                                          timeTo:availabilityEndTime]];
        
    }
    
  //  NSLog(@"delete object count: %lu", (unsigned long)objectsForDelete.count);
   // NSLog(@"saveObject Count: %lu", (unsigned long)objectsForSave.count);
    
    
    
    if (objectsForDelete.count > 0){
        [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:objectsForDelete];

        
        
    }
    if (objectsForSave.count > 0){
        [appDelegate.backgroundCommit.objectsStagedForSave addObjectsFromArray:objectsForSave];
        
    }
    
    
    return success;
}



+(BOOL)removeAvailableTimeWithService:(SCHService *) service location:(NSString *) location timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo cancelAppointments:(BOOL) cancelAppointments{
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refrshStagedQueue];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.refreshQueue refresh];
    BOOL debug = NO;
    BOOL success = YES;
    NSError *error = nil;

    
    NSUInteger limit = 500;
    NSUInteger skip = 0;
    NSUInteger lastObjectCount = 0;
    NSUInteger CurrentObjectCount = 0;
    
    
    if (cancelAppointments){
        success = [self removeAppointmentsForService:service
                                           location:location
                                           timeFrom:timeFrom
                                               timeTo:timeTo];
    
    }
    
    if (success){
        SCHUser *user = appDelegate.user;
        //get alltimeblocks in refresh queue
        NSMutableSet *changedTimeblocks = [[NSMutableSet alloc] init];
        for (NSDictionary *refreshObject in appDelegate.refreshQueue.availabilityRefreshQueue){
            [changedTimeblocks addObjectsFromArray:[refreshObject valueForKey:@"timeBlocks"]];
            
        }
        
        // Arrays to remove or changed time Block
        //Get all existing time Blocks in the time frame
        NSMutableArray *timeBlocks = [[NSMutableArray alloc] init];
        NSPredicate *getTimeBlockPredicate = [NSPredicate predicateWithFormat:@"(startTime >= %@) AND endTime <= %@ AND  allocationRequested = NO AND appointment = null AND (user = %@)",timeFrom, timeTo, user];
        PFQuery *getTimeBlocks = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:getTimeBlockPredicate];
        [getTimeBlocks setLimit:limit];
        while (CurrentObjectCount == skip){
            lastObjectCount = CurrentObjectCount;
            [getTimeBlocks setSkip:skip];
            [timeBlocks addObjectsFromArray:[getTimeBlocks findObjects:&error]];
            if (error){
                [timeBlocks removeAllObjects];
                success = NO;
                break;
            }
            
            CurrentObjectCount = [timeBlocks count];
            if (lastObjectCount == CurrentObjectCount){
                break;
            } else {
                skip = skip + limit;
            }
            
        }
        
        if (!success){
            return success;
        }
        NSMutableSet *existingTimeBlocks = [[NSMutableSet alloc] initWithCapacity:timeBlocks.count];
        
        [existingTimeBlocks addObjectsFromArray:timeBlocks];
        
       
        
        if (changedTimeblocks.count > 0){
            
            [existingTimeBlocks addObjectsFromArray:[changedTimeblocks allObjects]];
        }
        
        if ((service == NULL) && (location == NULL)){  // No servie and No location
            //remove all timeblck and related data
            statement = 130;
            if(debug) {
                NSLog(@"Statement: %ld",(long)statement);
                NSLog(@"No Location and  NO Service. Time block along with all its services will be removed");
            }
            
            // [timeBlockForRemove addObjectsFromArray:[existingTimeBlocks allObjects]];
            [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:[existingTimeBlocks allObjects]];
            
            
        } else if  (service != NULL && location != NULL) {
            //Just remove mentioned location for that service within the time blocks
            //Find time blocks
            if (debug){
                NSLog(@" Location and Service. App will remove services for that location if no other service available for time block then time block will be removed");
            }
            
            NSPredicate *TBfilterForLocationAndService = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *timeBlock, NSDictionary *bindings) {
                if([timeBlock.location isEqualToString:location] && [timeBlock.services containsObject:service]){
                    return YES;
                    
                } else return NO;
            }];
            
            NSSet *TBMatchingLocationAndServiceSet = [existingTimeBlocks filteredSetUsingPredicate:TBfilterForLocationAndService];
            
            if(debug){
                NSLog(@"TimeBlocks matching service and location for removal or change: %lu", (unsigned long)[TBMatchingLocationAndServiceSet count]);
            }
            
            for (SCHAvailableTimeBlock *timeBlock in TBMatchingLocationAndServiceSet){
                if (timeBlock.services.count == 1){
                    // [timeBlockForRemove addObject:timeBlock];
                    [appDelegate.backgroundCommit.objectsStagedForDelete addObject:timeBlock];
                } else {
                    NSMutableArray *timeBlockServices = [[NSMutableArray alloc] initWithArray:timeBlock.services];
                    [timeBlockServices removeObject:service];
                    timeBlock.services = timeBlockServices;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:timeBlock];
                }
                
            }

            
        }else if (service != NULL  && location == NULL){
            // remove that service for all location.
            //Find time blocks
           // NSLog(@" NO Location and  Yes Service. service will be removed for time frame. If no service remains the timeblock removed");
            
            NSPredicate *TBfilterForService = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *timeBlock, NSDictionary *bindings) {
                if([timeBlock.services containsObject:service]){
                    return YES;
                    
                } else return NO;
            }];
            NSSet *TBMatchingServiceSet = [existingTimeBlocks filteredSetUsingPredicate:TBfilterForService];
            
            
            for (SCHAvailableTimeBlock *timeBlock in TBMatchingServiceSet){
                if (timeBlock.services.count == 1){
                    [appDelegate.backgroundCommit.objectsStagedForDelete addObject:timeBlock];
                } else {
                    NSMutableArray *timeBlockServices = [[NSMutableArray alloc] initWithArray:timeBlock.services];
                    [timeBlockServices removeObject:service];
                    timeBlock.services = timeBlockServices;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:timeBlock];
                }
                
            }
            
            
        } else if (service == NULL && location != NULL) {
            // delete mentioned locations
            //Find time blocks
            statement = 220;
            if (debug){
                NSLog(@"Statement:%ld", (long)statement);
                NSLog(@" Location and Service.  if time block available for that location the it will be removed");
            }
            
            NSPredicate *TBfilterForLocation = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *timeBlock, NSDictionary *bindings) {
                if([timeBlock.location isEqualToString:location]){
                    return YES;
                    
                } else return NO;
            }];
            
            [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:[[existingTimeBlocks filteredSetUsingPredicate:TBfilterForLocation] allObjects]];

        } // end of service and location combination if clause
    }
    
    if (success){
        SCHObjectsForProcessing *objectsForProcessing = [SCHObjectsForProcessing sharedManager];
        [objectsForProcessing.objectsForProcessing removeAllObjects];
        [SCHAppointmentManager commit];
    }
    [appDelegate.backgroundCommit refrshStagedQueue];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.refreshQueue refresh];
    
    

    
    return success;
    
    
}



+(NSArray *) createAvailabilityForTimeBlocks:(NSArray *) timeBlocks user:(SCHUser *) user{
    BOOL debug = NO;
    NSMutableArray *availabilities = [[NSMutableArray alloc] init];
    NSMutableArray *availabilityServices = [[NSMutableArray alloc] init];
    
    
    if (debug){
        NSLog(@"timelock count: %lu", (unsigned long)timeBlocks.count);
    }
    
    
    
    if ([timeBlocks count] != 0){
        //assemble blocks to create time blocks
        NSDate *availabilityStartTime = nil;
        NSDate *availabilityEndTime = nil;
        NSString *availabilityLoation = @"";
        [availabilityServices removeAllObjects];
        int iterationNumber = 1;
        for (SCHAvailableTimeBlock *timeBlock in  timeBlocks){
            
            if (availabilityStartTime == nil){
                
                availabilityStartTime = timeBlock.startTime;
                availabilityEndTime = timeBlock.endTime;
                availabilityLoation = timeBlock.location;
                if (debug){
                    NSLog(@"iteration Number: %d", iterationNumber);
                    NSLog(@"availability start time: %@ - availability end time: %@", availabilityStartTime, availabilityEndTime);
                }
                
                // add services with their start and end time
                for (SCHService *service in timeBlock.services){
                    
                    
                    NSDictionary *availabilityService = @{@"service":service, @"startTime":timeBlock.startTime, @"endTime": timeBlock.endTime};
                    if (debug){
                        NSLog(@"service: %@, startTime: %@, endtime: %@", [(SCHService *)[availabilityService valueForKey:@"service"] serviceTitle], [availabilityService valueForKey:@"startTime"], [availabilityService valueForKey:@"endTime"]);
                    }
                    
                    [availabilityServices addObject:availabilityService];
                }
                
            } else {
                if (([timeBlock.startTime compare:availabilityEndTime] == NSOrderedSame) && [availabilityLoation isEqualToString:timeBlock.location])
                {
                    //This means this is a conjucative block
                    availabilityEndTime = timeBlock.endTime;
                    if(debug) {
                        NSLog(@"iteration Number: %d", iterationNumber);
                        NSLog(@"availability start time: %@ - availability end time: %@", availabilityStartTime, availabilityEndTime);
                    }
                    
                    // add services with their start and end time
                    for (SCHService *service in timeBlock.services){
                        NSDictionary *availabilityService = @{@"service":service, @"startTime":timeBlock.startTime, @"endTime": timeBlock.endTime};
                        if (debug){
                            NSLog(@"service: %@, startTime: %@, endtime: %@", [(SCHService *)[availabilityService valueForKey:@"service"] serviceTitle], [availabilityService valueForKey:@"startTime"], [availabilityService valueForKey:@"endTime"]);
                        }
                        
                        [availabilityServices addObject:availabilityService];
                    }
                } else {
                    //it is not conjucative block or different location
                    // create availability;
                    SCHAvailability *availability = [self availableWithStartTime:availabilityStartTime endTime:availabilityEndTime location:availabilityLoation services:availabilityServices user:user];
                    
                    [availabilities addObject:availability];
                    /*if (debug) {
                     NSLog(@"availability start Time: %@ and end Time: %@", availability.startTime, availability.endTime);
                     for (SCHAvailabilityService *service in availability.services){
                     NSLog(@"service: %@ - start time:%@    End Time:%@", service.service.serviceTitle, service.startTime, service.endTime);
                     }
                     }*/
                    //reset availability time
                    availabilityStartTime = timeBlock.startTime;
                    availabilityEndTime = timeBlock.endTime;
                    availabilityLoation = timeBlock.location;
                    [availabilityServices removeAllObjects];
                    // add services with their start and end time
                    for (SCHService *service in timeBlock.services){
                        NSDictionary *availabilityService = @{@"service":service, @"startTime":timeBlock.startTime, @"endTime": timeBlock.endTime};
                        [availabilityServices addObject:availabilityService];
                    }
                } //if clause (timeBlock.startTime == availabilityEndTime)
                
            } //if clause (availabilityStartTime == nil)
            iterationNumber++;
        } //End of for loop
        if (debug){
            NSLog(@"availability service count: %lu", (unsigned long)availabilityServices.count);
        }
        
        
        // create availability - last one
        SCHAvailability *availability = [self availableWithStartTime:availabilityStartTime endTime:availabilityEndTime location:availabilityLoation services:availabilityServices user:user];
        
        
        
        
        
        [availabilities addObject:availability];
        
        
        
    } // timeblock available if clause
    
    if (debug) {
        for (SCHAvailability *availability in availabilities){
            NSLog(@"availability Detail - start Time: %@, End Time: %@, Location: %@", availability.startTime, availability.endTime, availability.location);
            for (NSDictionary *availabilityservice in availability.services){
                NSLog(@"service: %@ - start time: %@ - end time: %@", [(SCHService *)[availabilityservice valueForKey:@"service"] serviceTitle], [availabilityservice valueForKey:@"startTime"], [availabilityservice valueForKey:@"endTime"]);
            }
            
        }
    }
    
    
    
    
    return  availabilities;
    
}

+(SCHAvailability *) availableWithStartTime:(NSDate *) startTime endTime:(NSDate *) endTime location:(NSString *)location  services:(NSArray *) services user: (SCHUser *)user{
    
    SCHAvailability *availability = [SCHAvailability object];
    availability.startTime = startTime;
    availability.endTime = endTime;
    availability.location = location;
    availability.user = user;
    availability.services = [self servicesForAvailabilityStartTime:startTime endTime:endTime services:services user:user];
    [SCHUtility setPublicAllRWACL:availability.ACL];
   
    
    return availability;
}

+ (NSArray *) servicesForAvailabilityStartTime:(NSDate *) startTime endTime:(NSDate *) endTime services:(NSArray *) services user: (SCHUser *) user{
    BOOL debug = NO;
   // NSLog(@"creating availability services");
    if (debug){
        NSLog(@"services count: %lu", (unsigned long)services.count);
    }
    
    //order service array with start time
    NSSortDescriptor *orderServices = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    [services sortedArrayUsingDescriptors:@[orderServices]];
    
    if (debug){
        for (NSDictionary *service in services){
            NSLog(@"Service: %@, start Time: %@, end Time: %@", [(SCHService *)[service valueForKey:@"service"] serviceTitle], [service valueForKey:@"startTime"], [service valueForKey:@"endTime"] );
        }
    }
    
    
    
    NSMutableArray *availabilityServices = [[NSMutableArray alloc] init];
    NSMutableSet *serviceSet = [[NSMutableSet alloc] init];
    // Get unique services
    for (NSDictionary *service in services){
        [serviceSet addObject:[service valueForKey:@"service"]];
    }
    if (debug){
        for (SCHService *service in serviceSet) {
            NSLog(@"serviceset- service: %@", service.serviceTitle);
        }
        
    }
    
    // Find each service start time and end time in availability time
    
    NSMutableArray *serviceBlocks = [[NSMutableArray alloc] init];
    for (SCHService *service in serviceSet) {
        [serviceBlocks removeAllObjects];
        NSPredicate *filterForService = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *serviceBlock, NSDictionary *bindings) {
            if ([serviceBlock valueForKey:@"service"] == service){
                return YES;
            } else return NO;
        }];
        [serviceBlocks addObjectsFromArray:[services filteredArrayUsingPredicate:filterForService]];
        [serviceBlocks sortedArrayUsingDescriptors:@[orderServices]];
        if (debug){
            NSLog (@"serviceblocks count: %lu for service: %@", (unsigned long)serviceBlocks.count, service.serviceTitle);
        }
        
        
        NSDate *serviceStartTime = nil;
        NSDate *serviceEndTime = nil;
        
        for (NSDictionary *serviceBlock in serviceBlocks){
            if (debug){
                NSLog(@"service: %@ - service Block detail- service: %@, start Time: %@, endTime: %@", service.serviceTitle, [(SCHService *)[serviceBlock valueForKey:@"service"] serviceTitle], [serviceBlock valueForKey:@"startTime"], [serviceBlock valueForKey:@"endTime"]);
            }
            
            if (serviceStartTime == nil){
                serviceStartTime = [serviceBlock valueForKey:@"startTime"];
                serviceEndTime = [serviceBlock valueForKey:@"endTime"];
            } else {
                if ([serviceEndTime compare:[serviceBlock valueForKey:@"startTime"]] == NSOrderedSame){
                    serviceEndTime = [serviceBlock valueForKey:@"endTime"];
                } else { //create SCH availability service
                    //create availability service and add to array
                    
                    [availabilityServices addObject:[self createAvailabilityService:service startTime:serviceStartTime endTime:serviceEndTime]];
                    // reset start and end time
                    serviceStartTime = [serviceBlock valueForKey:@"startTime"];
                    serviceEndTime = [serviceBlock valueForKey:@"endTime"];
                }
            }
            
        } //timeblock loop
        // create service availability last one
        
        [availabilityServices addObject:[self createAvailabilityService:service startTime:serviceStartTime endTime:serviceEndTime]];
        
    } //service set loop
    
    //reload table view
    //  [SCHUtility reloadScheduleTableView];
    
    return availabilityServices;
    
}

+(NSDictionary *) createAvailabilityService:(SCHService *) service startTime:(NSDate *) startTime endTime:(NSDate *) endTime{
    
    NSDictionary *availabilityService = @{@"service": service, @"startTime": startTime, @"endTime": endTime};
    
    return availabilityService;
    
    
}



+(SCHAvailabilityForAppointment *)createAvailabilityForAppointmentWithuser:(SCHUser *) user location:(NSString *) location locationPoint:(PFGeoPoint *) locationPoint service:(SCHService *) service timeForm:(NSDate *) timeFrom timeTo:(NSDate *) timeTo {
    SCHAvailabilityForAppointment *availabilityForAppointment = [SCHAvailabilityForAppointment object];
    availabilityForAppointment.user = user;
    availabilityForAppointment.location = location;
    availabilityForAppointment.locationPoint = locationPoint;
    availabilityForAppointment.service = service;
    availabilityForAppointment.startTime = timeFrom;
    availabilityForAppointment.endTime = timeTo;
    [SCHUtility setPublicAllRWACL:availabilityForAppointment.ACL];

    
    return availabilityForAppointment;
    
}



// New logic
+(BOOL) refreshNetAvailabilities{
    
    BOOL success = YES;
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableSet *availabilitiesForremoval = [[NSMutableSet alloc] init];
    NSMutableSet *availablitiesForSave = [[NSMutableSet alloc] init];
    NSMutableSet *currentAvailabilities = [[NSMutableSet alloc] init];
    
    NSDate *startTime = nil;
    NSDate *endTime = nil;
    NSArray *changedOrNewTimeBlocks = nil;
    SCHUser *user = nil;
    SCHService *service = nil;
    
    //get all availabilities to be refreshed
    
    for (NSDictionary *refreshDict in appDelegate.refreshQueue.availabilityRefreshQueue){
        startTime = [refreshDict valueForKey:@"startTime"];
        endTime = [refreshDict valueForKey:@"endTime"];
        user = [refreshDict valueForKey:@"user"];
        service = [refreshDict valueForKey: @"service"];
        NSPredicate *GetAvailabilitiesPredicate = [NSPredicate predicateWithFormat:@"((startTime BETWEEN  %@ OR endTime BETWEEN %@) OR (startTime <= %@ AND endTime >= %@)) AND user = %@", @[startTime, endTime],@[startTime, endTime], startTime, endTime, user ];
        
        PFQuery *getAvailabilitiesQuery = [PFQuery queryWithClassName:SCHAvailabilityClass predicate:GetAvailabilitiesPredicate];
        [getAvailabilitiesQuery orderByAscending:@"startTime"];
        
        
        NSArray *existingAvailabilities  = [getAvailabilitiesQuery findObjects:&error];
        if (error){
            success = NO;
            return  NO;
        }
        [currentAvailabilities addObjectsFromArray:existingAvailabilities];
        

        
    }
    
    startTime = nil;
    endTime = nil;
   changedOrNewTimeBlocks = nil;
    user = nil;
    service = nil;
    
    
    
    for (NSDictionary *refreshDict in appDelegate.refreshQueue.availabilityRefreshQueue){
        
        startTime = [refreshDict valueForKey:@"startTime"];
        endTime = [refreshDict valueForKey:@"endTime"];
        user = [refreshDict valueForKey:@"user"];
        service = [refreshDict valueForKey: @"service"];
        changedOrNewTimeBlocks = [refreshDict valueForKey:@"timeBlocks"];
        
        //get all availabilities in  current set that will be refreshed
        NSPredicate *GetAvailabilitiesPredicate = [NSPredicate predicateWithFormat:@"((startTime BETWEEN  %@ OR endTime BETWEEN %@) OR (startTime <= %@ AND endTime >= %@))", @[startTime, endTime],@[startTime, endTime], startTime, endTime];
        
        NSSortDescriptor *existingAvailabilitySort = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
        
        

        
        
        NSArray *existingAvailabilities  = [[[currentAvailabilities filteredSetUsingPredicate:GetAvailabilitiesPredicate] allObjects] sortedArrayUsingDescriptors:@[existingAvailabilitySort]];
        
        [availabilitiesForremoval addObjectsFromArray:existingAvailabilities];
        
        [currentAvailabilities minusSet:[NSSet setWithArray:existingAvailabilities]];
        
        [availablitiesForSave minusSet:[NSSet setWithArray:existingAvailabilities]];
        
        NSDate *availabilityRefreshStartTime = nil;
        NSDate *availabilityRefreshEndtime =  nil;
        
        if (existingAvailabilities.count == 0){
            availabilityRefreshStartTime = startTime;
            availabilityRefreshEndtime = endTime;
        }else {
            availabilityRefreshStartTime = [[(SCHAvailability *)[existingAvailabilities firstObject] startTime] compare: startTime] == NSOrderedAscending ? [(SCHAvailability *)[existingAvailabilities firstObject] startTime ]: startTime;
            availabilityRefreshEndtime = ([[(SCHAvailability *)[existingAvailabilities lastObject] endTime] compare: endTime] == NSOrderedDescending) ? [(SCHAvailability *)[existingAvailabilities lastObject] endTime] : endTime;
        }
        
        if (debug) {
            NSLog(@"input time from: %@ - input time to: %@", startTime, endTime);
            NSLog(@"first availability time from: %@ -- last availability time to: %@", [(SCHAvailability *)[existingAvailabilities firstObject] startTime ], [(SCHAvailability *)[existingAvailabilities lastObject] endTime]);
            NSLog(@"refresh avail: availability Start Time: %@ - availability end Time: %@", availabilityRefreshStartTime, availabilityRefreshEndtime);
        }
       
        //Get all timeblocks in refresh time interval
        NSMutableArray *existingTBIds = [[NSMutableArray alloc] init];
        if (changedOrNewTimeBlocks.count > 0){
            for (SCHAvailableTimeBlock *tb in changedOrNewTimeBlocks){
                if(tb.objectId){
                    [existingTBIds addObject:tb.objectId];
                }
                
            }
            
        }
        
        
        NSUInteger limit = 500;
        NSUInteger skip = 0;
        NSUInteger lastObjectCount = 0;
        NSUInteger CurrentObjectCount = 0;
        
        
        NSPredicate *timeBlocksForRefreshPredicate = [NSPredicate predicateWithFormat:@"startTime >= %@ AND endTime <= %@ AND user = %@", availabilityRefreshStartTime, availabilityRefreshEndtime, user ];
        
        PFQuery *timeBlocksForRefreshQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeBlocksForRefreshPredicate];
        [timeBlocksForRefreshQuery whereKey:@"availableForNewRequest" equalTo:@YES];
        
        if (existingTBIds.count > 0){
            [timeBlocksForRefreshQuery whereKey:@"objectId" notContainedIn:existingTBIds];
        }
         
        
        
        [timeBlocksForRefreshQuery includeKey:@"services"];
        
        //  NSMutableSet *timeBlockForRefreshSet = [[NSMutableSet alloc] init];
        [timeBlocksForRefreshQuery setLimit:limit];
        
        
        NSMutableArray *timeBlocks = [[NSMutableArray alloc] init];
        while (CurrentObjectCount == skip){
            lastObjectCount = CurrentObjectCount;
            [timeBlocksForRefreshQuery setSkip:skip];
            [timeBlocks addObjectsFromArray:[timeBlocksForRefreshQuery findObjects:&error]];
            if (error){
                [timeBlocks removeAllObjects];
                success = NO;
                break;
            }
            
            CurrentObjectCount = [timeBlocks count];
            if (lastObjectCount == CurrentObjectCount){
                break;
            } else {
                skip = skip + limit;
            }
            
        }
        
        if (!success){
            return success;
        }
        
        NSMutableSet *timeBlockForRefreshSet = [[NSMutableSet alloc] initWithArray:timeBlocks];

        
        if (debug){
            for(SCHAvailableTimeBlock *timeblock in timeBlockForRefreshSet){
                NSLog(@"timeblock - start Time: %@ - end time: %@", timeblock.startTime, timeblock.endTime);
            }
            
        }
        
        
        // addtimeblocks being processed
        if (changedOrNewTimeBlocks.count > 0){
            for (SCHAvailableTimeBlock *tb in changedOrNewTimeBlocks){
                if (!tb.appointment){
                    [timeBlockForRefreshSet addObject:tb];
                }
            }
        }
         
        
        
        
        
        // fileter the timeblocks with absolute availability
        
        NSPredicate *filterTBWithabsoluteAvailability = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *timeBlock, NSDictionary *bindings) {
            if (timeBlock.allocationRequested || timeBlock.appointment || !timeBlock.availableForNewRequest){
                return NO;
            } else return  YES;
        }];
        
        NSSortDescriptor *sortTBwithAbsoluteAvailability = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
        
        NSArray *TBwithAbsoluteAvailabiity = [[[timeBlockForRefreshSet allObjects] filteredArrayUsingPredicate:filterTBWithabsoluteAvailability] sortedArrayUsingDescriptors:@[sortTBwithAbsoluteAvailability]];
        
        
        
        
        if (debug){
            
            NSLog(@"TimeBlock with absolute availability: %lu", (unsigned long)TBwithAbsoluteAvailabiity.count);
            for(SCHAvailableTimeBlock *timeblock in TBwithAbsoluteAvailabiity){
                NSLog(@"timeblock with absolute availability - start Time: %@ - end time: %@", timeblock.startTime, timeblock.endTime);
            }
            
        }
        
        // create availability
        NSArray *newAvailabilities = [self createAvailabilityForTimeBlocks:TBwithAbsoluteAvailabiity user:user];
        
        [availablitiesForSave addObjectsFromArray:newAvailabilities];
        [currentAvailabilities addObjectsFromArray:newAvailabilities];
        
    }
    
   // [appDelegate.refreshQueue refresh];
    
    [appDelegate.backgroundCommit.objectsStagedForSave addObjectsFromArray:[availablitiesForSave allObjects]];
    [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:[availablitiesForSave allObjects]];
    [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:[availabilitiesForremoval allObjects]];
    [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:[availabilitiesForremoval allObjects]];
    
    
    return success;
}

+(BOOL) refreshAvailabilitiesForAppointment{
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL debug = NO;
    BOOL success = YES;
    NSError *error  = nil;
    NSMutableSet *availabilitiesForremoval = [[NSMutableSet alloc] init];
    NSMutableSet *availablitiesForSave = [[NSMutableSet alloc] init];
    NSMutableSet *currentAvailabilities = [[NSMutableSet alloc] init];
    
    NSDate *startTime = nil;
    NSDate *endTime = nil;
    NSArray *changedOrNewTimeBlocks = nil;
    SCHUser *user = nil;
    SCHService *service = nil;
    
    for (NSDictionary *refreshDict in appDelegate.refreshQueue.availabilityRefreshQueue){
        startTime = [refreshDict valueForKey:@"startTime"];
        endTime = [refreshDict valueForKey:@"endTime"];
        user = [refreshDict valueForKey:@"user"];
        service = [refreshDict valueForKey: @"service"];
        
        NSPredicate *GetAvailabilitiesPredicate = [NSPredicate predicateWithFormat:@"((startTime BETWEEN  %@ OR endTime BETWEEN %@) OR (startTime <= %@ AND endTime >= %@)) AND service = %@ AND user = %@", @[startTime, endTime],@[startTime, endTime], startTime, endTime, service, user ];
        
        PFQuery *getAvailabilitiesQuery = [PFQuery queryWithClassName:SCHAvailabilityForAppointmentClass predicate:GetAvailabilitiesPredicate];
        [getAvailabilitiesQuery orderByAscending:@"startTime"];
        
        NSArray *existingAvailabilities = [getAvailabilitiesQuery findObjects:&error];
        if (error){
            success = NO;
            return success;
        }
         [currentAvailabilities addObjectsFromArray:existingAvailabilities];
        
    }
    
    
    startTime = nil;
    endTime = nil;
    changedOrNewTimeBlocks= nil;
    user = nil;
    service = nil;
    
    for (NSDictionary *refreshDict in appDelegate.refreshQueue.availabilityRefreshQueue){
        
        startTime = [refreshDict valueForKey:@"startTime"];
        endTime = [refreshDict valueForKey:@"endTime"];
        user = [refreshDict valueForKey:@"user"];
        service = [refreshDict valueForKey: @"service"];
        changedOrNewTimeBlocks = [refreshDict valueForKey:@"timeBlocks"];
        NSPredicate *GetAvailabilitiesPredicate = [NSPredicate predicateWithFormat:@"((startTime BETWEEN  %@ OR endTime BETWEEN %@) OR (startTime <= %@ AND endTime >= %@)) AND service = %@ AND user = %@", @[startTime, endTime],@[startTime, endTime], startTime, endTime, service, user ];
        
        NSSortDescriptor *existingAvailabilitySort = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
        
        
        
        
        
        NSArray *existingAvailabilities  = [[[currentAvailabilities filteredSetUsingPredicate:GetAvailabilitiesPredicate] allObjects] sortedArrayUsingDescriptors:@[existingAvailabilitySort]];
        
        [availabilitiesForremoval addObjectsFromArray:existingAvailabilities];
        
        [currentAvailabilities minusSet:[NSSet setWithArray:existingAvailabilities]];
        
        [availablitiesForSave minusSet:[NSSet setWithArray:existingAvailabilities]];
        
        
        NSDate *availabilityRefreshStartTime = nil;
        NSDate *availabilityRefreshEndtime =  nil;
        
        if (existingAvailabilities.count == 0){
            availabilityRefreshStartTime = startTime;
            availabilityRefreshEndtime = endTime;
        }else {
            availabilityRefreshStartTime = [[(SCHAvailabilityForAppointment *)[existingAvailabilities firstObject] startTime] compare: startTime] == NSOrderedAscending ? [(SCHAvailabilityForAppointment *)[existingAvailabilities firstObject] startTime ]: startTime;
            availabilityRefreshEndtime = ([[(SCHAvailabilityForAppointment *)[existingAvailabilities lastObject] endTime] compare: endTime] == NSOrderedDescending) ? [(SCHAvailabilityForAppointment *)[existingAvailabilities lastObject] endTime] : endTime;
        }
        
        if (debug) {
            NSLog(@"input time from: %@ - input time to: %@", startTime, endTime);
            NSLog(@"first availability time from: %@ -- last availability time to: %@", [(SCHAvailabilityForAppointment *)[existingAvailabilities firstObject] startTime ], [(SCHAvailabilityForAppointment *)[existingAvailabilities lastObject] endTime]);
            NSLog(@"refresh avail: availability Start Time: %@ - availability end Time: %@", availabilityRefreshStartTime, availabilityRefreshEndtime);
        }
        
        
        //Get all timeblocks in refresh time interval
        
        NSMutableArray *existingTBIds = [[NSMutableArray alloc] init];
        
        if (changedOrNewTimeBlocks.count > 0){
            for (SCHAvailableTimeBlock *tb in changedOrNewTimeBlocks){
                if(tb.objectId){
                    [existingTBIds addObject:tb.objectId];
                }
            }
            
        }
        
        
        NSUInteger limit = 500;
        NSUInteger skip = 0;
        NSUInteger lastObjectCount = 0;
        NSUInteger CurrentObjectCount = 0;
        
        NSPredicate *timeBlocksForRefreshPredicate = [NSPredicate predicateWithFormat:@"startTime >= %@ AND endTime <= %@  AND user = %@", availabilityRefreshStartTime, availabilityRefreshEndtime, user ];
        
        PFQuery *timeBlocksForRefreshQuery = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:timeBlocksForRefreshPredicate];
        [timeBlocksForRefreshQuery whereKey:@"availableForNewRequest" equalTo:@YES];
        
        if (existingTBIds.count > 0){
            [timeBlocksForRefreshQuery whereKey:@"objectId" notContainedIn:existingTBIds];
        }
        
        [timeBlocksForRefreshQuery includeKey:@"services"];
        [timeBlocksForRefreshQuery setLimit:limit];
        
        
        NSMutableArray *timeBlocks = [[NSMutableArray alloc] init];
        while (CurrentObjectCount == skip){
            lastObjectCount = CurrentObjectCount;
            [timeBlocksForRefreshQuery setSkip:skip];
            [timeBlocks addObjectsFromArray:[timeBlocksForRefreshQuery findObjects:&error]];
            if (error){
                [timeBlocks removeAllObjects];
                success = NO;
                break;
            }
            
            CurrentObjectCount = [timeBlocks count];
            if (lastObjectCount == CurrentObjectCount){
                break;
            } else {
                skip = skip + limit;
            }
            
        }
        
        if (!success){
            return success;
        }
        
        NSMutableSet *timeBlockForRefreshSet = [[NSMutableSet alloc] initWithArray:timeBlocks];
        
        if (changedOrNewTimeBlocks.count > 0){
            for (SCHAvailableTimeBlock *tb in changedOrNewTimeBlocks){
                if (!tb.appointment){
                    [timeBlockForRefreshSet addObject:tb];
                }
            }
        }
        
        
        // take out all time blocks that has appointment allocated to it
        NSPredicate *tbWithoutAppointmentPredicate = [NSPredicate predicateWithFormat:@"appointment = NULL AND availableForNewRequest = YES"];
        
        [timeBlockForRefreshSet filterUsingPredicate:tbWithoutAppointmentPredicate];
        
        
        
        if (debug){
            for(SCHAvailableTimeBlock *timeblock in timeBlockForRefreshSet){
                NSLog(@"timeblock - start Time: %@ - end time: %@", timeblock.startTime, timeblock.endTime);
            }
            
        }
        
        
        // filter out all timeblocks that doesnot have service
        
        
        NSPredicate *filterTBWithService = [NSPredicate predicateWithBlock:^BOOL(SCHAvailableTimeBlock *timeBlock, NSDictionary *bindings) {
            if ([timeBlock.services containsObject:service] ){
                return YES;
            } else return  NO;
        }];
        
        NSSortDescriptor *sortTBwithService = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
        
        NSArray *TBwithService = [[[timeBlockForRefreshSet allObjects] filteredArrayUsingPredicate:filterTBWithService] sortedArrayUsingDescriptors:@[sortTBwithService]];
        
        if (debug){
            for(SCHAvailableTimeBlock *timeblock in TBwithService){
                NSLog(@"timeblock with service - start Time: %@ - end time: %@", timeblock.startTime, timeblock.endTime);
            }
            
        }
        
        if (TBwithService.count > 0){
            //assemble blocks to create time blocks
            NSDate *availabilityStartTime = nil;
            NSDate *availabilityEndTime = nil;
            NSString *availabilityLoation = @"";
            PFGeoPoint *availabilityLocationPoint = nil;
            int iterationNumber = 1;
            NSMutableArray *newAvailabilitiesForAppointment = [[NSMutableArray alloc] init];
            
            for (SCHAvailableTimeBlock *timeBlock in  TBwithService){
                
                if (availabilityStartTime == nil){
                    
                    availabilityStartTime = timeBlock.startTime;
                    availabilityEndTime = timeBlock.endTime;
                    availabilityLoation = timeBlock.location;
                    availabilityLocationPoint = timeBlock.locationPoint;
                    
                    if (debug){
                        NSLog(@"iteration Number: %d", iterationNumber);
                        NSLog(@"availability for appointment start time: %@ - availability end time: %@", availabilityStartTime, availabilityEndTime);
                    }
                    
                    
                } else {
                    if (([timeBlock.startTime compare:availabilityEndTime] == NSOrderedSame) && [availabilityLoation isEqualToString:timeBlock.location])
                    {
                        //This means this is a conjucative block
                        availabilityEndTime = timeBlock.endTime;
                        if(debug) {
                            NSLog(@"iteration Number: %d", iterationNumber);
                            NSLog(@"availability for appointmentstart time: %@ - availability end time: %@", availabilityStartTime, availabilityEndTime);
                        }
                        
                        
                        
                    } else {
                        //it is not conjucative block or different location
                        // create availability for appointment
                        [newAvailabilitiesForAppointment addObject:[self createAvailabilityForAppointmentWithuser:user
                                                                                        location:availabilityLoation
                                                                                     locationPoint:availabilityLocationPoint
                                                                                         service:service
                                                                                        timeForm:availabilityStartTime
                                                                                          timeTo:availabilityEndTime]];
                        //reset availability time
                        availabilityStartTime = timeBlock.startTime;
                        availabilityEndTime = timeBlock.endTime;
                        availabilityLoation = timeBlock.location;
                        availabilityLocationPoint = timeBlock.locationPoint;
                        
                    } //if clause (timeBlock.startTime == availabilityEndTime)
                    
                } //if clause (availabilityStartTime == nil)
                iterationNumber++;
            } //End of for loop
            
            
            // create availability - last one
            [newAvailabilitiesForAppointment  addObject:[self createAvailabilityForAppointmentWithuser:user
                                                                            location:availabilityLoation
                                                         locationPoint:availabilityLocationPoint
                                                                             service:service
                                                                            timeForm:availabilityStartTime
                                                                              timeTo:availabilityEndTime]];
            
            [availablitiesForSave addObjectsFromArray:newAvailabilitiesForAppointment];
            [currentAvailabilities addObjectsFromArray:newAvailabilitiesForAppointment];
            
        }


        
    }
    
    [appDelegate.backgroundCommit.objectsStagedForSave addObjectsFromArray:[availablitiesForSave allObjects]];
    [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:[availabilitiesForremoval allObjects]];
    
    return success;
    
}


+(BOOL) removeAppointmentsForService:(SCHService *) service location:(NSString *) location timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo{
    
    BOOL success = YES;
    SCHConstants *constants = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //find all appointments that falls in unavailability fime frame
    
    NSTimeInterval oneMin = 60;
    NSMutableSet *existingAppointmentSet = [[NSMutableSet alloc] init];
    
    
    NSDate *timeFromForCheck = [NSDate dateWithTimeInterval:oneMin sinceDate:timeFrom];
    NSDate *timeToForCheck = [NSDate dateWithTimeInterval:-oneMin sinceDate:timeTo];
    
    NSPredicate *existingAppointmentWithCurrentTimePred1 = [NSPredicate predicateWithFormat:@"serviceProvider = %@ AND status IN {%@, %@}  AND (startTime BETWEEN %@ OR endTime BETWEEN %@)", appDelegate.user, constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, @[timeFromForCheck, timeToForCheck], @[timeFromForCheck, timeToForCheck]];
    
    PFQuery *existingAppointmentQuery1 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred1];
    
    [existingAppointmentQuery1 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery1 findObjects]];
    
    NSPredicate *existingAppointmentWithCurrentTimePred2 = [NSPredicate predicateWithFormat:@"serviceProvider = %@ AND status IN {%@, %@}  AND (proposedStartTime BETWEEN %@ OR proposedEndTime BETWEEN %@)", appDelegate.user, constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, @[timeFromForCheck, timeToForCheck], @[timeFromForCheck, timeToForCheck]];
    
    PFQuery *existingAppointmentQuery2 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred2];
    
    [existingAppointmentQuery2 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery2 findObjects]];
    
    
    NSPredicate *existingAppointmentWithCurrentTimePred3 = [NSPredicate predicateWithFormat:@"serviceProvider = %@ AND status IN {%@, %@}  AND (startTime <= %@ AND endTime => %@)", appDelegate.user, constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, timeFromForCheck, timeToForCheck];
    
    PFQuery *existingAppointmentQuery3 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred3];
    
    [existingAppointmentQuery3 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery3 findObjects]];
    
    NSPredicate *existingAppointmentWithCurrentTimePred4 = [NSPredicate predicateWithFormat:@"status IN {%@, %@}  AND (proposedStartTime <= %@ AND proposedEndTime => %@)", constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, timeFromForCheck, timeToForCheck];
    
    PFQuery *existingAppointmentQuery4 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred4];
    
    [existingAppointmentQuery3 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery4 findObjects]];
    
    
    NSPredicate *appointmentFilter = [NSPredicate predicateWithBlock:^BOOL(SCHAppointment *appointment, NSDictionary<NSString *,id> * _Nullable bindings) {
        if ([appointment.status isEqual:constants.SCHappointmentStatusCancelled]){
            return NO;
        }
        if (appointment.expired){
            return NO;
        }
        return YES;
    }];
    
    [existingAppointmentSet filterUsingPredicate:appointmentFilter];
    
    
    
    //if there is service then discard the appointments that does not match to service
    
    if (service){
        NSPredicate *serviceFilterPredicate = [NSPredicate predicateWithFormat:@"service = %@", service];
        
        [existingAppointmentSet filterUsingPredicate:serviceFilterPredicate];
    }
    
    //if there is location then  discard the appointments that does not match to location
    if (location){
        NSPredicate *locationFilterPredicate = [NSPredicate predicateWithFormat:@"location = %@ OR proposedLocation = %@", location, location];
        [existingAppointmentSet filterUsingPredicate:locationFilterPredicate];
    }
    
    // Sacrigate the appointments for different actions
    
    NSMutableSet *appointmentsForCancellation = [[NSMutableSet alloc] init];
    NSMutableSet *appointmentsForDecline = [[NSMutableSet alloc] init];
    NSMutableSet *appointmentsForConfirmTimeBlockRelease = [[NSMutableSet alloc] init];
    
    
    for (SCHAppointment *appointment in existingAppointmentSet){
        if ([appointment.status isEqual:constants.SCHappointmentStatusConfirmed]){
            [appointmentsForCancellation addObject:appointment];
        } else{
            
            
            if (!appointment.proposedLocation && !appointment.proposedStartTime && !appointment.proposedEndTime){
                [appointmentsForDecline addObject:appointment];
            } else if (appointment.proposedLocation && !appointment.proposedStartTime && !appointment.proposedEndTime){
                
                [appointmentsForCancellation addObject:appointment];
            }else if (appointment.proposedStartTime || appointment.proposedEndTime){
                
                if ([self time:appointment.startTime fallsBetween:timeFromForCheck and:timeToForCheck]|| [self time:appointment.endTime fallsBetween:timeFromForCheck and:timeToForCheck]){
                    if ([self time:appointment.proposedStartTime fallsBetween:timeFromForCheck and:timeToForCheck] || [self time:appointment.proposedEndTime fallsBetween:timeFromForCheck and:timeToForCheck]){
                        [appointmentsForCancellation addObject:appointment];
                    } else{
                        // release confirmed time
                        [appointmentsForConfirmTimeBlockRelease addObject:appointment];
                    }
                    
                } else{
                    [appointmentsForDecline addObject:appointment];
                }
            }
            
            
            
            
            

        }
    } // end of for loop
    
    SCHObjectsForProcessing *objectsForProcessing = [SCHObjectsForProcessing sharedManager];
    [objectsForProcessing.objectsForProcessing addObjectsFromArray:[appointmentsForCancellation allObjects]];
    [objectsForProcessing.objectsForProcessing addObjectsFromArray:[appointmentsForConfirmTimeBlockRelease allObjects]];
    [objectsForProcessing.objectsForProcessing addObjectsFromArray:[appointmentsForDecline allObjects]];
    
    
    // Create Notification title and message
    NSString *title = [NSString stringWithFormat:@"%@ not available", appDelegate.user.preferredName];
    NSDateFormatter *dateformatter = [SCHUtility dateFormatterForFromTime];
    NSString *startTime = [dateformatter stringFromDate:timeFrom];
    NSString *endTime = [dateformatter stringFromDate:timeTo];
    NSString *message = [NSString stringWithFormat:@"%@ not available from %@ till %@",appDelegate.user.preferredName, startTime, endTime ];

    
    
    // Process decline
    for (SCHAppointment *appointment in appointmentsForDecline){
        if (![SCHAppointmentManager declineAppointmentRequest:appointment
                                                     isseries:NO
                                          refreshAvailability:NO
                                                         save:NO]){
            success = NO;
            break;
        } else{
            if  (appointment.client){
                SCHNotification *notification = [SCHUtility createNotificationForUser:appointment.client
                                                                     notificationType:constants.SCHNotificationForAcknowledgement
                                                                    notificationTitle:title
                                                                              message:message
                                                                      referenceObject:nil
                                                                  referenceObjectType:nil];
                
                [appDelegate.backgroundCommit.objectsStagedForSave addObject:notification];
                
                
            }
            
        }
    }
    
    // Process cancel appointment
    
    if (success){
        for (SCHAppointment *appointment in appointmentsForCancellation){
            if (![SCHAppointmentManager deleteAppointment:appointment
                                      refreshAvailability:NO
                                                     save:NO]){
                success = NO;
                break;
            } else {
                if  (appointment.client){
                    SCHNotification *notification = [SCHUtility createNotificationForUser:appointment.client
                                                                         notificationType:constants.SCHNotificationForAcknowledgement
                                                                        notificationTitle:title
                                                                                  message:message
                                                                          referenceObject:nil
                                                                      referenceObjectType:nil];
                    
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:notification];
                    
                    
                }

            }
            
        }
    }
    
    // Process release confirmed time
    if (success){
        for (SCHAppointment *appointment in appointmentsForConfirmTimeBlockRelease){
            if (![SCHAppointmentManager releaseConfirmedTimeForAppointment:appointment
                                                           refreshSchedule:NO
                                                                      save:NO]){
                success = NO;
                break;
            } else {
                if  (appointment.client){
                    SCHNotification *notification = [SCHUtility createNotificationForUser:appointment.client
                                                                         notificationType:constants.SCHNotificationForAcknowledgement
                                                                        notificationTitle:title
                                                                                  message:message
                                                                          referenceObject:nil
                                                                      referenceObjectType:nil];
                    
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:notification];
                    
                    
                }

            }
        }
    }

    
    
    return success;
}

+(BOOL)time:(NSDate *)time fallsBetween:(NSDate *)timeFrom and:(NSDate *) timeTo{
    NSComparisonResult startTimeCompare = [time compare:timeFrom];
    NSComparisonResult endTimeCompare = [time compare:timeTo];
    
    if ((startTimeCompare == NSOrderedDescending || startTimeCompare == NSOrderedSame) && (endTimeCompare == NSOrderedSame || endTimeCompare == NSOrderedAscending )){
        return  YES;
    } else return NO;
    
}

+(CLPlacemark *)generateCLLocationfromAddress:(NSString *)address{
    
    __block CLPlacemark *placeMark = nil;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    
    
    [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            // NSLog(@"%@", error);
        } else {
            placeMark = [placemarks firstObject];
            
            
        }
    }];
    
    return placeMark;
}







@end
