//
//  SCHMeetupChangeRequestTableViewController.h
//  CounterBean
//
//  Created by Sujit Dalai on 7/4/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "SCHBackgroundManager.h"
#import "SCHUtility.h"
#import "SCHObjectsForProcessing.h"
#import "SCHMeeting.h"
#import "SCHMeetingManager.h"
#import "AppDelegate.h"
#import "SCHConstants.h"
#import "SCHScheduledEventManager.h"
#import "SCHSyncManager.h"


@interface SCHMeetupChangeRequestTableViewController : UITableViewController

@property(nonatomic, strong) SCHMeeting *meeting;
@property (strong, nonatomic) SCHScheduledEventManager *eventManager;
@property (nonatomic, strong) SCHConstants *constants;
@property (nonatomic, strong) SCHObjectsForProcessing *objectsForProcessing;
@property CGFloat rowheight;

@end
