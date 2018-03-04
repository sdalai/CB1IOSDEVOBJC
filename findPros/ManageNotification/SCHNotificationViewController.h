//
//  SCHNotificationViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 6/29/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "SCHScheduledEventManager.h"
#import "SCHBackgroundManager.h"
#import "SCHUtility.h"
#import "SCHEvent.h"
#import "SCHScheduleSummeryViewController.h"
#import "SCHObjectsForProcessing.h"
#import "SCHMeeting.h"
#import "SCHMeetingManager.h"
@interface SCHNotificationViewController : UITableViewController
@property (strong, nonatomic) SCHScheduledEventManager *eventManager;
@property (nonatomic, strong) NSDateFormatter *scheduleHeaderFormatter;
@property (nonatomic, strong) NSDateFormatter *scheduleTimeFormatter;
@property (nonatomic, strong) SCHConstants *constants;
@property (nonatomic, strong) NSMutableArray *NotificationArray;
@property (nonatomic, strong) SCHObjectsForProcessing *objectsForProcessing;
@property CGFloat rowheight;
-(void) refreshNotificationScreen;
@end
