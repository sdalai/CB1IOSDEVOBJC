//
//  AppDelegate.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 4/11/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "SCHUtility.h"
#import "SCHBackendCommit.h"
#import "SCHObjectsForProcessing.h"
#import "SCHConstants.h"
#import "SCHBackgroundManager.h"
#import "SCHScheduledEventManager.h"
#import "SCHAvailabilityRefreshQueue.h"
#import "SCHScheduleTableViewController.h"
#import "SlideMenuViewController.h"
#import "MFSideMenu.h"
#import "SCHUser.h"
#import "SlideMenuViewController.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) SCHObjectsForProcessing *objectsForProcessing;
@property (nonatomic, strong) SCHConstants *constants;
@property (nonatomic, strong) SCHBackendCommit *backgroundCommit;
@property (nonatomic, strong) SCHBackgroundManager *backgroundManager;
@property (nonatomic, strong) SCHScheduledEventManager *scheduledManager;
@property (nonatomic, strong) SCHAvailabilityRefreshQueue *refreshQueue;
@property (nonatomic, assign) BOOL serviceProvider;
@property (nonatomic, assign) BOOL serviceProviderWithActiveService;
@property (nonatomic, assign) BOOL userJustLoggedIn;
@property (nonatomic, assign) BOOL userJustSignedUp;
@property (nonatomic, strong) SCHUser *user;
@property (nonatomic, assign) BOOL dataSyncFailure;



@property(strong, nonatomic) NSTimer *syncTimer;
@property(strong, nonatomic) NSTimer *phoneVerificationTimer;
@property (strong, nonatomic) UIWindow *window;
@property(strong) Reachability * serverConnectionReach;
@property (nonatomic, assign) BOOL serverReachable;
@property (nonatomic, assign) BOOL wifiReachable;

@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) SlideMenuViewController *slideMenu;


-(void)reachabilityChanged:(NSNotification*)note;
-(void) setApplicationbadgeCount:(int)badge;

@end

