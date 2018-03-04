//
//  SCHScheduledEventManager.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 4/25/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "SCHBackgroundManager.h"
#import "SCHScheduleScreenFilter.h"
#import "SCHUser.h"



@protocol SCHScheduledEventManagerDelegate <NSObject>

@optional

-(void) scheduledEventsRefreshed:(NSDictionary *) scheduledEvents eventDays:(NSArray *) scheduledEventDays;
-(void) notificationsRefreshed:(NSArray *) notifications;

@end



@interface SCHScheduledEventManager : NSObject


@property (strong, nonatomic) NSMutableArray *scheduledEventDays;
@property (strong, nonatomic) NSMutableDictionary *scheduledEvents;
@property (strong, nonatomic) NSMutableArray *notifications;
@property (nonatomic) BOOL scheduleEventsChanged;
@property (nonatomic) BOOL notificationChanged;

//@property (nonatomic, strong)SCHScheduleScreenFilter *filter;

@property (nonatomic, strong) id<SCHScheduledEventManagerDelegate> delegate;

+ (instancetype) sharedManager;
-(void) reset;

- (BOOL) buildScheduledEvent;
-(NSArray *)buildAvailablityCompleteRefresh:(SCHUser *) user;
-(NSArray *) getScheduledAppointments:(SCHUser *) user;
-(BOOL)notificationsForUser;





@end
