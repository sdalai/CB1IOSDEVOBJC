//
//  SCHSyncManager.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/6/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHSyncManager.h"
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
#import "SCHAvailabilityManager.h"
#import "SCHAvailabilityManager.h"
#import "SCHNonUserClient.h"
#import "AppDelegate.h"
#import "SCHActiveViewControllers.h"
#import "SCHNotificationViewController.h"
#import "SCHServiceMajorClassification.h"
#import "SCHUserFriend.h"
#import "SCHBookViewController.h"
#import "SCHManageBusinessViewController.h"
#import "SCHHomeViewController.h"
#import "SCHMeeting.h"


@implementation SCHSyncManager

NSDate *syncDate;

+(BOOL)syncAvailability{
    BOOL success = NO;
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *serverAvailabilities = [[NSMutableArray alloc] init];
    
    
        NSPredicate *serverAvailabilityPredicate = [NSPredicate predicateWithFormat:@"user = %@", appDelegate.user];
        PFQuery *serverAvailability = [PFQuery queryWithClassName:SCHAvailabilityClass predicate:serverAvailabilityPredicate];
        [serverAvailability setLimit:1000];
     if (appDelegate.serverReachable && appDelegate.user){
        [serverAvailabilities addObjectsFromArray:[serverAvailability findObjects:&error]];
         success = YES;
    } else{
        //call selector to handle unavailability
        return NO;
    }
    if (!appDelegate.serverReachable && appDelegate.user){
        return NO;
    }
    if (error){
        return NO;
    }
    
    //Unpin all in local data store
    NSPredicate *lDSAvailabilityPredicate = [NSPredicate predicateWithFormat:@"user = %@", appDelegate.user];
    PFQuery *LDSAvailability = [PFQuery queryWithClassName:SCHAvailabilityClass predicate:lDSAvailabilityPredicate];
    [LDSAvailability fromLocalDatastore];
    
    [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:[LDSAvailability findObjects]];
    [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:serverAvailabilities];
        
    
    
    return  success;
}


+(BOOL) syncBadge {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PFInstallation *installation = [PFInstallation currentInstallation];
    NSPredicate *notificationPredicate = [NSPredicate predicateWithFormat:@" user = %@ AND seen = NO", appDelegate.user ];
    PFQuery *notificationsForbadgeQuery = [PFQuery queryWithClassName:SCHNotificationClass predicate:notificationPredicate];
    [notificationsForbadgeQuery fromLocalDatastore];
    int notificationCount = (int) [notificationsForbadgeQuery countObjects];
    
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] setApplicationbadgeCount:notificationCount];
    installation.badge = notificationCount;
    
    [installation saveEventually];
    
    
    return YES;

}




//Notification will always be complete refresh

+(BOOL)syncNotification{
    
    BOOL success = YES;
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSUInteger limit = 500;
    NSUInteger skip = 0;
    NSUInteger lastObjectCount = 0;
    NSUInteger CurrentObjectCount = 0;
    
    // Unpin all notification
    
    PFQuery *LDSNotificationQuery = [SCHNotification query];
    [LDSNotificationQuery fromLocalDatastore];
    
    
    
    
    // Get all notifications for user and syn to LDS
    NSPredicate *notificationPredicate = [NSPredicate predicateWithFormat:@" user = %@",  appDelegate.user];
    
    PFQuery *notificationQuery = [PFQuery queryWithClassName:SCHNotificationClass predicate:notificationPredicate];
    
    [notificationQuery setLimit:limit];
    
    NSMutableArray *notifications = [[NSMutableArray alloc] init];
    

    while (CurrentObjectCount == skip){
        lastObjectCount = CurrentObjectCount;
        [notificationQuery setSkip:skip];
        if (appDelegate.serverReachable && appDelegate.user){
            [notifications addObjectsFromArray:[notificationQuery findObjects:&error]];
        } else{
            [notifications removeAllObjects];
            success = NO;
            break;
        }
        if (error){
            [notifications removeAllObjects];
            success = NO;
            break;
        }
        
        CurrentObjectCount = [notifications count];
        if (lastObjectCount == CurrentObjectCount){
            break;
        } else {
            skip = skip + limit;
        }
        
    }
    if (!appDelegate.serverReachable || !appDelegate.user){
        success = NO;
    }
    
    if (!success){
        return success;
    } else{
        
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:notifications];
        [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:[LDSNotificationQuery findObjects]];
        
        return success;
    }
    
}

+(BOOL)syncMeetups{
    BOOL success = YES;
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSUInteger limit = 500;
    NSUInteger skip = 0;
    NSUInteger lastObjectCount = 0;
    NSUInteger CurrentObjectCount = 0;
    // Unpin all meetups
    
    PFQuery *LDSMeetupQuery = [SCHMeeting query];
    [LDSMeetupQuery fromLocalDatastore];
    
    PFQuery *meetingQuery = [SCHMeeting  query];
    [meetingQuery whereKey:@"attendees" containsAllObjectsInArray:@[appDelegate.user]];
    
    NSMutableArray *meetupArray = [[NSMutableArray alloc] init];
    
    [meetingQuery setLimit:limit];
    
    while (CurrentObjectCount == skip){
        lastObjectCount = CurrentObjectCount;
        [meetingQuery setSkip:skip];
        if (appDelegate.serverReachable && appDelegate.user){
            [meetupArray addObjectsFromArray:[meetingQuery findObjects:&error]];
        } else{
            [meetupArray removeAllObjects];
            success = NO;
            break;
        }
        
        if (error){
            [meetupArray removeAllObjects];
            success = NO;
            break;
            
        }
        
        CurrentObjectCount = [meetupArray count];
        if (lastObjectCount == CurrentObjectCount){
            break;
        } else {
            skip = skip + limit;
        }
        
    }
    
    // if nor reachable then end here
    if (!appDelegate.serverReachable || !appDelegate.user){
        success = NO;
    }
    if (!success){
        return success;
    }
    
    
    if (meetupArray.count > 0){
        
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:meetupArray];
        
        NSMutableSet *meetupInvitesSet = [[NSMutableSet alloc] init];
        
        NSMutableArray *nonUserInvities = [[NSMutableArray alloc] init];
        NSMutableArray *CBUserInvites = [[NSMutableArray alloc] init];
        
        
        /*
         for (SCHMeeting *meetup in meetupArray){
         
         [meetupInvitesSet addObjectsFromArray:meetup.invites];
         if (![meetup.organizer isEqual:appDelegate.user]){
         [meetup.organizer fetch];
         [appDelegate.backgroundCommit.objectsStagedForPinning addObject:meetup.organizer];
         }
         
         }
         
         
         for (NSDictionary *invitee in meetupInvites){
         if ([[invitee valueForKey:SCHMeetupInviteeUser] isKindOfClass:[SCHNonUserClient class]]){
         [nonUserInvities addObject:[invitee valueForKey:SCHMeetupInviteeUser]];
         } else{
         [CBUserInvites addObject:[invitee valueForKey:SCHMeetupInviteeUser]];
         }
         
         }
         
         */
        
        for (SCHMeeting *meetUp in meetupArray){
            [meetupInvitesSet addObjectsFromArray:meetUp.attendees];
        }
        NSArray *meetupInvites = [meetupInvitesSet allObjects];
        
        for (id attendee in meetupInvites){
            if ([attendee isKindOfClass:[SCHUser class]]){
                [CBUserInvites addObject:attendee];
            } else{
                [nonUserInvities addObject:attendee];
            }
        }
        
        
        
        [PFObject fetchAll:nonUserInvities];
        [PFObject fetchAll:CBUserInvites];
        
        
        
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:nonUserInvities];
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:CBUserInvites];
        
        
        
    }
    
    [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:[LDSMeetupQuery findObjects]];
    
    
    return  success;
    
}



+(BOOL) syncWithServer {
    
    BOOL debug = NO;
    BOOL success = YES;
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    
   
    PFInstallation *installation = [PFInstallation currentInstallation];
    
    /*
    if (appDelegate.serverReachable){
        
       [installation fetch];
    } else{
        success = NO;
        return success;
    }
     */
    
    //Get syncDate
    syncDate = installation[@"syncDate"];
    
    if (debug){
        NSLog(@"syncDate: %@", syncDate);
    }
    
    
    if (appDelegate.serverReachable && appDelegate.user){
        
        installation[@"syncDate"] = [NSDate date];
        [installation save:&error];
        //NSMutableSet *objectsForPinning = [[NSMutableSet alloc] init];
        if (error){
            success = NO;
            return success;
        }
        

    }else{
        success = NO;
        return success;
    }
    
    
    if (appDelegate.serverReachable && appDelegate.user){
        if (!(syncDate == nil || [syncDate isEqual:[NSNull null]])){
            if (debug){
                NSLog(@"Targeted Refresh");
            }
            
            success =[self dataSync:syncDate];
            
        } else{
            // Complete refresh
            // //sync SCH Notification for user
            if (debug){
                NSLog(@"complete Refresh");
            }
            
            success =[self dataSync:nil];
        }

    } else{
        success = NO;
        return success;
        
    }
    

    

    
    
    return success;
}

+(BOOL)dataSync:(NSDate *) syncDate{
    
    BOOL success = YES;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSError *error = nil;
    NSUInteger limit = 500;
    NSUInteger skip = 0;
    NSUInteger lastObjectCount = 0;
    NSUInteger CurrentObjectCount = 0;
    
    //sync user data
    
    // Major Classification
    
    
    
    skip = 0;
    lastObjectCount = 0;
    CurrentObjectCount = 0;
    
    NSPredicate *majorClassificationPredicate = nil;
    PFQuery *majorClassificationQuery = nil;
    if (syncDate){
        majorClassificationPredicate = [NSPredicate predicateWithFormat:@"updatedAt >= %@", syncDate];
        majorClassificationQuery = [PFQuery queryWithClassName:SCHServiceMajorClassificationClass predicate:majorClassificationPredicate];
    } else {
        majorClassificationQuery = [SCHServiceMajorClassification query];
    }
    
    [majorClassificationQuery setLimit:limit];
    
    NSMutableArray *majorClassificationArray = [[NSMutableArray alloc] init];
    
    while (CurrentObjectCount == skip){
        lastObjectCount = CurrentObjectCount;
        [majorClassificationQuery setSkip:skip];
        if (appDelegate.serverReachable && appDelegate.user){
            [majorClassificationArray addObjectsFromArray:[majorClassificationQuery findObjects:&error]];
        } else{
            [majorClassificationArray removeAllObjects];
            success = NO;
            break;
        }
        
        if (error){
            [majorClassificationArray removeAllObjects];
            success = NO;
            break;
            
        }
        
        CurrentObjectCount = [majorClassificationArray count];
        if (lastObjectCount == CurrentObjectCount){
            break;
        } else {
            skip = skip + limit;
        }
        
    }
    // if nor reachable then end here
    if (!appDelegate.serverReachable || !appDelegate.user){
        success = NO;
    }
    if (!success){
        return success;
    }
    
    if (majorClassificationArray.count > 0){
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:majorClassificationArray];
    }
    
    // service Classification
    
    
    
    skip = 0;
    lastObjectCount = 0;
    CurrentObjectCount = 0;
    
    NSPredicate *serviceClassificationPredicate = nil;
    PFQuery *serviceClassificationQuery = nil;
    if (syncDate){
        serviceClassificationPredicate = [NSPredicate predicateWithFormat:@"updatedAt >= %@", syncDate];
        serviceClassificationQuery = [PFQuery queryWithClassName:SCHServiceClassificationClass predicate:majorClassificationPredicate];
    } else {
        serviceClassificationQuery = [SCHServiceClassification query];
    }
    
    [serviceClassificationQuery setLimit:limit];
    
    NSMutableArray *serviceClassificationArray = [[NSMutableArray alloc] init];
    
    while (CurrentObjectCount == skip){
        lastObjectCount = CurrentObjectCount;
        [serviceClassificationQuery setSkip:skip];
        if (appDelegate.serverReachable && appDelegate.user){
           [serviceClassificationArray addObjectsFromArray:[serviceClassificationQuery findObjects:&error]];
        } else{
            [serviceClassificationArray removeAllObjects];
            success = NO;
            break;
        }
        
        if (error){
            [serviceClassificationArray removeAllObjects];
            success = NO;
            break;
            
        }
        
        CurrentObjectCount = [serviceClassificationArray count];
        if (lastObjectCount == CurrentObjectCount){
            break;
        } else {
            skip = skip + limit;
        }
        
    }
    // if nor reachable then end here
    if (!appDelegate.serverReachable || !appDelegate.user){
        success = NO;
    }
    if (!success){
        return success;
    }
    
    if (serviceClassificationArray.count > 0){
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:serviceClassificationArray];
    }

    
    //User Location
    
    
    skip = 0;
    lastObjectCount = 0;
    CurrentObjectCount = 0;
    NSPredicate *userLocationPredicate = nil;
    
    
    if (syncDate){
        userLocationPredicate = [NSPredicate predicateWithFormat:@"user = %@ AND updatedAt >= %@", appDelegate.user, syncDate ];
    } else{
        userLocationPredicate = [NSPredicate predicateWithFormat:@"user = %@", appDelegate.user];
    }
    PFQuery *userLocationQuery = [PFQuery queryWithClassName:SCHUserLocationClass predicate:userLocationPredicate];
    [userLocationQuery setLimit:limit];
    
    
    NSMutableArray *userLocations = [[NSMutableArray alloc] init];
    
    while (CurrentObjectCount == skip){
        lastObjectCount = CurrentObjectCount;
        [userLocationQuery setSkip:skip];
        if (appDelegate.serverReachable && appDelegate.user){
            [userLocations addObjectsFromArray:[userLocationQuery findObjects:&error]];
        } else{
            [userLocations removeAllObjects];
            success = NO;
            break;
        }
        
        if (error){
            [userLocations removeAllObjects];
            success = NO;
            break;
            
        }
        
        CurrentObjectCount = [userLocations count];
        if (lastObjectCount == CurrentObjectCount){
            break;
        } else {
            skip = skip + limit;
        }
        
    }
    // if nor reachable then end here
    if (!appDelegate.serverReachable || !appDelegate.user){
        success = NO;
    }
    if (!success){
        return success;
    }
    
    if (userLocations.count > 0){
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:userLocations];
    }
    
    //UserFriends
    skip = 0;
    lastObjectCount = 0;
    CurrentObjectCount = 0;
    NSPredicate *userFriendPredicate = nil;
    
    if (syncDate){
        userFriendPredicate = [NSPredicate predicateWithFormat:@"user = %@ AND updatedAt >= %@", appDelegate.user, syncDate ];
    } else{
        userFriendPredicate = [NSPredicate predicateWithFormat:@"user = %@", appDelegate.user];
    }
    
    PFQuery *userFriendQuery = [PFQuery queryWithClassName:SCHUserFriendClass predicate:userFriendPredicate];
    [userFriendQuery includeKey:@"CBFriend"];
    [userFriendQuery setLimit:limit];
    NSMutableArray *userFriends = [[NSMutableArray alloc] init];
    
    while (CurrentObjectCount == skip){
        lastObjectCount = CurrentObjectCount;
        [userFriendQuery setSkip:skip];
        if (appDelegate.serverReachable && appDelegate.user){
            [userFriends addObjectsFromArray:[userFriendQuery findObjects:&error]];
        } else{
            [userFriends removeAllObjects];
            success = NO;
            break;
        }
        
        if (error){
            [userFriends removeAllObjects];
            success = NO;
            break;
            
        }
        
        CurrentObjectCount = [userFriends count];
        if (lastObjectCount == CurrentObjectCount){
            break;
        } else {
            skip = skip + limit;
        }
        
    }
    // if nor reachable then end here
    if (!appDelegate.serverReachable || !appDelegate.user){
        success = NO;
    }
    if (!success){
        return success;
    }
    if (userFriends.count > 0){
        for (SCHUserFriend *friend in userFriends){
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:friend];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:friend.CBFriend];
        }
       
    }
    
    // service Provider client List
    
        
    NSPredicate *serviceProviderClientListPredicate = nil;
    
    if (syncDate){
        serviceProviderClientListPredicate = [NSPredicate predicateWithFormat:@"serviceProvider = %@ AND updatedAt >= %@", appDelegate.user, syncDate];
    } else{
        serviceProviderClientListPredicate = [NSPredicate predicateWithFormat:@"serviceProvider = %@", appDelegate.user];
    }
    
    PFQuery *serviceProviderClientListQuery = [PFQuery queryWithClassName:SCHServiceProviderClientListClass predicate:serviceProviderClientListPredicate];
    [serviceProviderClientListQuery includeKey:@"client"];
    [serviceProviderClientListQuery includeKey:@"nonUserClient"];
    [serviceProviderClientListQuery setLimit:1000];
    NSArray *serviceProviderClientLists = nil;
    if (appDelegate.serverReachable && appDelegate.user){
        serviceProviderClientLists = [serviceProviderClientListQuery findObjects:&error];
    } else{
        return NO;
    }
    
    if (error || !appDelegate.serverReachable || !appDelegate.user){
        return NO;
    }
    for (SCHServiceProviderClientList *clientList in serviceProviderClientLists){
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:clientList];
  
        if (clientList.client){
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:clientList.client];
        }
        if (clientList.nonUserClient){
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:clientList.nonUserClient];
           // NSLog(@"Non User Client: %@", clientList.nonUserClient);
        }
        
    }
    
    
    //service
    
    NSPredicate *serviePredicate = nil;
    if (syncDate){
        serviePredicate = [NSPredicate predicateWithFormat:@"user = %@ AND updatedAt >= %@", appDelegate.user, syncDate];
    } else{
        serviePredicate = [NSPredicate predicateWithFormat:@"user = %@", appDelegate.user];
    }
    
    
    PFQuery *serviceQuery = [PFQuery queryWithClassName:SCHServiceClass predicate:serviePredicate];
    [serviceQuery includeKey:@"serviceClassification"];
    
    NSArray *serviceArray = nil;
    if (appDelegate.serverReachable && appDelegate.user){
        serviceArray = [serviceQuery findObjects:&error];
    }else{
        return NO;
    }
    
    if (error || !appDelegate.serverReachable || !appDelegate.user){
        return NO;
    }
    
    [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:serviceArray];
    
    //service Offering
    
    PFQuery *serviceOfferringQuery = [SCHServiceOffering query];
    
    [serviceOfferringQuery whereKey:@"service" containedIn:serviceArray];
    if (syncDate){
        [serviceOfferringQuery whereKey:@"updatedAt" greaterThanOrEqualTo:syncDate];
    }
    NSArray *serviceOfferingArray = nil;
    if (appDelegate.serverReachable && appDelegate.user){
        serviceOfferingArray = [serviceOfferringQuery findObjects:&error];
    } else{
        return NO;
    }
    
    
    if (error || !appDelegate.serverReachable || !appDelegate.user){
        return NO;
        
    }
    
    [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:serviceOfferingArray];
    
    //schedule screen Filter
    
    PFQuery *scheduleScreenFilterQuery = [SCHScheduleScreenFilter query];
    [scheduleScreenFilterQuery whereKey:@"user" equalTo:appDelegate.user];
    
    if (appDelegate.serverReachable && appDelegate.user){
        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:[scheduleScreenFilterQuery getFirstObject:&error]];
    } else{
        return NO;
    }
    
    
    
    if (error|| !appDelegate.serverReachable || !appDelegate.user){
        return NO;
    }
    
    
    
    //syncAppointmentSeries
    
    
    skip = 0;
    lastObjectCount = 0;
    CurrentObjectCount = 0;
    
    
    NSPredicate *appointmentSeriesPredicate = nil;
    if (syncDate){
        appointmentSeriesPredicate = [NSPredicate predicateWithFormat:@"(serviceProvider = %@ OR client == %@) AND updatedAt >= %@", appDelegate.user, appDelegate.user, syncDate];
    } else {
        appointmentSeriesPredicate = [NSPredicate predicateWithFormat:@"(serviceProvider = %@ OR client == %@)", appDelegate.user, appDelegate.user];
    }
    
    PFQuery *appointmentSeriesQuery = [PFQuery queryWithClassName:SCHAppointmentSeriesClass predicate:appointmentSeriesPredicate];
    [appointmentSeriesQuery includeKey:@"client"];
    [appointmentSeriesQuery includeKey:@"nonUserClient"];
    [appointmentSeriesQuery includeKey:@"serviceOffering"];
    [appointmentSeriesQuery includeKey:@"service"];
    [appointmentSeriesQuery includeKey:@"serviceProvider"];
    [appointmentSeriesQuery includeKey:@"status"];
    [appointmentSeriesQuery setLimit:limit];
    
    NSMutableArray *appointmentSeriesArray = [[NSMutableArray alloc] init];
    
    [appointmentSeriesQuery setLimit:limit];
    
    while (CurrentObjectCount == skip){
        lastObjectCount = CurrentObjectCount;
        [appointmentSeriesQuery setSkip:skip];
        if (appDelegate.serverReachable && appDelegate.user){
            [appointmentSeriesArray addObjectsFromArray:[appointmentSeriesQuery findObjects:&error]];
        } else{
            [appointmentSeriesArray removeAllObjects];
            success = NO;
            break;
        }
        
        if (error){
            [appointmentSeriesArray removeAllObjects];
            success = NO;
            break;
            
        }
        
        CurrentObjectCount = [appointmentSeriesArray count];
        if (lastObjectCount == CurrentObjectCount){
            break;
        } else {
            skip = skip + limit;
        }
        
    }
    // if nor reachable then end here
    if (!appDelegate.serverReachable || !appDelegate.user){
        success = NO;
    }
    if (!success){
        return success;
    }
    
    
    if (appointmentSeriesArray.count > 0){
        
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:appointmentSeriesArray];
        
        
        for (SCHAppointmentSeries *appointmentSeries in appointmentSeriesArray){
            
            if (appointmentSeries.client){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointmentSeries.client];
            }
            if (appointmentSeries.nonUserClient){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointmentSeries.nonUserClient];
            }
            if (appointmentSeries.serviceOffering){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointmentSeries.serviceOffering];
            }
            if (appointmentSeries.service){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointmentSeries.service];
            }
            if (appointmentSeries.serviceProvider){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointmentSeries.serviceProvider];
            }
            if (appointmentSeries.status){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointmentSeries.status];
            }

            
            //remove respective activities
            PFQuery *existingActivitiesQuery = [SCHAppointmentActivity query];
            [existingActivitiesQuery includeKey:@"appointmentSeries"];
            [existingActivitiesQuery fromLocalDatastore];
            [existingActivitiesQuery whereKey:@"appointmentSeries" equalTo:appointmentSeries];
            
            NSArray *existingActivities = [existingActivitiesQuery findObjects:&error];
            if (error) {
                success = NO;
                break;
            }
            [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:existingActivities];
            
        }
        
        if (!success){
            return success;
        }
        
    }
    
    //sync Appointment
    
    skip = 0;
    lastObjectCount = 0;
    CurrentObjectCount = 0;
    
    NSMutableArray *appointments = [[NSMutableArray alloc] init];
    
    NSPredicate *appointPredicate = nil;
    if (syncDate){
        appointPredicate = [NSPredicate predicateWithFormat:@"(client = %@ OR serviceProvider = %@) AND updatedAt >= %@", appDelegate.user, appDelegate.user, syncDate];
    } else{
        appointPredicate = [NSPredicate predicateWithFormat:@"(client = %@ OR serviceProvider = %@)", appDelegate.user, appDelegate.user];
    }
    
    
    PFQuery *appointmentsQuery = [PFQuery queryWithClassName:SCHAppointmentClass predicate:appointPredicate];
    [appointmentsQuery setLimit:limit];
    [appointmentsQuery includeKey:@"Client"];
    [appointmentsQuery includeKey:@"nonUserClient"];
    [appointmentsQuery includeKey:@"serviceOffering"];
    [appointmentsQuery includeKey:@"service"];
    [appointmentsQuery includeKey:@"serviceProvider"];
    [appointmentsQuery includeKey:@"status"];
    [appointmentsQuery setLimit:limit];
    
    while (CurrentObjectCount == skip){
        lastObjectCount = CurrentObjectCount;
        [appointmentsQuery setSkip:skip];
        if (appDelegate.serverReachable && appDelegate.user){
            [appointments addObjectsFromArray:[appointmentsQuery findObjects:&error]];
        } else{
            [appointments removeAllObjects];
            success = NO;
            break;
        }
        
        if (error){
            [appointments removeAllObjects];
            success = NO;
            break;
        }
        
        CurrentObjectCount = [appointments count];
        if (lastObjectCount == CurrentObjectCount){
            break;
        } else {
            skip = skip + limit;
        }
        
    }
    if (!appDelegate.serverReachable || !appDelegate.user){
        success = NO;
    }
    
    if (!success){
        return success;
    }
    
    
    if (appointments.count > 0){
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:appointments];
        for (SCHAppointment *appointment in appointments){
            
            if (appointment.client){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment.client];
            }
            if (appointment.nonUserClient){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment.nonUserClient];
            }
            if (appointment.serviceOffering){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment.serviceOffering];
            }
            if (appointment.service){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment.service];
            }
            if (appointment.serviceProvider){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment.serviceProvider];
            }
            if (appointment.status){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:appointment.status];
            }
            
            
            
            
            //remove respective activities
            PFQuery *existingActivitiesQuery = [SCHAppointmentActivity query];
            [existingActivitiesQuery includeKey:@"appointment"];
            [existingActivitiesQuery fromLocalDatastore];
            [existingActivitiesQuery whereKey:@"appointment" equalTo:appointment];
            
            NSArray *existingActivities = [existingActivitiesQuery findObjects:&error];
            if (error) {
                success = NO;
                break;
            }
            [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:existingActivities];
            
            
        }
    }
    
    //sync Appointment Activities for the appointments
    
    // Appointment Activities

    
    skip = 0;
    lastObjectCount = 0;
    CurrentObjectCount = 0;
    
    NSMutableArray *appointmentActivities = [[NSMutableArray alloc] init];
    NSPredicate *appointmentActivityPredicate = [NSPredicate predicateWithFormat:@"(actionInitiator = %@ OR actionAssignedTo = %@)", appDelegate.user, appDelegate.user];
    
    PFQuery *appointmentActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:appointmentActivityPredicate];
    [appointmentActivityQuery includeKey:@"actionInitiator"];
    [appointmentActivityQuery includeKey:@"actionAssignedTo"];
    [appointmentActivityQuery whereKey:@"appointment" containedIn:appointments];
   // [appointmentActivityQuery whereKey:@"appointmentSeries" containedIn:appointmentSeriesArray];
    [appointmentActivityQuery setLimit:limit];
    
    while (CurrentObjectCount == skip){
        lastObjectCount = CurrentObjectCount;
        [appointmentActivityQuery setSkip:skip];
        if (appDelegate.serverReachable && appDelegate.user){
            [appointmentActivities addObjectsFromArray:[appointmentActivityQuery findObjects:&error]];
        } else{
            [appointmentActivities removeAllObjects];
            success = NO;
            break;
        }
        
        if (error){
            [appointmentActivities removeAllObjects];
            success = NO;
            break;
        }
        
        CurrentObjectCount = [appointmentActivities count];
        if (lastObjectCount == CurrentObjectCount){
            break;
        } else {
            skip = skip + limit;
        }
        
    }
    
    if (!appDelegate.serverReachable || !appDelegate.user){
        success = NO;
    }
    

    
    if (!success){
        return success;
    }
    
    if (appointmentActivities.count > 0){
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:appointmentActivities];
        
        for (SCHAppointmentActivity *activity in appointmentActivities){
            if (activity.actionAssignedTo){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:activity.actionAssignedTo];
            }
            if (activity.actionInitiator){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:activity.actionInitiator];
            }
            
            
            
        }
    }
    
   // AppointmentSeries Activities
    
    skip = 0;
    lastObjectCount = 0;
    CurrentObjectCount = 0;
    NSMutableArray *appointmentSeriesActivities = [[NSMutableArray alloc] init];
    NSPredicate *appointmentSeriesActivityPredicate = [NSPredicate predicateWithFormat:@"(actionInitiator = %@ OR actionAssignedTo = %@)", appDelegate.user, appDelegate.user];
    
    PFQuery *appointmentSeriesActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:appointmentSeriesActivityPredicate];
    [appointmentSeriesActivityQuery includeKey:@"actionInitiator"];
    [appointmentSeriesActivityQuery includeKey:@"actionAssignedTo"];
    
    //[appointmentActivityQuery whereKey:@"appointment" containedIn:appointments];
    [appointmentSeriesActivityQuery whereKey:@"appointmentSeries" containedIn:appointmentSeriesArray];
    [appointmentSeriesActivityQuery setLimit:limit];
    
    while (CurrentObjectCount == skip){
        lastObjectCount = CurrentObjectCount;
        [appointmentSeriesActivityQuery setSkip:skip];
        if (appDelegate.serverReachable && appDelegate.user){
            [appointmentSeriesActivities addObjectsFromArray:[appointmentSeriesActivityQuery findObjects:&error]];
        } else{
            [appointmentSeriesActivities removeAllObjects];
            success = NO;
            break;
        }
        
        if (error){
            [appointmentSeriesActivities removeAllObjects];
            success = NO;
            break;
        }
        
        CurrentObjectCount = [appointmentSeriesActivities count];
        if (lastObjectCount == CurrentObjectCount){
            break;
        } else {
            skip = skip + limit;
        }
        
    }
    
    if (!appDelegate.serverReachable || !appDelegate.user){
        success = NO;
    }
    
    if (!success){
        return success;
    }
    
    if (appointmentSeriesActivities.count >0){
        [appDelegate.backgroundCommit.objectsStagedForPinning addObjectsFromArray:appointmentSeriesActivities];
        for (SCHAppointmentActivity *activity in appointmentSeriesActivities){
            if (activity.actionAssignedTo){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:activity.actionAssignedTo];
            }
            if (activity.actionInitiator){
                [appDelegate.backgroundCommit.objectsStagedForPinning addObject:activity.actionInitiator];
            }
            
            
            
        }
    }

    
    
    
    
    return success;
}




+(BOOL) removeexpiredObjects{
    
   // NSLog(@"Processing removeexpiredObjects");
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    

    SCHConstants *constants = [SCHConstants sharedManager];
    // Get time
    NSDate *cutoffTime = [SCHUtility startOrEndTime:[NSDate date]];

    //Get old availabilities for delete
    
    NSPredicate *availabilitiesForDeletePredicate = [NSPredicate predicateWithFormat:@"endTime <= %@", cutoffTime];
    PFQuery *availabilitiesForDeleteQuery = [PFQuery queryWithClassName:SCHAvailabilityClass predicate:availabilitiesForDeletePredicate];
    [availabilitiesForDeleteQuery fromLocalDatastore];
    NSArray *availabilitiesForDelete = [availabilitiesForDeleteQuery findObjects];
    
    if (availabilitiesForDelete.count > 0){
        [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:availabilitiesForDelete];
        [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:availabilitiesForDelete];

    }
    
    
    // Update current availabilities to cutoff Date
    
    NSPredicate *availatiesForUdatePredicate = [NSPredicate predicateWithFormat:@"startTime < %@ AND endTime > %@", cutoffTime, cutoffTime];
    PFQuery *availabilitiesForUpdateQuery = [PFQuery queryWithClassName:SCHAvailabilityClass predicate:availatiesForUdatePredicate];
    [availabilitiesForUpdateQuery fromLocalDatastore];
    //[availabilitiesForUpdateQuery includeKey:@"services"];
    
    NSArray *availabilitiesForUpdate = [availabilitiesForUpdateQuery findObjects];
    if (availabilitiesForUpdate.count > 0) {
        for (SCHAvailability *availability in availabilitiesForUpdate){
            availability.startTime = cutoffTime;
            // Rebuild services
            NSMutableArray *availabilityServices = [[NSMutableArray alloc] init];
            for (NSMutableDictionary *service in availability.services){
                BOOL removeService = NO;
                //NSDictionary *availabilityService = @{@"service": service, @"startTime": startTime, @"endTime": endTime};
                NSDate *serviceStartTime  = [service valueForKey:@"startTime"];
                NSDate *serviceEndTime = [service valueForKey:@"endTime"];
                if (serviceEndTime <= cutoffTime){
                    //remove object from service Array
                    removeService = YES;
                }
                if (serviceStartTime < cutoffTime) {
                    [service removeObjectForKey:@"startTime"];
                    [service setObject:cutoffTime forKey:@"startTime"];
                    
                }
                if (!removeService){
                    [availabilityServices addObject:service];
                }
                removeService = NO;
                
                
            }
            availability.services = availabilityServices;
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:availability];
        }
        
    }
    
    //expire and remove old meetups
    
    NSPredicate *expiredmeetupPredicate = [NSPredicate predicateWithFormat:@"expired != %@ AND endTime <= %@", @YES, cutoffTime];
    PFQuery *expiredMeetupQuery = [PFQuery queryWithClassName:SCHMeetingClass predicate:expiredmeetupPredicate];
    [expiredMeetupQuery fromLocalDatastore];
    NSArray *expiredMeetups = [expiredMeetupQuery findObjects];
    
    if (expiredMeetups.count > 0){
        for (SCHMeeting *meeting in expiredMeetups){
            
                [appDelegate.backgroundCommit.objectsStagedForUnpin addObject:meeting];
                [appDelegate.backgroundCommit.objectsStagedForDelete addObject:meeting];
                [SCHUtility removeOldNotifications:meeting.objectId];
            
            
        }
    }
    
    //remove all expired meetup change requests
    NSPredicate *meetupPredicate = [NSPredicate predicateWithFormat:@"expired != %@ AND endTime > %@", @YES, cutoffTime];
    PFQuery *MeetupQuery = [PFQuery queryWithClassName:SCHMeetingClass predicate:meetupPredicate];
    [MeetupQuery fromLocalDatastore];
    NSArray *meetups = [MeetupQuery findObjects];
    
    if (meetups.count > 0){
        for (SCHMeeting *meetup in meetups){
            if (meetup.changeRequests.count > 0){
                NSMutableArray *changeRequests = [[NSMutableArray alloc] initWithArray:meetup.changeRequests];
                NSPredicate *oldCRPredicates = [NSPredicate predicateWithBlock:^BOOL(NSDictionary  *CR, NSDictionary<NSString *,id> * _Nullable bindings) {
                    if ([[CR valueForKey:SCHMeetupCRAttrType] isEqualToString:SCHMeetupCRTypeChangeLocationOrTime]){
                        if ([cutoffTime compare:(NSDate *)[CR valueForKey:SCHMeetupCRAttrProposedEndTime] ]== NSOrderedDescending ){
                            
                            return YES;
                            
                        } else{
                            return  NO;
                            
                        }
                        
                        
                        
                    }else {
                        
                        return NO;
                    }
                    
                }];
                NSArray *oldChangeRequests = [meetup.changeRequests filteredArrayUsingPredicate:oldCRPredicates];
                if (oldChangeRequests.count > 0){
                    [changeRequests removeObjectsInArray:oldChangeRequests];
                    meetup.changeRequests = changeRequests;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:meetup];
                    [appDelegate.backgroundCommit.objectsStagedForPinning addObject:meetup];
                    
                }
                
            }
        }
    }
    
    
    
    
    
    
    
    //Expire all old appointments
    NSPredicate *expiredAppointmentsPredicate = [NSPredicate predicateWithFormat:@"expired != %@ AND (endTime <= %@  OR proposedEndTime <= %@)", @YES, cutoffTime, cutoffTime];
    PFQuery *expiredAppointmentQuery = [PFQuery queryWithClassName:SCHAppointmentClass predicate:expiredAppointmentsPredicate];
    [expiredAppointmentQuery fromLocalDatastore];
    NSArray *expiredAppointments = [expiredAppointmentQuery findObjects];
    
    if (expiredAppointments.count > 0){
        
        for (SCHAppointment *appointment in expiredAppointments){
            
            if (appointment.proposedEndTime){
                if ([appointment.proposedEndTime compare:cutoffTime] != NSOrderedAscending){
                    appointment.expired = YES;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
                    [SCHUtility removeOldNotifications:appointment.objectId];
                }
                
            } else{
                appointment.expired = YES;
                 [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
                [SCHUtility removeOldNotifications:appointment.objectId];
            }
        }
    }
    
    //clean up old appintment series
    
    NSPredicate *oldAppointmentSeriesPredicate = [NSPredicate predicateWithFormat:@"expired != %@ AND endDate <= %@", @YES, cutoffTime];
    PFQuery *oldAppointmentSeriesQuery = [PFQuery queryWithClassName:SCHAppointmentSeriesClass predicate:oldAppointmentSeriesPredicate];
    
    [oldAppointmentSeriesQuery fromLocalDatastore];
    
    NSArray *oldAppointmentSeries = [oldAppointmentSeriesQuery findObjects];
    
    if (oldAppointmentSeries.count > 0){
        for (SCHAppointmentSeries *series in oldAppointmentSeries){
            series.expired = YES;
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:series];
            [SCHUtility removeOldNotifications:series.objectId];
            
        }
    }
    
    //Unpin appointments, notification, and series that are past one week
    
    NSTimeInterval oneWeek = 7*24*60*60;
    NSDate *oneWeekBack = [SCHUtility getDate:[NSDate dateWithTimeIntervalSinceNow:-oneWeek]];
    
    // notification
    NSPredicate *oldNotificationPredicate = [NSPredicate predicateWithFormat:@"notificationType = %@ AND createdAt <= %@", constants.SCHNotificationForAcknowledgement, oneWeekBack];
    PFQuery *oldNotificationQuery = [PFQuery queryWithClassName:SCHNotificationClass predicate:oldNotificationPredicate];
    [oldNotificationQuery fromLocalDatastore];
    NSArray *oldNotifications = [oldNotificationQuery findObjects];
    
    if (oldNotifications.count > 0){
        [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:oldNotifications];
        [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:oldNotifications];
    }
    
    // Appointments
    
    NSPredicate *oldAppoointmentsPredicate = [NSPredicate predicateWithFormat:@"endTime <= %@  OR proposedEndTime <= %@", oneWeekBack, oneWeekBack];
    PFQuery *oldAppointmentQuery = [PFQuery queryWithClassName:SCHAppointmentClass predicate:oldAppoointmentsPredicate];
    [oldAppointmentQuery fromLocalDatastore];
    NSArray *oldAppointments = [oldAppointmentQuery findObjects];
    
    if (oldAppointments.count > 0){
        for (SCHAppointment *oldAppointment in oldAppointments){
            if (oldAppointment.proposedEndTime){
                if ([oldAppointment.proposedEndTime compare:oneWeekBack] != NSOrderedAscending){
                    [appDelegate.backgroundCommit.objectsStagedForUnpin addObject:oldAppointment];
                    [self removeOldActivities:oldAppointment series:nil];
                }
            } else{
                [appDelegate.backgroundCommit.objectsStagedForUnpin addObject:oldAppointment];
                [self removeOldActivities:oldAppointment series:nil];
            }
            
        }
    }
    
    // Appointment Series
    
    NSPredicate *expiredAppoointmentSeriesPredicate = [NSPredicate predicateWithFormat:@"endDate <= %@", oneWeekBack];
    PFQuery *expiredAppointmentSeriesQuery = [PFQuery queryWithClassName:SCHAppointmentSeriesClass predicate:expiredAppoointmentSeriesPredicate];
    [expiredAppointmentSeriesQuery fromLocalDatastore];
    NSArray *expiredAppointmentSeries = [expiredAppointmentSeriesQuery findObjects];
    
    if (expiredAppointmentSeries.count > 0){
        for (SCHAppointmentSeries *series in oldAppointmentSeries){
            [appDelegate.backgroundCommit.objectsStagedForUnpin addObject:series];
            [self removeOldActivities:nil series:series];
        }
    }

    
   [SCHUtility commitEventually];
    
    // remove Notifications for expired objects
    
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    
    PFQuery *expiredApptWithNotfnQuery = [SCHAppointment query];
    [expiredApptWithNotfnQuery whereKey:@"expired" equalTo:@YES];
    [expiredApptWithNotfnQuery fromLocalDatastore];
    NSArray *AppointmentsForNotificationRemoval = [expiredApptWithNotfnQuery findObjects];
    
    PFQuery *expiredSeriesWithNotfnQuery = [SCHAppointmentSeries query];
    [expiredSeriesWithNotfnQuery whereKey:@"expired" equalTo:@YES];
    [expiredSeriesWithNotfnQuery fromLocalDatastore];
    NSArray *SeriesForNotificationRemoval = [expiredSeriesWithNotfnQuery findObjects];
    
    NSMutableArray *objectsForNotificationRemoval = [[NSMutableArray alloc] init];
    
    if (AppointmentsForNotificationRemoval.count > 0){
        [objectsForNotificationRemoval addObjectsFromArray:AppointmentsForNotificationRemoval];
    }
    if (SeriesForNotificationRemoval.count > 0){
        [objectsForNotificationRemoval addObjectsFromArray:objectsForNotificationRemoval];
    }
    
    if (objectsForNotificationRemoval.count > 0){
        for (id object in objectsForNotificationRemoval){
            PFObject *oldObject = (PFObject *)object;
            NSPredicate *oldNotificationPredicate = [NSPredicate predicateWithFormat:@"referenceObject = %@", oldObject.objectId];
            PFQuery *oldNotificationQuery = [PFQuery queryWithClassName:SCHNotificationClass predicate:oldNotificationPredicate];
            [oldNotificationQuery fromLocalDatastore];
            NSArray *oldNotifications = [oldNotificationQuery findObjects];
            if (oldNotifications.count > 0){
                [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:oldNotifications];
                [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:oldNotifications];
            }
            
            
        }
        
        
        
       [SCHUtility commitEventually];
        [appDelegate.backgroundCommit refreshQueues];
        [appDelegate.backgroundCommit refrshStagedQueue];
    }
    
    
    // remove old location
    PFQuery *oldLocationsQuery = [SCHUserLocation query];
    [oldLocationsQuery fromLocalDatastore];
    [oldLocationsQuery setSkip:5];
    [oldLocationsQuery orderByDescending:@"updatedAt"];
    
    NSArray *oldLocations = [oldLocationsQuery findObjects];
    
    if (oldLocations.count > 0){
        [PFObject deleteAll:oldLocations];
        [PFObject unpinAll:oldLocations];
    }
    
    
    
      return YES;
    
}
/*

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
 */



+(BOOL) removeOldActivities:(SCHAppointment *) appointment series:(SCHAppointmentSeries *) series{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSError *error = nil;
    PFQuery *oldAppointmentActivitiesQuery = [SCHAppointmentActivity query];
    [oldAppointmentActivitiesQuery fromLocalDatastore];
    if (appointment){
        [oldAppointmentActivitiesQuery whereKey:@"appointment" equalTo:appointment];
    } else{
        [oldAppointmentActivitiesQuery whereKey:@"appointmentSeries" equalTo:series];
    }
    NSArray *oldActivities = [oldAppointmentActivitiesQuery findObjects:&error];
    if (!error){
        if (oldActivities.count > 0){
            [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:oldActivities];
        }
        
    } else return NO;
    
    return YES;
}





+(void) syncUserData:(NSDate *) calendarViewdate{
    
    
    
    BOOL success = YES;
    
    SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
    [backgroundManager beginBackgroundTask];
   // SCHScheduledEventManager *eventManager =
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (!appDelegate.dataSyncFailure){
        if (!appDelegate.scheduledManager){
            appDelegate.scheduledManager = [SCHScheduledEventManager sharedManager];
        }
        
        
        if (![SCHSyncManager syncWithServer]){
            success = NO;
        }
        
        if (success){
            if (![SCHSyncManager syncAvailability]){
                success = NO;
            }
        }
        if (success){
            if (![self syncMeetups]){
                success = NO;
            }
        }
        
        if (success){
            if (![SCHSyncManager syncNotification]){
                success = NO;
            }
        }
        
        
        
        PFInstallation *installation = [PFInstallation currentInstallation];
        
        BOOL commitSuccess = YES;
        if (success && appDelegate.serverReachable && appDelegate.user){
            if ([SCHUtility commit]){
                installation[@"syncDate"] = installation.updatedAt;
                [installation saveEventually];
            } else{
                commitSuccess = NO;
            }
            
        } else{
            installation[@"syncDate"] = syncDate;
            [installation saveEventually];
            [appDelegate.backgroundCommit refreshQueues];
        }
        
        if (!commitSuccess){
            // add observer
            [self commitFailure];
   
        } else{
            
            if (appDelegate.user){
                PFQuery *serviceQuery = [SCHService query];
                [serviceQuery fromLocalDatastore];
                [serviceQuery whereKey:@"user" equalTo:appDelegate.user];
                NSArray *services = [serviceQuery findObjects];
                [PFObject fetchAll:services];
                
                [SCHSyncManager removeexpiredObjects];
                [SCHUtility getFacebookUserFriends:appDelegate.user];
                [SCHUtility setServiceProviderStatus];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SCHSyncManager syncBadge];
                    
                });
                [appDelegate.scheduledManager buildScheduledEvent];
                [appDelegate.scheduledManager notificationsForUser];
                SCHActiveViewControllers *activeVCs = [SCHActiveViewControllers sharedManager];
                SCHScheduleTableViewController *scheduleVC = nil;
                SCHNotificationViewController *notificationVC = nil;
                SCHBookViewController *bookVC = nil;
                SCHManageBusinessViewController *manageServiceVC = nil;
                SCHHomeViewController *homeVC = nil;
                
                
                if ([activeVCs.viewControllers valueForKey:@"scheduleVC"]){
                    scheduleVC = [activeVCs.viewControllers valueForKey:@"scheduleVC"];
                    [scheduleVC refreshscheduleScreen:calendarViewdate];
                    //Enable behaviour
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        BOOL is_userrviceProvider =([SCHUtility hasActiveService] && appDelegate.serverReachable && ![SCHUtility IsMandatoryUpgradeRequired]);
                        if(is_userrviceProvider)
                        {
                            [scheduleVC addOptionWithServiceProvider];
                        }else{
                            [scheduleVC addOptionWithOutServiceProvider];
                        }
                        
                    });
                    
                }
                if ([activeVCs.viewControllers valueForKey:@"notificationVC"]){
                    notificationVC =[activeVCs.viewControllers valueForKey:@"notificationVC"];
                    [notificationVC refreshNotificationScreen];
                }
                if ([activeVCs.viewControllers valueForKey:@"bookVC"]){
                    bookVC = [activeVCs.viewControllers valueForKey:@"bookVC"];
                    [bookVC loadData];
                }
                //@"manageServiceVC"
                if ([activeVCs.viewControllers valueForKey:@"manageServiceVC"]){
                    manageServiceVC = [activeVCs.viewControllers valueForKey:@"manageServiceVC"];
                    [manageServiceVC loadData];
                }
                //homeVC
                if ([activeVCs.viewControllers valueForKey:@"homeVC"]){
                    homeVC = [activeVCs.viewControllers valueForKey:@"homeVC"];
                    [homeVC refreshHomeScreen];
                }
                

                
            }
            
        }
        
    }
    

    
    [backgroundManager endBackgroundTask];
}

+(void)syncUserDateNoInternetMode:(NSDate *) calendarViewDate{
    
    SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
    [backgroundManager beginBackgroundTask];
    //SCHScheduledEventManager *eventManager = [SCHScheduledEventManager sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (!appDelegate.dataSyncFailure && appDelegate.user) {

        if (!appDelegate.scheduledManager){
            appDelegate.scheduledManager = [SCHScheduledEventManager sharedManager];
        }
        
        [SCHUtility setServiceProviderStatus];
        
        [SCHSyncManager removeexpiredObjects];
        [appDelegate.scheduledManager buildScheduledEvent];
        [appDelegate.scheduledManager notificationsForUser];
        dispatch_async(dispatch_get_main_queue(), ^{
            [SCHSyncManager syncBadge];
        });
        SCHActiveViewControllers *activeVCs = [SCHActiveViewControllers sharedManager];
        SCHScheduleTableViewController *scheduleVC = nil;
        SCHNotificationViewController *notificationVC = nil;
        SCHBookViewController *bookVC = nil;
        SCHManageBusinessViewController *manageServiceVC = nil;
        SCHHomeViewController *homeVC = nil;
        
        if ([activeVCs.viewControllers valueForKey:@"scheduleVC"]){
            scheduleVC = [activeVCs.viewControllers valueForKey:@"scheduleVC"];
            
            //Enable behaviour
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                
                
                BOOL is_userrviceProvider =([SCHUtility hasActiveService]&& appDelegate.serverReachable);
                if(is_userrviceProvider)
                {
                    [scheduleVC addOptionWithServiceProvider];
                }else{
                    [scheduleVC addOptionWithOutServiceProvider];
                }
                
            });
            [scheduleVC refreshscheduleScreen:calendarViewDate];
            
        }
        
        
        if ([activeVCs.viewControllers valueForKey:@"notificationVC"]){
            notificationVC =[activeVCs.viewControllers valueForKey:@"notificationVC"];
            [notificationVC refreshNotificationScreen];
        }
        if ([activeVCs.viewControllers valueForKey:@"bookVC"]){
            bookVC = [activeVCs.viewControllers valueForKey:@"bookVC"];
            [bookVC loadData];
        }
        
        if ([activeVCs.viewControllers valueForKey:@"manageServiceVC"]){
            manageServiceVC = [activeVCs.viewControllers valueForKey:@"manageServiceVC"];
            [manageServiceVC loadData];
        }
        
        //homeVC
        if ([activeVCs.viewControllers valueForKey:@"homeVC"]){
            homeVC = [activeVCs.viewControllers valueForKey:@"homeVC"];
            [homeVC refreshHomeScreen];
        }

        
    }
    
    
    
    
}


+(void)callTimer
{
    AppDelegate * appDeligate =  (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDeligate.serverReachable){
        if (appDeligate.user){
            dispatch_barrier_async(appDeligate.backgroundManager.SCHSerialQueue, ^{
                
                [SCHSyncManager syncUserData:nil];
                
            });
        }
        
    } else{
        dispatch_barrier_async(appDeligate.backgroundManager.SCHSerialQueue, ^{
            
            [SCHSyncManager syncUserDateNoInternetMode:nil];
            
        });
        
    }
}
+(void) commitFailure{
     AppDelegate * appDeligate =  (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDeligate.dataSyncFailure = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SCHsyncFailure
                                                            object:self];
    });
    
}


@end
