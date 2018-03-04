//
//  SCHMeetingManager.h
//  CounterBean
//
//  Created by Sujit Dalai on 6/19/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCHMeeting.h"
#import "SCHUser.h"


static NSString * const kNewMeetingNotification = @"NewMeetingNotification";
static NSString * const kMeetingAcceptanceNotification = @"MeetingAcceptanceNotification";
static NSString * const kMeetingDeclineNotification = @"MeetingDeclineNotification";
static NSString * const kMeetingCancellationNotification = @"MeetingCancellationNotification";
static NSString * const kMeetingChangeProposalNotification = @"MeetingChangeProposalNotification";
static NSString * const kMeetingChangeNotification = @"MeetingChangeNotification";
static NSString * const kMeetingRemoveInviteeNotification = @"MeetingRemoveInviteeNotification";

@interface SCHMeetingManager : NSObject

+(NSDictionary *)createMeetingWithSubject:(NSString *) subject organizer:(SCHUser *) organizaer location:(NSString *)  location startTime:(NSDate *) startTime endTime:(NSDate *) endtime invites:(NSArray *) invites note:(NSString *) note;

+(NSDictionary *)addInvities:(NSArray *)invities toMeeting:(SCHMeeting *) meeting;
+(NSDictionary *)removeInvities:(NSArray *) invites fromMeeting:(SCHMeeting *) meeting;
+(NSDictionary *) createInvitesWith:(id) user name:(NSString *) name accepance:(NSString *) acceptance;
+(BOOL)acceptMeeting:(SCHMeeting *) meeting;
+(BOOL)declineMeeting:(SCHMeeting *) meeting;
+(NSDictionary *)cancelMeeting:(SCHMeeting *) meeting;

+(NSDictionary *)changeMeetingByOrganizer:(SCHMeeting *) meeting changedStartTime:(NSDate *) changedStartTime changedEndTime:(NSDate *) changedEndTime changedLocation:(NSString *) changedLocation;



+(BOOL)changeMeetingRequest:(SCHMeeting *) meeting requester: (SCHUser *) requester CRType:(NSString *) CRType newInvitees:(NSArray *) newInvities changedStartTime:(NSDate *) changedStartTime changedEndTime:(NSDate *) changedEndTime changedLocation:(NSString *) changedLocation;


+(NSDictionary *)acceptChangeProposal:(SCHMeeting *) meeting proposal:(NSDictionary *) proposal;

+(BOOL)declineChangerequest:(SCHMeeting *)meeting proposal:(NSDictionary *) proposal;
+(NSString *) textMessage:(SCHMeeting *) meeting messageType:(NSString *)messageType;
+(void) sendTextMessage:(SCHMeeting *) meeting textList:(NSArray *) textList messageType:(NSString *) messageType;
+(void) sendEmail:(SCHMeeting *) meeting emailList:(NSArray *) emailList  messageType:(NSString *) messageType;
+(void) sendEmailAndText:(SCHMeeting *) meeting emailList:(NSArray *) emailList  textList:(NSArray *) textList messageType:(NSString *) messageType;

@end
