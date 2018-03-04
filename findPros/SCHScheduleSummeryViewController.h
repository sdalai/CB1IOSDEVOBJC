//
//  SCHScheduleSummeryViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 7/21/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHConstants.h"
#import "SCHUtility.h"
#import "AppDelegate.h"
#import "SCHBackgroundManager.h"
#import "SCHObjectsForProcessing.h"
#import "SCHNonUserClient.h"
#import "SCHUser.h"
#import "SCHScheduledEventManager.h"
@interface SCHScheduleSummeryViewController : UITableViewController<UIAlertViewDelegate>
{
    UIView *footerView;
}
@property (nonatomic, strong) NSDateFormatter *scheduleTimeFormatter;
@property (nonatomic, strong) NSDateFormatter *scheduleDateFormatter;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) SCHConstants *constants;
@property (nonatomic, strong) NSArray *dataArray;
@property (nonatomic, strong) SCHEvent *event;
@property (nonatomic, strong) NSObject *recived_data;
@property CGFloat rowheight;
@property (retain,nonatomic)SCHUser *assignedToUser;
-(void)editAppointment;
-(void)initEditButton;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, strong) SCHScheduledEventManager *eventManager;
@property (nonatomic, strong) SCHObjectsForProcessing *objectsForProcessing;
@property (strong, nonatomic) IBOutlet UIView *appointmentRespondView;
@property (strong, nonatomic) IBOutlet UIButton *btnAccept;
@property (strong, nonatomic) IBOutlet UIButton *btnChange;
@property (strong, nonatomic) IBOutlet UIButton *btnDecline;

- (IBAction)AppointmentRespondAction:(id)sender;

@end
