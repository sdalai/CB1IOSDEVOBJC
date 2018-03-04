//
//  SCHMeetingManager.m
//  CounterBean
//
//  Created by Sujit Dalai on 6/19/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHMeetingManager.h"
#import "AppDelegate.h"
#import "SCHUtility.h"
#import "SCHConstants.h"

#import "SCHNonUserClient.h"
#import "SCHEmailAndTextMessage.h"




@implementation SCHMeetingManager

NSMutableArray *nonUsetTextList;
NSMutableArray *nonUserEmailList;
NSMutableArray *userNotificationList;


#pragma mark - Creation

+(NSDictionary *)createMeetingWithSubject:(NSString *) subject organizer:(SCHUser *) organizaer location:(NSString *)  location startTime:(NSDate *) startTime endTime:(NSDate *) endtime invites:(NSArray *) invites note:(NSString *) note{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate *inputStartTime = [SCHUtility startOrEndTime:startTime];
    NSDate *inputEndTime = [SCHUtility startOrEndTime:endtime];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    
    nonUsetTextList = nil;
    nonUserEmailList = nil;
    userNotificationList = nil;
    
    

    BOOL success = YES;
    SCHConstants *constants = [SCHConstants  sharedManager];



    SCHMeeting *meeting = [SCHMeeting new];
    meeting.subject = subject;
    meeting.organizer = organizaer;
    meeting.status = constants.SCHappointmentStatusConfirmed;
    meeting.expired = NO;
    meeting.startTime = inputStartTime;
    meeting.endTime = inputEndTime;
    meeting.location = location;
    meeting.notes = note;
    [SCHUtility setPublicAllRWACL:meeting.ACL];
    [self addInvities:invites
            toMeeting:meeting
            save:NO];
    
    if (meeting.invites.count == 0){
        return nil;
    }
    if ([SCHUtility pendingMeetupStatus:meeting.invites]> 0){
        meeting.status = constants.SCHappointmentStatusPending;
    }
    [appDelegate.backgroundCommit.objectsStagedForSave addObject:meeting];
    [appDelegate.backgroundCommit.objectsStagedForPinning addObject:meeting];
    
    if (appDelegate.serverReachable){
        success = [SCHUtility commit];
    }
    
    //Send Notifications
    if (success){
        if (userNotificationList.count > 0){
            for (SCHUser *user in userNotificationList){
                [self createNotificationForMeeting:meeting
                                  NotificationType:kNewMeetingNotification
                                          fromUser:appDelegate.user
                                            toUser:user];
            }
            
            
        }
        NSDictionary *output = @{@"meeting" : meeting,
                                 @"nonUsetTextList" : nonUsetTextList,
                                 @"nonUserEmailList" : nonUserEmailList};
        return output;
                                 
    } else{
        return nil;
    }
    

}

+(NSDictionary *)addInvities:(NSArray *)invities toMeeting:(SCHMeeting *) meeting{
    BOOL success = YES;
    SCHConstants *constants = [SCHConstants  sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    
    nonUsetTextList = nil;
    nonUserEmailList = nil;
    userNotificationList = nil;
    [self addInvities:invities
            toMeeting:meeting
                 save:NO];
    
    
    if ([SCHUtility pendingMeetupStatus:meeting.invites]> 0){
        meeting.status = constants.SCHappointmentStatusPending;
    }
    [appDelegate.backgroundCommit.objectsStagedForSave addObject:meeting];
    [appDelegate.backgroundCommit.objectsStagedForPinning addObject:meeting];
    
    
    if (success){
        if (userNotificationList.count > 0){
            for (SCHUser *user in userNotificationList){
                success = [self removeOldNotifications:meeting.objectId user:user];
                if (!success){
                    break;
                }
            }
            
        }

    }
    
    if (appDelegate.serverReachable){
        success = [SCHUtility commit];
    }
    
    
    
    //Send Notifications
    if (success){
        if (userNotificationList.count > 0){
            for (SCHUser *user in userNotificationList){
                [self createNotificationForMeeting:meeting
                                  NotificationType:kNewMeetingNotification
                                          fromUser:appDelegate.user
                                            toUser:user];
            }
            
            
        }
        NSDictionary *output = @{@"meeting" : meeting,
                                 @"nonUsetTextList" : nonUsetTextList,
                                 @"nonUserEmailList" : nonUserEmailList};
        return output;
        
    } else{
        return nil;
    }
    
}


+(BOOL)acceptMeeting:(SCHMeeting *) meeting{
    
    BOOL success = YES;
    SCHConstants *constants = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    nonUsetTextList = nil;
    nonUserEmailList = nil;
    userNotificationList = nil;
    NSMutableArray *meetingCRs = [[NSMutableArray alloc] init];
    if (meeting.changeRequests.count > 0){
        [meetingCRs addObjectsFromArray:meeting.changeRequests];
    }
    SCHUser *user = appDelegate.user;
    NSPredicate *inviteePredicate = [NSPredicate predicateWithFormat:@" user = %@", user];
    NSArray *inviteiesForAcceptance = [meeting.invites filteredArrayUsingPredicate:inviteePredicate];
    NSMutableArray *meetingInvites = [[NSMutableArray alloc] init];
    
    if (inviteiesForAcceptance.count >0){
        [meetingInvites addObjectsFromArray:meeting.invites];
        [meetingInvites removeObjectsInArray:inviteiesForAcceptance];
        
        for (NSDictionary *invitee in inviteiesForAcceptance){
            NSDictionary *accetpedInvitee = [self createInvitesWith:[invitee valueForKey:SCHMeetupInviteeUser]
                                                               name:[invitee valueForKey:SCHMeetupInviteeName]
                                                          accepance:SCHMeetupConfirmed];
            [meetingInvites addObject:accetpedInvitee];
            if (meeting.changeRequests.count > 0){
                if ([[invitee valueForKey:SCHMeetupInviteeUser] isKindOfClass:[SCHUser class]] && meetingCRs.count > 0){
                    NSPredicate *userCRPredicates = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *CR, NSDictionary<NSString *,id> * _Nullable bindings) {
                        if ([[CR valueForKey:SCHMeetupCRAttrRequester] isEqual:[invitee valueForKey:SCHMeetupInviteeUser]] && [[CR valueForKey:SCHMeetupCRAttrType] isEqualToString:SCHMeetupCRTypeChangeLocationOrTime] ){
                            return YES;
                        }else{
                            return NO;
                        }
            
                    }];
                    NSArray *userCRs = [meetingCRs filteredArrayUsingPredicate:userCRPredicates];
                    if (userCRs.count > 0){
                        [meetingCRs removeObjectsInArray:userCRs];
                    }
                    
                }
                
            }
            
        }
        meeting.invites = meetingInvites;
        if ([SCHUtility pendingMeetupStatus:meeting.invites]> 0){
            meeting.status = constants.SCHappointmentStatusPending;
        } else{
            meeting.status = constants.SCHappointmentStatusConfirmed;
        }

        [appDelegate.backgroundCommit.objectsStagedForSave addObject:meeting];
        
    } else{
        success = NO;
    }
    
    meeting.changeRequests = meetingCRs;
    
    if (success){
        
       success = [self removeOldNotifications:meeting.objectId user:user];
        
    }
    if (success){
         success = [SCHUtility commit];
    }
    
    if (success){
        [self createNotificationForMeeting:meeting
                          NotificationType:kMeetingAcceptanceNotification
                                  fromUser:appDelegate.user
                                    toUser:meeting.organizer];
        
    }
    
    
    



    return success;
}

+(BOOL)declineMeeting:(SCHMeeting *) meeting{
    
    BOOL success = YES;
    SCHConstants *constants = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    NSMutableArray *meetingCRs = [[NSMutableArray alloc] init];
    if (meeting.changeRequests.count > 0){
        [meetingCRs addObjectsFromArray:meeting.changeRequests];
    }
    
    SCHUser *user = appDelegate.user;
    NSPredicate *inviteePredicate = [NSPredicate predicateWithFormat:@" user = %@", user];
    NSArray *selfDicts = [meeting.invites filteredArrayUsingPredicate:inviteePredicate];
    
    
    
    if (selfDicts.count > 0){
        NSMutableArray *invities = [[NSMutableArray alloc] initWithArray:meeting.invites];
        NSMutableArray *attendees = [[NSMutableArray alloc] initWithArray:meeting.attendees];
        for (NSDictionary *invitee in selfDicts){
            [invities removeObject:invitee];
            //add declined invitee
            NSDictionary *declinedInvitee = [self createInvitesWith:[invitee valueForKey:SCHMeetupInviteeUser]
                                                               name:[invitee valueForKey:SCHMeetupInviteeName]
                                                          accepance:SCHMeetupDeclined];
            [invities addObject:declinedInvitee];
            
            
            
            [attendees removeObject:[invitee valueForKey:SCHMeetupInviteeUser]];
            if (meeting.changeRequests.count > 0){
                if ([[invitee valueForKey:SCHMeetupInviteeUser] isKindOfClass:[SCHUser class]] && meetingCRs.count > 0){
                    NSPredicate *userCRPredicates = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *CR, NSDictionary<NSString *,id> * _Nullable bindings) {
                        if ([[CR valueForKey:SCHMeetupCRAttrRequester] isEqual:[invitee valueForKey:SCHMeetupInviteeUser]] && [[CR valueForKey:SCHMeetupCRAttrType] isEqualToString:SCHMeetupCRTypeChangeLocationOrTime] ){
                            return YES;
                        }else{
                            return NO;
                        }
                        
                    }];
                    NSArray *userCRs = [meetingCRs filteredArrayUsingPredicate:userCRPredicates];
                    if (userCRs.count > 0){
                        [meetingCRs removeObjectsInArray:userCRs];
                    }
                    
                }
                
            }

        }
        meeting.invites = invities;
        meeting.attendees = attendees;
        meeting.changeRequests = meetingCRs;
        
        if ([SCHUtility nonDeclinedMeetupStatus:meeting.invites] == 0){
            
            meeting.status = constants.SCHappointmentStatusCancelled;
            
        }else{
            // get number of accepted invites
            int pendingInvites = (int)[SCHUtility pendingMeetupStatus:meeting.invites];
            if (pendingInvites > 0){
               meeting.status = constants.SCHappointmentStatusPending;
            } else{
                meeting.status = constants.SCHappointmentStatusConfirmed;
            }
            
        }

        [appDelegate.backgroundCommit.objectsStagedForSave addObject:meeting];

    } else{
        success = NO;
    }
    
    
    if (success){
        
        if ([meeting.status isEqual:constants.SCHappointmentStatusCancelled]){
            success = [self removeOldNotifications:meeting.objectId user:nil];
        } else{
            success = [self removeOldNotifications:meeting.objectId user:user];
        }
    }
    
    if (success){
        success =[SCHUtility commit];
    }

    if (success){
        [self createNotificationForMeeting:meeting
                          NotificationType:kMeetingDeclineNotification
                                  fromUser:user
                                    toUser:meeting.organizer];
    }
    
    
    
    return YES;
    
}

+(NSDictionary *)cancelMeeting:(SCHMeeting *) meeting{
    
    BOOL success = YES;
    SCHConstants *constants = [SCHConstants sharedManager];
    meeting.status = constants.SCHappointmentStatusCancelled;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    nonUserEmailList = [[NSMutableArray alloc] init];
    nonUsetTextList = [[NSMutableArray alloc] init];
    userNotificationList = [[NSMutableArray alloc] init];
    [appDelegate.backgroundCommit.objectsStagedForSave addObject:meeting];
    
    for (NSDictionary *invitee in meeting.invites){
        if (![[invitee valueForKey:SCHMeetupInviteeConfirmation] isEqualToString:SCHMeetupDeclined]){
            id attendee =  [invitee valueForKey:SCHMeetupInviteeUser];
            
            if ([attendee isKindOfClass:[SCHNonUserClient class]]){
                SCHNonUserClient *nonuserClinet = (SCHNonUserClient *) attendee;
                NSDictionary *nonUserReceipient = [self createNonUserReceipient:nonuserClinet.phoneNumber email:nonuserClinet.email name:[invitee valueForKey:SCHMeetupInviteeName]];
                if (nonuserClinet.phoneNumber.length > 0){
                    [nonUsetTextList addObject:nonUserReceipient];
                }
                if (nonuserClinet.phoneNumber){
                    [nonUserEmailList addObject:nonUserReceipient];
                }
                
            }else{
                SCHUser *user = (SCHUser *)attendee;
                if (![attendee isEqual:appDelegate.user]){
                    [userNotificationList addObject:user];
                }
                
            }
            
        }
        
    }
    if (success){
        success = [self removeOldNotifications:meeting.objectId user:nil];
    }
    
    if (success){
        success =[SCHUtility commit];
    }
    
    if (success){
        if (userNotificationList.count > 0){
            for (SCHUser *user in userNotificationList){
                [self createNotificationForMeeting:meeting
                                  NotificationType:kMeetingCancellationNotification
                                          fromUser:meeting.organizer
                                            toUser:user];
            }
            
            
        }
        NSDictionary *output = @{@"meeting" : meeting,
                                 @"nonUsetTextList" : nonUsetTextList,
                                 @"nonUserEmailList" : nonUserEmailList};
        return output;

        
    }else{
        return nil;
    }
    
}

+(NSDictionary *)removeInvities:(NSArray *) invites fromMeeting:(SCHMeeting *) meeting{
   BOOL success =  [self removeInvities:invites fromMeeting:meeting save:YES];
    if (success){
        NSDictionary *output = @{@"meeting" : meeting,
                                 @"nonUsetTextList" : nonUsetTextList,
                                 @"nonUserEmailList" : nonUserEmailList};
        return output;
    } else{
        return nil;
    }
    
}

+(BOOL)changeMeetingRequest:(SCHMeeting *) meeting requester: (SCHUser *) requester CRType:(NSString *) CRType newInvitees:(NSArray *) newInvities changedStartTime:(NSDate *) changedStartTime changedEndTime:(NSDate *) changedEndTime changedLocation:(NSString *) changedLocation{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    
    BOOL ChangeRequestCreated = NO;
    
    nonUsetTextList = nil;
    nonUserEmailList = nil;
    userNotificationList = nil;
    BOOL success = YES;
    SCHConstants *constants = [SCHConstants  sharedManager];
    
    NSMutableArray *meetingChangeRequests = nil;
    
    if (!meeting.changeRequests){
        meetingChangeRequests  = [[NSMutableArray alloc] init];
    } else{
        meetingChangeRequests  = [[NSMutableArray alloc] initWithArray:meeting.changeRequests];
    }
    if ([CRType isEqualToString:SCHMeetupCRTypeAddInvitee]){
        if (newInvities.count > 0){
            for (id invitee in newInvities){
                BOOL duplicate = NO;
                // Find if it is a duplicate CR
                if (!duplicate){
                    //Check invites list
                    NSPredicate *currentInvtesPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *currentInvitee, NSDictionary<NSString *,id> * _Nullable bindings) {
                        NSString *currentUserPhoneNumber = nil;
                        BOOL declined = NO;
                        

                        if ([[currentInvitee valueForKey:SCHMeetupInviteeUser] isKindOfClass:[SCHUser class]]){
                            SCHUser *user = (SCHUser *)[currentInvitee valueForKey:SCHMeetupInviteeUser];
                            currentUserPhoneNumber = user.phoneNumber;
                            declined = [[currentInvitee valueForKey:SCHMeetupInviteeConfirmation] isEqualToString:SCHMeetupDeclined];
                            
                        } else{
                            SCHNonUserClient *nonUser = (SCHNonUserClient *)[currentInvitee valueForKey:SCHMeetupInviteeUser];
                            currentUserPhoneNumber = nonUser.phoneNumber;
                        }
                        if ([currentUserPhoneNumber isEqualToString:[invitee valueForKey:@"phone"]]){
                            if (declined) {
                                return NO;
                            } else{
                                return YES;
                            }
                            
                        } else{
                            return NO;
                        }
                        
                    
                    }];
                    
                    NSArray *duplicateInvitees = [meeting.invites filteredArrayUsingPredicate:currentInvtesPredicate];
                    
                    if (duplicateInvitees.count > 0){
                        duplicate  = YES;
                    }
                    
                    
                    
                }
                
                if (!duplicate){
                    //check CRs
                    NSPredicate *duplicateCRPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *CR, NSDictionary<NSString *,id> * _Nullable bindings) {
                        NSDictionary *CRInvitee = [CR valueForKey:SCHMeetupCRAttrNewInvitee];
                        if (CRInvitee){
                            if ([[CRInvitee valueForKey:@"phone"]isEqualToString:[invitee valueForKey:@"phone"]]){
                                return YES;
                            }else{
                                return NO;
                            }
                            
                        } else {
                            return NO;
                        }
                        
                    }];
                    
                    NSArray *duplicateCRs = [meeting.changeRequests filteredArrayUsingPredicate:duplicateCRPredicate];
                    if (duplicateCRs.count > 0){
                        duplicate = YES;
                    }
                    
                }
    
                
                if (!duplicate){
                    NSDictionary *changeRequest = @{SCHMeetupCRAttrRequester: requester,
                                                    SCHMeetupCRAttrType: SCHMeetupCRTypeAddInvitee,
                                                    SCHMeetupCRAttrNewInvitee : invitee};
                    [meetingChangeRequests addObject:changeRequest];
                    meeting.status = constants.SCHappointmentStatusPending;
                    meeting.changeRequests = meetingChangeRequests;
                    if (!ChangeRequestCreated){
                        ChangeRequestCreated = YES;
                    }

                }
                

            }
            
            
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:meeting];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:meeting];
            
        }else{
            success = NO;
        }
        
    } else{

        BOOL duplcate = NO;
        if (meetingChangeRequests.count > 0){
            for (NSDictionary *CR in meetingChangeRequests){
                if (changedStartTime && changedLocation){
                    if (([[CR valueForKey:SCHMeetupCRAttrProposedStartTime] compare:changedStartTime] == NSOrderedSame) && ([[CR valueForKey:SCHMeetupCRAttrProposedEndTime] compare:changedEndTime] == NSOrderedSame) && [[CR valueForKey:SCHMeetupCRAttrProposedLocation] isEqualToString:changedLocation]){
                        duplcate = YES;
                        break;
                    }
                } else if (changedStartTime &&!changedLocation){
                    if (([[CR valueForKey:SCHMeetupCRAttrProposedStartTime] compare:changedStartTime] == NSOrderedSame) && ([[CR valueForKey:SCHMeetupCRAttrProposedEndTime] compare:changedEndTime] == NSOrderedSame) && [[CR valueForKey:SCHMeetupCRAttrProposedLocation] isEqualToString:meeting.location]){
                        duplcate = YES;
                        break;
                    }
                    
                }else if (!changedStartTime && changedLocation){
                    if (([(NSDate *)[CR valueForKey:SCHMeetupCRAttrProposedStartTime] compare:meeting.startTime] == NSOrderedSame) && ([(NSDate *)[CR valueForKey:SCHMeetupCRAttrProposedEndTime] compare:meeting.endTime] == NSOrderedSame) && [[CR valueForKey:SCHMeetupCRAttrProposedLocation] isEqualToString:changedLocation]){
                        duplcate = YES;
                        break;
                    }
                }
            }
        }
        
        if (!duplcate){
            
            //Remove old requests
            NSPredicate *existingCRPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *changeRequest, NSDictionary<NSString *,id> * _Nullable bindings) {
                
                SCHUser *requester = (SCHUser *)[changeRequest valueForKey:SCHMeetupCRAttrRequester];
                if ([requester isEqual:appDelegate.user] && [[changeRequest valueForKey:SCHMeetupCRAttrType] isEqualToString:SCHMeetupCRTypeChangeLocationOrTime]){
                    return YES;
                } else{
                    return NO;
                }
                
            }];
            NSArray *existingCRs = [meetingChangeRequests filteredArrayUsingPredicate:existingCRPredicate];
            
            if (existingCRs.count > 0){
                [meetingChangeRequests removeObjectsInArray:existingCRs];
            }

            
            
            NSMutableDictionary *changeRequest = [[NSMutableDictionary alloc] init];
            [changeRequest setObject:requester forKey:SCHMeetupCRAttrRequester];
            [changeRequest setObject:SCHMeetupCRTypeChangeLocationOrTime forKey:SCHMeetupCRAttrType];
            if (changedStartTime){
                [changeRequest setObject:changedStartTime forKey:SCHMeetupCRAttrProposedStartTime];
                [changeRequest setObject:changedEndTime forKey:SCHMeetupCRAttrProposedEndTime];
                
            } else{
                [changeRequest setObject:meeting.startTime forKey:SCHMeetupCRAttrProposedStartTime];
                [changeRequest setObject:meeting.endTime forKey:SCHMeetupCRAttrProposedEndTime];
            }
            if(changedLocation){
                [changeRequest setObject:changedLocation forKey:SCHMeetupCRAttrProposedLocation];
            }else{
                [changeRequest setObject:meeting.location forKey:SCHMeetupCRAttrProposedLocation];
            }
            
            
            
            [meetingChangeRequests addObject:changeRequest];
            if (!ChangeRequestCreated){
                ChangeRequestCreated = YES;
            }
            meeting.status = constants.SCHappointmentStatusPending;
            meeting.changeRequests = meetingChangeRequests;
            [appDelegate.backgroundCommit.objectsStagedForSave addObject:meeting];
            [appDelegate.backgroundCommit.objectsStagedForPinning addObject:meeting];

            
        }
        
    }
    
    if (ChangeRequestCreated){
        if (appDelegate.serverReachable){
            success = [SCHUtility commit];
        }
        
        if (success){
            [self createNotificationForMeeting:meeting
                              NotificationType:kMeetingChangeProposalNotification
                                      fromUser:requester
                                        toUser:meeting.organizer];
        }

        
    }
    
    
    return success;
}

+(NSDictionary *)changeMeetingByOrganizer:(SCHMeeting *) meeting changedStartTime:(NSDate *) changedStartTime changedEndTime:(NSDate *) changedEndTime changedLocation:(NSString *) changedLocation{
    [meeting fetch];
    [meeting pin];
    

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate *inputStartTime;
    NSDate *inputEndTime;
        if (changedStartTime){
            inputStartTime = [SCHUtility startOrEndTime:changedStartTime];
            inputEndTime= [SCHUtility startOrEndTime:changedEndTime];
        }
        
        [appDelegate.backgroundCommit refreshQueues];
        [appDelegate.backgroundCommit refrshStagedQueue];
        
        nonUsetTextList = [[NSMutableArray alloc] init];
        nonUserEmailList = [[NSMutableArray alloc] init];
        userNotificationList = [[NSMutableArray alloc] init];
    BOOL success = YES;
    SCHConstants *constants = [SCHConstants  sharedManager];
    
    if (changedStartTime){
        meeting.startTime = inputStartTime;
        meeting.endTime = inputEndTime;
    }
    
    if (changedLocation){
        meeting.location = changedLocation;
    }
    
    NSMutableArray *meetingInvites = [[NSMutableArray alloc] init];
    for (NSDictionary *invitee in meeting.invites){
        
        
        NSDictionary *changedInvitee = nil;
        
        if ([[invitee valueForKey:SCHMeetupInviteeConfirmation] isEqualToString:SCHMeetupDeclined]){
            changedInvitee = invitee;
            
        }else{
            if ([[invitee valueForKey:SCHMeetupInviteeUser] isKindOfClass:[SCHUser class]]){
                [userNotificationList addObject:[invitee valueForKey:SCHMeetupInviteeUser]];
                changedInvitee = [self createInvitesWith:[invitee valueForKey:SCHMeetupInviteeUser]
                                                    name:[invitee valueForKey:SCHMeetupInviteeName]
                                               accepance:SCHMeetupNotConfirmed];;
            } else{
                SCHNonUserClient *nonUser = [invitee valueForKey:SCHMeetupInviteeUser];
                NSDictionary *nonUserReceipient = [self createNonUserReceipient:nonUser.phoneNumber email:nonUser.email name:[invitee valueForKey:SCHMeetupInviteeName]];
                
                if (nonUser.email.length){
                    [nonUserEmailList addObject:nonUserReceipient];
                
                }
                if (nonUser.phoneNumber.length > 0){
                    [nonUsetTextList addObject:nonUserReceipient];
                }
                
                changedInvitee = [self createInvitesWith:[invitee valueForKey:SCHMeetupInviteeUser]
                                                    name:[invitee valueForKey:SCHMeetupInviteeName]
                                               accepance:SCHMeetupConfirmed];
            }
            
        }

        
        [meetingInvites addObject:changedInvitee];
        
    }
    
    meeting.invites = meetingInvites;
    if ([SCHUtility pendingMeetupStatus:meeting.invites]> 0){
        meeting.status = constants.SCHappointmentStatusPending;
    }
    //remve all proposal that are chage location or time type
    
    if (meeting.changeRequests.count > 0){
        NSMutableArray *changeProposals = [[NSMutableArray alloc] initWithArray:meeting.changeRequests];
        
        
        NSPredicate *changePredicates = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *changeRequest, NSDictionary<NSString *,id> * _Nullable bindings) {
            

            if ([[changeRequest valueForKey:SCHMeetupCRAttrType] isEqualToString:SCHMeetupCRTypeChangeLocationOrTime]){
                return YES;
            } else{
                return NO;
            }
            
        }];

        
        
        
        NSArray *existingChanges = [meeting.changeRequests filteredArrayUsingPredicate:changePredicates];
        if (existingChanges.count > 0){
            [changeProposals removeObjectsInArray:existingChanges];
            meeting.changeRequests = changeProposals;
        }
    }
    
    [appDelegate.backgroundCommit.objectsStagedForSave addObject:meeting];
    [appDelegate.backgroundCommit.objectsStagedForPinning addObject:meeting];
    
    if (success){
        success = [self removeOldNotifications:meeting.objectId user:nil];
    }
    
    if (appDelegate.serverReachable){
        success = [SCHUtility commit];
    }
    
    if (success){
        if (userNotificationList.count > 0){
            for (SCHUser *user in userNotificationList){
                [self createNotificationForMeeting:meeting
                                  NotificationType:kMeetingChangeNotification
                                          fromUser:meeting.organizer
                                            toUser:user];
            }
            
            
        }
        NSDictionary *output = @{@"meeting" : meeting,
                                 @"nonUsetTextList" : nonUsetTextList,
                                 @"nonUserEmailList" : nonUserEmailList};
        return output;
        
        
    }else{
        return nil;
    }
    
}

+(NSDictionary *)acceptChangeProposal:(SCHMeeting *) meeting proposal:(NSDictionary *) proposal{
    NSString *proposaltype = [proposal valueForKey:SCHMeetupCRAttrType];
    NSDictionary *output =nil;
    
    if ([proposaltype isEqualToString:SCHMeetupCRTypeAddInvitee]){
        output = [self addInvities:@[[proposal valueForKey:SCHMeetupCRAttrNewInvitee]] toMeeting:meeting];
    } else if ([proposaltype isEqualToString:SCHMeetupCRTypeChangeLocationOrTime]){
        output = [self changeMeetingByOrganizer:meeting
                               changedStartTime:[proposal valueForKey:SCHMeetupCRAttrProposedStartTime]
                                 changedEndTime:[proposal valueForKey:SCHMeetupCRAttrProposedEndTime]
                                changedLocation:[proposal valueForKey:SCHMeetupCRAttrProposedLocation]];
        
    }
    
    if (output){
        NSMutableArray *changeRequests = [[NSMutableArray alloc] initWithArray:meeting.changeRequests];
        if ([changeRequests containsObject:proposal]){
            [changeRequests removeObject:proposal];
            meeting.changeRequests = changeRequests;
            [meeting save];
            
        }
        
        
        
    }
    
    return output;
}

+(BOOL)declineChangerequest:(SCHMeeting *)meeting proposal:(NSDictionary *) proposal{
    
    BOOL success = YES;
    NSMutableArray *changeRequests = [[NSMutableArray alloc] initWithArray:meeting.changeRequests];
    if ([changeRequests containsObject:proposal]){
        [changeRequests removeObject:proposal];
        meeting.changeRequests = changeRequests;
        success =[meeting save];
    }
    return success;
}



#pragma mark - Helpers


+(BOOL)addInvities:(NSArray *)invities toMeeting:(SCHMeeting *) meeting save:(BOOL) save{
    BOOL success = YES;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (save){
        [appDelegate.backgroundCommit refreshQueues];
        [appDelegate.backgroundCommit refrshStagedQueue];
    }
    NSMutableArray *meetingInvites = [[NSMutableArray alloc] init];
    NSMutableArray *meetingattendees = [[NSMutableArray alloc] init];
    NSMutableArray *meetingCRs = [[NSMutableArray alloc] init];
    nonUserEmailList = [[NSMutableArray alloc] init];
    nonUsetTextList = [[NSMutableArray alloc] init];
    userNotificationList = [[NSMutableArray alloc] init];
    
    if (meeting.invites.count > 0){
        [meetingInvites addObjectsFromArray:meeting.invites];
    }
    
    if (meeting.attendees.count > 0){
        [meetingattendees addObjectsFromArray:meeting.attendees];
    } else{
        [meetingattendees addObject:meeting.organizer];
    }
    if (meeting.changeRequests.count > 0){
        [meetingCRs addObjectsFromArray:meeting.changeRequests];
    }
    
    if (invities.count > 0){
        for (NSDictionary *invitee in invities){
            BOOL duplicate = NO;
            NSString *name = [invitee valueForKey:@"name"];
            NSString *phoneNumber = [invitee valueForKey:@"phone"];
            NSString *email = [invitee valueForKey:@"email"];
            
            
            /*
            NSArray *users= [SCHUtility getClientWithName:name
                                                    email:email
                                              phoneNumber:phoneNumber];
             */
            
            NSDictionary *cloudFunctionDict = nil;
            
            
            if (phoneNumber.length > 0 && email.length > 0){
                cloudFunctionDict = @{@"email": email, @"phoneNumber" : phoneNumber};
            } else if (email.length > 0 && phoneNumber.length == 0){
                cloudFunctionDict = @{@"email": email, @"phoneNumber" : @""};
            } else if (email.length == 0 && phoneNumber.length > 0){
                cloudFunctionDict = @{@"email": @"", @"phoneNumber" : phoneNumber};
            }
            NSError *error = nil;
            NSDictionary *output = [PFCloud callFunction:@"NonUserDetails" withParameters:cloudFunctionDict error:&error];
            
            if (!error){
  
                NSString *objectType = [output valueForKey:@"Type"];
                NSString *objectId = [output valueForKey:@"ObjectID"];
                PFQuery *objectQuery = nil;
                if ([objectType isEqualToString:@"User"]){
                    objectQuery = [SCHUser query];
                } else{
                    objectQuery = [SCHNonUserClient query];
                }
                
                id user = [objectQuery getObjectWithId:objectId];
                [user pin];
                
                
                //check if user is already in invitee list
                if (meetingInvites.count >0){
                    NSPredicate *duplicatePredicate = [NSPredicate predicateWithFormat:@"user = %@", user];
                    NSArray *duplicates = [meetingInvites filteredArrayUsingPredicate:duplicatePredicate];
                    if (duplicates.count >0){
                        //check if declined
                        NSDictionary *dupInvitee = (NSDictionary *)duplicates[0];
                        if ([[dupInvitee valueForKey:SCHMeetupInviteeConfirmation] isEqualToString:SCHMeetupDeclined]){
                            [meetingInvites removeObject:dupInvitee];
                        }else{
                            duplicate = YES;
                        }
                        
                    }
                    
                }
                
                if (!duplicate){
                    if ([user isKindOfClass:[SCHNonUserClient class]]){
                        
                        NSDictionary *MeetingInvitee = [self createInvitesWith:user name:name accepance:SCHMeetupConfirmed];
                        [meetingattendees addObject:user];
                        [meetingInvites addObject:MeetingInvitee];
                        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:user];
                        
                        NSDictionary *recepient = [self createNonUserReceipient:phoneNumber email:email name:name];
                        if (phoneNumber.length > 0){
                            [nonUsetTextList addObject:recepient];
                        }
                        if (email.length > 0){
                            [nonUserEmailList addObject:recepient];
                        }
                        
                        
                        
                    }else{
                        NSDictionary *MeetingInvitee = [self createInvitesWith:user name:name accepance:SCHMeetupNotConfirmed];
                        [meetingattendees addObject:user];
                        [meetingInvites addObject:MeetingInvitee];
                        [userNotificationList addObject:user];
                        [appDelegate.backgroundCommit.objectsStagedForPinning addObject:user];
                    }
                    
                    //Reomve duplicate CRS
                    if (meeting.changeRequests.count> 0){
                        NSPredicate *duplicateCRsPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *CR, NSDictionary<NSString *,id> * _Nullable bindings) {
                            if ([[CR valueForKey:SCHMeetupCRAttrType] isEqualToString:SCHMeetupCRTypeAddInvitee]){
                                NSDictionary *CRinvitee = [CR valueForKey:SCHMeetupCRAttrNewInvitee];
                                if ([[CRinvitee valueForKey:@"phone"] isEqualToString:phoneNumber]){
                                    return YES;
                                } else{
                                    return NO;
                                }
                                
                                
                                
                            }else {
                                return NO;
                            }
                        }];
                        
                        NSArray *duplicateCRs = [meetingCRs filteredArrayUsingPredicate:duplicateCRsPredicate];
                        
                        if (duplicateCRs.count > 0){
                            [meetingCRs removeObjectsInArray:duplicateCRs];
                        }
                    }
                }

                
            }
        
        }
        
    }

    if (meetingInvites.count > 0){
        meeting.invites = meetingInvites;
        meeting.attendees = meetingattendees;
        meeting.changeRequests = meetingCRs;
        
    }
    
    if (save){
        // change status
        
        // save
        
        //send notification
    }
    
    return success;
    
}

+(BOOL)removeInvities:(NSArray *) invites fromMeeting:(SCHMeeting *) meeting save:(BOOL) save{
    BOOL success = YES;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (save){
        [appDelegate.backgroundCommit refreshQueues];
        [appDelegate.backgroundCommit refrshStagedQueue];
    }
    SCHConstants *constants = [SCHConstants sharedManager];
    NSMutableArray *meetingInvites = [[NSMutableArray alloc] initWithArray:meeting.invites];
    NSMutableArray *meetingAttendees = [[NSMutableArray alloc] initWithArray:meeting.attendees];
    NSMutableArray *meetingCRs = [[NSMutableArray alloc] init];
    nonUserEmailList = [[NSMutableArray alloc] init];
    nonUsetTextList = [[NSMutableArray alloc] init];
    userNotificationList = [[NSMutableArray alloc] init];
    
    if (meeting.changeRequests.count > 0){
        [meetingCRs addObjectsFromArray:meeting.changeRequests];
    }
    
    if (invites.count > 0){

        for (id invitee in invites){
            NSPredicate *inviteePredicate = [NSPredicate predicateWithFormat:@" user = %@", [invitee valueForKey:SCHMeetupInviteeUser]];
            NSArray *inviteDicts = [meetingInvites filteredArrayUsingPredicate:inviteePredicate];
            if (inviteDicts.count > 0){
                [meetingInvites removeObjectsInArray:inviteDicts];
                for (NSDictionary *inviteeDict in inviteDicts){
                    
                    
                    if ([[inviteeDict valueForKey:SCHMeetupInviteeUser] isKindOfClass:[SCHUser class]]){
                        
                        if (![[inviteeDict valueForKey:SCHMeetupInviteeConfirmation] isEqualToString:SCHMeetupDeclined]){
                            [userNotificationList addObject:[inviteeDict valueForKey:SCHMeetupInviteeUser]];
                            [meetingAttendees removeObject:[inviteeDict valueForKey:SCHMeetupInviteeUser]];
                        }
                        // remove existing CRs
                        if (meeting.changeRequests.count > 0){
                            
                            NSPredicate *CROfUserPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *CR, NSDictionary<NSString *,id> * _Nullable bindings) {
                                if ([[CR valueForKey:SCHMeetupCRAttrRequester] isEqual:[inviteeDict valueForKey:SCHMeetupInviteeUser]]){
                                    return YES;
                                } else{
                                    return NO;
                                }
                            }];
                            
                            NSArray *CRsOfUser = [meetingCRs filteredArrayUsingPredicate:CROfUserPredicate];
                            if (CRsOfUser.count > 0){
                                [meetingCRs removeObjectsInArray:CRsOfUser];
                            }
                        }
                        
                    } else{
                        SCHNonUserClient *nonUser = [invitee valueForKey:SCHMeetupInviteeUser];
                        NSDictionary *receipient = [self createNonUserReceipient:nonUser.phoneNumber email:nonUser.email name:[invitee valueForKey:SCHMeetupInviteeName]];
                        if (nonUser.phoneNumber.length > 0){
                            [nonUsetTextList addObject:receipient];
                        }
                        if (nonUser.email.length > 0){
                            [nonUserEmailList addObject:receipient];
                        }
                        
                    
                         [meetingAttendees removeObject:nonUser];
                    }
                }
            }
        }
        meeting.attendees = meetingAttendees;
        meeting.invites  =meetingInvites;
        meeting.changeRequests = meetingCRs;
        
        if ([SCHUtility nonDeclinedMeetupStatus:meeting.invites] == 0){
            meeting.status = constants.SCHappointmentStatusCancelled;
        } else{
            // get number of accepted invites
            int pendingInvites = (int)[SCHUtility pendingMeetupStatus:meeting.invites];
            if (pendingInvites > 0){
                meeting.status = constants.SCHappointmentStatusPending;
            } else{
                meeting.status = constants.SCHappointmentStatusConfirmed;
            }
        }
        
        
        [appDelegate.backgroundCommit.objectsStagedForSave addObject:meeting];
        
    } else{
        success = NO;
    }
    
    if (success){
        if ([meeting.status isEqual:constants.SCHappointmentStatusCancelled]){
            success = [self removeOldNotifications:meeting.objectId user:nil];
        } else{
            if (userNotificationList.count > 0){
                for (SCHUser *user in userNotificationList){
                    success = [self removeOldNotifications:meeting.objectId user:user];
                    if (!success){
                        break;
                    }
                }
                
            }

            
        }
        
        
        
        
    }
    
    
    
    if (success && save) {
        
        success = [SCHUtility commit];
        
        if (success){
            if (userNotificationList.count > 0){
                for (SCHUser *user in userNotificationList){
                    [self createNotificationForMeeting:meeting
                                      NotificationType:kMeetingRemoveInviteeNotification
                                              fromUser:meeting.organizer
                                                toUser:user];
                }
                
            }
        }
    }
    
    
    
    
    
    return success;
}

+(void)createNotificationForMeeting:(SCHMeeting *) meeting NotificationType:(NSString *) notificationType fromUser:(SCHUser *) fromUser toUser:(SCHUser *) toUser {
    
    SCHConstants *constants = [SCHConstants sharedManager];
    
    
    
    
    
    NSString *referenceObject = meeting.objectId;
    NSString *referenceObjectType = SCHMeetingClass;
    NSString *notificationTitle = nil;
    NSString *message = nil;
    
    
    
    // Notification
    if ([notificationType isEqual:kNewMeetingNotification ]) {
        notificationTitle = [NSString stringWithFormat:@"%@ invites you to Meet-up", fromUser.preferredName];
        message = [NSString localizedStringWithFormat:@"%@ at %@", meeting.subject, meeting.location];
        
        
        SCHNotification *notification = [SCHUtility createNotificationForUser:toUser
                                                             notificationType:constants.SCHNotificationForResponse
                                                            notificationTitle:notificationTitle
                                                                      message:message
                                                              referenceObject:referenceObject
                                                          referenceObjectType:referenceObjectType];
        
        [notification save];
        [SCHUtility sendNotification:notification];
        
    } else if ([notificationType isEqual:kMeetingAcceptanceNotification]) {
        notificationTitle = [NSString stringWithFormat:@"%@ accepted Meet-up", fromUser.preferredName];
        message = [NSString localizedStringWithFormat:@"%@ at %@", meeting.subject, meeting.location];
        
        
        SCHNotification *notification = [SCHUtility createNotificationForUser:toUser
                                                             notificationType:constants.SCHNotificationForAcknowledgement
                                                            notificationTitle:notificationTitle
                                                                      message:message
                                                              referenceObject:referenceObject
                                                          referenceObjectType:referenceObjectType];
        
        [notification save];
        [SCHUtility sendNotification:notification];
    } else if ([notificationType isEqual:kMeetingDeclineNotification]) {
        
        notificationTitle = [NSString stringWithFormat:@"%@ declined Meet-up", fromUser.preferredName];
        message = [NSString localizedStringWithFormat:@"%@ at %@", meeting.subject, meeting.location];
        
        
        SCHNotification *notification = [SCHUtility createNotificationForUser:toUser
                                                             notificationType:constants.SCHNotificationForAcknowledgement
                                                            notificationTitle:notificationTitle
                                                                      message:message
                                                              referenceObject:referenceObject
                                                          referenceObjectType:referenceObjectType];
        
        [notification save];
        [SCHUtility sendNotification:notification];
    }else if ([notificationType isEqual:kMeetingRemoveInviteeNotification]) {
        
        notificationTitle = [NSString stringWithFormat:@"%@ removed you from Meet-up invites list", fromUser.preferredName];
        message = [NSString localizedStringWithFormat:@"%@ at %@", meeting.subject, meeting.location];
        
        
        SCHNotification *notification = [SCHUtility createNotificationForUser:toUser
                                                             notificationType:constants.SCHNotificationForAcknowledgement
                                                            notificationTitle:notificationTitle
                                                                      message:message
                                                              referenceObject:nil
                                                          referenceObjectType:nil];
        
        [notification save];
        [SCHUtility sendNotification:notification];
    }else if ([notificationType isEqual:kMeetingCancellationNotification]) {
        notificationTitle = [NSString stringWithFormat:@"%@ cancelled Meet-up", fromUser.preferredName];
        message = [NSString localizedStringWithFormat:@"%@ at %@", meeting.subject, meeting.location];
        
        
        SCHNotification *notification = [SCHUtility createNotificationForUser:toUser
                                                             notificationType:constants.SCHNotificationForAcknowledgement
                                                            notificationTitle:notificationTitle
                                                                      message:message
                                                              referenceObject:referenceObject
                                                          referenceObjectType:referenceObjectType];
        
        [notification save];
        [SCHUtility sendNotification:notification];
    } else if ([notificationType isEqual:kMeetingChangeProposalNotification]) {
        notificationTitle = [NSString stringWithFormat:@"%@ proposed Meet-up change", fromUser.preferredName];
        message = [NSString localizedStringWithFormat:@"%@ at %@", meeting.subject, meeting.location];
        
        
        SCHNotification *notification = [SCHUtility createNotificationForUser:toUser
                                                             notificationType:constants.SCHNotificationForAcknowledgement
                                                            notificationTitle:notificationTitle
                                                                      message:message
                                                              referenceObject:referenceObject
                                                          referenceObjectType:referenceObjectType];
        
        [notification save];
        [SCHUtility sendNotification:notification];
        
    } else if ([notificationType isEqual:kMeetingChangeNotification]){
        notificationTitle = [NSString stringWithFormat:@"%@ changed Meet-up", fromUser.preferredName];
        message = [NSString localizedStringWithFormat:@"%@ at %@", meeting.subject, meeting.location];
        
        
        SCHNotification *notification = [SCHUtility createNotificationForUser:toUser
                                                             notificationType:constants.SCHNotificationForResponse
                                                            notificationTitle:notificationTitle
                                                                      message:message
                                                              referenceObject:referenceObject
                                                          referenceObjectType:referenceObjectType];
        
        [notification save];
        [SCHUtility sendNotification:notification];
    }
    
    
}

+(BOOL) removeOldNotifications:(NSString *)refreenceObjectId user:(SCHUser *) user{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSError *error = nil;
    NSPredicate *notificationPredicate = nil;
    if (user){
        notificationPredicate = [NSPredicate predicateWithFormat:@"referenceObject = %@ AND user = %@", refreenceObjectId, user];
    } else{
        notificationPredicate = [NSPredicate predicateWithFormat:@"referenceObject = %@", refreenceObjectId];
    }
    
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

+(NSDictionary *) createInvitesWith:(id) user name:(NSString *) name accepance:(NSString *) acceptance{
    
    return @{SCHMeetupInviteeUser :user,
             SCHMeetupInviteeName :name,
             SCHMeetupInviteeConfirmation: acceptance};
    
    
}

+(NSDictionary *)createNonUserReceipient:(NSString *) phoneNumber email:(NSString *) email name:(NSString *) name{
    NSMutableDictionary *receiient = [[NSMutableDictionary alloc] init];
    if (email.length > 0){
        [receiient setObject:email forKey:SCHMeetupInviteeEmail];
    }
    if (phoneNumber.length > 0){
        [receiient setObject:phoneNumber forKey:SCHMeetupInviteePhoneNumber];
    }
    if (name.length > 0){
        [receiient setObject:name forKey:SCHMeetupInviteeName];
    }
    
    return receiient;
}



+(NSString *) textMessage:(SCHMeeting *) meeting messageType:(NSString *)messageType{
    NSMutableString *messageBody = [[NSMutableString  alloc] init];
    NSString *title = nil;
    if ([messageType isEqualToString:kNewMeetingNotification]){
        title = [NSString localizedStringWithFormat:@"%@ invites you to %@", meeting.organizer.preferredName, meeting.subject];
        
    } else if ([messageType isEqualToString:kMeetingCancellationNotification]){
        title = [NSString localizedStringWithFormat:@"%@ cancelled %@", meeting.organizer.preferredName, meeting.subject];
    } else if ([messageType isEqualToString:kMeetingRemoveInviteeNotification]){
        title = [NSString localizedStringWithFormat:@"%@ removed you from invites list of %@", meeting.organizer.preferredName, meeting.subject];
    } else if ([messageType isEqualToString:kMeetingChangeNotification]){
        title = [NSString localizedStringWithFormat:@"%@ changed %@", meeting.organizer.preferredName, meeting.subject];
    }

    [messageBody appendString:title];
    
    [messageBody appendString:@"\n"];
    [messageBody appendString:@"\n"];
    //Add time
    // Get Date and Time
    
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
    NSString *appointmentDay = [dayformatter stringFromDate:meeting.startTime];
    // NSDateFormatter *fromTimeFormatter = [SCHUtility dateFormatterForFromTime];
    NSDateFormatter *toTimeFormatter = [SCHUtility dateFormatterForToTime];
    NSString *endTimeDateString = [SCHUtility getEndDate:meeting.endTime comparingStartDate:meeting.startTime];
    
    NSString *appointmentTime = nil;
    
    if (endTimeDateString.length > 0){
        appointmentTime = [NSString stringWithFormat:@"from %@ to %@ %@", [toTimeFormatter stringFromDate:meeting.startTime], [toTimeFormatter stringFromDate:meeting.endTime], endTimeDateString];
    } else{
        appointmentTime = [NSString stringWithFormat:@"from %@ to %@", [toTimeFormatter stringFromDate:meeting.startTime], [toTimeFormatter stringFromDate:meeting.endTime]];
    }
    [messageBody appendString:appointmentTime];
    [messageBody appendString:@"\n"];
    [messageBody appendString:[NSString stringWithFormat:@"On %@", appointmentDay]];
        
        
    [messageBody appendString:@"\n"];
    [messageBody appendString:@"\n"];
    
    //Add location
    
    [messageBody appendString:@"At"];
    [messageBody appendString:@"\n"];
    [messageBody appendString:meeting.location];
    
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

+(void) sendTextMessage:(SCHMeeting *) meeting textList:(NSArray *) textList messageType:(NSString *) messageType{
    
    if (textList.count > 0){
        int numberOfInvitees = (int)textList.count ;
        int counter = 0;
        //build phone numbers and names
        NSMutableArray *textNumbers = [[NSMutableArray alloc] init];
        NSMutableString *textNames = [[NSMutableString alloc] init];
        for (NSDictionary *textInvitee in textList){
            counter = counter +1;
            [textNumbers addObject:[textInvitee valueForKey:SCHMeetupInviteePhoneNumber]];
            if (numberOfInvitees == 1){
                [textNames appendString:[textInvitee valueForKey:SCHMeetupInviteeName]];
            } else{
                if ((numberOfInvitees -counter) == 1){
                    [textNames appendString:[NSString localizedStringWithFormat:@"%@ and ", [textInvitee valueForKey:SCHMeetupInviteeName]]];
                    
                } else if (numberOfInvitees == counter){
                    [textNames appendString:[textInvitee valueForKey:SCHMeetupInviteeName]];
                } else{
                    [textNames appendString:[NSString localizedStringWithFormat:@"%@, ", [textInvitee valueForKey:SCHMeetupInviteeName]]];
                }
            }
            
        }
        
        
        NSString *message = [SCHMeetingManager textMessage:meeting messageType:messageType];
        SCHEmailAndTextMessage *emailAndTextMessage = [SCHEmailAndTextMessage sharedManager];
        
        
        emailAndTextMessage.textAlertPhoneNumbers = textNumbers;
        emailAndTextMessage.textAlertMessage = message;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *alertMessage;
            NSString *alertTitle;
            if (textList.count == 1) {
                alertTitle = @"Notify Invitee";
                alertMessage = [NSString localizedStringWithFormat:@"%@ is not a user of CounterBean", textNames];
                
            } else{
                alertTitle = @"Notify Invitees";
                alertMessage = [NSString localizedStringWithFormat:@"%@ are not users of CounterBean", textNames];
            }
            
            emailAndTextMessage.textAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:emailAndTextMessage cancelButtonTitle:@"Cancel" otherButtonTitles:@"Text", nil];
            [emailAndTextMessage.textAlert show];
            
        });
        
    }
    
}

+(void) sendEmail:(SCHMeeting *) meeting emailList:(NSArray *) emailList  messageType:(NSString *) messageType{
    if (emailList.count > 0){
        int numberOfInvitees = (int)emailList.count;
        int counter = 0;
        NSMutableArray *emails = [[NSMutableArray alloc] init];
        NSMutableString *emailNames = [[NSMutableString alloc] init];
        for (NSDictionary *emailInvitee in emailList){
            counter = counter +1;
            [emails addObject:[emailInvitee objectForKey:SCHMeetupInviteeEmail]];
            if (numberOfInvitees == 1){
                [emailNames appendString:[emailInvitee valueForKey:SCHMeetupInviteeName]];
            } else{
                if ((numberOfInvitees -counter) == 1){
                    [emailNames appendString:[NSString localizedStringWithFormat:@"%@ and ", [emailInvitee valueForKey:SCHMeetupInviteeName]]];
                    
                } else if (numberOfInvitees == counter){
                    [emailNames appendString:[emailInvitee valueForKey:SCHMeetupInviteeName]];
                } else{
                    [emailNames appendString:[NSString localizedStringWithFormat:@"%@, ", [emailNames valueForKey:SCHMeetupInviteeName]]];
                }
            }
        }
        
        NSString *emailSubject = [self emailSubjectForMeeting:meeting messageType:messageType];
        NSString *message = [SCHMeetingManager textMessage:meeting messageType:messageType];
        SCHEmailAndTextMessage *emailMessage = [SCHEmailAndTextMessage sharedManager];
        
        emailMessage.emailSubject = emailSubject;
        emailMessage.emailAlertMessage = message;
        emailMessage.emailAlertaddresses =emails;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *alertMessage;
            NSString *alertTitle;
            if (emailList.count == 1) {
                alertTitle = @"Email Invitee";
                alertMessage = [NSString localizedStringWithFormat:@"%@ is not a user of CounterBean", emailNames];
                
            } else{
                alertTitle = @"Email Invitees";
                alertMessage = [NSString localizedStringWithFormat:@"%@ are not users of CounterBean", emailNames];
            }
            
            emailMessage.emailAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:emailMessage cancelButtonTitle:@"Cancel" otherButtonTitles:@"Email", nil];
            [emailMessage.emailAlert show];
            
        });

    }
    
}

+(void) sendEmailAndText:(SCHMeeting *) meeting emailList:(NSArray *) emailList  textList:(NSArray *) textList messageType:(NSString *) messageType{
    NSMutableArray *nonUserInvities = [[NSMutableArray alloc] init];
    [nonUserInvities addObjectsFromArray:emailList];
    [nonUserInvities addObjectsFromArray:textList];
    if (nonUserInvities.count > 0){
        
        NSMutableArray *emails = [[NSMutableArray alloc] init];
        NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
        NSMutableString *names = [[NSMutableString alloc] init];
        NSMutableSet *nameSet = [[NSMutableSet alloc] init];
        for (NSDictionary *nonUserInvitee in nonUserInvities){
            [nameSet addObject:[nonUserInvitee valueForKey:SCHMeetupInviteeName]];
        }
        int numberOfInvitees = (int)nameSet.count;
        int counter = 0;
        for (NSString *name in nameSet){
            counter = counter +1;
            if (numberOfInvitees == 1){
                [names appendString:name];
            } else{
                if ((numberOfInvitees -counter) == 1){
                    [names appendString:[NSString localizedStringWithFormat:@"%@ and ", name]];
                    
                } else if (numberOfInvitees == counter){
                    [names appendString:name];
                } else{
                    [names appendString:[NSString localizedStringWithFormat:@"%@, ", name]];
                }
            }
            
        }
        
        for (NSDictionary *invitee in emailList){

            [emails addObject:[invitee objectForKey:SCHMeetupInviteeEmail]];
            
        }
        for (NSDictionary *textInvitee in textList){

            [phoneNumbers addObject:[textInvitee valueForKey:SCHMeetupInviteePhoneNumber]];
        }
        
        NSString *emailSubject = [self emailSubjectForMeeting:meeting messageType:messageType];
        NSString *emailMessage = [SCHMeetingManager textMessage:meeting messageType:messageType];
        NSString *textMessage = [SCHMeetingManager textMessage:meeting messageType:messageType];
        SCHEmailAndTextMessage *emailAndTextMessage = [SCHEmailAndTextMessage sharedManager];
        
        emailAndTextMessage.emailSubject = emailSubject;
        emailAndTextMessage.emailAlertMessage = emailMessage;
        emailAndTextMessage.emailAlertaddresses = emails;
        emailAndTextMessage.textAlertMessage = textMessage;
        emailAndTextMessage.textAlertPhoneNumbers =phoneNumbers;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *alertMessage;
            NSString *alertTitle;
            if (nameSet.count == 1) {
                alertTitle = @"Notify Invitee";
                alertMessage = [NSString localizedStringWithFormat:@"%@ is not a user of CounterBean. Notify by email and text?", names ];
                
            } else{
                alertTitle = @"Notify Invitees";
                alertMessage = [NSString localizedStringWithFormat:@"%@ are not users of CounterBean. Notify by email and text?", names];
            }
            
            emailAndTextMessage.emailAndTextAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:emailAndTextMessage cancelButtonTitle:@"Cancel" otherButtonTitles:@"Notify", nil];
            [emailAndTextMessage.emailAndTextAlert show];
        
        
        });
    }
    
    
    
    
}




+(NSString *) emailSubjectForMeeting:(SCHMeeting *) meeting messageType:(NSString *)messageType{
    NSString *title = nil;
    if ([messageType isEqualToString:kNewMeetingNotification]){
        title = [NSString localizedStringWithFormat:@"%@ invites you to %@", meeting.organizer.preferredName, meeting.subject];
        
    } else if ([messageType isEqualToString:kMeetingCancellationNotification]){
        title = [NSString localizedStringWithFormat:@"%@ cancelled %@", meeting.organizer.preferredName, meeting.subject];
    } else if ([messageType isEqualToString:kMeetingRemoveInviteeNotification]){
        title = [NSString localizedStringWithFormat:@"%@ removed you from invites list of %@", meeting.organizer.preferredName, meeting.subject];
    } else if ([messageType isEqualToString:kMeetingChangeNotification]){
        title = [NSString localizedStringWithFormat:@"%@ changed %@", meeting.organizer.preferredName, meeting.subject];
    }
    return title;
    
    
}


@end
