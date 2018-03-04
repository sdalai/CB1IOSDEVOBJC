//
//  SCHEditMeetupViewController.m
//  CounterBean
//
//  Created by Sujit Dalai on 7/2/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHEditMeetupViewController.h"
#import "AppDelegate.h"
#import "SCHBackgroundManager.h"
#import "SCHappointmentSummaryCell.h"
#import <Parse/Parse.h>
#import "SPGooglePlacesAutocompleteDemoViewController.h"
#import "LocationValueTrasformer.h"
#import "SCHSyncManager.h"
#import "SCHLocationSelectorViewController.h"
#import "SCHScheduleTableViewController.h"
#import "SCHActiveViewControllers.h"
#import "SCHNotificationViewController.h"
#import "SCHEmailAndTextMessage.h"
#import "SCHAlert.h"
#import "SCHHomeViewController.h"
#import "SCHUtility.h"
#import "SCHMeetingManager.h"
#import "SCHConstants.h"
#import <KVNProgress/KVNProgress.h>



@interface SCHEditMeetupViewController ()
@property (strong, nonatomic) dispatch_queue_t backgroundQueue;
@property CGFloat rowheight;
@property(nonatomic, strong) XLFormRowDescriptor *appointmentSummary;
@property (nonatomic, strong) XLFormRowDescriptor *timeFromRow;
@property(nonatomic, strong) XLFormRowDescriptor *timeToRow;
@property(nonatomic, strong) XLFormRowDescriptor *locationRow;
@property (nonatomic, strong) SCHBackgroundManager *backgroundTask;
@property (nonatomic) NSTimeInterval defaultduration;




@end

@implementation SCHEditMeetupViewController

UIAlertView *nvavigationAlert;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        [self initializeForm];
        
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeForm];
    }
    return self;
}

- (void)initializeForm{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptorWithTitle:@"Change Meet-up"];
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleAppointmentSummary rowType:@"XLFormRowDescriptorTypeAppointmentSummary"];
    self.appointmentSummary = row;
    
    
    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Time";
    [form addFormSection:section];
    
    
    //Starts
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleFromTime rowType:XLFormRowDescriptorTypeDateTimeInline title:SCHFieldTitleFromTime];
    self.timeFromRow = row;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    
    XLFormDateCell *timeFrom =(XLFormDateCell *) [row cellForFormController:self];
    timeFrom.minimumDate = [SCHUtility startOrEndTime:[NSDate date]];
    timeFrom.minuteInterval = 15;
    
    
    [section addFormRow:row];
    
    
    // Ends
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleToTime rowType:XLFormRowDescriptorTypeDateTimeInline title:SCHFieldTitleToTime];
    self.timeToRow = row;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    XLFormDateCell *timeTo = (XLFormDateCell *) [row cellForFormController:self];
    NSTimeInterval defaultDuration = SCHTimeBlockDuration;
    timeTo.minuteInterval = 15;
    timeTo.minimumDate = [NSDate dateWithTimeInterval:defaultDuration sinceDate:timeFrom.minimumDate];
    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"location";
    [form addFormSection:section];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleLocation rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleLocation];
    self.locationRow = row;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    NSArray* userPreviousLocations = [SCHUtility getUserLocations:appDelegate.user];
    if(userPreviousLocations.count>0)
        row.action.viewControllerClass =[SCHLocationSelectorViewController class]; //
    else
        row.action.viewControllerClass =[SPGooglePlacesAutocompleteDemoViewController class];
    
    row.valueTransformer = [LocationValueTrasformer class];
    //row.value = @"test";
    [section addFormRow:row];
    
    
      self.form = form;

    
}

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue
{    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    if ([rowDescriptor isEqual:self.timeFromRow] && oldValue != newValue){
        [self resetTime:(NSDate *)newValue];
        
    } else if ([rowDescriptor isEqual:self.timeToRow] && oldValue != newValue){
        
        NSDate *endtime = newValue;
        
        self.defaultduration = [endtime timeIntervalSinceDate:(NSDate *)self.timeFromRow.value];
        
    }
    
    
    
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    self.navigationItem.leftBarButtonItem.title = @"";
    // [self setMinimumAndMaximumDuration:nil];
    
    
    
    UIBarButtonItem *addSPNewApptButton = [[UIBarButtonItem alloc]
                                           
                                           
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                           
                                           
                                           target:self action:@selector(CancelAction)];
    
    self.navigationItem.leftBarButtonItem = addSPNewApptButton;
    
        [self.locationRow setValue:@{@"address" : self.meeting.location}];
        self.defaultduration = [self.meeting.endTime timeIntervalSinceDate:self.meeting.startTime];
    self.timeFromRow.value = self.meeting.startTime;
   // [self resetTime:self.meeting.startTime];
    self.timeToRow.value = self.meeting.endTime;

    
    
}

-(void)internetConnectionChanged{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.serverReachable){
        [self.navigationController popToRootViewControllerAnimated:YES];
        // [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
}
-(void)CancelAction
{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)resetTime:(NSDate *) timeFromDate{
    XLFormDateCell *timeToCell = (XLFormDateCell *) [self.timeToRow cellForFormController:self];
    

    timeToCell.minimumDate = [NSDate dateWithTimeInterval:SCHTimeBlockDuration sinceDate:timeFromDate];
    NSDate *timeTo = [NSDate dateWithTimeInterval:self.defaultduration sinceDate:timeFromDate];
    
    self.timeToRow.value = timeTo;
    [timeToCell update];
    
    
}

- (IBAction)SaveMeetupChange:(UIBarButtonItem *)sender {
     XLFormRowDescriptor *row = [self.formValues valueForKey:SCHFieldTitleLocation] ;
    NSString *currentLocation = self.meeting.location;
    NSString *locationFieldValue = [row isKindOfClass:[NSNull class]]? NULL:[row valueForKey:@"address"];
    NSString *proposedChangeLocation = ([locationFieldValue isEqualToString:currentLocation])? NULL : locationFieldValue;
    
    NSDate *proposedChangeTimeFrom = ([self.formValues valueForKey:SCHFieldTitleFromTime] != NULL) ?  (NSDate *)[self.formValues valueForKey:SCHFieldTitleFromTime] : NULL;
    NSDate *proposedChangeTimeTo = ([self.formValues valueForKey:SCHFieldTitleToTime] != NULL) ? (NSDate *)[self.formValues valueForKey:SCHFieldTitleToTime] : NULL;
    
    // check if proposed values are same as appointment. If so thn return without doing anything
    
    NSDate *meetupTimeFrom = self.meeting.startTime;
    
    
    NSDate *meetupTimeTo = self.meeting.endTime;
    
    NSString *proposedLocationForComparision = (proposedChangeLocation)? proposedChangeLocation : currentLocation;
    
    if (([meetupTimeFrom compare:proposedChangeTimeFrom] == NSOrderedSame) && ([meetupTimeTo compare:proposedChangeTimeTo] == NSOrderedSame) && [proposedLocationForComparision isEqualToString:currentLocation]){
        return;
    }
    
    
    
    if ([meetupTimeFrom compare:proposedChangeTimeFrom] == NSOrderedSame  && [meetupTimeTo compare:proposedChangeTimeTo] == NSOrderedSame){
        proposedChangeTimeFrom = nil;
        proposedChangeTimeTo = nil;
    }
    
    // submit request to change
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
    
    if (appDelegate.serverReachable){
        [SCHUtility showProgressWithMessage:SCHProgressMessageGeneric];
        [appDelegate.objectsForProcessing addObjectsToProcessingQueue:self.meeting];
        appDelegate.scheduledManager.scheduleEventsChanged = YES;
        appDelegate.scheduledManager.notificationChanged = YES;
        [backgroundManager beginBackgroundTask];
        dispatch_async(backgroundManager.SCHSerialQueue, ^{
            
            
            
            
            if ([appDelegate.user isEqual:self.meeting.organizer]){
                NSDictionary *output = [SCHMeetingManager changeMeetingByOrganizer:self.meeting
                                                                  changedStartTime:proposedChangeTimeFrom
                                                                    changedEndTime:proposedChangeTimeTo
                                                                   changedLocation:proposedChangeLocation];
                if (output){
                    NSArray *textList = [output valueForKey:@"nonUsetTextList"];
                    NSArray *emailList = [output valueForKey:@"nonUserEmailList"];
                    [SCHSyncManager syncUserData:self.meeting.startTime];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SCHSyncManager syncBadge];
                    });
                    

                    if (textList.count > 0 && emailList.count > 0){
                        [SCHMeetingManager sendEmailAndText:self.meeting emailList:emailList textList:textList messageType:kMeetingCancellationNotification];
                    } else if (textList.count > 0 && emailList.count == 0){
                        [SCHMeetingManager sendTextMessage:self.meeting textList:textList messageType:kMeetingCancellationNotification];
                    } else if (textList.count == 0 && emailList.count > 0){
                        [SCHMeetingManager sendEmail:self.meeting emailList:emailList messageType:kMeetingCancellationNotification];
                    }


                    
                } else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        nvavigationAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                      message:@"Change request couldn't be processed. Try again."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"Ok"
                                                            otherButtonTitles:nil];
                        [nvavigationAlert show];
                    });
                    
                    
                }

                
                
                
            }else{
                if ([SCHMeetingManager changeMeetingRequest:self.meeting
                                              requester:appDelegate.user
                                                 CRType:SCHMeetupCRTypeChangeLocationOrTime
                                            newInvitees:nil
                                       changedStartTime:proposedChangeTimeFrom
                                         changedEndTime:proposedChangeTimeTo
                                            changedLocation:proposedChangeLocation]){
                    
                    [SCHSyncManager syncUserData:self.meeting.startTime];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        nvavigationAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                      message:[NSString localizedStringWithFormat:@"%@ has been notified.", self.meeting.organizer.preferredName]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"Ok"
                                                            otherButtonTitles:nil];
                        [nvavigationAlert show];
                        
                        
                        [SCHSyncManager syncBadge];
                    });
                } else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        nvavigationAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                      message:@"Change request couldn't be processed. Try again."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"Ok"
                                                            otherButtonTitles:nil];
                        [nvavigationAlert show];
                    });
                    
                }
                
                
            }
            

            [appDelegate.objectsForProcessing removeObjectsFromProcessingQueue:self.meeting];

            [KVNProgress dismissWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    
                    NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithObjects:self.navigationController.viewControllers[0], nil];
                    
                    UIViewController *firstVC = navigationArray[0];
                    
                    self.navigationController.viewControllers = navigationArray;
                    
                    
                    UITabBarController *tabBar =  firstVC.navigationController.tabBarController;
                    [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
                    
                });

            }];
            [appDelegate.backgroundManager endBackgroundTask];
            
            
    
            
        });
        
        
        
    }else{
        [SCHAlert internetOutageAlert];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

    
    
}



@end
