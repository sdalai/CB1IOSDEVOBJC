//
//  SCHScheduledEventManager.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 4/25/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHScheduledEventManager.h"
#import <Parse/Parse.h>
#import "SCHLookup.h"
#import "SCHUtility.h"
#import "SCHAvailableTimeBlock.h"
#import "SCHAvailability.h"
#import "SCHAppointment.h"
#import "SCHAppointmentActivity.h"
#import "SCHEvent.h"
#import "SCHAvailabilityService.h"
#import "SCHConstants.h"
#import "SCHScheduleScreenFilter.h"
#import "SCHMeeting.h"




@interface SCHScheduledEventManager ()


@property (nonatomic, strong) SCHConstants *constants;


@end


@implementation SCHScheduledEventManager

#pragma mark - Initialization
static SCHScheduledEventManager *sharedScheduledEventManager = nil;

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedScheduledEventManager = [[[self class] alloc] init];
        sharedScheduledEventManager->_scheduledEventDays = [[NSMutableArray alloc] init];
        sharedScheduledEventManager->_scheduledEvents = [[NSMutableDictionary alloc] init];
        sharedScheduledEventManager->_notifications = [[NSMutableArray alloc] init];
        sharedScheduledEventManager->_constants = [SCHConstants sharedManager];
        
        
    });
    
    return sharedScheduledEventManager;
}

-(void) reset{
    [self.scheduledEventDays removeAllObjects];
    [self.scheduledEvents removeAllObjects];
    [self.notifications removeAllObjects];
    self.scheduleEventsChanged  = NO;
    self.notificationChanged = NO;
   // self.notificationsForUser = NO;
}

#pragma mark - build event


- (BOOL)buildScheduledEvent{

    PFQuery *filterQuery = [SCHScheduleScreenFilter query];
    [filterQuery fromLocalDatastore];
    SCHScheduleScreenFilter *filter = [filterQuery getFirstObject];
    
    
    
    NSMutableDictionary *events = [[NSMutableDictionary alloc] init];
    NSMutableArray *eventDays = [[NSMutableArray alloc] init];
    
    
    SCHUser *user = [PFUser currentUser][@"CBUser"];
    
    NSArray *availabilities = [self buildAvailablityCompleteRefresh:user];

    NSArray *appointments = [self getScheduledAppointments:user];
    
    NSArray *meetups = [self getMeetups];
    
    
    // Create aray of scheduled events (union of availability and appointments
    NSSet *availabilitySet = [NSSet setWithArray:availabilities];
    NSSet *appointmentSet = [NSSet setWithArray:appointments];
    NSSet *meetupSet = [NSSet setWithArray:meetups];
    NSMutableSet *scheduledEventSet = [[NSMutableSet alloc] init];
    
    [scheduledEventSet setSet:availabilitySet];
    
    [scheduledEventSet unionSet:appointmentSet];
    [scheduledEventSet unionSet:meetupSet];
    
    NSMutableSet *scheduleDaysSet = [[NSMutableSet alloc] init];
    
    // Get schedule days as NSArray (only days in current time zone
    for (id event in scheduledEventSet){
        if ([event isKindOfClass:[SCHAppointment class]]) {
            SCHAppointment *appointment = (SCHAppointment *)event;
            
            [scheduleDaysSet addObject:[self getDate:(appointment.proposedStartTime)? appointment.proposedStartTime : appointment.startTime]];
            
        } else if ([event isKindOfClass:[SCHAvailability class]]){
            SCHAvailability *availability = (SCHAvailability *)event;
            [scheduleDaysSet addObject:[self getDate:availability.startTime]];
        } else if ([event isKindOfClass:[SCHMeeting class]]) {
            SCHMeeting *meeting = (SCHMeeting *)event;
            [scheduleDaysSet addObject:[self getDate:meeting.startTime]];
            
        }
    }
 
   // NSLog(@"Scheduled event set count: %lu", (unsigned long)scheduleDaysSet.count);
    
    
   
    NSSortDescriptor *scheduleDaysAsc = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    
    [eventDays addObjectsFromArray:[scheduleDaysSet sortedArrayUsingDescriptors:@[scheduleDaysAsc]]];
    
    if (eventDays.count >0 ) {
       // NSLog(@"scheduled event Days: %@", eventDays);
    }
    
    
   
    
    //Now Build Dictonary to for each days event
    
    NSMutableArray *scheduledEventDays = [[NSMutableArray alloc] init];
    
    for (NSDate *scheduleDay in eventDays){
        //filter the events that belong to scheduleDay
        
        //defiene descriptor
        NSPredicate *daySchedulePredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            if ([evaluatedObject isKindOfClass:[SCHAvailability class]]){
                SCHAvailability *availability = (SCHAvailability *)evaluatedObject;
                if ([[self getDate:availability.startTime] isEqualToDate:scheduleDay]){
                    return YES;
                } else {
                    return NO;
                }
            } else if ([evaluatedObject isKindOfClass:[SCHAppointment class]]) {
                SCHAppointment *appointment = (SCHAppointment *) evaluatedObject;
                if ([[self getDate:(appointment.proposedStartTime)? appointment.proposedStartTime : appointment.startTime] isEqualToDate:scheduleDay]){
                    return YES;
                } else {
                    return NO;
                }
            } else if([evaluatedObject isKindOfClass:[SCHMeeting class]]){
                SCHMeeting *meeting = (SCHMeeting *) evaluatedObject;
                if ([[self getDate:meeting.startTime] isEqualToDate:scheduleDay]){
                    return YES;
                } else {
                    return NO;
                }
                
            }else return NO;
            
        }];
        
        
        
        // filterout schedule that belong to scheduleday
        NSSet *scheduleDaysEventSet = [scheduledEventSet filteredSetUsingPredicate:daySchedulePredicate];
      //  NSLog(@"scheduledDaysEventSet: %@", scheduleDaysEventSet);
        
        NSMutableArray *scheduleDaysEvent = [[NSMutableArray alloc] init];
        
        //Now create events array for the schedule on scheleday
        for (id eventId in scheduleDaysEventSet){
           // NSLog(@"Building scheduleDaysEventSet");
           // NSLog(@"id: %@", eventId);
            
            
            
            if ([eventId isKindOfClass:[SCHAvailability class]]) {
                
                BOOL showAvailabilities = YES;
                if (filter){
                    showAvailabilities = filter.availabilities;
                }
                
                if (showAvailabilities){
                    SCHAvailability *availability = (SCHAvailability *)eventId;
                    
                    if ([self validateAvailabilityService:availability.services]){
                        SCHEvent *event = [self createEventWithEventDay:scheduleDay
                                                              eventType:SCHAvailabilityClass
                                                            eventObject:availability
                                                              startTime:availability.startTime
                                                                endTime:availability.endTime
                                                               Location:availability.location];
                        
                        
                        [scheduleDaysEvent addObject:event];
                        
                    }
                    
                }
                
                
                
                
                
            } else if ([eventId isKindOfClass:[SCHMeeting class]]){
                SCHMeeting *meeting = (SCHMeeting *)eventId;
                SCHEvent *event = [self createEventWithEventDay:scheduleDay
                                                      eventType:SCHMeetingClass
                                                    eventObject:meeting
                                                      startTime:meeting.startTime
                                                        endTime:meeting.endTime
                                                       Location:meeting.location];
                
                
                [scheduleDaysEvent addObject:event];
                
                
                
                
            }else if ([eventId isKindOfClass:[SCHAppointment class]]) {
                
                SCHAppointment *appointment = (SCHAppointment *)eventId;
                
              //  NSLog(@"About to create event for appointment: %@", appointment);
                
                SCHEvent *event = [self createEventWithEventDay:scheduleDay
                                                      eventType:SCHAppointmentClass
                                                    eventObject:appointment
                                                      startTime:(appointment.proposedStartTime)? appointment.proposedStartTime : appointment.startTime
                                                        endTime:(appointment.proposedEndTime)? appointment.proposedEndTime : appointment.endTime
                                                       Location:(appointment.proposedLocation)? appointment.proposedLocation: appointment.location];
                
              //  NSLog(@"event: %@", event);
                
                if (filter){
                    
                    if ([self showEvent:event]) {
                        
                        [scheduleDaysEvent addObject:event];
                    }
                    
                } else {
                    [scheduleDaysEvent addObject:event];
                }
                
                
                

                
            }

            
        }
        
        if (scheduleDaysEvent.count > 0){
            //sort day's schedule event array with start time, end time
            NSSortDescriptor *sortscheduleDaysEventSetStartTime = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
            NSSortDescriptor *sortscheduleDaysEventSetEndTime = [NSSortDescriptor sortDescriptorWithKey:@"endTime" ascending:YES];
            
            NSArray *sortArray = @[sortscheduleDaysEventSetStartTime, sortscheduleDaysEventSetEndTime];
            
            [scheduleDaysEvent sortUsingDescriptors:sortArray];
            
            // NSString *dayKey = [SCHUtility getCurrentDate:scheduleDay];
            NSDateFormatter *formatter = [SCHUtility dateFormatterForFullDate];
            NSString *dayKey = [formatter stringFromDate:scheduleDay];
            
            [events setObject:scheduleDaysEvent forKey:dayKey];
            [scheduledEventDays addObject:scheduleDay];
            
        }
        
    
        
        
    }
        
        self.scheduledEventDays = scheduledEventDays;
        self.scheduledEvents = events;
    
    
    
    

        self.scheduleEventsChanged = YES;
        [self.delegate scheduledEventsRefreshed:self.scheduledEvents eventDays:self.scheduledEventDays];
  
    
    
    return YES;
    
    
}

-(NSDate *)getDate:(NSDate *) date{
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSCalendarUnit units =  NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *components =[preferredCalendar components:units fromDate:date];
    return [preferredCalendar dateFromComponents:components];
    
}


-(SCHEvent *)createEventWithEventDay:(NSDate *)eventDay eventType:(NSString *) eventType eventObject:(id)eventObject startTime:(NSDate *) startTime endTime:(NSDate *) endTime Location:(NSString *) location {
    SCHEvent *event = [[SCHEvent alloc] init];
    
    

    
    
    if ([eventType isEqualToString:SCHAppointmentClass]){
        SCHAppointment *appointment = (SCHAppointment *)eventObject;
        
        
        if (appointment.status == self.constants.SCHappointmentStatusPending){
            NSPredicate *openActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointment = %@ AND status = %@", [PFUser currentUser][@"CBUser"], [PFUser currentUser][@"CBUser"], appointment, self.constants.SCHappointmentActivityStatusOpen];
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
                    
                    NSPredicate *openSeriesActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointmentSeries = %@ AND status = %@", [PFUser currentUser][@"CBUser"], [PFUser currentUser][@"CBUser"], appointment.appointmentSeries, self.constants.SCHappointmentActivityStatusOpen];
                    
                    
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
                } // else NSLog(@"couldn't retrieve apoen activity");
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

#pragma mark - Scheduled appointments

-(NSArray *) getScheduledAppointments:(SCHUser *) user{

    BOOL debug = NO;
    
    //NSPredicate *getAppointmentsPredicate = [NSPredicate predicateWithFormat:@"status IN {%@, %@}", constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending];
    PFQuery *getAppointments = [SCHAppointment query];
    [getAppointments fromLocalDatastore];
    

    
    [getAppointments includeKey:@"client"];
    [getAppointments includeKey:@"nonUserClient"];
    [getAppointments includeKey:@"service"];
    [getAppointments includeKey:@"serviceOffering"];
    [getAppointments includeKey:@"serviceProvider"];
 
    [getAppointments includeKey:@"status"];
    [getAppointments includeKey:@"appointmentSeries"];
 

    
    NSArray *appointments = [getAppointments findObjects];
    
    
    
   
    if(debug){
        NSLog(@"number of appointments:%ld", (long)[appointments count]);
        for (SCHAppointment *appointment in appointments) {
            NSLog(@"Get Appointment method: Appointment start Time: %@ - end time: %@ - %@", appointment.startTime, appointment.endTime, appointment.status.lookupText);
            
            if (appointment.nonUserClient){
                
                NSLog(@"Non User Client - %@", appointment.nonUserClient);
                NSLog(@"NON User Client Name: %@", appointment.clientName);
            }
        }
        
        
    }
    
    
    

    
    return appointments;
    
}

-(NSArray *) getMeetups{
    SCHConstants *constants = [SCHConstants sharedManager];
    
    PFQuery *meetupQuery = [SCHMeeting query];
    [meetupQuery fromLocalDatastore];
    [meetupQuery whereKey:@"status" notEqualTo:constants.SCHappointmentStatusCancelled];
    NSArray *meetups = [meetupQuery findObjects];
    
    return meetups;
    
}


#pragma mark - Availability computation of SP and Client viewing

-(NSArray *)buildAvailablityCompleteRefresh:(SCHUser*) user{

    NSDate *startDate = [SCHUtility startOrEndTime:[NSDate date]];
    //get all available timeslots with their service and loations
    NSPredicate *availabilityQueryPredicate = [NSPredicate predicateWithFormat:@"user = %@ AND endTime > %@", user, startDate];
    PFQuery *availabilityQuery = [PFQuery queryWithClassName:SCHAvailabilityClass predicate:availabilityQueryPredicate];
    //[availabilityQuery includeKey:@"services"];
    
    [availabilityQuery orderByAscending:@"startTime"];
    [availabilityQuery fromLocalDatastore];
    NSArray *availabilities = [availabilityQuery findObjects];
    
   // NSLog(@"availability count: %ld", (long)[availabilities count]);
    
    return availabilities;
    
}

#pragma mark - Notification
-(BOOL)notificationsForUser{
    
   // NSLog(@"Processing Notification");
    SCHUser *user = [PFUser currentUser][@"CBUser"];
    
   // NSLog(@"%@", user);
    NSMutableArray *notificationObjects = [[NSMutableArray alloc] init];
    NSPredicate *notificationPredicate = [NSPredicate predicateWithFormat:@"user = %@", user];
    PFQuery *notificationQuery = [PFQuery queryWithClassName:SCHNotificationClass predicate:notificationPredicate];
    [notificationQuery orderByDescending:@"createdAt"];
    [notificationQuery fromLocalDatastore];
    
    NSArray *notifications = [notificationQuery findObjects];
    
   // NSLog(@"%lu", (unsigned long)notifications.count);
    
    
    if (notifications.count >0){
        for (SCHNotification *notification in notifications) {
           // NSLog(@"%@", notification.objectId);
                  
                  
            if ([notification.referenceObjectType isEqualToString:SCHAppointmentClass]){
                
              //  NSLog(@"referenceObjects: %@", notification.referenceObject);
                
                PFQuery *appointmentQuery = [SCHAppointment query];
                [appointmentQuery fromLocalDatastore];
                [appointmentQuery includeKey:@"service"];
                [appointmentQuery includeKey:@"serviceOffering"];
                [appointmentQuery fromLocalDatastore];
                
               SCHAppointment *appointment = (SCHAppointment *)[appointmentQuery getObjectWithId:notification.referenceObject];
                
               // SCHAppointment *appointment = NULL;
                
              //  NSLog(@"appointmen: %@", appointment);
                
                if (appointment){
                    NSDictionary *notificationObject = @{@"notification" : notification, @"referenceObject": appointment};
                    [notificationObjects addObject:notificationObject];
                }
                
                
                               
                
            } else if ([notification.referenceObjectType isEqualToString:SCHAppointmentSeriesClass]){
                PFQuery *notificationObjectQuery  = [SCHAppointmentSeries query];
                [notificationObjectQuery includeKey:@"service"];
                [notificationObjectQuery includeKey:@"serviceOffering"];
                [notificationObjectQuery whereKey:@"objectId" equalTo:notification.referenceObject];
                [notificationObjectQuery fromLocalDatastore];
                SCHAppointmentSeries *appointmentSeries = (SCHAppointmentSeries *)[notificationObjectQuery getFirstObject];
                
               // NSLog(@"appointmentSeries: %@", appointmentSeries);
                
                
                if (appointmentSeries){
                    NSDictionary *notificationObject = @{@"notification" : notification, @"referenceObject": appointmentSeries};
                    [notificationObjects addObject:notificationObject];
                }
            }else if([notification.referenceObjectType isEqualToString:SCHMeetingClass]){
                
                PFQuery *meetingQuery = [SCHMeeting query];
                [meetingQuery fromLocalDatastore];
                
                SCHMeeting *meeting = (SCHMeeting *)[meetingQuery getObjectWithId:notification.referenceObject];
                
                if (meeting){
                    NSDictionary *notificationObject = @{@"notification" : notification, @"referenceObject": meeting};
                    [notificationObjects addObject:notificationObject];

                }
                
                
                
            }else if ([notification.referenceObjectType isEqualToString:@""] || !notification.referenceObjectType){
                
                
                NSDictionary *notificationObject = @{@"notification" : notification, @"referenceObject": [NSNull null]};
                [notificationObjects addObject:notificationObject];
            }
            
        }

    }
    
    if (self.notifications.count > 0){
        [self.notifications removeAllObjects];
    }
    
    if (notificationObjects.count >0){
        
      //  NSLog(@"notifications: %lu", (unsigned long)notificationObjects.count);
        
        
        [self.notifications addObjectsFromArray:notificationObjects];
        
       // NSLog(@"notifications: %lu", (unsigned long)self.notifications.count);
        
        
    }
    
    
    
  //  dispatch_async(dispatch_get_main_queue(), ^{
        self.notificationChanged = YES;
        [self.delegate notificationsRefreshed:self.notifications];
 //   });
    
    
    return  YES;
}


-(BOOL)showEvent:(SCHEvent *) event {
    
    SCHConstants *constants = [SCHConstants sharedManager];
    BOOL showEvent = NO;
    SCHUser *user = [PFUser currentUser][@"CBUser"];
    SCHAppointment *appointment = event.eventObject;
    SCHAppointmentActivity *openActivity = nil;
    
    PFQuery *filterQuery = [SCHScheduleScreenFilter query];
    [filterQuery fromLocalDatastore];
    SCHScheduleScreenFilter *filter = [filterQuery getFirstObject];
    
    if (filter.confirmedAppointmentsForMyServices){
        if ([appointment.status isEqual:constants.SCHappointmentStatusConfirmed] && [appointment.serviceProvider isEqual:user]){
            showEvent = YES;
        }
    }
    
    if (filter.pendingAppointmentsForMyServicesAwaitingMyResponse){
        if ([appointment.status isEqual:constants.SCHappointmentStatusPending] && [appointment.serviceProvider isEqual:user] && [openActivity.actionAssignedTo isEqual:user]){
            showEvent = YES;
        }
        
    }
    
    if (filter.pendingAppointmentsForMyServicesNotAwaitingMyResponse){
        if([appointment.status isEqual:constants.SCHappointmentStatusPending] && [appointment.serviceProvider isEqual:user] && ![openActivity.actionAssignedTo isEqual:user]){
            showEvent = YES;
        }
    }
    
    
    
    if (filter.confirmedAppointmentsIHaveBooked){
        if ([appointment.status isEqual:constants.SCHappointmentStatusConfirmed] && [appointment.client isEqual:user]){
            showEvent = YES;
        }
    }
    
    if (filter.pendingAppointmentsIHaveBookedAwaitingMyResponse){
        if ([appointment.status isEqual:constants.SCHappointmentStatusPending] && [appointment.client isEqual:user] && [openActivity.actionAssignedTo isEqual:user]){
            showEvent = YES;
        }
        
    }
    
    if (filter.pendingAppointmentsIHaveBookedNotAwaitingMyResponse){
        if([appointment.status isEqual:constants.SCHappointmentStatusPending] && [appointment.client isEqual:user] && ![openActivity.actionAssignedTo isEqual:user]){
            showEvent = YES;
        }
    }
    
    if (filter.cancelledAppointments){
        if ([appointment.status isEqual:constants.SCHappointmentStatusCancelled]){
            showEvent = YES;
        }
    }
    
    
    if (!filter.expiredAppointments){
        if (appointment.expired){
            showEvent = NO;
        }
    }
    
    
    
    if ([appointment.status isEqual:constants.SCHappointmentStatusProcessing]){
        showEvent = YES;
    }

    
    
    return showEvent;
}

-(BOOL)validateAvailabilityService:(NSArray *) services{
    BOOL valid = YES;
    for (NSDictionary *serviceDict in services){
        
        if(![[serviceDict valueForKey:@"service"] isKindOfClass:[SCHService class]]){
            valid = NO;
            break;
        }
    }
    
    return valid;
}








@end
