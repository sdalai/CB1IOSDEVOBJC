//
//  SCHNewAppointmentBySPViewController.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 4/4/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHNewAppointmentBySPViewController.h"
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
#import "SCHLocationSelectorViewController.h"
#import "SCHClientListViewController.h"
#import "ClientValueTransformer.h"
#import "SCHServiceProviderAvailabilityViewController.h"
#import "SCHActiveViewControllers.h"
#import "SCHScheduleTableViewController.h"
#import "SCHNotificationViewController.h"
#import "SCHEmailAndTextMessage.h"
#import "AppDelegate.h"
#import "SCHAlert.h"
#import "SCHUser.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
#import <KVNProgress/KVNProgress.h>

static SCHServiceOffering *serviceOffering = NULL;
static BOOL debug = NO;

@interface SCHNewAppointmentBySPViewController ()<CNPPopupControllerDelegate>

@property (nonatomic, strong) CNPPopupController *popupController;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) dispatch_queue_t backgroundQueue;
@property (strong, nonatomic) NSArray* contactList ;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic) NSTimeInterval minimumDuration;
@property (nonatomic) NSTimeInterval maximumDuration;
@property (nonatomic) NSTimeInterval currentDuration;






@end

@implementation SCHNewAppointmentBySPViewController
SCHService *selectedService;
UIButton * headerBtn;



#pragma mark - XLform



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
    
    form = [XLFormDescriptor formDescriptorWithTitle:SCHSCreenTitleNewAppointment];
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Service";
    [form addFormSection:section];

    [form addFormSection:section];
    
    //For Service
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleService rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleService];
    row.selectorTitle = SCHSelectorTitleServiceList;
    row.required = YES;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.selectorOptions = [SCHUtility servicelist];
    self.serviceRow = row;
    [section addFormRow:row];
    
    // For service offering
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleServiceType rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleServiceType];
    row.disabled = @YES;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.selectorTitle = SCHSelectorTitleServiceTypeList;
    XLFormRowDescriptor *serviceRow = [self.form formRowWithTag:SCHFieldTitleService];
    if (serviceRow.valueData){
        row.selectorOptions =[SCHUtility serviceOfferingList:(SCHService *)serviceRow.valueData];
    }
    self.serviceOfferingRow = row;
    
    row.required = YES;
    [section addFormRow:row];
    
    
    //Location

    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleLocation rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleLocation];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    
   NSArray* userPreviousLocations = [SCHUtility getUserLocations:appDelegate.user];
    if(userPreviousLocations.count>0)
          row.action.viewControllerClass =[SCHLocationSelectorViewController class]; //
    else
        row.action.viewControllerClass =[SPGooglePlacesAutocompleteDemoViewController class];
    
    
    row.valueTransformer = [LocationValueTrasformer class];
    
    self.locationRow = row;
  
    [section addFormRow:row];
    
    //Client
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleClient rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleClient];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.required = YES;
//    row.action.viewControllerClass =[SCHClientListViewController class]; //
    row.action.viewControllerStoryboardId = @"clientList";
    row.valueTransformer = [ClientValueTransformer class];
    
    self.clientRow= row;
    
    [section addFormRow:row];
  
    
    //start and End Time Row
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Time";
    [form addFormSection:section];
    
    
    //Starts
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleFromTime rowType:XLFormRowDescriptorTypeDateTimeInline title:SCHFieldTitleFromTime];
    
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    
    row.disabled = @YES;
    
    self.StartTimeRow = row;
    [section addFormRow:row];
    
    
    // Ends
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleToTime rowType:XLFormRowDescriptorTypeTimeInline title:SCHFieldTitleToTime];
    
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.disabled = @YES;
    self.endTimeRow = row;
    [section addFormRow:row];
    
    // Repeat Section
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHScreenSectionTitleRepeatation;
    section.hidden = @NO;
    
    [form addFormSection:section];
    
    // Repeat Row
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleRepeat rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleRepeat];
    row.value = SCHSelectorRepeatationOptionNever;
    row.selectorOptions = @[SCHSelectorRepeatationOptionNever,
                            SCHSelectorRepeatationOptionEveryDay,
                            SCHSelectorRepeatationOptionEveryWeek,
                            SCHSelectorRepeatationOptionEvery2Weeks,
                            SCHSelectorRepeatationOptionEveryMonth,
                            SCHSelectorRepeatationOptionSpectficDaysOftheWeek];
    row.selectorTitle = SCHSelectorTitleRepeat;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    
    self.repeatDaysRow = row;
    
    [section addFormRow:row];
    
    // Repeat Row
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleRepeatDays rowType:XLFormRowDescriptorTypeMultipleSelector title:SCHFieldTitleRepeatDays];
    row.disabled = @YES;
    row.selectorTitle = SCHSelectorTitleRepeatDay;
    row.selectorOptions = @[SCHSelectorRepeatationOptionSunday,
                            SCHSelectorRepeatationOptionMonday,
                            SCHSelectorRepeatationOptionTuesday,
                            SCHSelectorRepeatationOptionWednesday,
                            SCHSelectorRepeatationOptionThursday,
                            SCHSelectorRepeatationOptionFriday,
                            SCHSelectorRepeatationOptionSaturday];
    
    self.repeatDaysRow = row;
    
    
    [section addFormRow:row];
    
    
    
    // End date
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleEndDate rowType:XLFormRowDescriptorTypeDateInline title:SCHFieldTitleEndDate];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    
    row.disabled = @YES;
        self.endDateRow = row;
    
    [section addFormRow:row];
    

    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Note";
    
    [form addFormSection:section];
    
    // Notes
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleNote rowType:XLFormRowDescriptorTypeTextView];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textView.textColor"];
    [row.cellConfigAtConfigure setObject:@"Notes" forKey:@"textView.placeholder"];
    [section addFormRow:row];
    
    
    
    self.form = form;
   
}



- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // create the parent view that will hold header Label
    if(section==0){
        UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
        // create the button object
        headerBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-150, 32.0,150-10 , 20.0)];
        headerBtn.backgroundColor = [UIColor clearColor];
        headerBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [headerBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        headerBtn.titleLabel.font = [SCHUtility getPreferredSubtitleFont];//[UIFont boldSystemFontOfSize:13];
        [headerBtn setTitle:@"Help" forState:UIControlStateNormal];
        [headerBtn addTarget:self action:@selector(helpAction) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:headerBtn];
        return customView;
        
    }
    else if(section==1){
        UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
        
        UILabel *lblStr = [[UILabel alloc]initWithFrame:CGRectMake(12, 8, 150, 20)];
        lblStr.text = @"TIME";
        lblStr.textColor=[UIColor grayColor];
        lblStr.font = [UIFont systemFontOfSize:13];
        [customView addSubview:lblStr];
        
        // create the button object
        headerBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-150, 8.0,150-10 , 20.0)];
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
    
    [self performSegueWithIdentifier:@"viewScheduleSegue" sender:nil];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"viewScheduleSegue"]){
        SCHServiceProviderAvailabilityViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.selectedServiceProvider  = selectedService;
        vcToPushTo.CurrentAppointment = nil;
        vcToPushTo.parent = self;
    }
}

-(void)changeScheduleTimeToAvaliableSchedule:(NSDate *)from_time location:(NSString *) location
{
   // NSLog(@"avalibility selected");
    self.StartTimeRow.value = from_time;
    
   [self reloadFormRow:self.StartTimeRow];
    
    //change location
    [self.locationRow setValue:@{@"address" : location}];
    [self reloadFormRow:self.locationRow];
}

                                 
    



#pragma mark - XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue
{    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    
    
    
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleService] && oldValue != newValue) {
        
        SCHService *service = ([self.formValues valueForKey:SCHFieldTitleService] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleService] valueData] : NULL;
        if(service!=NULL)
        {
            selectedService = service;
            headerBtn.hidden = false;
        }
        
        // set start Time
        
        self.StartTimeRow.disabled = @NO;
        [self setMinimumAndMaximumDuration:nil];
        
        if (self.availabilityServices){
            NSPredicate *servicePredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *serviceDict, NSDictionary<NSString *,id> * _Nullable bindings) {
                
                if ([[serviceDict valueForKey:@"service"] isEqual:service]){
                    return YES;
                } else return NO;
            }];
            
            
            NSArray *filteredServiceArray = [self.availabilityServices filteredArrayUsingPredicate:servicePredicate];
            if (filteredServiceArray.count >0){
                NSDate *startTime = [filteredServiceArray[0] valueForKey:@"startTime"];
                if ([startTime compare:[NSDate date]] == NSOrderedAscending){
                    self.StartTimeRow.value = [SCHUtility startOrEndTime:[NSDate date]];
                } else{
                    self.StartTimeRow.value = startTime;
                }
                
                
            } else{
                self.StartTimeRow.value = [SCHUtility startOrEndTime:[NSDate date]];
            }
            
        
        } else{
            self.StartTimeRow.value = [SCHUtility startOrEndTime:[NSDate date]];
        }
        
        
        // Enable service Type
        
        XLFormRowDescriptor *serviceType = [self.form formRowWithTag:SCHFieldTitleServiceType];
        serviceType.disabled = @NO;
        NSArray *serviceTypeList = [SCHUtility serviceOfferingList:(SCHService *)[newValue valueData]];
        
        serviceType.selectorOptions = serviceTypeList ;
        
        // If only one service type the assign it
        
        if (serviceTypeList.count == 1){
            XLFormTextFieldCell *serviceTypeRow = (XLFormTextFieldCell *) [serviceType cellForFormController:self];
            
            serviceType.value = (XLFormOptionsObject *)serviceTypeList[0];
           [serviceTypeRow update];
            SCHServiceOffering *serviceOffering = [(XLFormOptionsObject *)serviceTypeList[0] valueData];
            self.currentDuration = serviceOffering.defaultDurationInMin*60;

            
           
        } else{
            XLFormTextFieldCell *serviceTypeRow = (XLFormTextFieldCell *) [serviceType cellForFormController:self];
            
            serviceType.value = (XLFormOptionsObject *)serviceTypeList[0];
            [serviceTypeRow update];
            SCHServiceOffering *serviceOffering = [(XLFormOptionsObject *)serviceTypeList[0] valueData];
             self.currentDuration = serviceOffering.defaultDurationInMin*60;
        }
        
    }
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleServiceType] && oldValue != newValue) {
        SCHServiceOffering *serviceOffering = [newValue valueData];
        [self setMinimumAndMaximumDuration:serviceOffering];
        [self setStartTimeCell];
    
        
    }
    

    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleFromTime]){
        if (oldValue != newValue){
            [self setStartTimeCell];
            
            
        }
    }
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleToTime]){
        if (oldValue != newValue){
           
            
            NSTimeInterval duration = [newValue timeIntervalSinceDate:self.StartTimeRow.value];
            [self resetCurrentDuration:duration];
            
             [self setEndTimeCell];
        }
    }
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleEndDate]){
        if (oldValue != newValue){
            [self setEndDateCell];
        }
    }
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleRepeat]){
        XLFormRowDescriptor *endDate = [self.form formRowWithTag:SCHFieldTitleEndDate];
        XLFormRowDescriptor *repeatDays = [self.form formRowWithTag:SCHFieldTitleRepeatDays];
        
        
        //enable end Date
        if ([[newValue displayText] isEqualToString:SCHSelectorRepeatationOptionNever] ){
            
            endDate.disabled = @YES;
            endDate.value = nil;
            XLFormDateCell *endDateCell = (XLFormDateCell *) [endDate cellForFormController:self];
            [endDateCell update];
            
            
        } else {
            
            endDate.disabled = @NO;
            XLFormDateCell *endDateCell = (XLFormDateCell *) [endDate cellForFormController:self];
            [endDateCell update];
            
            
        }
        //if specific day of the week then allow to enter days
        if ([[newValue displayText] isEqualToString:SCHSelectorRepeatationOptionSpectficDaysOftheWeek] ) {
            repeatDays.disabled = @NO;
            [[repeatDays cellForFormController:self] update];
            
        } else {
            repeatDays.disabled = @YES;
            repeatDays.value = nil;
            [[repeatDays cellForFormController:self] update];
        }
        
        
    }

    
    
    
}

-(NSTimeInterval)defaultDuation:(SCHServiceOffering *) serviceOffering{
    
    NSTimeInterval defaultDuration = serviceOffering.defaultDurationInMin*60;
    
    return defaultDuration;
    
}



#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    // Do any additional setup after loading the view.
    self.backgroundQueue = [SCHBackgroundManager sharedManager].SCHSerialQueue;
    self.client_info_Dict = [[NSDictionary alloc]init];
    self.navigationItem.leftBarButtonItem.title = @"";
   // [self setMinimumAndMaximumDuration:nil];
    


    UIBarButtonItem *addSPNewApptButton = [[UIBarButtonItem alloc]
                                  
                                  
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                  
                                  
                                  target:self action:@selector(CancelAction)];
    
    self.navigationItem.leftBarButtonItem = addSPNewApptButton;
    
   
    
    //add location
    if (self.availabilityLocation){
        //add location
        [self.locationRow  setValue:@{@"address" : self.availabilityLocation}];
    }else{
        //if there is one user location then add it
        PFQuery *locationQuery = [SCHUserLocation query];
        [locationQuery whereKey:@"user" equalTo:appDelegate.user];
        [locationQuery fromLocalDatastore];
        if ([locationQuery countObjects] == 1){
            SCHUserLocation *location = [locationQuery getFirstObject];
             [self.locationRow  setValue:@{@"address" : location.location}];
        }
        
    }
     
    
    
    //Only show applicable services
    if (self.availabilityServices){
        NSMutableArray *serviceList = [[NSMutableArray alloc] init];
        for (NSDictionary *serviceDict in  self.availabilityServices){
            SCHService *service = [serviceDict valueForKey:@"service"];
            XLFormOptionsObject *optionobject = [XLFormOptionsObject formOptionsObjectWithValue:service displayText:service.serviceTitle];
            [serviceList addObject:optionobject];
        }
        if (serviceList.count > 0){
            self.serviceRow.selectorOptions = serviceList;
            
        }
        
    }
    
    //add client
    if (self.client){
        NSString *name;
        if(self.client.client){
            SCHUser *user = self.client.client;
            name = user.preferredName;
            
        }else if(self.client.nonUserClient){
            name = self.client.name;
            
        }
        [self.clientRow setValue:@{@"name": name,@"client":self.client}];
        
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

-(void)CancelAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Appointment with Client";
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
    
    
    
    if (!self.serviceRow.value){
        headerBtn.hidden = true;
        
    } else{
        headerBtn.hidden = false;
    }
    
    
    
    
    if (self.serviceRow.selectorOptions.count  == 1){
        self.serviceRow.value = self.serviceRow.selectorOptions[0];
        [self.tableView reloadData];
    }
    

    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationItem.title = @"";

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

#pragma  mark - Actions

- (IBAction)save:(UIBarButtonItem *)sender {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHService *service = ([self.formValues valueForKey:SCHFieldTitleService] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleService] valueData] : NULL;
    SCHServiceOffering *serviceType = ([self.formValues valueForKey:SCHFieldTitleServiceType] != NULL) ? ((serviceOffering == NULL) ? [[self.formValues valueForKey:SCHFieldTitleServiceType] valueData] : serviceOffering) : NULL;
    XLFormRowDescriptor *row = [self.formValues valueForKey:SCHFieldTitleLocation] ;

    NSString *location =[row isKindOfClass:[NSNull class]]?NULL:[row valueForKey:@"address"];
    
    row = [self.formValues valueForKey:SCHFieldTitleClient];

    SCHServiceProviderClientList *SPClient = [row isKindOfClass:[NSNull class]] ? NULL : [row valueForKey:@"client"];

    NSString *clientName =[row isKindOfClass:[NSNull class]]?NULL:[row valueForKey:@"name"];
    
    
    
    id client = (SPClient.client) ? SPClient.client : SPClient.nonUserClient;
    
    NSString *clientPhone = (SPClient.client) ? SPClient.client.phoneNumber : SPClient.nonUserClient.phoneNumber;
    
    if ([clientPhone isEqualToString:appDelegate.user.phoneNumber]){
        
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Not a Client" message:@"You can not be client of yourself!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [theAlert show];
        return;
        
    }
    
    
    NSDate *timeFrom = ([self.formValues valueForKey:SCHFieldTitleFromTime] != NULL) ?  (NSDate *)[self.formValues valueForKey:SCHFieldTitleFromTime] : NULL;
    NSDate *timeTo = ([self.formValues valueForKey:SCHFieldTitleToTime] != NULL) ? (NSDate *)[self.formValues valueForKey:SCHFieldTitleToTime] : NULL;
    
    NSString *notes = ([self.formValues valueForKey:SCHFieldTitleNote] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleNote] displayText] : @"";
    
    NSString *repeat = [self.formValues valueForKey:SCHFieldTitleRepeat];
    NSDate *endDate = ([repeat isEqualToString:SCHSelectorRepeatationOptionNever]) ? nil: ([self.formValues valueForKey:SCHFieldTitleEndDate] != NULL) ?[self.formValues valueForKey:SCHFieldTitleEndDate]: nil;
    
    NSMutableArray *repeatDays = [[NSMutableArray alloc] init];
    
    if ([repeat isEqualToString:SCHSelectorRepeatationOptionSpectficDaysOftheWeek]) {
        if (![[self.formValues valueForKey:SCHFieldTitleRepeatDays] isEqual:[NSNull null]])  {
            [repeatDays addObjectsFromArray:[self.formValues valueForKey:SCHFieldTitleRepeatDays]];
        }
        
    }

    
    if (debug){
        
        NSLog(@"Input values to launch new appointment Request");
        NSLog(@" Service: %@", service);
        NSLog(@" Service Type: %@", serviceType);
        NSLog(@" Location: %@", location);
        NSLog(@" Client: %@", client);
        NSLog(@" time from : %@", timeFrom);
        NSLog(@" time To : %@", timeTo);
        NSLog(@" Notes : %@", notes);
    }
    
    
    
    if ([self validateDateForService:service
                         serviceType:serviceType
                            location:location
                          clientName:clientName
                              client:client
                            timeFrom:timeFrom
                              timeTo:timeTo
                              repeat:repeat
                          repeatDays:repeatDays
                             endDate:endDate]){
        
        endDate = (endDate == NULL)? timeTo : endDate;
        [SCHUtility showProgressWithMessage:SCHProgressMessageCreateAppointment];
        
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        
        [geocoder geocodeAddressString:location completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *placeMark = nil;
            if (!error) {
                placeMark = [placemarks firstObject];
            }
            PFGeoPoint *locationPoint = [PFGeoPoint geoPoint];
            if (placeMark){
                locationPoint = [PFGeoPoint geoPointWithLocation:placeMark.location];
            }
            dispatch_async(self.backgroundQueue, ^{
                [self beginBackgroundTask];
                
                id newObject = [SCHAppointmentManager  createAppointmentServiceProvider:appDelegate.user
                                                                                service:service
                                                                        serviceOffering:serviceType
                                                                               location:location
                                                                          locationPoint:locationPoint
                                                                                 client:client
                                                                             clientName:clientName
                                                                               timeFrom:timeFrom
                                                                                 timeTo:timeTo
                                                                           repeatOption:repeat
                                                                             repeatDays:repeatDays
                                                                                endDate:endDate
                                                                                  notes:notes];
                
                
                
                
                
                
                
                [SCHUtility createUserLocation:location];
                
                
                [SCHSyncManager syncUserData:timeFrom];
                
                [KVNProgress dismissWithCompletion:^{
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        
                        /*
                         //[self.navigationController popToRootViewControllerAnimated:YES];
                         NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithObjects:self.navigationController.viewControllers[0], nil];
                         
                         UIViewController *firstVC = navigationArray[0];
                         
                         self.navigationController.viewControllers = navigationArray;
                         
                         UITabBarController *tabBar =  firstVC.navigationController.tabBarController;
                         [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
                         
                         */
                        NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithObjects:self.navigationController.viewControllers[0], nil];
                        
                        UIViewController *firstVC = navigationArray[0];
                        
                        self.navigationController.viewControllers = navigationArray;
                        
                        
                        UITabBarController *tabBar =  firstVC.navigationController.tabBarController;
                        [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
                        
                        
                    });

                    
                }];
                [self endBackgroundTask];
                
                
                
                if (newObject){
                    if ([client isKindOfClass:[SCHNonUserClient class]]){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            SCHEmailAndTextMessage *emailAndMessage = [SCHEmailAndTextMessage sharedManager];
                            SCHAppointment *appointment = nil;
                            SCHAppointmentSeries *series = nil;
                            SCHNonUserClient *nonUserClient = client;
                            if (nonUserClient.email){
                                emailAndMessage.emailAlertaddresses = @[nonUserClient.email];
                            }
                            
                            emailAndMessage.textAlertPhoneNumbers = @[nonUserClient.phoneNumber];
                            
                            
                            
                            if ([newObject isKindOfClass:[SCHAppointment class]]){
                                appointment = (SCHAppointment *)newObject;
                                //clientName = appointment.clientName;
                                emailAndMessage.textAlertMessage = [NSString stringWithFormat:@"%@ booked a CounterBean appointment with you\n%@", appointment.serviceProvider.preferredName, [SCHAppointmentManager messageBody:appointment]];
                                emailAndMessage.emailAlertMessage = [SCHAppointmentManager messageBody:appointment];
                                emailAndMessage.emailSubject = [NSString stringWithFormat:@"%@ booked a CounterBean appointment with you", appointment.serviceProvider.preferredName];
                                
                            } else if ([newObject isKindOfClass:[SCHAppointmentSeries class]]){
                                series = newObject;
                                //  clientName = series.clientName;
                                emailAndMessage.textAlertMessage = [NSString stringWithFormat:@"%@ booked CounterBean appointments with you\n%@", series.serviceProvider.preferredName, [SCHAppointmentManager messageBody:series]];
                                emailAndMessage.emailAlertMessage = [SCHAppointmentManager messageBody:series];
                                emailAndMessage.emailSubject = [NSString stringWithFormat:@"%@ booked CounterBean appointments with you", series.serviceProvider.preferredName];
                            }
                            
                            
                            //Show Alert
                            
                            if (nonUserClient.email.length > 0){
                                NSString *alterMessage = [NSString stringWithFormat:@"%@ is not a user of CounterBean.", clientName];
                                emailAndMessage.emailOrTextAlert = [[UIAlertView alloc] initWithTitle:@"Notify Client" message:alterMessage delegate:emailAndMessage cancelButtonTitle:@"Cancel" otherButtonTitles:@"email", @"Text", nil];
                                [emailAndMessage.emailOrTextAlert show];
                            } else {
                                NSString *alterMessage = [NSString stringWithFormat:@"%@ is not a user of CounterBean.", clientName];
                                emailAndMessage.textAlert = [[UIAlertView alloc] initWithTitle:@"Notify Client" message:alterMessage delegate:emailAndMessage cancelButtonTitle:@"Cancel" otherButtonTitles:@"Text", nil];
                                [emailAndMessage.textAlert show];
                                
                            }
                            
                            
                        });
                        
                        
                    }
                    
                }
                
                
               
                
            });

            
        }];

        
        
        
        
        
        

        
        
    } else return;
    
    
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



-(BOOL) validateDateForService:(SCHService *) service serviceType:(SCHServiceOffering *) serviceType location:(NSString *) location clientName:(NSString*)clientName client:(SCHUser *) client timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo repeat:(NSString *) repeat repeatDays:(NSArray *) repeatDays endDate:(NSDate *) endDate {
    BOOL dataValid = NO;
    
    if ([repeat isEqualToString:SCHSelectorRepeatationOptionNever]){
        if (service == NULL || serviceType == NULL || location == NULL || clientName==NULL || client == NULL || timeFrom == NULL || timeTo == NULL){
            if (debug) {
                NSLog(@" All required info not provided");
            }
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Please fill out all the information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            dataValid = NO;
            
        } else dataValid = YES;
        
    } else if ([repeat isEqualToString:SCHSelectorRepeatationOptionSpectficDaysOftheWeek]){
        if (service == NULL || serviceType == NULL || location == NULL ||  clientName==NULL || client == NULL || timeFrom == NULL || timeTo == NULL || [endDate isEqual:[NSNull null]] || repeatDays.count == 0){
            if (debug) {
                NSLog(@" All required info not provided");
            }
            [self showMissingInfoMessage];
            
            dataValid = NO;
            
        } else dataValid = YES;
    } else {
        if (service == NULL || serviceType == NULL || location == NULL ||  clientName==NULL || client == NULL || timeFrom == NULL || timeTo == NULL || [endDate isEqual:[NSNull null]]){
            if (debug) {
                NSLog(@" All required info not provided");
            }
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"please fill out all the information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            dataValid = NO;
            
        } else dataValid = YES;
        
    }
    
    return dataValid;
    
}




-(void) showMissingInfoMessage{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"please fill out all the information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    
}





-(void) clearAllInputValues{
    [self.formValues setValue:NULL forKey:SCHFieldTitleService];
    
    
}

#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    id cell =[tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[XLFormDateCell class]] ){
        XLFormDateCell *fromOrToCell = cell;
        if ([fromOrToCell.textLabel.text isEqualToString:SCHFieldTitleFromTime]||[fromOrToCell.textLabel.text isEqualToString:SCHFieldTitleToTime]) {
            if (!self.serviceOfferingRow.value){
                //show message
                [SCHAlert selectServiceTypeAlert];
                
            } else{
                [super tableView:tableView didSelectRowAtIndexPath:indexPath];
            }
            
            
        } else{
            [super tableView:tableView didSelectRowAtIndexPath:indexPath];
        }
        
        
    } else{
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
    

}

-(void) presentAddressBookPicker {
    switch (ABAddressBookGetAuthorizationStatus()) {
        case kABAuthorizationStatusAuthorized:
            [self accessGrantedForAddressBook];
            break;
        case kABAuthorizationStatusNotDetermined:
            [self requestAccessToAddressBook];
            break;
        case kABAuthorizationStatusRestricted:
        case kABAuthorizationStatusDenied:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"Unable to access address book"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [alert show];
        }
            break;
        default:
            // Unlikely but log it anyway.
           // NSLog(@"Unknown address book status.");
            break;
    }
}

-(void) accessGrantedForAddressBook {
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    [self presentViewController:picker animated:YES completion:nil];
   
}

-(void) requestAccessToAddressBook {
    __weak SCHNewAppointmentBySPViewController* weakSelf = self;
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf accessGrantedForAddressBook];
            });
        }
        
        CFRelease(addressBook);
    });
}



//Needed for iOS 8
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person
{
   // NSLog(@"Went here 1 ...");
    
    [self peoplePickerNavigationController:peoplePicker shouldContinueAfterSelectingPerson:person];
}


//needed for iOS 7 and lower
- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    
    //NSLog(@"Went here 2 ...");
    self.client_info_Dict = [self formateClientInfo:person];
    NSString *firstName = [self.client_info_Dict valueForKey:@"firstName"];
    NSString *lastName = [self.client_info_Dict valueForKey:@"lastName"];
    self.clientRow.value = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
    [self.tableView reloadData];
    return true;
    //add your logic here
    
}


-(NSDictionary*) formateClientInfo:(ABRecordRef)person{
    // Initialize a mutable dictionary and give it initial values.
    NSMutableDictionary *contactInfoDict = [[NSMutableDictionary alloc]
                                            initWithObjects:@[@"", @"", @"", @"", @"", @"", @"", @"", @""]
                                            forKeys:@[@"firstName", @"lastName", @"mobileNumber", @"homeNumber", @"homeEmail", @"workEmail", @"address", @"zipCode", @"city"]];
    
    // Use a general Core Foundation object.
    CFTypeRef generalCFObject = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    
    // Get the first name.
    if (generalCFObject) {
        [contactInfoDict setObject:(__bridge NSString *)generalCFObject forKey:@"firstName"];
        CFRelease(generalCFObject);
    }
    
    // Get the last name.
    generalCFObject = ABRecordCopyValue(person, kABPersonLastNameProperty);
    if (generalCFObject) {
        [contactInfoDict setObject:(__bridge NSString *)generalCFObject forKey:@"lastName"];
        CFRelease(generalCFObject);
    }
    
    // Get the phone numbers as a multi-value property.
    ABMultiValueRef phonesRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
    for (int i=0; i<ABMultiValueGetCount(phonesRef); i++) {
        CFStringRef currentPhoneLabel = ABMultiValueCopyLabelAtIndex(phonesRef, i);
        CFStringRef currentPhoneValue = ABMultiValueCopyValueAtIndex(phonesRef, i);
        
        if (CFStringCompare(currentPhoneLabel, kABPersonPhoneMobileLabel, 0) == kCFCompareEqualTo) {
            [contactInfoDict setObject:(__bridge NSString *)currentPhoneValue forKey:@"mobileNumber"];
        }
        
        if (CFStringCompare(currentPhoneLabel, kABHomeLabel, 0) == kCFCompareEqualTo) {
            [contactInfoDict setObject:(__bridge NSString *)currentPhoneValue forKey:@"homeNumber"];
        }
        
        CFRelease(currentPhoneLabel);
        CFRelease(currentPhoneValue);
    }
    CFRelease(phonesRef);
    
    
    // Get the e-mail addresses as a multi-value property.
    ABMultiValueRef emailsRef = ABRecordCopyValue(person, kABPersonEmailProperty);
    for (int i=0; i<ABMultiValueGetCount(emailsRef); i++) {
        CFStringRef currentEmailLabel = ABMultiValueCopyLabelAtIndex(emailsRef, i);
        CFStringRef currentEmailValue = ABMultiValueCopyValueAtIndex(emailsRef, i);
        
        if (CFStringCompare(currentEmailLabel, kABHomeLabel, 0) == kCFCompareEqualTo) {
            [contactInfoDict setObject:(__bridge NSString *)currentEmailValue forKey:@"homeEmail"];
        }
        
        if (CFStringCompare(currentEmailLabel, kABWorkLabel, 0) == kCFCompareEqualTo) {
            [contactInfoDict setObject:(__bridge NSString *)currentEmailValue forKey:@"workEmail"];
        }
        
        CFRelease(currentEmailLabel);
        CFRelease(currentEmailValue);
    }
    CFRelease(emailsRef);
    
    
    // Get the first street address among all addresses of the selected contact.
    ABMultiValueRef addressRef = ABRecordCopyValue(person, kABPersonAddressProperty);
    if (ABMultiValueGetCount(addressRef) > 0) {
        NSDictionary *addressDict = (__bridge NSDictionary *)ABMultiValueCopyValueAtIndex(addressRef, 0);
        
        [contactInfoDict setObject:[addressDict objectForKey:(NSString *)kABPersonAddressStreetKey] forKey:@"address"];
        [contactInfoDict setObject:[addressDict objectForKey:(NSString *)kABPersonAddressZIPKey] forKey:@"zipCode"];
        [contactInfoDict setObject:[addressDict objectForKey:(NSString *)kABPersonAddressCityKey] forKey:@"city"];
    }
    CFRelease(addressRef);
    
    
    // If the contact has an image then get it too.
    if (ABPersonHasImageData(person)) {
        NSData *contactImageData = (__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
        
        [contactInfoDict setObject:contactImageData forKey:@"image"];
    }
    
    return contactInfoDict;
}


#pragma  mark - Time Setting

-(void) setMinimumAndMaximumDuration:(SCHServiceOffering *) serviceOffering{
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
            
             self.maximumDuration = 8*60*60;
            
            
            if (self.StartTimeRow.value && self.endTimeRow.value){
                if ([self.endTimeRow.value timeIntervalSinceDate:self.StartTimeRow.value] < self.minimumDuration){
                    self.currentDuration = self.minimumDuration;
                } else if ([self.endTimeRow.value timeIntervalSinceDate:self.StartTimeRow.value] > self.maximumDuration){
                    self.currentDuration = self.maximumDuration;
                } else{
                    self.currentDuration = [self.endTimeRow.value timeIntervalSinceDate:self.StartTimeRow.value];
                }
                
            } else{
                self.currentDuration = self.minimumDuration;
            
            }
        }
    }
    
    
    
}




-(void)setStartTimeCell{
    XLFormDateCell *timeFromCell =(XLFormDateCell *) [self.StartTimeRow cellForFormController:self];
    timeFromCell.minimumDate = [SCHUtility startOrEndTime:[NSDate date]];
    timeFromCell.minuteInterval = SCHTimeBlockDuration/60;
    
    [timeFromCell update];
    
    if (self.currentDuration != 0){
        
        self.endTimeRow.disabled = @NO;
        self.endTimeRow.value = [NSDate dateWithTimeInterval:self.currentDuration sinceDate:self.StartTimeRow.value];
    }
    
    
}

-(void)setEndTimeCell{
    XLFormDateCell *timeToCell = (XLFormDateCell *) [self.endTimeRow cellForFormController:self];
    
    timeToCell.minuteInterval = SCHTimeBlockDuration/60;
    timeToCell.minimumDate = [NSDate dateWithTimeInterval:self.minimumDuration sinceDate:self.StartTimeRow.value];
    timeToCell.maximumDate = [NSDate dateWithTimeInterval:self.maximumDuration sinceDate:self.StartTimeRow.value];
    [timeToCell update];
    self.endDateRow.value = timeToCell.maximumDate;
    
}

-(void)setEndDateCell{
    XLFormDateCell *endDateCell = (XLFormDateCell *) [self.endDateRow cellForFormController:self];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *threeMonths = [[NSDateComponents alloc] init];
    [threeMonths setMonth:3];
    [threeMonths setDay:-1];
    
    endDateCell.maximumDate = [self maxdate:[calendar dateByAddingComponents:threeMonths toDate:self.endTimeRow.value options:NSCalendarMatchFirst]];
    endDateCell.minimumDate = self.endTimeRow.value;
    
    [endDateCell update];
}

-(NSDate *)maxdate:(NSDate *) endDate{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *threemonths = [[NSDateComponents alloc] init];
    [threemonths setMonth:3];
    [threemonths setDay:-1];
    NSDate *MaxDateAllowed = [calendar dateByAddingComponents:threemonths toDate:[NSDate date] options:NSCalendarMatchFirst];
    NSDate *maxDate = [NSDate date];
    if ([endDate compare:MaxDateAllowed] == NSOrderedSame){
        maxDate = endDate;
    } else if ([endDate compare:MaxDateAllowed] == NSOrderedAscending){
        maxDate = endDate;
    } else{
        maxDate = MaxDateAllowed;
    }
    
    return maxDate;
    
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


-(void)helpAction{
    [self showPopupWithStyle:CNPPopupStyleCentered];
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)showPopupWithStyle:(CNPPopupStyle)popupStyle {
    
    //Define Button
    CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [button setTitle:@"OK" forState:UIControlStateNormal];
    button.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    button.layer.cornerRadius = 4;
    button.selectionHandler = ^(CNPPopupButton *button){
        [self.popupController dismissPopupControllerAnimated:YES];
        NSLog(@"Block for button: %@", button.titleLabel.text);
    };
    // Define View
    
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 300)];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 280, 300)];
    
    
    /*
     NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
     paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
     paragraphStyle.alignment = NSTextAlignmentCenter;
     
     NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"It's A Popup!" attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:24], NSParagraphStyleAttributeName : paragraphStyle}];
     NSAttributedString *lineOne = [[NSAttributedString alloc] initWithString:@"You can add text and images" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSParagraphStyleAttributeName : paragraphStyle}];
     NSAttributedString *lineTwo = [[NSAttributedString alloc] initWithString:@"With style, using NSAttributedString" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSForegroundColorAttributeName : [UIColor colorWithRed:0.46 green:0.8 blue:1.0 alpha:1.0], NSParagraphStyleAttributeName : paragraphStyle}];
     
     */
    
    
    
    
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = [self helpTitle];
    
    
    // UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"info"]];
    
    
    
    // customView.backgroundColor = [UIColor lightGrayColor];
    
    
    
    [textView setEditable:NO];
    [textView setSelectable:NO];
    [textView setAttributedText:[self helpContent]];
    [customView addSubview:textView];
    
    self.popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, customView, button]];
    self.popupController.theme = [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle = popupStyle;
    self.popupController.theme.cornerRadius = 20;
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];
}

-(NSAttributedString *) helpContent{
    
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] init];
    NSString *nextLine = @"\n";
    
    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    
    NSDictionary *blueBodylAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[UIColor blueColor]};
    
    

    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Business"] attributes:blueBodylAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@", "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"For"] attributes:blueBodylAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" (Offering), "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Location"] attributes:blueBodylAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" and "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Client"] attributes:blueBodylAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"."] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Enter appointment time"] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"For recuuring appointment, select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Repeat"] attributes:blueBodylAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" option and "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"End Date"] attributes:blueBodylAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Enter "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Notes"] attributes:blueBodylAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" for client."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Tap on Book to book the appointment."] attributes:bodyAttr]];
    
    
    return content;
    
}




-(NSAttributedString *) helpTitle{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Appointment with Client"]  attributes:titleAttr]];
    return title;
}


@end
