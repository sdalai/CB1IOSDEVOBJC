//
//  SCHEditAppointmentViewController.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/28/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHEditAppointmentViewController.h"
#import "XLForm.h"
#import <Parse/Parse.h>
#import "SCHService.h"
#import "SCHServiceOffering.h"
#import "SCHUtility.h"
#import "SCHAppointmentManager.h"
#import "SCHBackgroundManager.h"
#import "SCHAppointmentSeries.h"
#import "SPGooglePlacesAutocompleteDemoViewController.h"
#import "LocationValueTrasformer.h"
#import "SCHSyncManager.h"
#import "SCHServiceProviderAvailabilityViewController.h"
#import "AppDelegate.h"
#import "SCHLocationSelectorViewController.h"
#import "SCHScheduleTableViewController.h"
#import "SCHActiveViewControllers.h"
#import "SCHNotificationViewController.h"
#import "SCHEmailAndTextMessage.h"
#import "SCHAlert.h"
#import "SCHHomeViewController.h"
#import "SCHScheduledEventManager.h"
#import <KVNProgress/KVNProgress.h>





@interface SCHEditAppointmentViewController () 

@property (strong, nonatomic) dispatch_queue_t backgroundQueue;
@property CGFloat rowheight;
@property(nonatomic, strong) XLFormSectionDescriptor *section1;
@property(nonatomic, strong) XLFormRowDescriptor *appointmentSummary;
@property (nonatomic, strong) XLFormRowDescriptor *timeFromRow;
@property(nonatomic, strong) XLFormRowDescriptor *timeToRow;
@property(nonatomic, strong) XLFormRowDescriptor *locationRow;
@property (nonatomic, strong) XLFormRowDescriptor *note;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic) NSTimeInterval minimumDuration;
@property (nonatomic) NSTimeInterval maximumDuration;
@property (nonatomic) NSTimeInterval currentDuration;


@end

@implementation SCHEditAppointmentViewController

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





- (void)initializeForm
{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptorWithTitle:@"Edit"];
    
    section = [XLFormSectionDescriptor formSection];
    self.section1 = section;
    [form addFormSection:section];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleAppointmentSummary rowType:@"XLFormRowDescriptorTypeAppointmentSummary"];
    self.appointmentSummary = row;

    
    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Propose Time";
    [form addFormSection:section];
    
    
    //Starts
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleFromTime rowType:XLFormRowDescriptorTypeDateTimeInline title:SCHFieldTitleFromTime];
    self.timeFromRow = row;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    
   // XLFormDateCell *timeFrom =(XLFormDateCell *) [row cellForFormController:self];
    //Set XLform date cell properties
    // timeFrom. = [SCHUtility dateFormatterForFromTime];
   // timeFrom.minimumDate = [SCHUtility startOrEndTime:[NSDate date]];
   // timeFrom.minuteInterval = 15;
    
   // row.value = timeFrom.minimumDate;
    [section addFormRow:row];
    
    
    // Ends
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleToTime rowType:XLFormRowDescriptorTypeTimeInline title:SCHFieldTitleToTime];
    self.timeToRow = row;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    
    //XLFormDateCell *timeTo = (XLFormDateCell *) [row cellForFormController:self];
    //  timeTo.dateFormatter = [SCHUtility dateFormatterForToTime];
   // timeTo.minuteInterval = 15;
   // NSTimeInterval defaultDuration = 60*60;
  //  NSTimeInterval maximumDuration = 8*60*60;
  //  timeTo.minimumDate = [NSDate dateWithTimeInterval:defaultDuration sinceDate:timeFrom.minimumDate];
   // timeTo.maximumDate = [NSDate dateWithTimeInterval:maximumDuration sinceDate:timeFrom.minimumDate];
   // row.value = timeTo.minimumDate;
    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Propose location";
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
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Note";
    [form addFormSection:section];
    
    // Notes
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleNote rowType:XLFormRowDescriptorTypeTextView];
    [row.cellConfigAtConfigure setObject:@"Notes" forKey:@"textView.placeholder"];
    self.note = row;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textView.textColor"];

    [section addFormRow:row];
    
    
    // Delete Appointment
    section = [XLFormSectionDescriptor formSection];

    [form addFormSection:section];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"deleteApplointment" rowType:XLFormRowDescriptorTypeButton title:@"Cancel Appointment"];
    [row.cellConfig setObject:[UIColor redColor] forKey:@"textLabel.textColor"];
    
   row.action.formSelector = @selector(deleteAppointment);
    
    [section addFormRow:row];

    
    
    self.form = form;

    


}
#pragma mark - Alert View Delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    
        if (buttonIndex==1){
            [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            if (appDelegate.serverReachable){
                [appDelegate.objectsForProcessing addObjectsToProcessingQueue:self.appointment];
                appDelegate.scheduledManager.scheduleEventsChanged = YES;
                appDelegate.scheduledManager.notificationChanged = YES;
               // [SCHUtility showProgressWithMessage:@"Cancelling Appointment"];

                
                [self beginBackgroundTask];
                dispatch_async(self.backgroundQueue, ^{
                    
                    [SCHAppointmentManager deleteAppointment:self.appointment refreshAvailability:YES save:YES];
                    
                    SCHObjectsForProcessing *objectsForProcessing = [SCHObjectsForProcessing sharedManager];
                    [objectsForProcessing removeObjectsFromProcessingQueue:self.appointment];
                    [SCHSyncManager syncUserData:(self.appointment.proposedStartTime) ? self.appointment.proposedStartTime : self.appointment.startTime];
                    
                    [SCHUtility completeProgress];
                    [self endBackgroundTask];

                    // send notification to non user
                    
                    [self.appointment fetch];
                    
                    if (self.appointment.nonUserClient){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            SCHEmailAndTextMessage *emailAndMessage = [SCHEmailAndTextMessage sharedManager];
                            SCHAppointment *appointment = self.appointment;
                            
                            SCHNonUserClient *nonUserClient = appointment.nonUserClient;
                            if (nonUserClient.email){
                                emailAndMessage.emailAlertaddresses = @[nonUserClient.email];
                            }
                            
                            emailAndMessage.textAlertPhoneNumbers = @[nonUserClient.phoneNumber];
                            
                            emailAndMessage.textAlertMessage = [NSString stringWithFormat:@"%@ cancelled a CounterBean appointment with you\n%@", appointment.serviceProvider.preferredName, [SCHAppointmentManager messageBody:appointment]];
                            emailAndMessage.emailAlertMessage = [SCHAppointmentManager messageBody:appointment];
                            emailAndMessage.emailSubject = [NSString stringWithFormat:@"%@ cancelled a CounterBean appointment with you", appointment.serviceProvider.preferredName];
                            
                            
                            //Show Alert
                            
                            if (nonUserClient.email.length > 0){
                                NSString *alterMessage = [NSString stringWithFormat:@"%@ is not a user of CounterBean.", appointment.clientName];
                                emailAndMessage.emailOrTextAlert = [[UIAlertView alloc] initWithTitle:@"Notify Client" message:alterMessage delegate:emailAndMessage cancelButtonTitle:@"Cancel" otherButtonTitles:@"email", @"Text", nil];
                                [emailAndMessage.emailOrTextAlert show];
                            } else {
                                NSString *alterMessage = [NSString stringWithFormat:@"%@ is not a user of CounterBean.", appointment.clientName];
                                emailAndMessage.textAlert = [[UIAlertView alloc] initWithTitle:@"Notify Client" message:alterMessage delegate:emailAndMessage cancelButtonTitle:@"Cancel" otherButtonTitles:@"Text", nil];
                                [emailAndMessage.textAlert show];
                                
                            }
                            
                            
                        });
                        
                        
                    }
                    

                });
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    
                    NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithObjects:self.navigationController.viewControllers[0], nil];
                    
                    UIViewController *firstVC = navigationArray[0];
                    
                    self.navigationController.viewControllers = navigationArray;
                    
                    
                    UITabBarController *tabBar =  firstVC.navigationController.tabBarController;
                    [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
                    
                });

            }else{
                [SCHAlert internetOutageAlert];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }

        }
        
}



#pragma mark - Delete Appointment

-(void)deleteAppointment{
    
    UIAlertView *confirmationAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean" message:@"Cancel Appointment?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
    
    [confirmationAlert show];

}
#pragma mark - XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue
{    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleFromTime]){
        if (oldValue != newValue){
           // [self setStartTimeCell];
            if ([appDelegate.user isEqual:self.appointment.client]){
                if (self.selectedAvailabilityForAppointment){
                    NSTimeInterval duration = [self.selectedAvailabilityForAppointment.endTime timeIntervalSinceDate:newValue];
                    if (!self.appointment.serviceOffering.fixedDuration){
                        if (duration < self.minimumDuration){
                            self.maximumDuration = self.minimumDuration;
                        } else {
                            self.maximumDuration = duration;
                        }
                    }
                    
                    [self forClientSetFromTime:NO setToTime:YES];
                }

            } else{
                [self forSPSetFromTime:NO setToTime:YES];
            }
        }
    }
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleToTime]){
        if (oldValue != newValue){
       // [self setEndTimeCell];
            
            if([appDelegate.user isEqual:self.appointment.client]){
                NSTimeInterval duration = [newValue timeIntervalSinceDate:self.timeFromRow.value];
                [self resetCurrentDuration:duration];
            } else{
                NSTimeInterval duration = [newValue timeIntervalSinceDate:self.timeFromRow.value];
                [self resetCurrentDuration:duration];
            }
        }
    }
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification 
                                               object:nil];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.backgroundQueue = [SCHBackgroundManager sharedManager].SCHSerialQueue;
    [self setMinimumAndMaximumDuration:self.appointment.serviceOffering];
    
    self.timeFromRow.value = (self.appointment.proposedStartTime == NULL || [self.appointment.proposedStartTime isEqual:[NSNull null]] )?  self.appointment.startTime : self.appointment.proposedStartTime;
    
    
    if ([appDelegate.user isEqual:self.appointment.client]){
        self.timeToRow.value = (self.appointment.proposedEndTime) ? self.appointment.proposedEndTime : self.appointment.endTime;
    } else{
        [self forSPSetFromTime:YES setToTime:NO];
    }

    
    
    [self.locationRow setValue:@{@"address" : (self.appointment.proposedLocation) ? self.appointment.proposedLocation : self.appointment.location}];
    
    

    self.note.value = @"";
    
    
    if (!self.selectedAvailabilityForAppointment && [appDelegate.user isEqual:self.appointment.client]){
        self.timeFromRow.disabled = @YES;
        self.timeToRow.disabled = @YES;
    }
    
    

    
}

-(void)internetConnectionChanged{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.serverReachable){
        [SCHAlert internetOutageAlert];
        [self.navigationController popToRootViewControllerAnimated:YES];
       // [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
}



- (IBAction)saveAppointmentChange:(UIBarButtonItem *)sender {
    
    // get all the values
    
    XLFormRowDescriptor *row = [self.formValues valueForKey:SCHFieldTitleLocation] ;
    
  //  NSString * selectedLocation = [[self.formValues valueForKey:SCHFieldTitleLocation] valueData];
    
  //  NSLog(@"Selected Location: %@", selectedLocation);
    
    NSString *currentLocation = (self.appointment.proposedLocation) ? self.appointment.proposedLocation : self.appointment.location;
    NSString *locationFieldValue = [row isKindOfClass:[NSNull class]]? NULL:[row valueForKey:@"address"];
    NSString *proposedChangeLocation = ([locationFieldValue isEqualToString:currentLocation])? NULL : locationFieldValue;
    
    
    
   // NSLog(@"Location : %@",  proposedChangeLocation);
    
   // NSLog(@"appointment Location: %@", currentLocation);
          
    
    NSDate *proposedChangeTimeFrom = ([self.formValues valueForKey:SCHFieldTitleFromTime] != NULL) ?  (NSDate *)[self.formValues valueForKey:SCHFieldTitleFromTime] : NULL;
    NSDate *proposedChangeTimeTo = ([self.formValues valueForKey:SCHFieldTitleToTime] != NULL) ? (NSDate *)[self.formValues valueForKey:SCHFieldTitleToTime] : NULL;
    
    NSString *notes = ([self.formValues valueForKey:SCHFieldTitleNote] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleNote] displayText] : @"";
    
    
    
    
    // check if proposed values are same as appointment. If so thn return without doing anything
    
    NSDate *appointmentTimeFrom = (self.appointment.proposedStartTime)? self.appointment.proposedStartTime : self.appointment.startTime;
    
   // NSDate *appointmentTimeFrom = (self.appointment.proposedStartTime == NULL || [self.appointment.proposedStartTime isEqual:[NSNull null]] )?  self.appointment.startTime : self.appointment.proposedStartTime;
    
    NSDate *appointmentTimeTo = (self.appointment.proposedEndTime) ? self.appointment.proposedEndTime : self.appointment.endTime;
    
    NSString *proposedLocationForComparision = (proposedChangeLocation)? proposedChangeLocation : currentLocation;
    
    if (([appointmentTimeFrom compare:proposedChangeTimeFrom] == NSOrderedSame) && ([appointmentTimeTo compare:proposedChangeTimeTo] == NSOrderedSame) && [proposedLocationForComparision isEqualToString:currentLocation]){
        return;
    }
    
    
    
    if ([appointmentTimeFrom compare:proposedChangeTimeFrom] == NSOrderedSame  && [appointmentTimeTo compare:proposedChangeTimeTo] == NSOrderedSame){
        proposedChangeTimeFrom = nil;
        proposedChangeTimeTo = nil;
    }
    
    
    
    
    // submit request to change
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.serverReachable){
        [appDelegate.objectsForProcessing addObjectsToProcessingQueue:self.appointment];
        appDelegate.scheduledManager.scheduleEventsChanged = YES;
        appDelegate.scheduledManager.notificationChanged = YES;
        [SCHUtility showProgressWithMessage:@"Requesting appointment change"];
        
        [self beginBackgroundTask];
        
        NSString *locationForGeoPoint = (proposedChangeLocation) ? proposedChangeLocation : (self.appointment.proposedLocation)? self.appointment.proposedLocation : self.appointment.location;
        
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        
        [geocoder geocodeAddressString:locationForGeoPoint completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *placeMark = nil;
            
            if (!error) {
                placeMark = [placemarks firstObject];
                
            }
            PFGeoPoint *locationPoint = [PFGeoPoint geoPoint];
            
            if (placeMark){
                locationPoint = [PFGeoPoint geoPointWithLocation:placeMark.location];
            }
            
            dispatch_async(self.backgroundQueue, ^{
                
                // NSLog(@"proposed Start Time: %@", proposedChangeTimeFrom);
                //  NSLog(@"proposed end Time: %@", proposedChangeTimeTo);
                
                
                
                BOOL success = NO;
                
                
                success =[SCHAppointmentManager appointmentChangeRequest:self.appointment
                                                       proposedStartTime:proposedChangeTimeFrom
                                                         proposedEndTime:proposedChangeTimeTo
                                                        proposedLocation:proposedChangeLocation
                                                           locationPoint:locationPoint
                                                                    note:notes];
                
                
                
                
                
                SCHObjectsForProcessing *objectsForProcessing = [SCHObjectsForProcessing sharedManager];
                [objectsForProcessing removeObjectsFromProcessingQueue:self.appointment];
                
                
                [SCHSyncManager syncUserData:proposedChangeTimeTo];
                [KVNProgress dismissWithCompletion:^{
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        
                        NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithObjects:self.navigationController.viewControllers[0], nil];
                        
                        UIViewController *firstVC = navigationArray[0];
                        
                        self.navigationController.viewControllers = navigationArray;
                        
                        
                        UITabBarController *tabBar =  firstVC.navigationController.tabBarController;
                        [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
                        
                    });

                
                }];
                [self endBackgroundTask];
                
                
                
                if (success){
                    [self.appointment fetch];
                    if (self.appointment.nonUserClient){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            SCHEmailAndTextMessage *emailAndMessage = [SCHEmailAndTextMessage sharedManager];
                            SCHAppointment *appointment = self.appointment;
                            SCHNonUserClient *nonUserClient = appointment.nonUserClient;
                            if (nonUserClient.email){
                                emailAndMessage.emailAlertaddresses = @[nonUserClient.email];
                            }
                            
                            emailAndMessage.textAlertPhoneNumbers = @[nonUserClient.phoneNumber];
                            
                            emailAndMessage.textAlertMessage = [NSString stringWithFormat:@"%@ changed a CounterBean appointment with you\n%@", appointment.serviceProvider.preferredName, [SCHAppointmentManager messageBody:appointment]];
                            emailAndMessage.emailAlertMessage = [SCHAppointmentManager messageBody:appointment];
                            emailAndMessage.emailSubject = [NSString stringWithFormat:@"%@ changed a CounterBean appointment with you", appointment.serviceProvider.preferredName];
                            
                            
                            //Show Alert
                            
                            
                            
                            
                            if (nonUserClient.email.length > 0){
                                NSString *alterMessage = [NSString stringWithFormat:@"%@ is not a user of CounterBean. Would like to email or text?", appointment.clientName];
                                emailAndMessage.emailOrTextAlert = [[UIAlertView alloc] initWithTitle:@"Notify Client" message:alterMessage delegate:emailAndMessage cancelButtonTitle:@"Cancel" otherButtonTitles:@"email", @"Text", nil];
                                [emailAndMessage.emailOrTextAlert show];
                            } else {
                                NSString *alterMessage = [NSString stringWithFormat:@"%@ is not a user of CounterBean. Would like to text?", appointment.clientName];
                                emailAndMessage.textAlert = [[UIAlertView alloc] initWithTitle:@"Notify Client" message:alterMessage delegate:emailAndMessage cancelButtonTitle:@"Cancel" otherButtonTitles:@"Text", nil];
                                [emailAndMessage.textAlert show];
                                
                            }
                            
                            
                        });
                        
                        
                    }
                    
                }

                
                
                
            });
            
            
        }];

        

        
 

        
    } else{
        [SCHAlert internetOutageAlert];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    

    
    
    
    
    
    
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // create the parent view that will hold header Label
    if(section==1){
        UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
        
        UILabel *lblStr = [[UILabel alloc]initWithFrame:CGRectMake(12, 8, 150, 20)];
        lblStr.text = @"PROPOSED TIME";
        lblStr.textColor=[UIColor grayColor];
        lblStr.font = [UIFont systemFontOfSize:13];
        [customView addSubview:lblStr];
        
        // create the button object
        UIButton * headerBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-150, 8.0,150-10 , 20.0)];
        headerBtn.backgroundColor = [UIColor clearColor];
        headerBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [headerBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        headerBtn.titleLabel.font = [SCHUtility getPreferredSubtitleFont];//[UIFont boldSystemFontOfSize:13];
        [headerBtn setTitle:@"View Schedule" forState:UIControlStateNormal];
        [headerBtn addTarget:self action:@selector(viewScheduleAction) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:headerBtn];
        return customView;
    }
    return nil;
}

-(void)viewScheduleAction{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        [self performSegueWithIdentifier:@"viewScheduleSegue" sender:self.appointment];

    } else{
        [SCHAlert internetOutageAlert];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Change";
    
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.selectedAvailabilityForAppointment){
        [self.locationRow setValue:@{@"address" : self.selectedAvailabilityForAppointment.location}];
    }
    [self.tableView reloadData];
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.title = SCHBackkButtonTitle;
    self.selectedAvailabilityForAppointment = nil;
    
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"viewScheduleSegue"]){
        SCHAppointment *appointment = sender;
        SCHServiceProviderAvailabilityViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.selectedServiceProvider  = (SCHService *)appointment.service;
        vcToPushTo.CurrentAppointment = appointment;
        vcToPushTo.parent = self;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)changeScheduleTimeToAvaliableSchedule:(NSDate *)from_time
{
   // NSLog(@"avalibility selected");
    self.timeFromRow.value = from_time;
   // self.timeTo.value = to_time;
    [self.tableView reloadData];
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

#pragma  mark - Time Setting

-(void) setMinimumAndMaximumDuration:(SCHServiceOffering *) serviceOffering{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!serviceOffering){
        self.minimumDuration = 0;
        self.maximumDuration = 0;
        self.currentDuration = 0;
        
    } else{
        self.minimumDuration = serviceOffering.defaultDurationInMin*60;
        if(serviceOffering.fixedDuration){
            self.maximumDuration = self.minimumDuration;
            self.currentDuration = self.minimumDuration;
        } else{
            NSDate *currentStartTime = (self.appointment.proposedStartTime == NULL || [self.appointment.proposedStartTime isEqual:[NSNull null]] )?  self.appointment.startTime : self.appointment.proposedStartTime;
            
            NSDate *currentEndTime = (self.appointment.proposedEndTime) ? self.appointment.proposedEndTime : self.appointment.endTime;
            self.currentDuration = [currentEndTime timeIntervalSinceDate:currentStartTime];
            
            if ([self.appointment.serviceProvider isEqual:appDelegate.user]){
                self.maximumDuration = 8*60*60;
            } else{
                if (self.selectedAvailabilityForAppointment){
                    self.maximumDuration = [self.selectedAvailabilityForAppointment.endTime timeIntervalSinceDate:self.selectedAvailabilityForAppointment.startTime];
                } else{
                   self.maximumDuration = self.currentDuration;
                }
                
            }
            
        }
    }
    
    
    
}

-(void)resetWhenNewAvailabilityIsSelected{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.user isEqual:self.appointment.client]){
        [self resetWhenNewAvailabilityIsSelectedForClient];
    } else {
        [self resetWhenNewAvailabilityIsSelectedForSP];
    }
    
    
    
}

-(void)resetWhenNewAvailabilityIsSelectedForSP{
    
    [self forSPSetFromTime:YES setToTime:NO];
    
}

-(void)resetWhenNewAvailabilityIsSelectedForClient{
    self.timeFromRow.disabled = @NO;
    self.timeToRow.disabled = @NO;
    //set minimum and maximum time
    [self setMinimumAndMaximumDuration:self.appointment.serviceOffering];
    NSDate *currentAppointmentStartTime = self.appointment.proposedStartTime ? self.appointment.proposedStartTime : self.appointment.startTime;
    if ([self.selectedAvailabilityForAppointment.startTime compare:currentAppointmentStartTime] == NSOrderedSame){
       [self forClientSetFromTime:YES setToTime:YES];
    } else{
        [self forClientSetFromTime:YES setToTime:NO];
    }
    
    
    
    
}
-(void)forSPSetFromTime:(BOOL) setFromTime setToTime:(BOOL)setToTime{
    NSDate *fromTime = nil;
    NSDate *toTime = nil;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //get current vlaues
    
    
    if (self.timeFromRow.value){
        fromTime = self.timeFromRow.value;
    }
    if (self.timeToRow.value){
        toTime = self.timeToRow.value;
    }
    
    if (setFromTime){
        XLFormDateCell *timeFrom=(XLFormDateCell *) [self.timeFromRow cellForFormController:self];
        if ([appDelegate.user isEqual:self.appointment.serviceProvider]){
            timeFrom.minimumDate = [SCHUtility startOrEndTime:[NSDate date]];
            timeFrom.minuteInterval = SCHTimeBlockDuration/60;
            
            
        
            
            if (self.selectedAvailabilityForAppointment){
                self.timeFromRow.value = self.selectedAvailabilityForAppointment.startTime;
               // [self resetCurrentDuration:self.currentDuration];
                //self.timeToRow.value = [fromTime dateByAddingTimeInterval:self.currentDuration];
                
            }
            
            [timeFrom update];
            
            fromTime = self.timeFromRow.value;
            
            
        }
    }
    
    if (setToTime){
       XLFormDateCell *timeTo = (XLFormDateCell *) [self.timeToRow cellForFormController:self];
        if ([appDelegate.user isEqual:self.appointment.serviceProvider]){
           timeTo.minuteInterval = SCHTimeBlockDuration/60;
            timeTo.minimumDate = [NSDate dateWithTimeInterval:self.minimumDuration sinceDate:fromTime];
            timeTo.maximumDate = [NSDate dateWithTimeInterval:self.maximumDuration sinceDate:fromTime];
            
            // reset current duration
            [self resetCurrentDuration:self.currentDuration];
            self.timeToRow.value = [fromTime dateByAddingTimeInterval:self.currentDuration];
            
        }
        [timeTo update];
        toTime = self.timeToRow.value;
        
    }
    
}


-(void)forClientSetFromTime:(BOOL) setFromTime setToTime:(BOOL)setToTime {
    NSDate *fromTime = nil;
    NSDate *toTime = nil;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    
    //get current vlaues
    
    
    if (self.timeFromRow.value){
        fromTime = self.timeFromRow.value;
    }
    if (self.timeToRow.value){
        toTime = self.timeToRow.value;
    }
    
    
    if (setFromTime){
        //min interval, minimum time, maximum time
        //set timeFrom Parameters
        XLFormDateCell *timeFrom=(XLFormDateCell *) [self.timeFromRow cellForFormController:self];
        
        if ([appDelegate.user isEqual:self.appointment.client]){
            if ([self.selectedAvailabilityForAppointment.startTime compare:[NSDate dateWithTimeInterval:-self.minimumDuration sinceDate:self.selectedAvailabilityForAppointment.endTime]] == NSOrderedAscending ){
                timeFrom.maximumDate =[NSDate dateWithTimeInterval:-self.minimumDuration sinceDate:self.selectedAvailabilityForAppointment.endTime];
                timeFrom.minimumDate = self.selectedAvailabilityForAppointment.startTime;
                
                
            } else {
                timeFrom.maximumDate = self.selectedAvailabilityForAppointment.startTime;
                timeFrom.minimumDate = self.selectedAvailabilityForAppointment.startTime;
            }
            timeFrom.minuteInterval = SCHTimeBlockDuration/60;
            self.timeFromRow.value = timeFrom.minimumDate;
            
        }
        [timeFrom update];
        
        fromTime = self.timeFromRow.value;
    }
    
    if (setToTime){
        XLFormDateCell *timeTo = (XLFormDateCell *) [self.timeToRow cellForFormController:self];
        if ([appDelegate.user isEqual:self.appointment.client]){
            timeTo.minuteInterval = SCHTimeBlockDuration/60;
            if ([[NSDate dateWithTimeInterval:self.minimumDuration sinceDate:fromTime] compare:self.selectedAvailabilityForAppointment.endTime] == NSOrderedAscending){
                timeTo.minimumDate = [NSDate dateWithTimeInterval:self.minimumDuration sinceDate:fromTime];
                timeTo.maximumDate =self.selectedAvailabilityForAppointment.endTime;
            } else{
                timeTo.maximumDate =self.selectedAvailabilityForAppointment.endTime;
                timeTo.minimumDate = self.selectedAvailabilityForAppointment.endTime;
            }
            
            // reset current duration
            [self resetCurrentDuration:self.currentDuration];
            self.timeToRow.value = [fromTime dateByAddingTimeInterval:self.currentDuration];
            
        }
        
        [timeTo update];
        toTime = self.timeToRow.value;
        
    }
    
    
    
    
}

-(void)resetCurrentDuration:(NSTimeInterval)currentDuration{
    if (currentDuration < self.minimumDuration){
        self.currentDuration = self.minimumDuration;
    }else if (currentDuration > self.maximumDuration){
        self.currentDuration = self.maximumDuration;
    }else {
        self.currentDuration = currentDuration;
    }
}








-(void)setStartTimeCell{
 
    XLFormDateCell *timeFromCell =(XLFormDateCell *) [self.timeFromRow cellForFormController:self];
    timeFromCell.minimumDate = [SCHUtility startOrEndTime:[NSDate date]];
    timeFromCell.minuteInterval = SCHTimeBlockDuration/60;
    
    [timeFromCell update];

    
    if (!self.timeToRow.value){
        self.timeToRow.value = [NSDate dateWithTimeInterval:self.currentDuration sinceDate:self.timeFromRow.value];
        XLFormDateCell *timeToCell = (XLFormDateCell *) [self.timeToRow cellForFormController:self];
        timeToCell.minuteInterval = SCHTimeBlockDuration/60;
        
        timeToCell.minimumDate = [NSDate dateWithTimeInterval:self.minimumDuration sinceDate:self.timeFromRow.value];
        timeToCell.maximumDate = [NSDate dateWithTimeInterval:self.maximumDuration sinceDate:self.timeFromRow.value];
        [timeToCell update];
    } else {
        NSDate *formTime = self.timeFromRow.value;
        NSDate *toTime = self.timeToRow.value;
        
        NSTimeInterval duration = [toTime timeIntervalSinceDate:formTime];
        if (duration < self.minimumDuration){
            toTime = [NSDate dateWithTimeInterval:self.minimumDuration sinceDate:self.timeFromRow.value];
        }else if (duration > self.maximumDuration){
            toTime = [NSDate dateWithTimeInterval:self.maximumDuration sinceDate:self.timeFromRow.value];
        }
        self.timeToRow.value = toTime;
        XLFormDateCell *timeToCell = (XLFormDateCell *) [self.timeToRow cellForFormController:self];
        timeToCell.minuteInterval = SCHTimeBlockDuration/60;
        
        timeToCell.minimumDate = [NSDate dateWithTimeInterval:self.minimumDuration sinceDate:self.timeFromRow.value];
        timeToCell.maximumDate = [NSDate dateWithTimeInterval:self.maximumDuration sinceDate:self.timeFromRow.value];
        [timeToCell update];
    }
    
    
}

/*

-(void)setEndTimeCell{
    
    XLFormDateCell *timeToCell = (XLFormDateCell *) [self.timeTo cellForFormController:self];
    if (!self.timeFrom.value){
        timeToCell.minuteInterval = SCHTimeBlockDuration/60;
        timeToCell.minimumDate = self.timeTo.value;
        [timeToCell update];
    } else{
        NSDate *formTime = self.timeFrom.value;
        NSDate *toTime = self.timeTo.value;
        
        NSTimeInterval duration = [toTime timeIntervalSinceDate:formTime];
        if (duration < self.minimumDuration){
            toTime = [NSDate dateWithTimeInterval:self.minimumDuration sinceDate:self.timeFrom.value];
        }else if (duration > self.maximumDuration){
            toTime = [NSDate dateWithTimeInterval:self.maximumDuration sinceDate:self.timeFrom.value];
        }
        self.timeTo.value = toTime;
        XLFormDateCell *timeToCell = (XLFormDateCell *) [self.timeTo cellForFormController:self];
        timeToCell.minuteInterval = SCHTimeBlockDuration/60;
        
        timeToCell.minimumDate = [NSDate dateWithTimeInterval:self.minimumDuration sinceDate:self.timeFrom.value];
        timeToCell.maximumDate = [NSDate dateWithTimeInterval:self.maximumDuration sinceDate:self.timeFrom.value];
        [timeToCell update];
    }
    
    
}
 
 */



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.serverReachable){
        id cell =[tableView cellForRowAtIndexPath:indexPath];
        
        if ([self.appointment.client isEqual:appDelegate.user]){
            if ([cell isKindOfClass:[XLFormDateCell class]] ){
                XLFormDateCell *fromOrToCell = cell;
                if ([fromOrToCell.textLabel.text isEqualToString:SCHFieldTitleFromTime]||[fromOrToCell.textLabel.text isEqualToString:SCHFieldTitleToTime]){
                    
                   // NSLog(@"%d", [self.timeFromRow.disabled boolValue]);
                  //  NSLog(@"%d", [self.timeToRow.disabled boolValue]);
                    
                    if ([self.timeFromRow.disabled boolValue] || [self.timeToRow.disabled boolValue]){
                        
                        [self performSegueWithIdentifier:@"viewScheduleSegue" sender:self.appointment];
                        
                    } else {
                        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
                    }
                } else {
                    [super tableView:tableView didSelectRowAtIndexPath:indexPath];;
                }
                
                
            } else {
                [super tableView:tableView didSelectRowAtIndexPath:indexPath];
            }
            
        } else{
            [super tableView:tableView didSelectRowAtIndexPath:indexPath];
        }
        
    } else{
        [SCHAlert internetOutageAlert];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    
    
}



-(void) removefromProcessingQueue{
    SCHObjectsForProcessing *objectsForProcessing = [SCHObjectsForProcessing sharedManager];
    [objectsForProcessing removeObjectsFromProcessingQueue:self.appointment];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
