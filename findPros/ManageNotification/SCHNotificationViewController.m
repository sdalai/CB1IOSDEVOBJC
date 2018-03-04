//
//  SCHNotificationViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 6/29/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHNotificationViewController.h"
#import <KVNProgress/KVNProgress.h>
#import "SCHAppointmentManager.h"
#import <QuartzCore/QuartzCore.h>
#import "SCHUtility.h"
#import "SCHSyncManager.h"
#import "SCHNotificationAcknowledgementDetailViewController.h"
#import "SCHActiveViewControllers.h"
#import "SCHScheduleTableViewController.h"
#import "SCHAlert.h"
#import "SCHMeetingManager.h"
#import "SCHMeeting.h"


@interface SCHNotificationViewController ()
@property (nonatomic, strong) SCHBackgroundManager *backgrounfManager;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
- (IBAction)CloseButtonPressed:(id)sender;

@end


@implementation SCHNotificationViewController
UIRefreshControl *refreshControl;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appdeligate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });

    
    
    SCHActiveViewControllers *activeVC = [SCHActiveViewControllers sharedManager];
    
    [activeVC.viewControllers setObject:self forKey:@"notificationVC"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCHUserLogout object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLogout)
                                                 name:SCHUserLogout
                                               object:nil];
    
    self.scheduleHeaderFormatter = [SCHUtility dateFormatterForFullDate];
    self.scheduleTimeFormatter = [SCHUtility dateFormatterForToTime];
    self.eventManager = [SCHScheduledEventManager sharedManager];
    self.constants = [SCHConstants sharedManager];
    self.NotificationArray = [[NSMutableArray alloc] initWithArray:self.eventManager.notifications];
    self.objectsForProcessing  = [SCHObjectsForProcessing sharedManager];
   // self.eventManager.delegate = self;
  
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addPullToRefresh];
    [self setupMenuBarButtonItems];
}

-(void)userLogout{
    SCHActiveViewControllers *activeVC = [SCHActiveViewControllers sharedManager];
    [activeVC.viewControllers removeObjectForKey:@"notificationVC"];
    [self dismissViewControllerAnimated:NO completion:NULL];
}


- (void)setupMenuBarButtonItems {
    if(self.menuContainerViewController.menuState == MFSideMenuStateClosed &&
       ![[self.navigationController.viewControllers objectAtIndex:0] isEqual:self]) {
        self.navigationItem.leftBarButtonItem = [self backBarButtonItem];
    } else {
        self.navigationItem.leftBarButtonItem = [self leftMenuBarButtonItem];
    }
}

- (UIBarButtonItem *)leftMenuBarButtonItem {
    return [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStylePlain
            target:self
            action:@selector(leftSideMenuButtonPressed:)];
}
- (void)leftSideMenuButtonPressed:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
        [self setupMenuBarButtonItems];
    }];
}

- (UIBarButtonItem *)backBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(backButtonPressed:)];
}
-(void)internetConnectionChanged{
    

    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appdeligate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Messages";
    [self.menuContainerViewController setPanMode:MFSideMenuPanModeNone];
    
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.menuContainerViewController setPanMode:MFSideMenuPanModeDefault];
}


-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.eventManager.notificationChanged){
        [self refreshNotificationScreen];
 
        
        
    }
    
    SCHBackgroundManager *backgoundManager = [SCHBackgroundManager sharedManager];
    dispatch_async(backgoundManager.SCHSerialQueue , ^{
        
        SCHConstants *constants = [SCHConstants sharedManager];
        NSArray *notificationdicts = [[NSArray alloc] initWithArray:self.NotificationArray];
        for (NSDictionary *notificationDict in notificationdicts){
            SCHNotification *notification = [notificationDict valueForKey:@"notification"];
            if ([notification.notificationType isEqual:constants.SCHNotificationForAcknowledgement]){
                notification.seen = YES;
                [notification saveEventually];
                [notification pin];
               
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SCHSyncManager syncBadge];
        });
    });
    
}


-(void) refreshNotificationScreen{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        [self.NotificationArray removeAllObjects];
        [self.NotificationArray addObjectsFromArray:self.eventManager.notifications];
        [self removeObjectsBeingProcessed];
        self.eventManager.notificationChanged = NO;
        [self.tableView reloadData];
        
    });
    
}



#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.NotificationArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return self.rowheight;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    NSDictionary *notificatioDict = [self.NotificationArray objectAtIndex:indexPath.row];
    SCHNotification *notification = [notificatioDict valueForKey:@"notification"];
 //   SCHAppointment *appointment = [notificatioDict valueForKey:@"referenceObject"];
    
    
    if(notification.notificationType == self.constants.SCHNotificationForResponse)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"SCHNotificationCell1" forIndexPath:indexPath];
        if(!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SCHNotificationCell1"];
        }
        UIButton *acceptButton = (UIButton*)[cell.contentView viewWithTag:2];
        UIButton *declineButton = (UIButton*)[cell.contentView viewWithTag:3];
        
        [acceptButton addTarget:self action:@selector(acceptButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [declineButton addTarget:self action:@selector(declineButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        UIFont *titlefont = [SCHUtility getPreferredTitleFont];
        UIFont *bodyFont = [SCHUtility getPreferredBodyFont];
        NSDictionary *titleAttr =
        [NSDictionary dictionaryWithObject:titlefont
                                    forKey:NSFontAttributeName];
        
        NSDictionary *bodyAttr = @{NSFontAttributeName: bodyFont,
                                   NSForegroundColorAttributeName: [UIColor grayColor]};
        
        NSAttributedString *nextLine = [[NSAttributedString alloc] initWithString:@"\n"];
        
        NSMutableAttributedString *notificationMessage = [[NSMutableAttributedString alloc] init];
        
        [notificationMessage appendAttributedString:[[NSAttributedString alloc] initWithString:notification.notificationTitle attributes:titleAttr]];
        [notificationMessage appendAttributedString:nextLine];
        
        if([notification.message length]>0){
            [notificationMessage appendAttributedString:[[NSAttributedString alloc] initWithString:notification.message attributes:bodyAttr]];
        }
        
                
        UITextView *contentTextView = (UITextView *)[cell.contentView viewWithTag:1];
        [contentTextView setAttributedText:notificationMessage];
        
   
            self.rowheight = ([SCHUtility tableViewCellHeight:contentTextView width:contentTextView.bounds.size.width] +55);
    
    
        
    }else if(notification.notificationType == self.constants.SCHNotificationForAcknowledgement)
    
    {
        //if cancled, declind
        cell = [tableView dequeueReusableCellWithIdentifier:@"SCHNotificationCell2" forIndexPath:indexPath];
        if(!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SCHNotificationCell2"];
        }
        UITextView *contentTextView = (UITextView *)[cell.contentView viewWithTag:1];
        UIFont *titlefont = [SCHUtility getPreferredTitleFont];
        UIFont *bodyFont = [SCHUtility getPreferredBodyFont];
        NSDictionary *titleAttr =
        [NSDictionary dictionaryWithObject:titlefont
                                    forKey:NSFontAttributeName];
        
        NSDictionary *bodyAttr = @{NSFontAttributeName: bodyFont,
                                   NSForegroundColorAttributeName: [UIColor grayColor]};
        
        NSAttributedString *nextLine = [[NSAttributedString alloc] initWithString:@"\n"];
        
        NSMutableAttributedString *notificationMessage = [[NSMutableAttributedString alloc] init];
        
        [notificationMessage appendAttributedString:[[NSAttributedString alloc] initWithString:notification.notificationTitle attributes:titleAttr]];
        [notificationMessage appendAttributedString:nextLine];
        
        if([notification.message length]>0){
            [notificationMessage appendAttributedString:[[NSAttributedString alloc] initWithString:notification.message attributes:bodyAttr]];
        }

        

        [contentTextView setAttributedText:notificationMessage];
        self.rowheight = ([SCHUtility tableViewCellHeight:contentTextView width:contentTextView.bounds.size.width] +10);
        

    }
    
    return cell;
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    NSDictionary *notificatioDict = [self.NotificationArray objectAtIndex:indexPath.row];
    SCHNotification *notification = [notificatioDict valueForKey:@"notification"];
    //   SCHAppointment *appointment = [notificatioDict valueForKey:@"referenceObject"];
    
   if(notification.notificationType == self.constants.SCHNotificationForAcknowledgement)
    {
    return YES;
    }
    return NO;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSDictionary *notificatioDict = [self.NotificationArray objectAtIndex:indexPath.row];
        SCHNotification *notification = [notificatioDict valueForKey:@"notification"];
        [notification unpin];
        [notification delete];
        dispatch_async(dispatch_get_main_queue(), ^{
            [SCHSyncManager syncBadge];
        });
        [self.NotificationArray removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadData];
        [self viewWillDisappear:YES];
    }
}

#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *notificatioDict = [self.NotificationArray objectAtIndex:indexPath.row];
   // notificationDetailForMessage
    SCHNotification *notification = [notificatioDict valueForKey:@"notification"];
    if ([notification.referenceObjectType isEqualToString:SCHAppointmentClass]||[notification.referenceObjectType isEqualToString:SCHAppointmentSeriesClass] || [notification.referenceObjectType isEqualToString:SCHMeetingClass]) {
        [self performSegueWithIdentifier:@"notificationDetailForAppointmentObject" sender:notificatioDict];
    } else if (!notification.referenceObjectType || [notification.referenceObjectType isEqualToString:@""]){
        [self performSegueWithIdentifier:@"notificationDetailForMessage" sender:notification];
    }
}

#pragma overriding segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"notificationDetailForAppointmentObject"]){
        NSDictionary *notificatioDict = (NSDictionary*)sender;

        SCHNotification *notification = [notificatioDict valueForKey:@"notification"];
        self.navigationItem.title = SCHBackkButtonTitle;

        SCHScheduleSummeryViewController *vcToPushTo = segue.destinationViewController;
        if((NSObject *)[notificatioDict valueForKey:@"referenceObject"]){
            vcToPushTo.recived_data  = (NSObject *)[notificatioDict valueForKey:@"referenceObject"];

        }
        
        if(notification.notificationType == self.constants.SCHNotificationForResponse)
        {
            vcToPushTo.assignedToUser = notification.user;
            
        } else {
            vcToPushTo.assignedToUser = nil;
            
        }
    }else if([segue.identifier isEqualToString:@"notificationDetailForMessage"])
    {
        SCHNotificationAcknowledgementDetailViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.notification =(SCHNotification*)sender;
        
    }
}

#pragma mark - accept decline clicked
-(void)acceptButtonClicked:(id)sender{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        NSIndexPath *indexPath = [self indexPathForsender:sender];
        NSDictionary *notificatioDict = [self.NotificationArray objectAtIndex:indexPath.row];

        SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
        
        
        [self.objectsForProcessing addObjectsToProcessingQueue:[notificatioDict valueForKey:@"referenceObject"]];
        self.eventManager.notificationChanged = YES;
        self.eventManager.scheduleEventsChanged = YES;
        [SCHUtility showProgressWithMessage:SCHProgressMessageAcceptAppointment];
        dispatch_async(backgroundManager.SCHSerialQueue, ^{
            
            [self beginBackgroundTask];
            SCHNotification *notification = [notificatioDict valueForKey:@"notification"];
            
            id  appointmentObject = [notificatioDict valueForKey:@"referenceObject"];
            
           // NSLog(@"referenceObject: %@", appointmentObject);
            
            if ([notification.referenceObjectType isEqualToString:SCHAppointmentClass]){
                //it's a single appointment
                if ([appointmentObject isKindOfClass:[SCHAppointment class]]){

                    
                    [SCHAppointmentManager confirmAppointmentRequest:appointmentObject series:NO refreshAvailability:YES save:YES];
                }
                
                
            } else if ([notification.referenceObjectType isEqualToString:SCHAppointmentSeriesClass]){
                [SCHAppointmentManager confirmAppointmentSeries:[notificatioDict valueForKey:@"referenceObject"]];
            } else if ([notification.referenceObjectType isEqualToString:SCHMeetingClass]){
                SCHMeeting *meeting = (SCHMeeting *)[notificatioDict valueForKey:@"referenceObject"];
                [meeting fetch];
                [SCHMeetingManager acceptMeeting:meeting];
            }
            

            [self.objectsForProcessing removeObjectsFromProcessingQueue:[notificatioDict valueForKey:@"referenceObject"]];
            
            [SCHSyncManager syncUserData:nil];
            
            [SCHUtility completeProgress];
            [self endBackgroundTask];
            
        });
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self.NotificationArray removeObject:notificatioDict];
            [self.tableView reloadData];
            // Set appointment status to processing
            
            
        }];

    } else {
        [SCHAlert internetOutageAlert];
        [self viewWillDisappear:YES];
    }
    
    
    
}
-(void)declineButtonClicked:(id)sender{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        NSIndexPath *indexPath = [self indexPathForsender:sender];
        NSDictionary *notificatioDict = [self.NotificationArray objectAtIndex:indexPath.row];
       // NSLog(@"Notification dict: %@", notificatioDict);
        SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
        [self.objectsForProcessing addObjectsToProcessingQueue:[notificatioDict valueForKey:@"referenceObject"]];
        self.eventManager.notificationChanged = YES;
        self.eventManager.scheduleEventsChanged = YES;
        [SCHUtility showProgressWithMessage:SCHProgressMessageDeclineAppointment];
        
        dispatch_async(backgroundManager.SCHSerialQueue, ^{
            
            [self beginBackgroundTask];
            SCHNotification *notification = [notificatioDict valueForKey:@"notification"];
            
            id  appointmentObject = [notificatioDict valueForKey:@"referenceObject"];
            
           // NSLog(@"referenceObject: %@", appointmentObject);
            
            if ([notification.referenceObjectType isEqualToString:SCHAppointmentClass]){
                //it's a single appointment
                if ([appointmentObject isKindOfClass:[SCHAppointment class]]){
                   // NSLog(@"Reference Object: %@", [notificatioDict valueForKey:@"referenceObject"] );
                    
                    [SCHAppointmentManager declineAppointmentRequest:[notificatioDict valueForKey:@"referenceObject"] isseries:NO refreshAvailability:YES save:YES];
                }
                
                
            } else if ([notification.referenceObjectType isEqualToString:SCHAppointmentSeriesClass]){
                [SCHAppointmentManager declineAppointmentSeriesRequest:[notificatioDict valueForKey:@"referenceObject"]];
            } else if ([notification.referenceObjectType isEqualToString:SCHMeetingClass]){
                SCHMeeting *meeting = (SCHMeeting *)[notificatioDict valueForKey:@"referenceObject"];
                [meeting fetch];
                [SCHMeetingManager declineMeeting:meeting];
            }
            

            [self.objectsForProcessing removeObjectsFromProcessingQueue:[notificatioDict valueForKey:@"referenceObject"]];
            
            [SCHSyncManager syncUserData:nil];

            
           [SCHUtility completeProgress];
            
             [self endBackgroundTask];
        });
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self.NotificationArray removeObject:notificatioDict];
            [self.tableView reloadData];
            // Set appointment status to processing
            
            
        }];

    } else {
        [SCHAlert internetOutageAlert];
        [self viewWillDisappear:YES];
    }
    
    
    
}

- (void) beginBackgroundTask
{
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void) endBackgroundTask
{
    [[UIApplication sharedApplication] endBackgroundTask: self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
}

-(void)okClicked:(id)sender{
//    NSIndexPath *indexpath = [self indexPathForsender:sender];
    // NSLog(@"okClicked at row %ld",(long)indexpath.row);
}
-(void)removeButtonClicked:(id)sender{
//    NSIndexPath *indexpath = [self indexPathForsender:sender];
    // NSLog(@"removeButtonClicked at row %ld",(long)indexpath.row);
}

-(NSIndexPath *) indexPathForsender:(id)sender{
        UITableViewCell *cell = (UITableViewCell *)[[sender superview] superview];
    
        return [self.tableView indexPathForCell:cell];
    
}

-(void)removeObjectsBeingProcessed{
    NSMutableArray *objectsToBeremoved = [[NSMutableArray alloc] init];
    for (NSDictionary *notificationDictonary in self.NotificationArray){
        if ([notificationDictonary valueForKey:@"referenceObject"]){
            if ([self.objectsForProcessing.objectsForProcessing containsObject:[notificationDictonary valueForKey:@"referenceObject"]]){
                [objectsToBeremoved addObject:notificationDictonary];
            
            }
            
        }
    }
    if (objectsToBeremoved.count > 0){
        [self.NotificationArray removeObjectsInArray:objectsToBeremoved];
    }
    
}


#pragma Methord of Pull To Refresh
-(void)addPullToRefresh{
    //to add the UIRefreshControl to UIView
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 0, 0)];
    [self.tableView insertSubview:refreshView atIndex:0]; //the tableView is a IBOutlet
    
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    NSMutableAttributedString *refreshString = [[NSMutableAttributedString alloc] initWithString:@"Pull To Refresh"];
    [refreshString addAttributes:@{NSForegroundColorAttributeName : [UIColor grayColor]} range:NSMakeRange(0, refreshString.length)];
    refreshControl.attributedTitle = refreshString;
    [refreshView addSubview:refreshControl];
    
    [self.tableView addSubview:refreshView];
}

- (void)refresh:(UIRefreshControl *)refreshControl
{
                [self.NotificationArray removeAllObjects];
                [self.NotificationArray addObjectsFromArray:self.eventManager.notifications];
                [self removeObjectsBeingProcessed];
                self.eventManager.notificationChanged = NO;
                [self.tableView reloadData];
    
    [refreshControl endRefreshing];
}

- (IBAction)CloseButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
