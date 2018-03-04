//
//  SCHAvailabilityForAppointmentManager.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/13/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAvailabilityForAppointmentManager.h"
#import "SCHLookup.h"
#import "SCHUtility.h"
#import "SCHAvailabilityForAppointment.h"
#import "SCHAppointment.h"
#import "SCHAppointmentActivity.h"
#import "SCHConstants.h"
#import "SCHEvent.h"
#import "SCHAvailableTimeBlock.h"
#import "AppDelegate.h"

@implementation SCHAvailabilityForAppointmentManager

/***************************************************/

#pragma  mark - Find Service Provider

/****************************************************/



+(NSArray *) ServiceCategoryList{
    NSMutableArray *serviceCatogories = [[NSMutableArray alloc] init];
    
    PFQuery *serviceCategoryQuery = [SCHServiceClassification query];
    [serviceCategoryQuery fromLocalDatastore];
    
    [serviceCatogories addObjectsFromArray:[serviceCategoryQuery findObjects]];
    
    return serviceCatogories;
}

+(NSArray *)ServiceProviderListForService:(SCHServiceClassification *) serviceType {
    NSMutableArray *serviceProviderList = [[NSMutableArray alloc] init];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSPredicate *serviceProvidersPredicate = [NSPredicate predicateWithFormat:@"active = TRUE AND serviceClassification = %@ AND user != %@", serviceType, appDelegate.user];
    PFQuery *serviceProvidersQuery = [PFQuery queryWithClassName:SCHServiceClass predicate:serviceProvidersPredicate];
    [serviceProvidersQuery includeKey:@"user"];
    [serviceProviderList addObjectsFromArray:[serviceProvidersQuery findObjects]];
    
    // Add locations and earliest Availability
    
    
    return serviceProviderList;
}



+(NSDictionary *) getAvailabilitiesForServiceProvide:(SCHUser *) serviceProvider service: (SCHService *) service currentAppointment:(SCHAppointment *) currentAppointment{
   // NSLog(@"getAvailabilitiesForServiceProvide - launched");
    NSMutableArray *openAvailabilities = [[NSMutableArray alloc] init];
    NSMutableArray *appointments = [[NSMutableArray alloc] init];
    SCHConstants *constants = [SCHConstants sharedManager];
    
    // Get existing availabilities that ends after current date time
    
    NSPredicate *availabilitiesPredicate = [NSPredicate predicateWithFormat:@"user = %@ AND service = %@ AND endTime > %@", serviceProvider, service, [SCHUtility startOrEndTime:[NSDate date]]];
    PFQuery *availabilityQuery = [PFQuery queryWithClassName:SCHAvailabilityForAppointmentClass predicate:availabilitiesPredicate];
    [availabilityQuery includeKey:@"user"];
    [availabilityQuery includeKey:@"service"];
    [availabilityQuery orderByAscending:@"startTime"];
    NSArray *currentAvailabilities = [availabilityQuery findObjects];
    
    
    NSMutableArray *availabilitiesArray = nil;
    
    if (currentAppointment){
       availabilitiesArray = [[NSMutableArray alloc] initWithArray:[self availabilityAdjustmentForAppointmentChange:currentAppointment availabilities:currentAvailabilities]];
        
    } else {
        availabilitiesArray = [[NSMutableArray alloc] initWithArray:currentAvailabilities];
    }
    

    
    //Make first availability start time to curent time
    
    if (availabilitiesArray.count > 0){
        SCHAvailabilityForAppointment *firstAvailability = availabilitiesArray[0];
        SCHAvailabilityForAppointment *lastAvaailability = (SCHAvailabilityForAppointment *) availabilitiesArray.lastObject;
        NSDate *dateToBeSet = [SCHUtility startOrEndTime:[NSDate date]];
        
        if ([firstAvailability.startTime compare:dateToBeSet] == NSOrderedAscending){
            firstAvailability.startTime = dateToBeSet;
        }
        
        if (currentAppointment){
            NSDate *startTimeAdjustment = (currentAppointment.proposedStartTime) ? currentAppointment.proposedStartTime : currentAppointment.startTime;
            NSDate *endTimeAdjustment = (currentAppointment.proposedEndTime) ? currentAppointment.proposedEndTime : currentAppointment.endTime;
            
            if ([endTimeAdjustment compare:firstAvailability.startTime] == NSOrderedSame){
                firstAvailability.startTime = startTimeAdjustment;
            }
            if ([startTimeAdjustment compare:lastAvaailability.endTime] == NSOrderedSame){
                lastAvaailability.endTime = endTimeAdjustment;
            }
        }
        
        
        
    }
    
    
    

    

    
    
   // NSLog(@"availability Array: %lu", (unsigned long)availabilitiesArray.count);
    
    
    
    //Check of conflicting appointments if there is availability
    
    if (availabilitiesArray.count > 0){
        
        NSMutableSet *availabilities = [NSMutableSet setWithArray:availabilitiesArray];
        
        // Get Appointments
        SCHAvailabilityForAppointment *firstAvailability = (SCHAvailabilityForAppointment *)availabilitiesArray.firstObject;
        NSDate *startTimeForAppointmentQuery = [SCHUtility startOrEndTime:firstAvailability.startTime];
        
        SCHAvailabilityForAppointment *lastAvailability = (SCHAvailabilityForAppointment *)availabilitiesArray.lastObject;
        NSDate *endTimeForAppointmentQuery = [SCHUtility startOrEndTime:lastAvailability.endTime];
        
       // NSLog(@"availability Window start_time: %@ - endTime: %@", startTimeForAppointmentQuery, endTimeForAppointmentQuery);
        
        
        NSPredicate *conflictingAppointmentsPredicate = [NSPredicate predicateWithFormat:@"((startTime BETWEEN  %@ OR endTime BETWEEN %@) OR (startTime <= %@ AND endTime >= %@)) AND status IN {%@, %@}", @[startTimeForAppointmentQuery, endTimeForAppointmentQuery], @[startTimeForAppointmentQuery, endTimeForAppointmentQuery], startTimeForAppointmentQuery, endTimeForAppointmentQuery, constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending];
        
        PFQuery *conflictingAappointmentsQuery = [PFQuery queryWithClassName:SCHAppointmentClass predicate:conflictingAppointmentsPredicate];
        [conflictingAappointmentsQuery fromLocalDatastore];
        [conflictingAappointmentsQuery includeKey:@"client"];
        [conflictingAappointmentsQuery includeKey:@"service"];
        [conflictingAappointmentsQuery includeKey:@"serviceOffering"];
        [conflictingAappointmentsQuery includeKey:@"serviceProvider"];
        [conflictingAappointmentsQuery includeKey:@"status"];
        [conflictingAappointmentsQuery fromLocalDatastore];
        

        
        NSMutableSet *appointmentSet = [[NSMutableSet alloc] initWithArray:[conflictingAappointmentsQuery findObjects]];
        if (currentAppointment){
            [appointmentSet removeObject:currentAppointment];
        }
        
        //Only keep the appointments that belongs to service Provider
        
        NSPredicate *appointmentFilter = [NSPredicate predicateWithBlock:^BOOL(SCHAppointment *appointment, NSDictionary *bindings) {
            if ([appointment.serviceProvider isEqual:serviceProvider] || [appointment.client isEqual:serviceProvider]){
                return YES;
            } else return NO;
        }];
        
        NSSet *conflictingAppointmentSet = [appointmentSet filteredSetUsingPredicate:appointmentFilter];
        
        NSSortDescriptor *appointmentSorDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
        
        [appointments addObjectsFromArray:[conflictingAppointmentSet sortedArrayUsingDescriptors:@[appointmentSorDescriptor]]];
        
        
       // NSLog(@"conflicting Appointments: %lu", (unsigned long)appointments.count);
        
        
        
        
        // if appoitnemtnt exists  then check for conflict
        if (appointments.count > 0){
            // Get all availabilities that have conflict
            for (SCHAppointment *appointment in appointments){
                
                NSPredicate *availabilitiesWithConflictPredicate = [NSPredicate  predicateWithFormat:@"(startTime BETWEEN %@ OR endTime BETWEEN %@) OR (startTime <= %@ AND endTime >= %@)", @[appointment.startTime, appointment.endTime], @[appointment.startTime, appointment.endTime], appointment.startTime, appointment.endTime];
                
                
                NSMutableSet *availibilityWithConflict = (NSMutableSet *)[availabilities filteredSetUsingPredicate:availabilitiesWithConflictPredicate];
                
              //  NSLog(@"availability with conflict count: %lu", (unsigned long)availibilityWithConflict.count);
                
                
                
                if (availibilityWithConflict.count > 0) {
                    
                    
                    for (SCHAvailabilityForAppointment *availability in availibilityWithConflict){
                        if ((([appointment.startTime compare:availability.startTime] == NSOrderedAscending) ||
                             ([appointment.startTime compare:availability.startTime] == NSOrderedSame)) &&
                            (([appointment.endTime compare:availability.endTime] == NSOrderedSame) ||
                             ([appointment.endTime compare:availability.endTime] == NSOrderedDescending))) {
                                
                                
                                
                                // remove availability from set
                                [availabilities removeObject:availability];
                                
                            } else if (([appointment.startTime compare:availability.startTime] == NSOrderedDescending) &&
                                       ([appointment.endTime compare:availability.endTime] == NSOrderedSame ||
                                        [appointment.endTime compare:availability.endTime] == NSOrderedDescending))
                                
                                
                                
                                
                            {
                                availability.endTime = appointment.startTime;
                                
                            } else if (([appointment.startTime compare:availability.startTime] == NSOrderedAscending ||
                                        [appointment.startTime compare:availability.startTime] == NSOrderedSame) &&
                                       ([appointment.endTime compare:availability.endTime] == NSOrderedAscending))
                                
                                
                                
                            {
                                availability.startTime = appointment.endTime;
                            } else if ([appointment.startTime compare:availability.startTime] == NSOrderedDescending && [appointment.endTime compare:availability.endTime] == NSOrderedAscending){
                                
                                
                                
                                
                                // split availability
                                [availabilities removeObject:availability];
                                
                               // NSLog(@"availability: %@", availability);
                                SCHAvailabilityForAppointment *availability1 = [SCHAvailabilityForAppointment object];
                                availability1.user = availability.user;
                                availability1.service = availability.service;
                                availability1.location = availability.location;
                                availability1.startTime = availability.startTime;
                                availability1.endTime = appointment.startTime;
                                
                                [availabilities addObject:availability1];
                                
                               // NSLog(@"availability1: %@", availability1);
                                SCHAvailabilityForAppointment *availability2 = [SCHAvailabilityForAppointment object];
                                availability2.user = availability.user;
                                availability2.service = availability.service;
                                availability2.location = availability.location;
                                availability2.startTime = appointment.endTime;
                                availability2.endTime = availability.endTime;
                                
                                [availabilities addObject:availability2];
                                
                               //  NSLog(@"availability2: %@", availability2);
                                
                                
                            } //end of availability change clauses
                        
                        
                    } // conflicted availability processing for loop
                    
                } // end of conflicted availability if clause
                
                
                
                
                
                
            } // end of appointment for clause
            
            
        } // end of appointment exists if  clause
        
        
        [openAvailabilities addObjectsFromArray:availabilities.allObjects];
        
    }// end of acheck for conflicting appointments if there is availability
    
    
    // Now we have openavailabilities and appointments. Order them to be shown
    
    
    
    /*
    NSDictionary *availabilityEvents = @{@"availabilities" : (openAvailabilities.count > 0) ? openAvailabilities : [[NSMutableDictionary alloc]init],
                                         @"appointments" : (appointments.count > 0) ? appointments: [[NSMutableDictionary alloc]init]};
     
     */
    
    NSDictionary *availabilityEvents = @{@"availabilities" : (openAvailabilities.count > 0) ? openAvailabilities : [[NSMutableDictionary alloc]init],
                                         @"appointments" : [[NSMutableDictionary alloc]init]};
    
    
    
    
    return availabilityEvents;
    
}

+(NSDictionary *)availabilityForAppointment:(SCHUser *) serviceProvider service:(SCHService *) service appointment:(SCHAppointment *) currentAppointment{
    
   // NSLog(@"availabilityForAppointment - launched");
    
    NSMutableDictionary *openavailabilities = [[NSMutableDictionary alloc]init];
    
    NSDictionary *availabilitiesAndAppointments = [self getAvailabilitiesForServiceProvide:serviceProvider service:service currentAppointment:currentAppointment];

    NSArray *inputAvailabilities = ([(NSArray *)[availabilitiesAndAppointments valueForKey:@"availabilities"] count] > 0) ? [availabilitiesAndAppointments valueForKey:@"availabilities"] : NULL;
    NSArray *appointments = ([(NSArray *)[availabilitiesAndAppointments valueForKey:@"appointments"] count]> 0) ? [availabilitiesAndAppointments valueForKey:@"appointments"] : NULL;
    
   // NSLog(@"availability Count:%lu", (unsigned long)inputAvailabilities.count);
    
    //NSLog(@"conflicting appointment count: %lu", (unsigned long)appointments.count);
    
    
    int minAppointmentTime = [self minimumAllowedDurtionforServiceInMin:service];
    
    NSMutableArray *availabilities = [[NSMutableArray alloc] init];
    
    
    
    for (SCHAvailability *availability in inputAvailabilities){
        int availabilityDuration = [availability.endTime timeIntervalSinceDate:availability.startTime]/60;
        if (availabilityDuration >= minAppointmentTime){
            [availabilities addObject:availability];
        }
        
        
    }
    
    
    if ([availabilities isEqual:[NSNull null]]){
        return NULL;
    }else{
        //build availability dictonary
        
        NSMutableSet *availabilityDaysSet = [[NSMutableSet alloc] init];
        for(SCHAvailabilityForAppointment *availability in availabilities){
            [availabilityDaysSet addObject:[SCHUtility getDate:availability.startTime]];
        }
        
        NSSortDescriptor *availabilityDaysAsc = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        
        NSArray *availabilityDays = [availabilityDaysSet sortedArrayUsingDescriptors:@[availabilityDaysAsc]];
        
        // Add Availabilitiy days to dictonary
        [openavailabilities setObject:availabilityDays forKey:@"availabilityDays"];
        
        //Now build availabilities and conflicting appointments that interfere with availability
        
        NSMutableSet *availabilitiesAndAppointmentsSet = [[NSMutableSet alloc] init];
        
        [availabilitiesAndAppointmentsSet addObjectsFromArray:availabilities];
        
        if (![appointments isEqual:[NSNull null]]){
            [availabilitiesAndAppointmentsSet addObjectsFromArray:appointments];
        }
        
        NSMutableDictionary *availabilityDictonary = [[NSMutableDictionary alloc] init];
        for (NSDate *availabilityDay in availabilityDays ){
            //defiene descriptor
            NSPredicate *daySchedulePredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                if ([evaluatedObject isKindOfClass:[SCHAvailabilityForAppointment class]]){
                    SCHAvailabilityForAppointment *availability = (SCHAvailabilityForAppointment *)evaluatedObject;
                    if ([[SCHUtility getDate:availability.startTime] isEqualToDate:availabilityDay]){
                        return YES;
                    } else {
                        return NO;
                    }
                } else if ([evaluatedObject isKindOfClass:[SCHAppointment class]]) {
                    SCHAppointment *appointment = (SCHAppointment *) evaluatedObject;
                    if ([[SCHUtility getDate:appointment.startTime] isEqualToDate:availabilityDay]){
                        return YES;
                    } else {
                        return NO;
                    }
                } else return NO;
                
            }];

            NSSet *scheduleDaysEventSet = [availabilitiesAndAppointmentsSet filteredSetUsingPredicate:daySchedulePredicate];
            NSMutableArray *scheduleDaysEvent = [[NSMutableArray alloc] init];
            
            for (id eventId in scheduleDaysEventSet){
                if ([eventId isKindOfClass:[SCHAvailabilityForAppointment class]]) {
                    SCHAvailabilityForAppointment *availability = (SCHAvailabilityForAppointment *)eventId;
                    
                    
                    SCHEvent *event = [self createEventWithEventDay:availabilityDay
                                                          eventType:SCHAvailabilityClass
                                                        eventObject:availability
                                                          startTime:availability.startTime
                                                            endTime:availability.endTime
                                                           Location:availability.location];
                    
                    
                    [scheduleDaysEvent addObject:event];
                    
                } else if ([eventId isKindOfClass:[SCHAppointment class]]) {
                    SCHAppointment *appointment = (SCHAppointment *)eventId;
                    SCHEvent *event = [self createEventWithEventDay:availabilityDay
                                                          eventType:SCHAppointmentClass
                                                        eventObject:appointment
                                                          startTime:appointment.startTime
                                                            endTime:appointment.endTime
                                                           Location:appointment.location];
                    [scheduleDaysEvent addObject:event];
                    
                    
                }
                
                
            }
            
            //sort day's schedule event array with start time, end time
            NSSortDescriptor *sortscheduleDaysEventSetStartTime = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
            NSSortDescriptor *sortscheduleDaysEventSetEndTime = [NSSortDescriptor sortDescriptorWithKey:@"endTime" ascending:YES];
            
            NSArray *sortArray = @[sortscheduleDaysEventSetStartTime, sortscheduleDaysEventSetEndTime];
            
            [scheduleDaysEvent sortUsingDescriptors:sortArray];
            
            // NSString *dayKey = [SCHUtility getCurrentDate:scheduleDay];
            NSDateFormatter *formatter = [SCHUtility dateFormatterForFullDate];
            NSString *dayKey = [formatter stringFromDate:availabilityDay];
            
            [availabilityDictonary setObject:scheduleDaysEvent forKey:dayKey];
            
        }
    
        [openavailabilities setObject:availabilityDictonary forKey:@"availabilities"];
        
    }
    
    
    return openavailabilities ;
}



+(SCHEvent *)createEventWithEventDay:(NSDate *)eventDay eventType:(NSString *) eventType eventObject:(id)eventObject startTime:(NSDate *) startTime endTime:(NSDate *) endTime Location:(NSString *) location {
    SCHEvent *event = [[SCHEvent alloc] init];
    SCHConstants *constants = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    if ([eventType isEqualToString:SCHAppointmentClass]){
        SCHAppointment *appointment = (SCHAppointment *)eventObject;
        
        
        if (appointment.status == constants.SCHappointmentStatusPending){
            NSPredicate *openActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointment = %@ AND status = %@", appDelegate.user, appDelegate.user, appointment, constants.SCHappointmentActivityStatusOpen];
            PFQuery *openActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openActivityPredicate];
            [openActivityQuery includeKey:@"actionAssignedTo"];
            [openActivityQuery includeKey:@"actionInitiator"];
            [openActivityQuery includeKey:@"status"];
            [openActivityQuery includeKey:@"action"];
            [openActivityQuery fromLocalDatastore];
            NSArray *appointmentOpenActivity = [openActivityQuery findObjects];
            
            if (appointmentOpenActivity.count == 0){
                // check series
                if (appointment.appointmentSeries){
                    // Get appointment Series  Open Activity
                    NSPredicate *openSeriesActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointmentSeries = %@ AND status = %@", appDelegate.user, appDelegate.user, appointment.appointmentSeries, constants.SCHappointmentActivityStatusOpen];
                    PFQuery *openSeriesActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openSeriesActivityPredicate];
                    [openSeriesActivityQuery includeKey:@"actionAssignedTo"];
                    [openSeriesActivityQuery includeKey:@"actionInitiator"];
                    [openSeriesActivityQuery includeKey:@"status"];
                    [openSeriesActivityQuery includeKey:@"action"];
                    [openSeriesActivityQuery fromLocalDatastore];
                    NSArray *appointmentSeriesOpenActivity = [openSeriesActivityQuery findObjects];
                    
                    if(appointmentSeriesOpenActivity.count > 0){
                        event.openActivity = appointmentSeriesOpenActivity.firstObject;
                    } //else NSLog(@"couldn't retrieve apoen activity");
                }// else NSLog(@"couldn't retrieve apoen activity");
            }  else event.openActivity = appointmentOpenActivity.firstObject;
            
        }
    }
    event.eventDay = eventDay;
    event.eventType = eventType;
    event.eventObject = eventObject;
    event.startTime = startTime;
    event.endTime = endTime;
    event.location = location;
    
    return event;
    
}


+(int)minimumAllowedDurtionforServiceInMin:(SCHService *) service{
    
    // Get all service Offering for service
    PFQuery *serviceOfferingQuery = [SCHServiceOffering query];
    [serviceOfferingQuery whereKey:@"service" equalTo:service];
    [serviceOfferingQuery orderByAscending:@"defaultDurationInMin"];
    
    NSArray *offerings = [serviceOfferingQuery findObjects];
    SCHServiceOffering *offering = offerings[0];
    
    return  offering.defaultDurationInMin;
}

+(NSArray *)availabilityAdjustmentForAppointmentChange:(SCHAppointment *) appointment availabilities:(NSArray *)availabilities{
    
    NSMutableArray *finalAvailabilities = nil;
    if (availabilities.count > 0){
        finalAvailabilities = [[NSMutableArray alloc] initWithArray:availabilities];
    } else{
        finalAvailabilities = [[NSMutableArray alloc] init];
    }
    
    if ([self availabilityShouldChange:appointment]){
        
        NSMutableArray *availabilitiesToBeRemoved = [[NSMutableArray alloc] init];
        NSMutableArray *availabilitiesToBeAdded = [[NSMutableArray alloc] init];
        
        
        // Get preceeding availabilities
        
        NSPredicate *preceedingAvailabilityPredicate = [NSPredicate predicateWithBlock:^BOOL(SCHAvailabilityForAppointment *availability, NSDictionary<NSString *,id> * _Nullable bindings) {
            if ([availability.endTime compare:appointment.startTime] == NSOrderedSame){
                return YES;
            } else {
                return NO;
            }
        }];
        
        NSArray *preceedingAvailabilities = [availabilities filteredArrayUsingPredicate:preceedingAvailabilityPredicate];
        
        SCHAvailabilityForAppointment *preceedingAvailability = nil;
        if (preceedingAvailabilities.count > 0){
            preceedingAvailability = preceedingAvailabilities[0];
        }
        
        // Get Succedding availability
        NSPredicate *suceedingAvailabilityPredicate = [NSPredicate predicateWithBlock:^BOOL(SCHAvailabilityForAppointment *availability, NSDictionary<NSString *,id> * _Nullable bindings) {
            if ([availability.startTime compare:appointment.endTime] == NSOrderedSame){
                return YES;
            } else {
                return NO;
            }
        }];
        
        NSArray *suceedingAvailabilities = [availabilities filteredArrayUsingPredicate:suceedingAvailabilityPredicate];
        
        SCHAvailabilityForAppointment *succeddingAvailability = nil;
        if (suceedingAvailabilities.count > 0){
            succeddingAvailability = suceedingAvailabilities[0];
        }
        
        
        
        //Get Timeblicks for appointment
        
        NSPredicate *getTimeBlockPredicate = [NSPredicate predicateWithFormat:@"(startTime >= %@) AND endTime <= %@ AND (user = %@)",appointment.startTime, appointment.endTime, appointment.serviceProvider];
        PFQuery *getTimeBlocks = [PFQuery queryWithClassName:SCHAvailableTimeBlockClass predicate:getTimeBlockPredicate];
        [getTimeBlocks orderByAscending:@"startTime"];
        NSArray *timeBlocks = [getTimeBlocks findObjects];
        
        if (timeBlocks.count >0){
            
            NSDate *newAvailabilityStartTime = nil;
            NSDate *newAvailabilityendTime = nil;
            NSString *newavailabilityLocation = nil;
            SCHUser *newAvailabilityUser = appointment.serviceProvider;
            SCHService *newAvailabilityService = appointment.service;
            
            if (preceedingAvailability){
                newAvailabilityStartTime = preceedingAvailability.startTime;
                newAvailabilityendTime = preceedingAvailability.endTime;
                newavailabilityLocation = preceedingAvailability.location;
                [availabilitiesToBeRemoved addObject:preceedingAvailability];

            }
            for (SCHAvailableTimeBlock *timeBlock in timeBlocks){
                
                if (!newAvailabilityStartTime && !newAvailabilityendTime && !newavailabilityLocation){
                    
                    // No prededing availability
                    newAvailabilityStartTime = timeBlock.startTime;
                    newAvailabilityendTime = timeBlock.endTime;
                    newavailabilityLocation = timeBlock.location;
                    
                } else{
                    if (([newAvailabilityendTime compare:timeBlock.startTime] == NSOrderedSame) && [timeBlock.location isEqualToString:newavailabilityLocation]){
                        newAvailabilityendTime = timeBlock.endTime;
                        
                    } else{
                        // Create New Availability
                        [availabilitiesToBeAdded addObject:[self createAvailabilityForAppointment:newAvailabilityStartTime
                                                                                          endTime:newAvailabilityendTime
                                                                                             user:newAvailabilityUser
                                                                                          service:newAvailabilityService
                                                                                         location:newavailabilityLocation]];
                        
                        newAvailabilityStartTime = nil;
                        newAvailabilityendTime = nil;
                        newavailabilityLocation = nil;
                        
                    }
                    
                }
                
                
            }// End of for loop
            
            if (newAvailabilityStartTime && newAvailabilityendTime && newavailabilityLocation){
                
                if (succeddingAvailability){
                    if(([newAvailabilityendTime compare:succeddingAvailability.startTime] == NSOrderedSame) && [succeddingAvailability.location isEqualToString:newavailabilityLocation]){
                        newAvailabilityendTime = succeddingAvailability.endTime;
                        [availabilitiesToBeRemoved addObject:succeddingAvailability];
                        
                    }
                }
                
                
                [availabilitiesToBeAdded addObject:[self createAvailabilityForAppointment:newAvailabilityStartTime
                                                                                  endTime:newAvailabilityendTime
                                                                                     user:newAvailabilityUser
                                                                                  service:newAvailabilityService
                                                                                 location:newavailabilityLocation]];
                
                
            }
            
            
            
        } else return finalAvailabilities;
        

        if (availabilitiesToBeRemoved.count > 0){
           [finalAvailabilities removeObjectsInArray:availabilitiesToBeRemoved];
        }
        if (availabilitiesToBeAdded.count > 0){
            [finalAvailabilities addObjectsFromArray:availabilitiesToBeAdded];
        }
        NSSortDescriptor *availabilitySorDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
        return [finalAvailabilities sortedArrayUsingDescriptors:@[availabilitySorDescriptor]];
        
    } return finalAvailabilities;
    

}

+(SCHAvailabilityForAppointment *)createAvailabilityForAppointment:(NSDate *) startTime endTime:(NSDate *) endTime user:(SCHUser *) user service:(SCHService *) service location: (NSString *)location{
    SCHAvailabilityForAppointment *availabilitiy = [SCHAvailabilityForAppointment object];
    availabilitiy.startTime =startTime;
    availabilitiy.endTime = endTime;
    availabilitiy.user = user;
    availabilitiy.service = service;
    availabilitiy.location = location;
    return availabilitiy;
}

+(BOOL)availabilityShouldChange:(SCHAppointment *) appointment{
    SCHConstants *constants = [SCHConstants sharedManager];
    if ([appointment.status isEqual:constants.SCHappointmentStatusConfirmed]){
        return YES;
    }
    
    if ([appointment.status isEqual:constants.SCHappointmentStatusPending] && (appointment.proposedEndTime  && appointment.proposedStartTime)) {
        return YES;
    }
    
    
    return NO;
}

@end;
