//
//  SCHNewAppointmentByClientViewController.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/9/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHNewAppointmentByClientViewController.h"
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
#import "SCHScheduledEventManager.h"
#import "AppDelegate.h"
#import "SCHLocationSelectorViewController.h"
#import "SCHConstants.h"
#import "SCHActiveViewControllers.h"
#import "SCHScheduleTableViewController.h"
#import "SCHNotificationViewController.h"
#import "SCHActiveViewControllers.h"
#import "SCHScheduleTableViewController.h"
#import "SCHUser.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
#import <KVNProgress/KVNProgress.h>
static BOOL debug = NO;

@interface SCHNewAppointmentByClientViewController ()<CNPPopupControllerDelegate>
@property (nonatomic, strong) CNPPopupController *popupController;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) dispatch_queue_t backgroundQueue;
@property (strong, nonatomic) XLFormSectionDescriptor *titleSection;
@property (strong, nonatomic) XLFormRowDescriptor *serviceType;
@property (strong, nonatomic) NSArray *serviceOfferingList;
@property (strong, nonatomic) XLFormRowDescriptor *locationRow;
@property (strong, nonatomic)XLFormRowDescriptor *timeFromRow;
@property (strong, nonatomic) XLFormRowDescriptor *timeToRow;
@property (strong, nonatomic) XLFormRowDescriptor *endDateRow;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic) NSTimeInterval minimumDuration;
@property (nonatomic) NSTimeInterval maximumDuration;
@property (nonatomic) NSTimeInterval currentDuration;

@end

@implementation SCHNewAppointmentByClientViewController



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

- (void)initializeForm{
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptorWithTitle:SCHSCreenTitleNewAppointment];
    section = [XLFormSectionDescriptor formSection];
    self.titleSection = section;
    [form addFormSection:section];
    
    // For service offering
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleServiceType rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleServiceType];
    self.serviceType = row;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];

    row.required = YES;
    [section addFormRow:row];
    
    //Location
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleLocation rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleLocation];
    self.locationRow = row;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];

    NSArray* userPreviousLocations = [SCHUtility getUserLocations:appDelegate.user];
    if(userPreviousLocations.count>0)
        row.action.viewControllerClass =[SCHLocationSelectorViewController class]; //
    else
        row.action.viewControllerClass =[SPGooglePlacesAutocompleteDemoViewController class];
   
    row.valueTransformer = [LocationValueTrasformer class];

    [section addFormRow:row];
    self.locationRow = row;
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Time";
    [form addFormSection:section];
    
    
    //Starts
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleFromTime rowType:XLFormRowDescriptorTypeDateTimeInline title:SCHFieldTitleFromTime];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.disabled = @YES;

    self.timeFromRow = row;
    
    


    [section addFormRow:row];
    
    
    
    // Ends
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleToTime rowType:XLFormRowDescriptorTypeTimeInline title:SCHFieldTitleToTime];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.disabled = @YES;
    self.timeToRow = row;
    

    [section addFormRow:row];
    // Repeat Section
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHScreenSectionTitleRepeatation;
    section.hidden = @YES;
    
    [form addFormSection:section];
    
    
    // Repeat Row
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleRepeat rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleRepeat];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];

    row.value = SCHSelectorRepeatationOptionNever;
    row.selectorOptions = @[SCHSelectorRepeatationOptionNever,
                            SCHSelectorRepeatationOptionEveryDay,
                            SCHSelectorRepeatationOptionEveryWeek,
                            SCHSelectorRepeatationOptionEvery2Weeks,
                            SCHSelectorRepeatationOptionEveryMonth,
                            SCHSelectorRepeatationOptionSpectficDaysOftheWeek];
    row.selectorTitle = SCHSelectorTitleRepeat;
    
    [section addFormRow:row];
    
    // Repeat Row
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleRepeatDays rowType:XLFormRowDescriptorTypeMultipleSelector title:SCHFieldTitleRepeatDays];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];

    row.disabled = @YES;
    row.selectorTitle = SCHSelectorTitleRepeatDay;
    row.selectorOptions = @[SCHSelectorRepeatationOptionSunday,
                            SCHSelectorRepeatationOptionMonday,
                            SCHSelectorRepeatationOptionTuesday,
                            SCHSelectorRepeatationOptionWednesday,
                            SCHSelectorRepeatationOptionThursday,
                            SCHSelectorRepeatationOptionFriday,
                            SCHSelectorRepeatationOptionSaturday];
    
    
    
    [section addFormRow:row];
    
    
    
    // End date
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleEndDate rowType:XLFormRowDescriptorTypeDateInline title:SCHFieldTitleEndDate];
    row.disabled = @YES;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];


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

#pragma mark - XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue
{ [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleService] && oldValue != newValue) {
        XLFormRowDescriptor *serviceType = [self.form formRowWithTag:SCHFieldTitleServiceType];
        serviceType.disabled = @NO;
        serviceType.selectorOptions = [SCHUtility serviceOfferingList:(SCHService *)[newValue valueData]];
        
    }
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleServiceType] && (newValue != oldValue)){
        if ([[newValue valueData] isEqual:[NSNull null]]){
            self.timeFromRow.value = nil;
            self.timeToRow.value = nil;
            self.timeFromRow.disabled = @YES;
            self.timeToRow.disabled = @YES;
            
        } else{
            self.timeFromRow.disabled = @NO;
            self.timeToRow.disabled = @NO;
            
            SCHServiceOffering *serviceOffering = [newValue valueData];
            [self setMinimumAndMaximumDuration:serviceOffering];
            
            [self setFromTime:YES
                    setToTime:NO
                   setEndDate:NO];
        }
        
    }
    
    
 //
    
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleFromTime]){
        if (oldValue != newValue){
            
            
            //set maximum duration
            
            NSTimeInterval duration = [self.selectedAvailability.endTime timeIntervalSinceDate:newValue];
            SCHServiceOffering *offering = [self.serviceType.value formValue];
            
            if (!offering.fixedDuration){
                if (duration < self.minimumDuration){
                    self.maximumDuration = self.minimumDuration;
                } else {
                    self.maximumDuration = duration;
                }
            }
            
            
            [self setFromTime:NO
                    setToTime:YES
                   setEndDate:NO];
            

            
        }
    }
    
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleToTime]){
        if (oldValue != newValue){
            
            
            NSTimeInterval duration = [newValue timeIntervalSinceDate:self.timeFromRow.value];
            [self resetCurrentDuration:duration];
            
            
            [self setFromTime:NO
                    setToTime:NO
                   setEndDate:YES];
            
            
            
            [self hasEnoughTimeForAppointment];
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
            endDate.value = endDateCell.maximumDate;
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


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
   /*
    NSLog(@"View did load");
    
    NSLog(@"selected service provider %@",self.selectedServiceProvider);
    NSLog(@"selected availability %@",self.selectedAvailability);
    
    */
    NSString *appointmentTitle = [NSString stringWithFormat:@"%@ with %@", self.selectedServiceProvider.serviceTitle, self.selectedServiceProvider.user.preferredName];
    self.titleSection.title = appointmentTitle;
    
    //set service Offering
    self.serviceOfferingList = [SCHUtility serviceOfferingList:self.selectedServiceProvider];
  //  NSLog(@"service Offering Count: %lu", (unsigned long)self.serviceOfferingList.count);
    
    self.serviceType.selectorTitle = SCHSelectorTitleServiceTypeList;
    self.serviceType.selectorOptions = self.serviceOfferingList;
    
    //If there is only one service type then make it as deafult
    
    if (self.serviceOfferingList.count == 1){
        
        self.serviceType.value = self.serviceOfferingList[0];
    }
    
    
    //setLocation
    NSDictionary * locationDict = @{@"address":self.selectedAvailability.location};
    
    self.locationRow.value = locationDict;
    
    
    
    UIBarButtonItem *addNewApptButton = [[UIBarButtonItem alloc]
                                  
                                  
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                  
                                  
                                  target:self action:@selector(CancelAction)];
    
    self.navigationItem.leftBarButtonItem = addNewApptButton;
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
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
- (IBAction)save:(UIBarButtonItem *)sender {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHService *service = self.selectedServiceProvider;
    SCHServiceOffering *serviceType = ([self.formValues valueForKey:SCHFieldTitleServiceType] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleServiceType] valueData] : NULL;
    XLFormRowDescriptor *row = [self.formValues valueForKey:SCHFieldTitleLocation] ;
    
//    NSString * selectedLocation = [[self.formValues valueForKey:SCHFieldTitleLocation] valueData];
    
   // NSLog(@"Selected Location: %@", selectedLocation);
    
    
    NSString *location =[row isKindOfClass:[NSNull class]]?NULL:[row valueForKey:@"address"];
    
    SCHUser *client = appDelegate.user;
    SCHUser *serviceProvider = self.selectedServiceProvider.user;
    
    
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
                              client:client
                            timeFrom:timeFrom
                              timeTo:timeTo
                              repeat:repeat
                          repeatDays:repeatDays
                             endDate:endDate] && appDelegate.serverReachable){
        
        endDate = (endDate == NULL)? timeTo : endDate;
        
        
        
        

        
        SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
       // BOOL progressIndicatorEnabled  = NO;

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
            dispatch_async(backgroundManager.SCHSerialQueue, ^{
                
                [self beginBackgroundTask];
                
                
                
                NSDictionary *output = [SCHAppointmentManager createAppointmentServiceProvider:serviceProvider
                                                                                       service:service
                                                                               serviceOffering:serviceType
                                                                                      location:location
                                                                                 locationPoint:locationPoint
                                                                                        client:client
                                                                                    clientName:nil
                                                                                      timeFrom:timeFrom
                                                                                        timeTo:timeTo
                                                                                  repeatOption:repeat
                                                                                    repeatDays:repeatDays
                                                                                       endDate:endDate
                                                                                         notes:notes];
                
                
                
                
                
                [self postAppointmentProcessing:output];
                [SCHSyncManager syncUserData:timeFrom];
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




-(BOOL) validateDateForService:(SCHService *) service serviceType:(SCHServiceOffering *) serviceType location:(NSString *) location client:(SCHUser *) client timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo repeat:(NSString *) repeat repeatDays:(NSArray *) repeatDays endDate:(NSDate *) endDate {
    BOOL dataValid = NO;
    
    if ([repeat isEqualToString:SCHSelectorRepeatationOptionNever]){
        if (service == NULL || serviceType == NULL || location == NULL || client == NULL || timeFrom == NULL || timeTo == NULL){
            if (debug) {
                NSLog(@" All required info not provided");
            }
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"please fill out all the information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            dataValid = NO;
            
        } else dataValid = YES;
        
    } else if ([repeat isEqualToString:SCHSelectorRepeatationOptionSpectficDaysOftheWeek]){
        if (service == NULL || serviceType == NULL || location == NULL || client == NULL || timeFrom == NULL || timeTo == NULL || [endDate isEqual:[NSNull null]] || repeatDays.count == 0){
            if (debug) {
                NSLog(@" All required info not provided");
            }
            [self showMissingInfoMessage];
            
            dataValid = NO;
            
        } else dataValid = YES;
    } else {
        if (service == NULL || serviceType == NULL || location == NULL || client == NULL || timeFrom == NULL || timeTo == NULL || [endDate isEqual:[NSNull null]]){
            if (debug) {
                NSLog(@" All required info not provided");
            }
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"please fill out all the information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            dataValid = NO;
            
        } else dataValid = YES;
        
    }
    
    if (![self hasEnoughTimeForAppointment]){
        dataValid = NO;
    }
    
    return dataValid;
    
}

-(void) showMissingInfoMessage{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"please fill out all the information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    
}


-(void)postAppointmentProcessing:(NSDictionary *) output{
    
    NSInteger numberOfAppointmentRequest = [[output valueForKey:@"numberOfAppointmentRequest"] intValue];
    /*
    NSInteger numberOfAppointmentWithConflict = [[output valueForKey:@"numberOfAppointmentWithConflict"] intValue];
    NSInteger numberofAppointmentWithAvailabilityConflict = [[output valueForKey:@"numberofAppointmentWithAvailabilityConflict"] intValue];
    NSInteger numberOfAppointmentsCreated = [[output valueForKey:@"numberOfAppointmentsCreated"] intValue];
    */
    if (numberOfAppointmentRequest > 1){
        
        //show message
        nil;
    }
    
}

-(void) setMinimumAndMaximumDuration:(SCHServiceOffering *) serviceOffering{
    if (!serviceOffering){
        self.minimumDuration = 0;
        self.maximumDuration = 0;
        self.currentDuration = 0;
        
    } else{
        self.minimumDuration = serviceOffering.defaultDurationInMin*60;
        self.currentDuration = self.minimumDuration;
        if(serviceOffering.fixedDuration){
            self.maximumDuration = self.minimumDuration;
        } else{
            
            self.maximumDuration = [self.selectedAvailability.endTime timeIntervalSinceDate:self.selectedAvailability.startTime];
        }
    }
    
    
    
}


-(void)setFromTime:(BOOL) setFromTime setToTime:(BOOL)setToTime setEndDate:(BOOL) setEndDate{
    NSDate *fromTime = nil;
    NSDate *toTime = nil;
    NSDate *endDate = nil;
    
    //get current vlaues

    
    if (self.timeFromRow.value){
        fromTime = self.timeFromRow.value;
    }
    if (self.timeToRow.value){
        toTime = self.timeToRow.value;
    }
    
    if (self.endDateRow.value){
        endDate = self.endDateRow.value;
    }
    
    
    if (setFromTime){
        //min interval, minimum time, maximum time
        //set timeFrom Parameters
        XLFormDateCell *timeFrom =(XLFormDateCell *) [self.timeFromRow cellForFormController:self];
        
        if ([self.selectedAvailability.startTime compare:[NSDate dateWithTimeInterval:-self.minimumDuration sinceDate:self.selectedAvailability.endTime]] == NSOrderedAscending ){
            timeFrom.maximumDate =[NSDate dateWithTimeInterval:-self.minimumDuration sinceDate:self.selectedAvailability.endTime];
            timeFrom.minimumDate = self.selectedAvailability.startTime;
            
            
        } else {
            timeFrom.maximumDate = self.selectedAvailability.startTime;
            timeFrom.minimumDate = self.selectedAvailability.startTime;
        }
        
        timeFrom.minuteInterval = SCHTimeBlockDuration/60;
        
        
        
        self.timeFromRow.value = timeFrom.minimumDate;
        
        
        
        [timeFrom update];
        
        fromTime = self.timeFromRow.value;
    }
    
    if (setToTime){
        XLFormDateCell *timeTo = (XLFormDateCell *) [self.timeToRow cellForFormController:self];
        
        timeTo.minuteInterval = SCHTimeBlockDuration/60;
        if ([[NSDate dateWithTimeInterval:self.minimumDuration sinceDate:fromTime] compare:self.selectedAvailability.endTime] == NSOrderedAscending){
            timeTo.minimumDate = [NSDate dateWithTimeInterval:self.minimumDuration sinceDate:fromTime];
            timeTo.maximumDate =self.selectedAvailability.endTime;
        } else{
            timeTo.maximumDate =self.selectedAvailability.endTime;
            timeTo.minimumDate = self.selectedAvailability.endTime;
        }
        
        // reset current duration
        [self resetCurrentDuration:self.currentDuration];
        
        
        
        self.timeToRow.value = [fromTime dateByAddingTimeInterval:self.currentDuration];
        [timeTo update];
        toTime = self.timeToRow.value;
        
    }
    
    if (setEndDate){
        // set end Date Row
        XLFormDateCell *endDate = (XLFormDateCell *) [self.endDateRow cellForFormController:self];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *threeMonths = [[NSDateComponents alloc] init];
        [threeMonths setMonth:3];
        [threeMonths setDay:-1];
        
        endDate.maximumDate = [self maxdate:[calendar dateByAddingComponents:threeMonths toDate:toTime options:NSCalendarMatchFirst]];
        
        // NSLog(@"Maximum Date: %@", endDate.maximumDate);
        endDate.minimumDate = toTime;
        [endDate update];
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


-(BOOL)hasEnoughTimeForAppointment{
    
    BOOL hasEnoughTime = YES;
    XLFormOptionsObject *serviceTypeObject = self.serviceType.value;
    SCHServiceOffering *serviceOffering = serviceTypeObject.formValue;
    
    NSDate *timeFrom = self.timeFromRow.value;
    NSDate *timeTo = self.timeToRow.value;
    
    
    if ([timeTo timeIntervalSinceDate:timeFrom] < (serviceOffering.defaultDurationInMin*60)){
        
        hasEnoughTime = NO;
        NSString *message = [NSString stringWithFormat:@"Minimum duration for this appointment is %d min. Please select some other time.", serviceOffering.defaultDurationInMin];
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No enough Time", nil) message:NSLocalizedString(message, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    return YES;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // create the parent view that will hold header Label
    if(section==0){
        UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
         NSString *appointmentTitle = [NSString stringWithFormat:@"%@ with %@", self.selectedServiceProvider.serviceTitle, self.selectedServiceProvider.user.preferredName];
        UILabel *lblStr = [[UILabel alloc]initWithFrame:CGRectMake(12, 30, 150, 20)];
        lblStr.text = appointmentTitle;
        lblStr.textColor=[UIColor grayColor];
        lblStr.font = [UIFont systemFontOfSize:13];
        [customView addSubview:lblStr];
        
        // create the button object
        UIButton * headerBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-150, 30,150-10 , 20.0)];
        headerBtn.backgroundColor = [UIColor clearColor];
        headerBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [headerBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        headerBtn.titleLabel.font = [SCHUtility getPreferredSubtitleFont];//[UIFont boldSystemFontOfSize:13];
        [headerBtn setTitle:@"Help" forState:UIControlStateNormal];
        [headerBtn addTarget:self action:@selector(helpAction) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:headerBtn];
        return customView;
    }
    return nil;
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
    
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 250)];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 280, 250)];
    
    
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
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select for service you want to request appointment. "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Optionally set your desired timing, request new location or enter note for professional."] attributes:bodyAttr]];
        
 
    
    
    return content;
    
}




-(NSAttributedString *) helpTitle{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Request Appointment"]  attributes:titleAttr]];
    return title;
}




@end
