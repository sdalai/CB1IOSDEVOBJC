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
static SCHServiceOffering *serviceOffering = NULL;
static BOOL debug = YES;

@interface SCHNewAppointmentBySPViewController ()
@property (strong, nonatomic) dispatch_queue_t backgroundQueue;
@property (strong, nonatomic) NSArray* contactList ;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@end

@implementation SCHNewAppointmentBySPViewController

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
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptorWithTitle:SCHSCreenTitleNewAppointment];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    //For Service
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleService rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleService];
    row.selectorTitle = SCHSelectorTitleServiceList;
    row.required = YES;
    row.selectorOptions = [SCHUtility servicelist];
    [section addFormRow:row];
    
    // For service offering
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleServiceType rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleServiceType];
    row.disabled = @YES;
    row.selectorTitle = SCHSelectorTitleServiceTypeList;
    XLFormRowDescriptor *serviceRow = [self.form formRowWithTag:SCHFieldTitleService];
    if (serviceRow.valueData){
        row.selectorOptions =[SCHUtility serviceOfferingList:(SCHService *)serviceRow.valueData];
    }
    
    row.required = YES;
    [section addFormRow:row];
    
    
    //Location
//    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleLocation rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleLocation];
//    row.required = YES;
//    [section addFormRow:row];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleLocation rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleLocation];
   NSArray* userPreviousLocations = [SCHUtility getUserLocations:[PFUser currentUser]];
    if(userPreviousLocations.count>0)
          row.action.viewControllerClass =[SCHLocationSelectorViewController class]; //
    else
        row.action.viewControllerClass =[SPGooglePlacesAutocompleteDemoViewController class];
    
    
    row.valueTransformer = [LocationValueTrasformer class];
    
    
    //row.value = @"test";
    [section addFormRow:row];
    
    //Client
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleClient rowType:XLFormRowDescriptorTypeInfo title:SCHFieldTitleClient];
    row.selectorTitle = SCHSelectorTitleClentList;
    row.required = YES;
 //   row.selectorOptions = [SCHUtility clientlist]; // _contactList;
    [section addFormRow:row];
    self.client_row = row;
    
    row.value = @"Tap to select client";
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Time";
    [form addFormSection:section];
    
    
    //Starts
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleFromTime rowType:XLFormRowDescriptorTypeDateTimeInline title:SCHFieldTitleFromTime];
    XLFormDateCell *timeFrom =(XLFormDateCell *) [row cellForFormController:self];
    //Set XLform date cell properties
   // timeFrom. = [SCHUtility dateFormatterForFromTime];
    timeFrom.minimumDate = [SCHUtility startOrEndTime:[NSDate date]];
    timeFrom.minuteInterval = 15;
    
    row.value = timeFrom.minimumDate;
    [section addFormRow:row];
    
    
    // Ends
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleToTime rowType:XLFormRowDescriptorTypeTimeInline title:SCHFieldTitleToTime];
    XLFormDateCell *timeTo = (XLFormDateCell *) [row cellForFormController:self];
  //  timeTo.dateFormatter = [SCHUtility dateFormatterForToTime];
    timeTo.minuteInterval = 15;
    NSTimeInterval defaultDuration = 60*60;
    NSTimeInterval maximumDuration = 8*60*60;
    timeTo.minimumDate = [NSDate dateWithTimeInterval:defaultDuration sinceDate:timeFrom.minimumDate];
    timeTo.maximumDate = [NSDate dateWithTimeInterval:maximumDuration sinceDate:timeFrom.minimumDate];
    row.value = timeTo.minimumDate;
    [section addFormRow:row];
    
    // Repeat Section
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHScreenSectionTitleRepeatation;
    
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
    
    
    
    [section addFormRow:row];
    
    
    
    // End date
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleEndDate rowType:XLFormRowDescriptorTypeDateInline title:SCHFieldTitleEndDate];
    row.disabled = @YES;
    XLFormDateCell *endDate = (XLFormDateCell *) [row cellForFormController:self];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *threeMonths = [[NSDateComponents alloc] init];
    [threeMonths setMonth:2];
    
    endDate.maximumDate = [calendar dateByAddingComponents:threeMonths toDate:[NSDate date] options:NSCalendarMatchFirst];
    
    // NSLog(@"Maximum Date: %@", endDate.maximumDate);
    endDate.minimumDate = [NSDate date];
    
    [section addFormRow:row];
    

    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Note";
    [form addFormSection:section];
    
    // Notes
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleNote rowType:XLFormRowDescriptorTypeTextView];
    [row.cellConfigAtConfigure setObject:@"Notes" forKey:@"textView.placeholder"];
    [section addFormRow:row];
    
    
    
    self.form = form;
   
}

#pragma mark - XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue
{    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleService] && oldValue != newValue) {
        XLFormRowDescriptor *serviceType = [self.form formRowWithTag:SCHFieldTitleServiceType];
        serviceType.disabled = @NO;
        serviceType.selectorOptions = [SCHUtility serviceOfferingList:(SCHService *)[newValue valueData]];
        
    }
    
    
    
    

    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleFromTime]){
        if (oldValue != newValue){
            XLFormRowDescriptor *ToTimeRow = [self.form formRowWithTag:SCHFieldTitleToTime];
            XLFormDateCell *timeTo = (XLFormDateCell *) [ToTimeRow cellForFormController:self];
            NSTimeInterval defaultDuration = 60*60;
            NSTimeInterval maximumDuration = 8*60*60;
            timeTo.minimumDate = [NSDate dateWithTimeInterval:defaultDuration sinceDate:(NSDate *)newValue];
            timeTo.maximumDate = [NSDate dateWithTimeInterval:maximumDuration sinceDate:(NSDate *)newValue];
            ToTimeRow.value = timeTo.minimumDate;
            [timeTo update];
            XLFormRowDescriptor *EndDateRow = [self.form formRowWithTag:SCHFieldTitleEndDate];
            XLFormDateCell *endDate = (XLFormDateCell *) [EndDateRow cellForFormController:self];
            endDate.minimumDate = timeTo.minimumDate;
            EndDateRow.value = endDate.minimumDate;
            [endDate update];
            
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



#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.backgroundQueue = [SCHBackgroundManager sharedManager].SCHSerialQueue;
    self.client_info_Dict = [[NSDictionary alloc]init];
    self.navigationItem.leftBarButtonItem.title = @"";
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
    
    SCHService *service = ([self.formValues valueForKey:SCHFieldTitleService] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleService] valueData] : NULL;
    SCHServiceOffering *serviceType = ([self.formValues valueForKey:SCHFieldTitleServiceType] != NULL) ? ((serviceOffering == NULL) ? [[self.formValues valueForKey:SCHFieldTitleServiceType] valueData] : serviceOffering) : NULL;
    XLFormRowDescriptor *row = [self.formValues valueForKey:SCHFieldTitleLocation] ;
    
    NSString * selectedLocation = [[self.formValues valueForKey:SCHFieldTitleLocation] valueData];
    
    NSLog(@"Selected Location: %@", selectedLocation);
    
    
    NSString *location =[row isKindOfClass:[NSNull class]]?NULL:[row valueForKey:@"address"];
    
    PFUser *client = ([self.formValues valueForKey:SCHFieldTitleClient] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleClient] valueData] : NULL;
    
    
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
                             endDate:endDate]){
        
        endDate = (endDate == NULL)? timeTo : endDate;
      //  [SCHUtility showProgressWithMessage:SCHProgressMessageCreateAppointment onView:self.view];
        dispatch_async(self.backgroundQueue, ^{
            [self beginBackgroundTask];
            NSDictionary *output = [SCHAppointmentManager createAppointmentServiceProvider:[PFUser currentUser]
                                                                                   service:service
                                                                           serviceOffering:serviceType
                                                                                  location:location
                                                                                    client:client
                                                                                clientName:nil
                                                                                  timeFrom:timeFrom
                                                                                    timeTo:timeTo
                                                                              repeatOption:repeat
                                                                                repeatDays:repeatDays
                                                                                   endDate:endDate
                                                                                     notes:notes];
            
            
            NSInteger numberOfAppointmentRequest = [[output valueForKey:@"numberOfAppointmentRequest"] intValue];
            NSInteger numberOfAppointmentWithConflict = [[output valueForKey:@"numberOfAppointmentWithConflict"] intValue];
            NSInteger numberofAppointmentWithAvailabilityConflict = [[output valueForKey:@"numberofAppointmentWithAvailabilityConflict"] intValue];
            NSInteger numberOfAppointmentsCreated = [[output valueForKey:@"numberOfAppointmentsCreated"] intValue];
            
            
            NSLog(@"numberOfAppointmentRequest: %ld", (long)numberOfAppointmentRequest);
            NSLog(@"numberOfAppointmentWithConflict: %ld", (long)numberOfAppointmentWithConflict);
            NSLog(@"numberofAppointmentWithAvailabilityConflict: %ld", (long)numberofAppointmentWithAvailabilityConflict);
            NSLog(@"numberOfAppointmentsCreated: %ld", (long)numberOfAppointmentsCreated);
            
            
            
            NSString *message = @"";
            if (numberOfAppointmentRequest == numberOfAppointmentsCreated){
                if (numberOfAppointmentRequest == 0){
                    [message stringByAppendingString:[NSString stringWithFormat:@"No appointment request was created."]];
                } else if (numberOfAppointmentRequest == 1){
                    [message stringByAppendingString:[NSString stringWithFormat:@"Appointment request was created."]];
                } else if (numberOfAppointmentRequest > 1){
                    [message stringByAppendingString:[NSString stringWithFormat:@"All appointment requests were created."]];
                }
                
                
            } else if (numberOfAppointmentRequest > numberOfAppointmentsCreated){
                if (numberOfAppointmentsCreated == 0){
                    [message stringByAppendingString:[NSString stringWithFormat:@"No appointment request was created."]];
                } else if (numberOfAppointmentsCreated > 0){
                    [message stringByAppendingString:[NSString stringWithFormat:@"%ld appointment request of %ld were created. %ld conflicts with existing appointment and %ld due to  time unavailability", (long)numberOfAppointmentsCreated, (long)numberOfAppointmentRequest, (long)numberOfAppointmentWithConflict, (long)numberofAppointmentWithAvailabilityConflict]];
                }
                
            }
            
           
            SCHScheduledEventManager *eventManager = [SCHScheduledEventManager sharedManager];
            [eventManager buildScheduledEvent];
            
            [self endBackgroundTask];
            
            });
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.navigationController popViewControllerAnimated:YES];
        });

        
        
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



-(BOOL) validateDateForService:(SCHService *) service serviceType:(SCHServiceOffering *) serviceType location:(NSString *) location client:(PFUser *) client timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo repeat:(NSString *) repeat repeatDays:(NSArray *) repeatDays endDate:(NSDate *) endDate {
    BOOL dataValid = NO;
    
    if ([repeat isEqualToString:SCHSelectorRepeatationOptionNever]){
        if (service == NULL || serviceType == NULL || location == NULL || client == NULL || timeFrom == NULL || timeTo == NULL){
            if (debug) {
                NSLog(@" All required info not provided");
            }
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
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
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            dataValid = NO;
            
        } else dataValid = YES;
        
    }
    
    return dataValid;
    
}



-(void) showMissingInfoMessage{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    
}





-(void) clearAllInputValues{
    [self.formValues setValue:NULL forKey:SCHFieldTitleService];
    
    
}

#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   if(indexPath.row == 3)
    {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        
        [self presentAddressBookPicker];
    }else{
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
            NSLog(@"Unknown address book status.");
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
    NSLog(@"Went here 1 ...");
    
    [self peoplePickerNavigationController:peoplePicker shouldContinueAfterSelectingPerson:person];
}


//needed for iOS 7 and lower
- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    
    NSLog(@"Went here 2 ...");
    self.client_info_Dict = [self formateClientInfo:person];
    NSString *firstName = [self.client_info_Dict valueForKey:@"firstName"];
    NSString *lastName = [self.client_info_Dict valueForKey:@"lastName"];
    self.client_row.value = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
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


@end
