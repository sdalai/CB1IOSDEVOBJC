//
//  SCHScheduleSummeryViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 7/21/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHScheduleSummeryViewController.h"
#import "SCHAppointmentManager.h"
#import <MapKit/MapKit.h>
#import "SCHEvent.h"
#import "SCHEditAppointmentViewController.h"
#import "SelectedObjects.h"
#import "SCHSyncManager.h"
#import "SCHScheduledEventManager.h"
#import "SCHConstants.h"
#import "SCHScheduleClientDetailViewController.h"
#import "SCHNewAppointmentBySPViewController.h"
#import "SCHActiveViewControllers.h"
#import "SCHScheduleTableViewController.h"
#import "SCHNotificationViewController.h"
#import "SCHConstants.h"
#import "UITabBarController+HideTabBar.h"
#import "AppDelegate.h"
#import "SCHAlert.h"
#import "SCHManageAvailabilityViewController.h"
#import "PureLayout.h"
#import "SCHUser.h"
#import "UIView+Toast.h"
#import "SCHEmailAndTextMessage.h"
#import "SCHMeeting.h"
#import "SCHInvitiesListViewController.h"
#import "SCHMeeting.h"
#import "SCHMeetingManager.h"
#import "SCHEditMeetupViewController.h"
#import "SCHMeetupChangeRequestTableViewController.h"
//#import <QuartzCore/QuartzCore.h>
//@implementation CALayer (Additions)
//
//- (void)setBorderColorFromUIColor:(UIColor *)color
//{
//    self.borderColor = color.CGColor;
//}
//
//@end

static NSString * const kAccept = @"accept";
static NSString * const kDecline = @"decline";
static NSString * const kChange = @"change";
static NSString * const kCancel = @"Cancal";




@interface SCHScheduleSummeryViewController () <UIActionSheetDelegate>

@property(nonatomic) BOOL series;
@property(nonatomic, strong) NSString *declineBtnAction;
@property(nonatomic) BOOL showDeclineOrCancelAlert;

@end


@implementation SCHScheduleSummeryViewController
bool isUserSame = false;
bool isHideTabBar = false;
NSString *selectedLocation;
UIAlertView *cancelDeclineAlert;
UIAlertView *nvavigationAlert;
NSString *responseAction;

NSString *availabilityChangeAction;


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.declineBtnAction = kDecline;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    self.eventManager = [SCHScheduledEventManager sharedManager];
    self.objectsForProcessing = [SCHObjectsForProcessing sharedManager];
    self.rowheight = 45;
    //responceSugmentButtion.hidden = true;
    // Loading data
    //[self initilizeDataSource];
//    UIColor *greenColorForConfirmedAppointment = [UIColor colorWithRed:28.0/255.0
//                                                                 green:159.0/255.0
//                                                                  blue:81.0/255.0
//                                                                 alpha:1];

    
    self.appointmentRespondView.frame =CGRectMake(0, (self.view.frame.size.height- 50), self.view.frame.size.width, 50);
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (!appDelegate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    

    
}



-(void)initEditButton{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                      initWithTitle:@"Change" style:UIBarButtonItemStyleDone target:self action:@selector(editAppointment)];
        
        self.navigationItem.rightBarButtonItem = addButton;
    }

    
}

-(void)removeEditButton{
    
    self.navigationItem.rightBarButtonItem = nil;
}

-(void)editAppointment{
    
    if ([self.event.eventObject isKindOfClass:[SCHMeeting class]]){
        [self performSegueWithIdentifier:@"editMeetupSegue" sender:self.event.eventObject];
    } else{
        [self performSegueWithIdentifier:@"editAppointmentSegue" sender:self.event.eventObject];
    }


    
  
}



- (IBAction)AppointmentRespondAction:(id)sender{
    UIButton *btnSelected = (UIButton*)sender;
    responseAction = nil;

    if ([btnSelected isEqual:self.btnAccept]){
        responseAction = kAccept;
    }else if ([btnSelected isEqual:self.btnChange]){
        responseAction = kChange;
    } else if ([btnSelected isEqual:self.btnDecline]){
        responseAction = self.declineBtnAction;
    }
    
    if (self.showDeclineOrCancelAlert){
        
        NSString *alterButtonTitle = nil;
        if ([responseAction isEqualToString:kDecline]){
            alterButtonTitle= @"Decline";
        
        }else if([responseAction isEqualToString:kCancel]){
            alterButtonTitle= @"Cancel";
        } else if ([responseAction isEqualToString:kAccept]){
            alterButtonTitle= @"Accept";
        }else if ([responseAction isEqualToString:kChange]){
            alterButtonTitle= @"Change";
        }
        NSString *objectString = nil;
        if ([self.event.eventType isEqualToString:SCHMeetingClass]){
            objectString = @"meetup";
        }
        
        cancelDeclineAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                           message:[NSString localizedStringWithFormat:@"%@ %@?", alterButtonTitle, objectString]
                                                          delegate:self
                                                 cancelButtonTitle:@"No"
                                                 otherButtonTitles:@"Yes",nil];
        [cancelDeclineAlert show];

        
        
        
        
        
    } else{
        [self responseAction:responseAction];
    }

}




-(void)responseAction:(NSString *)responseAction{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.serverReachable)
        
    {
        SCHBackgroundManager *backgrounndManager = [SCHBackgroundManager sharedManager];
        SCHConstants *constants = [SCHConstants sharedManager];
        
        //Determine kind of processing from object Type
        SCHAppointment *appointment = nil;
        SCHAppointmentSeries *appointmentSeries = nil;
        SCHMeeting *meeting = nil;;
        
        BOOL series = NO;
        
        if ([self.event.eventObject isKindOfClass:[SCHAppointment class]]){
            
            appointment = (SCHAppointment *)self.event.eventObject;
            
            if (appointment.appointmentSeries ) {
                //find if there is open activity for user to respond at appointment level
                
                
                NSPredicate *openactivityPreducate  = [NSPredicate predicateWithFormat:@"actionAssignedTo = %@ AND appointmentSeries = %@ AND status = %@", appDelegate.user, appointment.appointmentSeries, constants.SCHappointmentActivityStatusOpen];
                PFQuery *openactivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openactivityPreducate];
                
                series = ([openactivityQuery countObjects] > 0) ? YES : NO;
                if (series){
                    appointmentSeries = appointment.appointmentSeries;
                    appointment = nil;
                }
                
                
            }
            
            
        } else if ([self.event.eventObject isKindOfClass:[SCHAppointmentSeries class]]){
            series = YES;
            appointmentSeries = (SCHAppointmentSeries *)self.event.eventObject;
            
        } else if ([self.event.eventObject isKindOfClass:[SCHMeeting class]]){
            meeting = (SCHMeeting *)self.event.eventObject;
            [meeting fetch];
        }
        
        if (series){
            [self.objectsForProcessing addObjectsToProcessingQueue:appointmentSeries];
        } else{
            if (appointment){
                [self.objectsForProcessing addObjectsToProcessingQueue:appointment];
            } else if (meeting){
                [self.objectsForProcessing addObjectsToProcessingQueue:meeting];
            }
            
        }
        self.eventManager.scheduleEventsChanged = YES;
        self.eventManager.notificationChanged = YES;
        
        
        
        if([responseAction isEqualToString:kAccept])
        {
            [SCHUtility showProgressWithMessage:SCHProgressMessageAcceptAppointment];
            
            dispatch_async(backgrounndManager.SCHSerialQueue, ^{
                [self beginBackgroundTask];
                
                if (appointmentSeries){
                    
                    [SCHAppointmentManager confirmAppointmentSeries:appointmentSeries];
                } else if (appointment){
                    [SCHAppointmentManager confirmAppointmentRequest:appointment series:NO refreshAvailability:YES save:YES];
                } else if (meeting){
                    [SCHMeetingManager acceptMeeting:meeting];
                }
                
                if (appointmentSeries){
                    [self.objectsForProcessing removeObjectsFromProcessingQueue:appointmentSeries];
                } else if (appointment) {
                    [self.objectsForProcessing removeObjectsFromProcessingQueue:appointment];
                } else if (meeting){
                    [self.objectsForProcessing removeObjectsFromProcessingQueue:meeting];
                }
                
                [SCHSyncManager syncUserData:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SCHSyncManager syncBadge];
                });
                [SCHUtility completeProgress];
                [self endBackgroundTask];
                
            });
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                [self.navigationController popViewControllerAnimated:YES];
            }];
            
            
            
        }else if([responseAction isEqualToString:kChange])
        {
            if (appointment){
                [self.objectsForProcessing removeObjectsFromProcessingQueue:appointmentSeries];
            }else if(appointment){
                [self.objectsForProcessing removeObjectsFromProcessingQueue:appointment];
            }else if (meeting){
                [self.objectsForProcessing removeObjectsFromProcessingQueue:meeting];
            }
            [self editAppointment];
        }
        else if([responseAction isEqualToString:kDecline])
        {
           // [SCHUtility showProgressWithMessage:SCHProgressMessageDeclineAppointment];
            
            
            
            
            dispatch_async(backgrounndManager.SCHSerialQueue, ^{
                
                [self beginBackgroundTask];
                if (appointmentSeries){
                    [SCHAppointmentManager declineAppointmentSeriesRequest:appointmentSeries];
                } else if (appointment){
                    [SCHAppointmentManager declineAppointmentRequest:appointment isseries:NO refreshAvailability:YES save:YES];
                } else if (meeting){
                    //removemeetup from event
                    
                    [SCHMeetingManager declineMeeting:meeting];
                }

                
                if (appointmentSeries){
                    [self.objectsForProcessing removeObjectsFromProcessingQueue:appointmentSeries];
                } else if (appointment) {
                    [self.objectsForProcessing removeObjectsFromProcessingQueue:appointment];
                } else if (meeting){
                    [self.objectsForProcessing removeObjectsFromProcessingQueue:meeting];
                }
                
                
                [SCHSyncManager syncUserData:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SCHSyncManager syncBadge];
                });
                //[SCHUtility completeProgress];
                [self endBackgroundTask];
                
            });
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                [self.navigationController popViewControllerAnimated:YES];
            }];
            
            
        }else if ([responseAction isEqualToString:kCancel]){
           // [SCHUtility showProgressWithMessage:SCHProgressMessageGeneric];
            dispatch_async(backgrounndManager.SCHSerialQueue, ^{
                
                [self beginBackgroundTask];
                NSDictionary *output = [SCHMeetingManager cancelMeeting:meeting];
                if (output){
                    NSArray *textList = [output valueForKey:@"nonUsetTextList"];
                    NSArray *emailList = [output valueForKey:@"nonUserEmailList"];
                    [SCHSyncManager syncUserData:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SCHSyncManager syncBadge];
                    });
                    
                    [SCHMeetingManager sendTextMessage:meeting textList:textList messageType:kMeetingCancellationNotification];
                    [SCHMeetingManager sendEmail:meeting emailList:emailList messageType:kMeetingCancellationNotification];
                    
                    if (textList.count > 0 && emailList.count > 0){
                        [SCHMeetingManager sendEmailAndText:meeting emailList:emailList textList:textList messageType:kMeetingCancellationNotification];
                    } else if (textList.count > 0 && emailList.count == 0){
                        [SCHMeetingManager sendTextMessage:meeting textList:textList messageType:kMeetingCancellationNotification];
                    } else if (textList.count == 0 && emailList.count > 0){
                        [SCHMeetingManager sendEmail:meeting emailList:emailList messageType:kMeetingCancellationNotification];
                    }


                    
                } else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        nvavigationAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                            message:@"Invites couldn't be added. Try again."
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [nvavigationAlert show];
                    });
                    
                    
                }

               // [SCHUtility completeProgress];
                [self endBackgroundTask];
            });
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
    }else{
        [SCHAlert internetOutageAlert];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self.navigationController popViewControllerAnimated:YES];
        }];
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



#pragma mark - Table view data source



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    if(self.event.eventType == SCHAvailabilityClass){
        NSArray * serviceList =[[self.dataArray objectAtIndex:self.dataArray.count-1] valueForKey:@"service"];
        return self.dataArray.count+serviceList.count-1;
    }else if(self.event.eventType == SCHAppointmentClass){
        return  self.dataArray.count;
    }
    return self.dataArray.count;
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
       return self.rowheight;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    

    
    if([self.dataArray count] > indexPath.row+1 || self.event.eventType == SCHAppointmentClass || self.event.eventType == SCHAppointmentSeriesClass || self.event.eventType == SCHMeetingClass){
        if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"appointmentSummary"]!= nil)
        {
            NSDictionary *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"appointmentSummary"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"SCHAppointmentsSummaryCell"];
            UITextView *contentTextView = (UITextView *)[cell.contentView viewWithTag:1];
            [contentTextView setAttributedText:[cellData valueForKey:@"content"]];
            self.rowheight = [SCHUtility tableViewCellHeight:contentTextView width:contentTextView.bounds.size.width] + 10.0;
            
        }else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"withWhom"]!= nil){
            NSDictionary *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"withWhom"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"SCHAppointmentLocationCell"];
            UILabel *lblRowTitle = (UILabel *)[cell.contentView viewWithTag:1];
            UITextView *contenttxtView = (UITextView*)[cell.contentView viewWithTag:2];
            [lblRowTitle setAttributedText:[cellData valueForKey:@"title"]];
            NSDictionary *userInfo = [cellData valueForKey:@"content"];
            NSString *displayName = nil;
            if ([userInfo valueForKey:@"user"]) {
                SCHUser * user = [userInfo valueForKey:@"user"];
                displayName = user.preferredName;
            } else {
                displayName = [userInfo valueForKey:@"name"];
            }
                
           
            
            [contenttxtView setAttributedText:[[NSAttributedString alloc] initWithString:displayName attributes:[SCHUtility preferredTextDispalyFontAttr]]];
            self.rowheight = [SCHUtility tableViewCellHeight:contenttxtView width:contenttxtView.bounds.size.width] +30;
            
            
        }else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"appointmentLocation"]!= nil){
            NSDictionary *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"appointmentLocation"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"SCHAppointmentLocationCell"];
            UILabel *lblRowTitle = (UILabel *)[cell.contentView viewWithTag:1];
            UITextView *contenttxtView = (UITextView*)[cell.contentView viewWithTag:2];
            [lblRowTitle setAttributedText:[cellData valueForKey:@"title"]];
            [contenttxtView setAttributedText:[cellData valueForKey:@"content"]];
            
            self.rowheight = [SCHUtility tableViewCellHeight:contenttxtView width:contenttxtView.bounds.size.width] +30;
            
        }else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"notes"]!= nil){
            NSDictionary *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"notes"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"SCHAppointmentNoteCell"];
            UILabel *lblRowTitle = (UILabel *)[cell.contentView viewWithTag:1];
            UITextView *contenttxtView = (UITextView*)[cell.contentView viewWithTag:2];
            [lblRowTitle setAttributedText:[cellData valueForKey:@"title"]];
            [contenttxtView setAttributedText:[cellData valueForKey:@"content"]];
            self.rowheight = [SCHUtility tableViewCellHeight:contenttxtView width:contenttxtView.bounds.size.width] +30;
            
        }else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"availabilityTitle"]!= nil)
        {
            NSAttributedString *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"availabilityTitle"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"SCHAppointmentsSummaryCell"];
            UITextView *contentTextView = (UITextView *)[cell.contentView viewWithTag:1];
            [contentTextView setAttributedText:cellData];
            self.rowheight = [SCHUtility tableViewCellHeight:contentTextView width:contentTextView.bounds.size.width] +10;
            
        }else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"serviceListHeader"]!= nil)
        {
            NSAttributedString *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"serviceListHeader"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"SCHAppointmentsSummaryCell"];
            UITextView *contentTextView = (UITextView *)[cell.contentView viewWithTag:1];
            [contentTextView setAttributedText:cellData];
            self.rowheight = [SCHUtility tableViewCellHeight:contentTextView width:contentTextView.bounds.size.width] + 10.0;
            
        }else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"sendReminder"]!= nil){
            NSDictionary *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"sendReminder"];
            
           
            cell = [tableView dequeueReusableCellWithIdentifier:@"SCHAppointmentsNotifyCell"];
            UITextView *contentTextView = (UITextView *)[cell.contentView viewWithTag:1];
            [contentTextView setAttributedText:[cellData valueForKey:@"content"]];
            self.rowheight = [SCHUtility tableViewCellHeight:contentTextView width:contentTextView.bounds.size.width]+10;

        } else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"invities"]!= nil){
            
            NSDictionary *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"invities"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"SCHInvitiesCell"];
            UILabel *lblRowTitle = (UILabel *)[cell.contentView viewWithTag:1];
            [lblRowTitle setAttributedText:[cellData valueForKey:@"title"]];
            self.rowheight = 50;

        } else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"changeRequest"]!= nil){
            
            NSDictionary *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"changeRequest"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"SCHInvitiesCell"];
            
            UILabel *lblRowTitle = (UILabel *)[cell.contentView viewWithTag:1];
            [lblRowTitle setAttributedText:[cellData valueForKey:@"title"]];
            self.rowheight = 50;
        }

 
    } else {

        NSArray * serviceList =[[self.dataArray objectAtIndex:self.dataArray.count-1] valueForKey:@"service"];
        NSDictionary *serviceDict = [serviceList objectAtIndex:(indexPath.row - self.dataArray.count+1)];
       
        cell = [tableView dequeueReusableCellWithIdentifier:@"SCHAppointmentsSummaryCell"];
        UITextView *contentTextView = (UITextView *)[cell.contentView viewWithTag:1];
        
        NSMutableAttributedString *finalString = [[NSMutableAttributedString alloc] initWithAttributedString:[serviceDict valueForKey:@"service"]];
        NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
        [finalString appendAttributedString:newline];
        [finalString appendAttributedString:[serviceDict valueForKey:@"serviceTime"]];
        [contentTextView setAttributedText:finalString];
        self.rowheight = [SCHUtility tableViewCellHeight:contentTextView width:contentTextView.bounds.size.width]+20;
    }
        
    
    return cell;
}





#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"appointmentLocation"]!= nil){
        nvavigationAlert = [[UIAlertView alloc] initWithTitle:SCHAppName
                                                          message:@"You will be redirected to Navigation app.\n Do you want to continue ?"
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"Continue", nil];
        [nvavigationAlert show];
        
          NSDictionary *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"appointmentLocation"];
        selectedLocation = [[cellData valueForKey:@"content"] string];
        
       // [SCHUtility showProgressWithMessage:@"Opening Direction..."];
    }else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"withWhom"]!= nil)
    {
        NSDictionary *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"withWhom"];
        
        
        
        [self performSegueWithIdentifier:@"goToClientDetailSegue" sender:cellData];
    }else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"sendReminder"]!= nil)
    {
        
        //[self.view makeToast:@"Reminder Sent Successfully" duration:1 position:CSToastPositionCenter];
        [self sendReminder];
        
    }else if([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"invities"]!= nil)
    {
        NSDictionary *cellData = [[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"invities"];
        
        NSArray *invitiArray =[cellData valueForKey:@"content"];
        //invitiesSegue
        [self performSegueWithIdentifier:@"invitiesSegue" sender:invitiArray];
        
    }else if ([[self.dataArray objectAtIndex:indexPath.row] valueForKey:@"changeRequest"]!= nil){

        
        [self performSegueWithIdentifier:@"changeRequestSegue" sender:self.event.eventObject];
    }
   
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];

    
  //  goToClientDetailSegue
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1 && [alertView isEqual:nvavigationAlert])
    {
        [self openMapWithAddress:selectedLocation];
    } else if ([alertView isEqual:cancelDeclineAlert] && buttonIndex == 1){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self responseAction:responseAction];
        });

    }
}

-(void) openMapWithAddress:(NSString*)address
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
           // NSLog(@"%@", error);
        } else {
            [SCHUtility completeProgress];
            CLPlacemark* placemark = [placemarks lastObject];
            
            MKPlacemark *endLocation = [[MKPlacemark alloc] initWithCoordinate:placemark.location.coordinate addressDictionary:nil];
            MKMapItem *endingItem = [[MKMapItem alloc] initWithPlacemark:endLocation];
            
            NSMutableDictionary *launchOptions = [[NSMutableDictionary alloc] init];
            [launchOptions setObject:MKLaunchOptionsDirectionsModeDriving forKey:MKLaunchOptionsDirectionsModeKey];
            
            [endingItem openInMapsWithLaunchOptions:launchOptions];
        }
    }];
    
    
   
}
-(void) initOption
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        dispatch_barrier_async([SCHBackgroundManager sharedManager].SCHSerialQueue, ^{
            BOOL is_userrviceProvider =([SCHUtility hasActiveService] && [SCHUtility BusinessUserAccess]);
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if(is_userrviceProvider){
                     [self initializeTabButton];
                }
               
            });
            
            
            
        });
        if(footerView == nil)
        {
            footerView  = [[UIView alloc] init];
            
            [footerView setFrame:CGRectMake(0, ([UIScreen mainScreen].bounds.size.height)-50, self.tableView.frame.size.width, 60)];
            //we would like to show a gloosy red button, so get the image first
            
            //create the button
            UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [button setBackgroundColor:[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor]];
            button.layer.cornerRadius = 0; // this value vary as per your desire
            button.clipsToBounds = YES;
            
            //the button should be as big as a table view cell
            [button setFrame:CGRectMake(16, 0, self.tableView.frame.size.width-32, 44)];
            
            //set title, font size and font color
            [button setTitle:@"Setup Appointment with Client" forState:UIControlStateNormal];
            [button.titleLabel setFont:[SCHUtility getPreferredTitleFont]];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            //set action of the button
            [button addTarget:self action:@selector(newAppointmentAction)
             forControlEvents:UIControlEventTouchUpInside];
            
            //add the button to the view
            [footerView addSubview:button];
            
            //         footerView.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
        }
        [self.navigationController.view addSubview:footerView];
        //    [self.view.window addSubview:footerView];

        
    }else{
        
        /*
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.navigationItem.rightBarButtonItem = nil;
        });
         */
        [self removeEditButton];
        

        
        if(self.tabBarController.isTabBarHidden){
            [self.tabBarController setTabBarHidden:NO];
        }
    
        
        if(footerView != nil){
            [footerView removeFromSuperview];
        }
        
        if(_appointmentRespondView!=nil)
            [_appointmentRespondView removeFromSuperview];

        
        
    }

    
}

-(SCHEvent *)createEventWithEventDay:(NSDate *)eventDay eventType:(NSString *) eventType eventObject:(id)eventObject startTime:(NSDate *) startTime endTime:(NSDate *) endTime Location:(NSString *) location {
    SCHEvent *event = [[SCHEvent alloc] init];
    SCHConstants *constants = [SCHConstants sharedManager];
    
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    if ([eventType isEqualToString:SCHAppointmentClass]){
        SCHAppointment *appointment = (SCHAppointment *)eventObject;
        
        
        if (appointment.status == constants.SCHappointmentStatusPending){
            NSPredicate *openActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointment = %@ AND status = %@", appDelegate.user, appDelegate.user, appointment, constants.SCHappointmentActivityStatusOpen];
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
                    
                    NSPredicate *openSeriesActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointmentSeries = %@ AND status = %@", appDelegate.user, appDelegate.user, appointment.appointmentSeries, constants.SCHappointmentActivityStatusOpen];
                    
                    
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
    } else if ([eventType isEqualToString:SCHAppointmentSeriesClass]){
        SCHAppointmentSeries *series = (SCHAppointmentSeries *)eventObject;
        if (series.status == constants.SCHappointmentStatusPending){
             NSPredicate *openSeriesActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointmentSeries = %@ AND status = %@", appDelegate.user, appDelegate.user, series, constants.SCHappointmentActivityStatusOpen];
             PFQuery *openSeriesActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openSeriesActivityPredicate];
             [openSeriesActivityQuery includeKey:@"actionAssignedTo"];
             [openSeriesActivityQuery includeKey:@"actionInitiator"];
             [openSeriesActivityQuery includeKey:@"status"];
             [openSeriesActivityQuery includeKey:@"action"];
             [openSeriesActivityQuery fromLocalDatastore];
             NSArray *appointmentSeriesOpenActivity = [openSeriesActivityQuery findObjects];
             if(appointmentSeriesOpenActivity.count > 0){
                 event.openActivity = appointmentSeriesOpenActivity.firstObject;
             }
             
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    

    
    
    self.showDeclineOrCancelAlert = NO;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    SCHConstants *constants = [SCHConstants sharedManager];
    
    //set title of screen
    
    
    
    if([self.recived_data isKindOfClass:[SCHEvent class]]){
        self.event = (SCHEvent*)self.recived_data;
        
        if(self.event.eventType == SCHAvailabilityClass){
            self.navigationItem.title=SCHScreenTitleManageAvailability;
        }else if(self.event.eventType == SCHAppointmentClass){
            self.navigationItem.title= SCHSCreenTitleNewAppointment;
        }else if ([self.event.eventType isEqualToString:SCHMeetingClass]){
            self.navigationItem.title= SCHSCreenTitleNewMeetup;
        }
    }else {
        self.navigationItem.title = SCHSCreenTitleNewAppointment;
    }
    
    // Construct Event
    
    if([self.recived_data isKindOfClass:[SCHEvent class]]){
        self.event = (SCHEvent*)self.recived_data;
    } else {
        //build event
        if ([self.recived_data isKindOfClass:[SCHAppointmentSeries class]]){
            SCHAppointmentSeries *series = (SCHAppointmentSeries *)self.recived_data;
            self. event =[self createEventWithEventDay:series.startTime
                                eventType:SCHAppointmentSeriesClass
                              eventObject:series
                                startTime:series.startTime
                                  endTime:series.endTime
                                 Location:series.location];
        } else if ([self.recived_data isKindOfClass:[SCHAppointment class]]) {
            SCHAppointment *appointment = (SCHAppointment *)self.recived_data;
            self. event =[self createEventWithEventDay:appointment.startTime
                                             eventType:SCHAppointmentClass
                                           eventObject:appointment
                                             startTime:appointment.startTime
                                               endTime:appointment.endTime
                                              Location:appointment.location];
        }else {
            SCHMeeting *meeting  = (SCHMeeting *)self.recived_data;
            self. event =[self createEventWithEventDay:meeting.startTime
                                             eventType:SCHMeetingClass
                                           eventObject:meeting
                                             startTime:meeting.startTime
                                               endTime:meeting.endTime
                                              Location:meeting.location];
            
        }
        
        
    }
    
    self.series = NO;
    
    if ([self.event.eventObject isKindOfClass:[SCHAppointment class]]){
        SCHConstants *constants = [SCHConstants sharedManager];
        SCHAppointment *appointment = (SCHAppointment *) self.event.eventObject;
        if ([appointment.status isEqual:constants.SCHappointmentStatusPending] && !appointment.expired){
            if(self.event.openActivity.appointmentSeries){
                self.series = YES;
            }
            
        }
        
    }
    
    if ([self.event.eventType isEqualToString:SCHAvailabilityClass]){
        self.title = @"Availability";
        self.dataArray = [SCHUtility availabilityDetailContents:self.event.eventObject];
        if(!self.tabBarController.isTabBarHidden){
            [self.tabBarController setTabBarHidden:YES];
            [self removeEditButton];
            isHideTabBar = true;
        }
        
        [self initOption];
    } else if ([self.event.eventType isEqualToString:SCHAppointmentClass]){
        SCHAppointment *appointment = self.event.eventObject;
        
        
        if (self.series){
            /*
            if ([appointment.status isEqual:constants.SCHappointmentStatusConfirmed] &&(!appointment.expired && appDelegate.serverReachable)){
                [self initEditButton];
            } else{
               [self removeEditButton];
            }
             */
            [self removeEditButton];
            
        } else{
            if ((![self objectIsProcessing:appointment]) &&( [appointment.status isEqual:constants.SCHappointmentStatusConfirmed] ||[appointment.status isEqual:constants.SCHappointmentStatusPending]) &&(!appointment.expired && appDelegate.serverReachable)){
                [self initEditButton];
            } else{
                [self removeEditButton];
            }
        }
        
        
        
        self.title = @"Appointment";
        self.dataArray = [SCHUtility appointmentDetailContents:self.event];
        if(self.event.openActivity.actionAssignedTo == appDelegate.user){
            
            if ((![self objectIsProcessing:appointment]) && [appointment.status isEqual:constants.SCHappointmentStatusPending] &&!appointment.expired && appDelegate.serverReachable){
                
                
                if (self.series){
                    [self.btnChange setHidden:YES];
                }
                
                [self.navigationController.view addSubview:self.appointmentRespondView];
                
                if(!self.tabBarController.isTabBarHidden){
                    [self.tabBarController setTabBarHidden:YES];
                    [self removeEditButton];
                    isHideTabBar = true;
                }
                [self.tableView setContentSize:CGSizeMake(self.tableView.contentSize.width, self.tableView.contentSize.height+40)];
                isUserSame = true;
            } else{
                 if(self.tabBarController.isTabBarHidden){
                    [self.tabBarController setTabBarHidden:NO];
                }
                

                
                if(_appointmentRespondView!=nil)
                    [_appointmentRespondView removeFromSuperview];
                
            }
            
        }

    } else if ([self.event.eventType isEqualToString:SCHMeetingClass]){
        [self removeEditButton];
        self.title = @"Meet-up";
        SCHMeeting *meeting = (SCHMeeting *)self.event.eventObject;
        self.dataArray = [SCHUtility appointmentDetailContents:self.event];
        BOOL expired = NO;
        if ([meeting.endTime compare:[NSDate date]] == NSOrderedAscending){
            expired = YES;
        }else{
            expired = NO;
        }
        
        
        if (appDelegate.serverReachable && !expired){
            NSString *status = [SCHUtility getmeetupStatus:self.event];
            if ([meeting.organizer isEqual:appDelegate.user]){
                if (![status isEqualToString:SCHMeetupStatusCancelled] && appDelegate.serverReachable){
                    [self initEditButton];
                    [self setAppointmentRespondViewAccept:NO decline:YES change:NO];
                    [self.btnDecline setTitle:@"Cancel" forState:UIControlStateNormal];
                    self.showDeclineOrCancelAlert = YES;
                    self.declineBtnAction = kCancel;
                    [self.navigationController.view addSubview:self.appointmentRespondView];
                    
                    if(!self.tabBarController.isTabBarHidden){
                        [self.tabBarController setTabBarHidden:YES];
                        isHideTabBar = true;
                    }
                    [self.tableView setContentSize:CGSizeMake(self.tableView.contentSize.width, self.tableView.contentSize.height+40)];
                    isUserSame = true;
                    
                } else{
                    [self removeEditButton];
                    
                    
                }
                
            } else{
                if ([status isEqualToString:SCHMeetupStatusRespond]){
                    [self.navigationController.view addSubview:self.appointmentRespondView];
                    
                    if(!self.tabBarController.isTabBarHidden){
                        [self.tabBarController setTabBarHidden:YES];
                        [self removeEditButton];
                        isHideTabBar = true;
                    }
                    [self.tableView setContentSize:CGSizeMake(self.tableView.contentSize.width, self.tableView.contentSize.height+40)];
                    isUserSame = true;
                    
                } else if ([status isEqualToString:SCHMeetupStatusConfirmed]){
                    [self initEditButton];
                    [self setAppointmentRespondViewAccept:NO decline:YES change:NO];
                    self.showDeclineOrCancelAlert = YES;
                    [self.navigationController.view addSubview:self.appointmentRespondView];
                    
                    if(!self.tabBarController.isTabBarHidden){
                        [self.tabBarController setTabBarHidden:YES];
                        isHideTabBar = true;
                    }
                    [self.tableView setContentSize:CGSizeMake(self.tableView.contentSize.width, self.tableView.contentSize.height+40)];
                    isUserSame = true;
                    
                    
                }
                
                
            }

            
        } else{
            [self removeEditButton];
            if(self.tabBarController.isTabBarHidden){
                [self.tabBarController setTabBarHidden:NO];
            }
            
            if(_appointmentRespondView!=nil){
                [_appointmentRespondView removeFromSuperview];
            }
        
        }
        
        
        
        
    }else if ([self.event.eventType isEqualToString:SCHAppointmentSeriesClass]){
        self.title = @"Appointment Series";
        SCHAppointmentSeries *series = (SCHAppointmentSeries *)self.event.eventObject;
        self.dataArray = [SCHUtility appointmentDetailContents:series];
        [self removeEditButton];
        if(self.event.openActivity.actionAssignedTo == appDelegate.user){
            if(!series.expired && ![self objectIsProcessing:series]&& appDelegate.serverReachable){
               [self.navigationController.view addSubview:self.appointmentRespondView];
                [self.btnChange setHidden:YES];
                if(!self.tabBarController.isTabBarHidden){
                    [self.tabBarController setTabBarHidden:YES];
                    [self removeEditButton];
                    isHideTabBar = true;
                }
                [self.tableView setContentSize:CGSizeMake(self.tableView.contentSize.width, self.tableView.contentSize.height+40)];
                isUserSame = true;
                
            } else{

                
                if(self.tabBarController.isTabBarHidden){
                    [self.tabBarController setTabBarHidden:NO];
                }
                
                if(_appointmentRespondView!=nil)
                    [_appointmentRespondView removeFromSuperview];
            }
            
            
        }
        
        


    }
    
    
    if ([self objectIsProcessing:self.event.eventObject]){
        [self.tableView reloadData];
    }
    
    if(self.tabBarController.isTabBarHidden && isHideTabBar)
        [self.tabBarController setTabBarHidden:YES];

    
    
}


-(BOOL)objectIsProcessing:(id)object{
    
    if ([self.objectsForProcessing.objectsForProcessing containsObject:object]){
        return YES;
    } else return NO;
  
}



-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    self.navigationItem.title = SCHBackkButtonTitle;
    
    if(isUserSame)
        [self.segmentedControl removeFromSuperview];
    
    if(self.tabBarController.isTabBarHidden)
       [self.tabBarController setTabBarHidden:NO];
    
    
    
    if(footerView != nil){
        [footerView removeFromSuperview];
    }

    if(_appointmentRespondView!=nil)
        [_appointmentRespondView removeFromSuperview];
}




//editAppointmentSegue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{//appointmentDetailNew
    if([segue.identifier isEqualToString:@"editAppointmentSegue"]){
        self.navigationItem.title = SCHBackkButtonTitle;
        SelectedObjects *selectedObject = [SelectedObjects sharedManager];
        selectedObject.selectedAppointment = (SCHAppointment *)sender;
        selectedObject.selectedMeeting = nil;
        SCHEditAppointmentViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.appointment  =(SCHAppointment *)sender;
    
    }else if([segue.identifier isEqualToString:@"goToClientDetailSegue"])
    {
        
        SCHScheduleClientDetailViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.clientInfo = (NSDictionary*)sender;
        if ([self.event.eventObject isKindOfClass:[SCHAppointment class]]){
            vcToPushTo.appointment = (SCHAppointment *)self.event.eventObject;
        } else if ([self.event.eventObject isKindOfClass:[SCHAppointmentSeries class]]){
            vcToPushTo.series = (SCHAppointmentSeries *)self.event.eventObject;
        }
        
    
    }else if([segue.identifier isEqualToString:@"appointmentSegue"])
    {
        SCHNewAppointmentBySPViewController *vcToPushTo = segue.destinationViewController;
        SCHEvent *availabilityEvent = ((SCHEvent*)self.recived_data);
        vcToPushTo.startTime = ((SCHEvent*)self.recived_data).startTime ;
        vcToPushTo.availabilityLocation = ((SCHEvent*)self.recived_data).location;
        if ([availabilityEvent.eventObject isKindOfClass:[SCHAvailability class]]){
            SCHAvailability *availability = ((SCHEvent*)self.recived_data).eventObject;
            vcToPushTo.availabilityServices = availability.services;
        }
        
    }else if ([segue.identifier isEqualToString:@"availabilitySegue"]){
        SCHManageAvailabilityViewController *vcPushTo = segue.destinationViewController;
        SCHEvent *availabilityEvent = ((SCHEvent*)self.recived_data);
        if ([availabilityEvent.eventObject isKindOfClass:[SCHAvailability class]]){
            vcPushTo.selectedAvailabiity = availabilityEvent.eventObject;
        }
        if (availabilityChangeAction){
            vcPushTo.presetAvailabilityAction = availabilityChangeAction;
        }
        
        
    }else if ([segue.identifier isEqualToString:@"invitiesSegue"])
    {
        SCHInvitiesListViewController *vcpush = segue.destinationViewController;
        vcpush.meeting = (SCHMeeting *)self.event.eventObject;
        
    }else if ([segue.identifier isEqualToString:@"editMeetupSegue"])
    {
        self.navigationItem.title = SCHBackkButtonTitle;
        SelectedObjects *selectedObject = [SelectedObjects sharedManager];
        selectedObject.selectedMeeting = (SCHMeeting *)sender;
        selectedObject.selectedAppointment = nil;
        SCHInvitiesListViewController *vcpush = segue.destinationViewController;
        vcpush.meeting = (SCHMeeting *)self.event.eventObject;
        
    } else if([segue.identifier isEqualToString:@"changeRequestSegue"]) {
        self.navigationItem.title = SCHBackkButtonTitle;
        SCHMeetupChangeRequestTableViewController *vcpush = segue.destinationViewController;
        vcpush.meeting = (SCHMeeting *)self.event.eventObject;


    }
}



#pragma mark - Add Action sheet
-(void)initializeTabButton{
    
    // check user type
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                  initWithTitle:@"Edit" style:UIBarButtonItemStyleDone target:self action:@selector(EditButtonAction)];
    
//    [[UIBarButtonItem alloc]
//                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
//                                  target:self action:@selector(showActionSheet:)];
//    
    
    self.navigationItem.rightBarButtonItem = addButton;
    
}
-(void)EditButtonAction{
    [self performSegueWithIdentifier:@"availabilitySegue" sender:nil];
}

-(void)newAppointmentAction{
    if ([self.event.eventObject isKindOfClass:[SCHAvailability class]]){
        SCHAvailability *availability = (SCHAvailability *)self.event.eventObject;
        NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary  *serviceDict, NSDictionary<NSString *,id> * _Nullable bindings) {
            SCHService *servie = (SCHService *)[serviceDict valueForKey:@"service"];
            
            if (servie.suspended){
                return NO;
            } else{
                return YES;
            }
            
        }];
        
        NSArray *validServices = [availability.services filteredArrayUsingPredicate:filterPredicate];
        
        if (validServices.count > 0){
            [self performSegueWithIdentifier:@"appointmentSegue" sender:nil];

        } else{
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                   message:@"Business is suspended. Please email contact@counterbean.com."
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [theAlert show];
                
            });

        }
    }

}

- (IBAction)showActionSheet:(id)sender
{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(appDelegate.serverReachable)
        
    {
        NSString *actionSheetTitle = @"New"; //Action Sheet Title
        NSString *appointmentButton = @"Setup Appointment with Client";
        NSString *AvailabilityChangeButton = @"Change Availability";
        NSString *AvailabilityRemoveButton = @"Remove Availability";
        NSString *cancelTitle = @"Cancel";
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                      initWithTitle:actionSheetTitle
                                      delegate:self
                                      cancelButtonTitle:cancelTitle
                                      destructiveButtonTitle:nil
                                      otherButtonTitles:appointmentButton, AvailabilityChangeButton, AvailabilityRemoveButton, nil];
        
        
        [actionSheet showInView:self.view];
        
        
        
    }else{
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                           message:@"Internet Not Avaliable"
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    
    SEL selector = NSSelectorFromString(@"_alertController");
    if ([actionSheet respondsToSelector:selector])
    {
        UIAlertController *alertController = [actionSheet valueForKey:@"_alertController"];
        if ([alertController isKindOfClass:[UIAlertController class]])
        {
            alertController.view.tintColor = [SCHUtility colorFromHexString:@"#FF5621"];
        }
    }
    else
    {
        // use other methods for iOS 7 or older.
        for (UIView *subview in actionSheet.subviews) {
            if ([subview isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)subview;
                [button setTitleColor:[SCHUtility colorFromHexString:@"#FF5621"] forState:UIControlStateNormal];
            }
        }
    }
}



- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    //Get the name of the current pressed button
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if  ([buttonTitle isEqualToString:@"Setup Appointment with Client"]) {
        [self performSegueWithIdentifier:@"appointmentSegue" sender:nil];
        
    }
    if ([buttonTitle isEqualToString:@"Change Availability"]) {
        availabilityChangeAction = SCHSelectorAvailabilityActionOptionChange;
        [self performSegueWithIdentifier:@"availabilitySegue" sender:nil];
        
    }

    if ([buttonTitle isEqualToString:@"Remove Availability"]) {
        availabilityChangeAction = SCHSelectorAvailabilityActionOptionUnavailable;
        [self performSegueWithIdentifier:@"availabilitySegue" sender:nil];
        
    }
    
}




-(void)internetConnectionChanged{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appDelegate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });
    
    
    


    
    if ([self.navigationController.viewControllers.lastObject isEqual:self]){
        [self viewWillAppear:YES];
    } else{

        
        if(self.tabBarController.isTabBarHidden)
            [self.tabBarController setTabBarHidden:NO];

        if(footerView != nil){
            [footerView removeFromSuperview];
        }
        
        if(_appointmentRespondView!=nil)
            [_appointmentRespondView removeFromSuperview];
    }
    

    
}




-(void) sendReminder{
    
    if ([self.event.eventType isEqualToString:SCHAppointmentClass]){
        SCHAppointment *appointment = self.event.eventObject;
        SCHEmailAndTextMessage *emailAndMessage = [SCHEmailAndTextMessage sharedManager];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        // determine to whom
        id towhom = ([appointment.serviceProvider isEqual:appDelegate.user])? ((appointment.client) ? appointment.client : appointment.nonUserClient) : appointment.serviceProvider;
        
        if([towhom isKindOfClass:[SCHUser class]]){
            SCHUser *toUser = (SCHUser *)towhom;
            emailAndMessage.textAlertPhoneNumbers = @[toUser.phoneNumber];
            
        } else{
            SCHNonUserClient *toNonUser = (SCHNonUserClient *)towhom;
            emailAndMessage.textAlertPhoneNumbers = @[toNonUser.phoneNumber];
        }
        emailAndMessage.textAlertMessage = [NSString localizedStringWithFormat:@"%@ sent appointment reminder.\n%@",appDelegate.user.preferredName, [SCHAppointmentManager messageBody:appointment]];
        
        [emailAndMessage showSMSToNumber:emailAndMessage.textAlertPhoneNumbers message:emailAndMessage.textAlertMessage];
        [emailAndMessage resetValues];
        
        
        
    }
    
}

-(void) setAppointmentRespondViewAccept:(BOOL) accept decline:(BOOL) decline change:(BOOL) change{
    if (!accept && !change && decline){
        [self.btnAccept removeFromSuperview];
        [self.btnChange removeFromSuperview];
        [self.btnDecline setBounds:self.appointmentRespondView.bounds];
        [self.btnDecline autoCenterInSuperview];
        
    }
    
    
    
}


@end
