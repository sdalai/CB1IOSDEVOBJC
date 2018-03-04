//
//  SCHManageAvailabilityViewController.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/29/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHManageAvailabilityViewController.h"
#import "XLForm.h"
#import <Parse/Parse.h>
#import "SCHAvailabilityManager.h"
#import "SCHService.h"
#import "SCHUtility.h"
#import "SCHConstants.h"
#import "SCHBackgroundManager.h"
#import "SPGooglePlacesAutocompleteDemoViewController.h"
#import "LocationValueTrasformer.h"
#import "SCHSyncManager.h"
#import "SCHScheduledEventManager.h"
#import "SCHSyncManager.h"
#import "AppDelegate.h"
#import "SCHLocationSelectorViewController.h"
#import "SCHScheduleTableViewController.h"
#import "SCHActiveViewControllers.h"
#import "SCHNotificationViewController.h"
#import "AppDelegate.h"
#import "SCHAlert.h"
#import "SCHUser.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
#import <KVNProgress/KVNProgress.h>
const BOOL debug = NO;

@interface SCHManageAvailabilityViewController ()<CNPPopupControllerDelegate>

@property (nonatomic, strong) CNPPopupController *popupController;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) SCHService *service;
@property (strong, nonatomic) dispatch_queue_t backgroundQueue;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, strong) XLFormSectionDescriptor *repeatSection;



@end

@implementation SCHManageAvailabilityViewController

NSString *action;
SCHService *service;
NSString *location;
NSDate *timeFrom;
NSDate *timeTo;
BOOL CancelAppointments;
NSString *repeat;
NSDate *endDate;
NSMutableArray *repeatDays;


#pragma mark - Initilization
XLFormRowDescriptor *actionRow;
XLFormRowDescriptor *serviceRow;
XLFormRowDescriptor *locationRow;
XLFormRowDescriptor *timeFromRow;
XLFormRowDescriptor *timeToRow;
XLFormRowDescriptor *unavailabilityTimeToRow;
//XLFormRowDescriptor *cancelAppointmentRow;
XLFormRowDescriptor *repeatOptionRow;
XLFormRowDescriptor *repeatDaysRow;
XLFormRowDescriptor *endDateRow;

- (SCHService *) service {
    if(!_service) _service = [SCHService object];
    return _service;
}

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

#pragma mark - XL Form

- (void)initializeForm {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    form = [XLFormDescriptor formDescriptorWithTitle:SCHScreenTitleManageAvailability];
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHScreenSectionTitleService;
    [form addFormSection:section];
    
    //Action
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleAvailabilityAction rowType:XLFormRowDescriptorTypeSelectorSegmentedControl title:@""];
    row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@(0) displayText:SCHSelectorAvailabilityActionOptionAvailable],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:SCHSelectorAvailabilityActionOptionUnavailable],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(2) displayText:SCHSelectorAvailabilityActionOptionChange]
                            ];
    row.height = 55;
    [row.cellConfig setObject:[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] forKey:@"segmentedControl.tintColor"];

//    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleAvailabilityAction rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleAvailabilityAction];
//    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.value = [XLFormOptionsObject formOptionsObjectWithValue:@(0) displayText:SCHSelectorAvailabilityActionOptionAvailable];
//    row.selectorTitle = SCHselectorTitleManageAvailabilityActionList;
   
    actionRow = row;
    
    [section addFormRow:row];
    
    
    
    //For Service
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleService rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleService];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.selectorTitle = SCHSelectorTitleServiceList;
    row.required = YES;
    row.selectorOptions = [SCHUtility servicelist];
   // row.value = row.selectorOptions[0];
    
    serviceRow = row;
    [section addFormRow:row];
    
    //Location
//    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleLocation rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleLocation];
//    row.required = YES;
//    [section addFormRow:row];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleLocation rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleLocation];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    NSArray* userPreviousLocations = [SCHUtility getUserLocations:appDelegate.user];
    if(userPreviousLocations.count>0)
        row.action.viewControllerClass =[SCHLocationSelectorViewController class]; //
    else
        row.action.viewControllerClass =[SPGooglePlacesAutocompleteDemoViewController class];
  
    row.valueTransformer = [LocationValueTrasformer class];
    
    locationRow = row;
    
    [section addFormRow:row];
    
    // Time Section
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHScreenSectionTitleTime;

    [form addFormSection:section];
    
    
    //Time From
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleFromTime rowType:XLFormRowDescriptorTypeDateTimeInline title:SCHFieldTitleFromTime];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    XLFormDateCell *timeFrom =(XLFormDateCell *) [row cellForFormController:self];
    //Set XLform date cell properties
   // timeFrom.dateFormatter = [SCHUtility dateFormatterForFromTime];
    timeFrom.minimumDate = [SCHUtility startOrEndTime:[NSDate date]];
    timeFrom.minuteInterval = 15;
    
    row.value = timeFrom.minimumDate;
    timeFromRow = row;
    
    [section addFormRow:row];
    
    // Time to
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleToTime rowType:XLFormRowDescriptorTypeTimeInline title:SCHFieldTitleToTime];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];

    timeToRow = row;
    XLFormDateCell *timeTo = (XLFormDateCell *) [row cellForFormController:self];
    
    NSTimeInterval defaultDuration = [self getMinimumDuation];
    

    timeTo.minuteInterval = 15;
 

    timeTo.minimumDate = [NSDate dateWithTimeInterval:defaultDuration sinceDate:timeFrom.minimumDate];

    
    row.value = timeTo.minimumDate;
 
 
    [section addFormRow:row];
    
    
    
    //Unavailability TimeTo
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"UnavailabilityToTime" rowType:XLFormRowDescriptorTypeDateTimeInline title:SCHFieldTitleToTime];
    unavailabilityTimeToRow = row;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];

    XLFormDateCell *UnavailabilityTimeTo = (XLFormDateCell *) [row cellForFormController:self];
    
    UnavailabilityTimeTo.minuteInterval = 15;

    UnavailabilityTimeTo.minimumDate = [NSDate dateWithTimeInterval:defaultDuration sinceDate:timeFrom.minimumDate];
    row.value = timeTo.minimumDate;
    row.hidden = @YES;
    [section addFormRow:row];
    
    
    // Repeat Section
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHScreenSectionTitleRepeatation;
    self.repeatSection = section;
    
    [form addFormSection:section];
    
    
    
    // Repeat Row
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleRepeat rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleRepeat];
    row.value = SCHSelectorRepeatationOptionNever;
   // row.disabled = @YES;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.selectorOptions = @[SCHSelectorRepeatationOptionNever,
                            SCHSelectorRepeatationOptionEveryDay,
                            SCHSelectorRepeatationOptionEveryWeek,
                            SCHSelectorRepeatationOptionEvery2Weeks,
                            SCHSelectorRepeatationOptionEveryMonth,
                            SCHSelectorRepeatationOptionSpectficDaysOftheWeek];
    row.selectorTitle = SCHSelectorTitleRepeat;
    repeatOptionRow = row;
    [section addFormRow:row];
    
    // Repeat Row
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleRepeatDays rowType:XLFormRowDescriptorTypeMultipleSelector title:SCHFieldTitleRepeatDays];
    row.disabled = @YES;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];

    row.selectorTitle = SCHSelectorTitleRepeatDay;
    row.selectorOptions = @[SCHSelectorRepeatationOptionSunday,
                            SCHSelectorRepeatationOptionMonday,
                            SCHSelectorRepeatationOptionTuesday,
                            SCHSelectorRepeatationOptionWednesday,
                            SCHSelectorRepeatationOptionThursday,
                            SCHSelectorRepeatationOptionFriday,
                            SCHSelectorRepeatationOptionSaturday];
    
    
    repeatDaysRow = row;
    [section addFormRow:row];
    
    
    
    // End date
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleEndDate rowType:XLFormRowDescriptorTypeDateInline title:SCHFieldTitleEndDate];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];

    row.disabled = @YES;
    
    /*
   // XLFormDateCell *endDate = (XLFormDateCell *) [row cellForFormController:self];
   // NSCalendar *calendar = [NSCalendar currentCalendar];
   // NSDateComponents *oneMonths = [[NSDateComponents alloc] init];
   // [oneMonths setMonth:1];
  //  [oneMonths setDay:-1];
    
   // endDate.maximumDate = [self maxdate:[calendar dateByAddingComponents:oneMonths toDate:timeTo.maximumDate options:NSCalendarMatchFirst]];
    

   // endDate.minimumDate = timeTo.maximumDate;
     
     */
    endDateRow = row;

    [section addFormRow:row];
    
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"";
    
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    section.title = @"";
    
    [form addFormSection:section];
    



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

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue{
    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleAvailabilityAction]){
        
        if (newValue == [NSNull null]){
            
            rowDescriptor.value = oldValue;
            
        } else{
            if ([[newValue displayText] isEqualToString:SCHSelectorAvailabilityActionOptionUnavailable]){
                self.repeatSection.hidden = @YES;
                timeToRow.hidden = @YES;
                unavailabilityTimeToRow.hidden = @NO;
                //  cancelAppointmentRow.hidden = @NO;
                
                
                
            }else if ([[newValue displayText] isEqualToString:SCHSelectorAvailabilityActionOptionAvailable]) {
                
                if (self.selectedAvailabiity){
                    self.repeatSection.hidden = @YES;
                } else{
                    self.repeatSection.hidden = @NO;
                }
                
                timeToRow.hidden = @NO;
                unavailabilityTimeToRow.hidden = @YES;
                //  cancelAppointmentRow.hidden = @YES;
                
                
            } else if ([[newValue displayText] isEqualToString:SCHSelectorAvailabilityActionOptionChange]){
                if (self.selectedAvailabiity){
                    self.repeatSection.hidden = @YES;
                } else{
                    self.repeatSection.hidden = @NO;
                }
                timeToRow.hidden = @NO;
                unavailabilityTimeToRow.hidden = @YES;
                // cancelAppointmentRow.hidden = @YES;
                
                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                   message:@"Changing availability will replace existing availability."
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [theAlert show];
                
            }
            
            NSString *action = [newValue displayText];
            NSDate *timeFromDate = timeFromRow.value;
            [self setMinMaxValueForDates:timeFromDate action:action];
            [self resetTime];
            [self.tableView reloadData];
            
        }
        
    }

    
    
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleFromTime]){
        if (oldValue != newValue){
            
            NSString *action = [actionRow.value displayText];
            NSDate *timeFromDate = newValue;
            [ self setMinMaxValueForDates:timeFromDate action:action];
           // [unavailabilityTimeToCell update];
            [self resetTime];
            //[self.tableView reloadData];
            
        }
    }
    
    //SCHFieldTitleRepeat
    
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleRepeat]){
        
        if (newValue == [NSNull null]){
            
            rowDescriptor.value = oldValue;
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


#pragma mark - lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    // Do any additional setup after loading the view.
    self.backgroundQueue = [SCHBackgroundManager sharedManager].SCHSerialQueue;
    self.navigationItem.leftBarButtonItem.title = @"";
    self.navigationItem.title = @"Schedule";
    

    
    
    
    
    
    // Do any additional setup after loading the view.
    UIBarButtonItem *addavailButton = [[UIBarButtonItem alloc]
                                  
                                  
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                  
                                  
                                  target:self action:@selector(CancelAction)];
    
    self.navigationItem.leftBarButtonItem = addavailButton;
    
    
    if (self.serviceForAvailability){
        XLFormRowDescriptor *serviceRow = [self.form formRowWithTag:SCHFieldTitleService];
        XLFormOptionsObject *optionobject = [XLFormOptionsObject formOptionsObjectWithValue:self.serviceForAvailability displayText:self.serviceForAvailability.serviceTitle];
        serviceRow.value = optionobject;
    }
    
    if (self.selectedAvailabiity){
        //initiliatize changes
        self.repeatSection.hidden = @YES;
        [locationRow setValue:@{@"address" : self.selectedAvailabiity.location}];
        
        NSArray *services = self.selectedAvailabiity.services;
        
        // Now build selectors for services
        NSMutableArray *serviceList = [[NSMutableArray alloc] init];
        for (NSDictionary *serviceDict in services){
            SCHService *service = [serviceDict valueForKey:@"service"];
            XLFormOptionsObject *optionobject = [XLFormOptionsObject formOptionsObjectWithValue:service displayText:service.serviceTitle];
            [serviceList addObject:optionobject];
        }
        serviceRow.selectorOptions = serviceList;
        serviceRow.value = serviceList[0];
        timeFromRow.value = self.selectedAvailabiity.startTime;
        timeToRow.value = self.selectedAvailabiity.endTime;
        unavailabilityTimeToRow.value = self.selectedAvailabiity.endTime;
        
        
    }
    if (self.presetAvailabilityAction){
        if ([self.presetAvailabilityAction isEqualToString:SCHSelectorAvailabilityActionOptionUnavailable]){
            actionRow.value = [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:SCHSelectorAvailabilityActionOptionUnavailable];
            actionRow.disabled = @YES;
        } else if ([self.presetAvailabilityAction isEqualToString:SCHSelectorAvailabilityActionOptionChange]){
            actionRow.value = [XLFormOptionsObject formOptionsObjectWithValue:@(2) displayText:SCHSelectorAvailabilityActionOptionChange];
            actionRow.disabled = @YES;
        }
        
    }
    
    
    NSDate *timeFromDate = timeFromRow.value;
    
    NSString *action = [actionRow.value displayText];
    
    
    [self setMinMaxValueForDates:timeFromDate action:action];
        
    
    [self.tableView reloadData];
}


-(void) setMinMaxValueForDates:(NSDate *) timefromDate action:(NSString *) action{
    XLFormDateCell *timeFromCell = (XLFormDateCell *) [timeFromRow cellForFormController:self];
    XLFormDateCell *timeToCell = (XLFormDateCell *) [timeToRow cellForFormController:self];
    XLFormDateCell *unavailabilityTimeToCell = (XLFormDateCell *) [unavailabilityTimeToRow cellForFormController:self];
    XLFormDateCell *endDateCell = (XLFormDateCell *) [endDateRow cellForFormController:self];
    
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSCalendarUnit units = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay| NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitTimeZone;
    
    //End Time of Timefrom Date
    NSDateComponents *TFDcomponents = [preferredCalendar components:units fromDate:timefromDate];
    NSDateComponents *TFDETComponents = [[NSDateComponents alloc] init];
    [TFDETComponents setYear:TFDcomponents.year];
    [TFDETComponents setMonth:TFDcomponents.month];
    [TFDETComponents setDay:TFDcomponents.day];
    [TFDETComponents setHour:23];
    [TFDETComponents setMinute:45];
    [TFDETComponents setSecond:0];
    [TFDETComponents setTimeZone:TFDcomponents.timeZone];
    NSDate *timeFromDateEndTime = [preferredCalendar dateFromComponents:TFDETComponents];
    
    
    NSDateComponents *oneHour = [[NSDateComponents alloc] init];
    [oneHour setHour:1];
    NSDateComponents *oneHourLess = [[NSDateComponents alloc] init];
    [oneHourLess setHour:-1];
    NSDateComponents *oneWeek = [[NSDateComponents alloc] init];
    [oneWeek setDay:7];
    NSDateComponents *twoWeek = [[NSDateComponents alloc] init];
    [twoWeek setDay:14];

    NSDateComponents *oneMonth = [[NSDateComponents alloc] init];
    [oneMonth setMonth:1];
    [oneMonth setDay:-1];
    
    NSDate *currentDate = [SCHUtility startOrEndTime:[NSDate date]];
    NSDateComponents *CDcomponents = [preferredCalendar components:units fromDate:currentDate];
    [CDcomponents setHour:24];
    [CDcomponents setMinute:0];
    [CDcomponents setSecond:0];
    [CDcomponents setTimeZone:[NSTimeZone localTimeZone]];
    
    
    // set timefrom Minimum date
    [TFDETComponents setHour:0];
    [TFDETComponents setMinute:0];
    
    NSDate *timeFromDaysMinDate = [preferredCalendar dateFromComponents:TFDETComponents];
    
    NSDate *timeFromMinimumDate = nil;
    if ([currentDate compare:timeFromDaysMinDate] == NSOrderedAscending){
        timeFromMinimumDate = currentDate;
    } else{
        timeFromMinimumDate = timeFromDaysMinDate;
    }
    
    
    
    
    //Set min and max dates
    if (self.selectedAvailabiity){
        //timefrom Cell
        timeFromCell.minimumDate = timeFromMinimumDate;
        timeFromCell.maximumDate = [preferredCalendar dateByAddingComponents:oneHourLess toDate:timeFromDateEndTime options:NSCalendarMatchFirst];
        [timeFromCell update];
        
        //time To Cell
        timeToCell.minimumDate = [preferredCalendar dateByAddingComponents:oneHour toDate:timefromDate options:NSCalendarMatchFirst];
        timeToCell.maximumDate = timeFromDateEndTime;
        [timeToCell update];
        
        //Unavailability cell
        unavailabilityTimeToCell.minimumDate = [preferredCalendar dateByAddingComponents:oneHour toDate:timefromDate options:NSCalendarMatchFirst];        unavailabilityTimeToCell.maximumDate =timeFromDateEndTime;
        [unavailabilityTimeToCell update];
        
        //endDate
        endDateCell.minimumDate = nil;
        endDateCell.maximumDate =nil;
        [endDateCell update];
        
        
        
    } else{
        
        if ([action isEqualToString:SCHSelectorAvailabilityActionOptionAvailable]){
            //timefrom Cell
            timeFromCell.minimumDate = currentDate;
            timeFromCell.maximumDate = nil;
            [timeFromCell update];
            
            //time To Cell
            timeToCell.minimumDate = [preferredCalendar dateByAddingComponents:oneHour toDate:timefromDate options:NSCalendarMatchFirst];
            timeToCell.maximumDate = timeFromDateEndTime;
            [timeToCell update];
            
            //Unavailability cell
            unavailabilityTimeToCell.minimumDate = nil;
            unavailabilityTimeToCell.maximumDate =nil;
            [unavailabilityTimeToCell update];
            
            //endDate
            endDateCell.minimumDate = timeFromDateEndTime;
            endDateCell.maximumDate =[preferredCalendar dateByAddingComponents:oneMonth toDate:timeFromDateEndTime options:NSCalendarMatchFirst];
            [endDateCell update];
            
        } else if ([action isEqualToString:SCHSelectorAvailabilityActionOptionUnavailable]){
            //timefrom Cell
            timeFromCell.minimumDate = currentDate;
            timeFromCell.maximumDate = nil;
            [timeFromCell update];
            
            //time To Cell
            timeToCell.minimumDate = nil;
            timeToCell.maximumDate = nil;
            [timeToCell update];
            
            //Unavailability cell
            unavailabilityTimeToCell.minimumDate = [preferredCalendar dateByAddingComponents:oneHour toDate:timefromDate options:NSCalendarMatchFirst];
            unavailabilityTimeToCell.maximumDate = [preferredCalendar dateByAddingComponents:oneMonth toDate:timeFromDateEndTime options:NSCalendarMatchFirst];
            [unavailabilityTimeToCell update];
            
            //endDate
            endDateCell.minimumDate = nil;
            endDateCell.maximumDate =nil;
            [endDateCell update];
            
            
        } else if ([action isEqualToString:SCHSelectorAvailabilityActionOptionChange]){
            
            //timefrom Cell
            timeFromCell.minimumDate = currentDate;
            timeFromCell.maximumDate = nil;
            [timeFromCell update];
            
            //time To Cell
            timeToCell.minimumDate = [preferredCalendar dateByAddingComponents:oneHour toDate:timefromDate options:NSCalendarMatchFirst];
            timeToCell.maximumDate = timeFromDateEndTime;
            [timeToCell update];
            
            //Unavailability cell
            unavailabilityTimeToCell.minimumDate = nil;
            unavailabilityTimeToCell.maximumDate =nil;
            [unavailabilityTimeToCell update];
            
            //endDate
            endDateCell.minimumDate = timeFromDateEndTime;
            endDateCell.maximumDate =[preferredCalendar dateByAddingComponents:oneMonth toDate:timeFromDateEndTime options:NSCalendarMatchFirst];
            [endDateCell update];
            
        }
        
        
    }
    
    
}

-(void)resetTime{
    XLFormDateCell *timeFromCell = (XLFormDateCell *) [timeFromRow cellForFormController:self];
    XLFormDateCell *timeToCell = (XLFormDateCell *) [timeToRow cellForFormController:self];
    XLFormDateCell *unavailabilityTimeToCell = (XLFormDateCell *) [unavailabilityTimeToRow cellForFormController:self];
    XLFormDateCell *endDateCell = (XLFormDateCell *) [endDateRow cellForFormController:self];
    
    NSDate *timefromDate = timeFromRow.value;
    if ([timefromDate compare:timeFromCell.minimumDate] == NSOrderedAscending){
        timeFromRow.value = timeFromCell.minimumDate;
    }
    
    if (timeToRow.value && timeToCell.minimumDate && timeToCell.maximumDate){
        NSDate *timetoDate = timeToRow.value;
        if ([timetoDate compare:timeToCell.minimumDate] == NSOrderedAscending){
            timeToRow.value = timeToCell.minimumDate;
        }
        if ([timetoDate compare:timeToCell.maximumDate] == NSOrderedDescending){
            timeToRow.value = timeToCell.minimumDate;
        }
    }
    
    if (unavailabilityTimeToRow.value && unavailabilityTimeToCell.minimumDate && unavailabilityTimeToCell.maximumDate){
        NSDate *unavailabilityTimeToDate = unavailabilityTimeToRow.value;
        if ([unavailabilityTimeToDate compare:unavailabilityTimeToCell.minimumDate] == NSOrderedAscending){
            unavailabilityTimeToRow.value = unavailabilityTimeToCell.minimumDate;
        }
        if ([unavailabilityTimeToDate compare:unavailabilityTimeToCell.maximumDate] == NSOrderedDescending){
            unavailabilityTimeToRow.value = unavailabilityTimeToCell.minimumDate;
        }
    }
    
    if (endDateRow.value && endDateCell.minimumDate && endDateCell.maximumDate){
        NSDate *endDate = endDateRow.value;
        if ([endDate compare:endDateCell.minimumDate] == NSOrderedAscending){
            endDateRow.value = endDateCell.minimumDate;
        }
        if ([endDate compare:endDateCell.maximumDate] == NSOrderedDescending){
            endDateRow.value = endDateCell.maximumDate;
        }
        
        
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)save:(UIBarButtonItem *)sender {
    
     //check if all reuired values are provided
    
    action = ([self.formValues valueForKey:SCHFieldTitleAvailabilityAction] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleAvailabilityAction] displayText] : @"";
    
    service = ([self.formValues valueForKey:SCHFieldTitleService] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleService] valueData] : NULL;
    XLFormRowDescriptor *row = [self.formValues valueForKey:SCHFieldTitleLocation] ;
    location = [row isKindOfClass:[NSNull class]]?NULL:[row valueForKey:@"address"];
    
    timeFrom = ([self.formValues valueForKey:SCHFieldTitleFromTime] != NULL) ?  (NSDate *)[self.formValues valueForKey:SCHFieldTitleFromTime] : NULL;
    
    timeTo = nil;
    if ([action isEqualToString:SCHSelectorAvailabilityActionOptionAvailable]||[action isEqualToString:SCHSelectorAvailabilityActionOptionChange]){
        timeTo = ([self.formValues valueForKey:SCHFieldTitleToTime] != NULL) ? (NSDate *)[self.formValues valueForKey:SCHFieldTitleToTime] : NULL;
        
    } else if ([action isEqualToString:SCHSelectorAvailabilityActionOptionUnavailable]){
        timeTo = ([self.formValues valueForKey:@"UnavailabilityToTime"] != NULL) ? (NSDate *)[self.formValues valueForKey:@"UnavailabilityToTime"] : NULL;
    }
    
    if ([action isEqualToString:SCHSelectorAvailabilityActionOptionAvailable]){
        CancelAppointments = NO;
    } else{
        CancelAppointments = YES;
    }

    repeat = ([self.formValues valueForKey:SCHFieldTitleRepeat]) ? [self.formValues valueForKey:SCHFieldTitleRepeat] : SCHSelectorRepeatationOptionNever;
    endDate = ([repeat isEqualToString:SCHSelectorRepeatationOptionNever]) ? timeTo: ([self.formValues valueForKey:SCHFieldTitleEndDate] != NULL) ?[self.formValues valueForKey:SCHFieldTitleEndDate]: timeTo;
    
    repeatDays = [[NSMutableArray alloc] init];
    
    if ([repeat isEqualToString:SCHSelectorRepeatationOptionSpectficDaysOftheWeek]) {
        if (![[self.formValues valueForKey:SCHFieldTitleRepeatDays] isEqual:[NSNull null]])  {
            [repeatDays addObjectsFromArray:[self.formValues valueForKey:SCHFieldTitleRepeatDays]];
        }
        
    }
    
    if (debug) {
        NSLog(@" Action: %@", action);
        NSLog(@" Service: %@", service);
        NSLog(@" Location: %@", location);
        NSLog(@" time from : %@", timeFrom);
        NSLog(@" time To : %@", timeTo);
        NSLog(@" repeat : %@", repeat);
        NSLog(@" End Date: %@", endDate);
        NSLog(@" Specific Days of The Week: %@", repeatDays);
        NSLog(@"Cancel Existing Appointments: %d", CancelAppointments);
        
        

    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([self dataValidationForAction:action
                              service:service
                             location:location
                             timeFrom:timeFrom
                               timeTo:timeTo
                               repeat:repeat
                           repeatDays:repeatDays
                              endDate:endDate] && appDelegate.serverReachable){
        
        
        
        // Get availablity hours for publication
        if (([action isEqualToString:SCHSelectorAvailabilityActionOptionAvailable] || [action isEqualToString:SCHSelectorAvailabilityActionOptionChange])&& ![repeat isEqualToString:SCHSelectorRepeatationOptionNever]){
            
            
            NSArray *scheduledays =[SCHUtility getDaysforschedulingwithStartTime:timeFrom
                                                  endTime:timeTo
                                                  endDate:endDate
                                             repeatOption:repeat
                                               repeatDays:repeatDays];
            
            NSTimeInterval daysAvailabilityDuration = [timeTo timeIntervalSinceDate:timeFrom];
            int numberofTimeBlocksPerDay = daysAvailabilityDuration/SCHTimeBlockDuration;
            int totalTimeBlocks = numberofTimeBlocksPerDay * (int)scheduledays.count;
            
            if (totalTimeBlocks > 1000){
                

                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                   message:@"Maximum 250 hours of availability can be published in one go. Plese change timings accordingly"
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [theAlert show];
                
                
                return;
                
                
            }
            
        }
        
        // Check for appointment cancellation scenario
        if ([action isEqualToString:SCHSelectorAvailabilityActionOptionChange]||[action isEqualToString:SCHSelectorAvailabilityActionOptionUnavailable]){

            
            NSArray *conflictingAppoints = [self getConflictingAppointments];

            
            if (conflictingAppoints.count > 0){
                
                // show altert
                UIAlertView *conflictingAppointmentAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean" message:@"There are appointments" delegate:self cancelButtonTitle:@"Force Cancel & proceed" otherButtonTitles:@"Reschedule",@"Cancel free time only", nil];
                
                [conflictingAppointmentAlert show];
                
                
            } else{
                CancelAppointments = NO;
                [self processAvailability];
            }
            
        } else {
            // This is publishing availability
            [self processAvailability];
        }
        
        
    } else {
        
        if (!appDelegate.serverReachable){
            [self.navigationController popToRootViewControllerAnimated:YES];
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                               message:@"Internet Not Avaliable"
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
            [theAlert show];

            
        }
        
        
        return;
        
    }
     
}

- (void) beginBackgroundUpdateTask
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

-(void)availabilityProcessWithParamAction:(NSString *)action service:(SCHService *) service location:(NSString *) location timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo repeatOption:(NSString *) repeateOption repeatDays:(NSArray *) repeatDays endDate:(NSDate *) endDate{
    
    UIBackgroundTaskIdentifier taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void) {
        // Uh-oh - we took too long. Stop task.
    }];
    
    // Perform task here
    
    if (taskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:taskId];
    }

    
}




-(BOOL) dataValidationForAction:(NSString *)action service:(SCHService *) service location:(NSString *) location timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo repeat:(NSString *) repeat repeatDays:(NSArray *) repeatDays endDate:(NSDate *) endDate{
    BOOL datValid = NO;
    
    if ([action isEqualToString:@""]) {
        if (debug) {
            NSLog(@"sction : %@", [self.form valueForKey:SCHFieldTitleAvailabilityAction]);
            NSLog(@"Action must be provided");
        }
        datValid = NO;
    } else if ([action isEqualToString:SCHSelectorAvailabilityActionOptionAvailable]||[action isEqualToString:SCHSelectorAvailabilityActionOptionChange] ){
        
        if ([repeat isEqualToString:SCHSelectorRepeatationOptionNever]){
            
            
            if (service == NULL || location == NULL || timeFrom == NULL || timeTo == NULL) {
                
                
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"please fill out all the information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                
                datValid = NO;
            } else datValid = YES;
        } else if ([repeat isEqualToString:SCHSelectorRepeatationOptionSpectficDaysOftheWeek]){
            
            
            if (service == NULL || location == NULL || timeFrom == NULL || timeTo == NULL || [endDate isEqual:[NSNull null]] || repeatDays.count == 0) {
                
                
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"please fill out all the information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                
                datValid = NO;
                
            } else datValid = YES;
        } else {
            if (service == NULL || location == NULL || timeFrom == NULL || timeTo == NULL || [endDate isEqual:[NSNull null]]) {
                
                
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"please fill out all the information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                
                datValid = NO;
                
            } else datValid = YES;
        }
    }else if  ([action isEqualToString:SCHSelectorAvailabilityActionOptionUnavailable]) {
        
        if (debug) {
            NSLog(@"Processing Not available");
        }
        
        if ( timeFrom == NULL|| timeTo == NULL){
            NSLog(@"All required Values not provided");
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"Please provide all details.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            
            datValid = NO;
        } else datValid = YES;
    }
    
        

    
    return datValid;
}

-(NSSet *)appointmentExistsFromTime:(NSDate *) fromTime toTome:(NSDate *) toTime{
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
    NSTimeInterval oneMin = 60;
    NSMutableSet *existingAppointmentSet = [[NSMutableSet alloc] init];
    
    
    NSDate *timeFromForCheck = [NSDate dateWithTimeInterval:oneMin sinceDate:fromTime];
    NSDate *timeToForCheck = [NSDate dateWithTimeInterval:-oneMin sinceDate:toTime];
    
    
    NSPredicate *existingAppointmentWithCurrentTimePred1 = [NSPredicate predicateWithFormat:@"serviceProvider = %@ AND status IN {%@, %@}  AND (startTime BETWEEN %@ OR endTime BETWEEN %@)", appDelegate.user, constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, @[timeFromForCheck, timeToForCheck], @[timeFromForCheck, timeToForCheck]];
    
    PFQuery *existingAppointmentQuery1 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred1];
    
    [existingAppointmentQuery1 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery1 findObjects]];
    
    
    
    NSPredicate *existingAppointmentWithCurrentTimePred2 = [NSPredicate predicateWithFormat:@"serviceProvider = %@ AND status IN {%@, %@}  AND (proposedStartTime BETWEEN %@ OR proposedEndTime BETWEEN %@)", appDelegate.user, constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, @[timeFromForCheck, timeToForCheck], @[timeFromForCheck, timeToForCheck]];
    
    PFQuery *existingAppointmentQuery2 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred2];
    
    [existingAppointmentQuery2 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery2 findObjects]];
    
    NSPredicate *existingAppointmentWithCurrentTimePred3 = [NSPredicate predicateWithFormat:@"serviceProvider = %@ AND status IN {%@, %@}  AND (startTime <= %@ AND endTime => %@)", appDelegate.user, constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, timeFromForCheck, timeToForCheck];
    
    PFQuery *existingAppointmentQuery3 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred3];
    
    [existingAppointmentQuery3 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery3 findObjects]];
    
    NSPredicate *existingAppointmentWithCurrentTimePred4 = [NSPredicate predicateWithFormat:@"status IN {%@, %@}  AND (proposedStartTime <= %@ AND proposedEndTime => %@)", constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, timeFromForCheck, timeToForCheck];
    
    PFQuery *existingAppointmentQuery4 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred4];
    
    [existingAppointmentQuery3 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery4 findObjects]];
    
    
    
    
    return existingAppointmentSet;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if ([alertView.message isEqualToString:@"There are appointments"]){
        if(buttonIndex==0){
            CancelAppointments = YES;
            [self processAvailability];
        } else if (buttonIndex==1){
            
            // move to SChedule screen
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else if (buttonIndex == 2){
            
            CancelAppointments = NO;
            [self processAvailability];
            
        }
        
        
        
    }
    
}

-(NSArray *)getConflictingAppointments{
    NSDate *cancellationStartTime = nil;
    NSDate *cancellationEndTime = nil;
    
    if ([action isEqualToString:SCHSelectorAvailabilityActionOptionUnavailable]){

        
        
        cancellationStartTime = timeFrom;
        cancellationEndTime = timeTo;
        return  [SCHUtility conflictingAppointmentsForService:service
                                                                   location:location
                                                                   timeFrom:cancellationStartTime
                                                                     timeTo:cancellationEndTime];
    } else if ([action isEqualToString:SCHSelectorAvailabilityActionOptionChange]){

        
        NSCalendar *preferredCalendar =[NSCalendar currentCalendar];
        NSCalendarUnit units = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay| NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitTimeZone;
        
        if (![repeat isEqualToString:SCHSelectorRepeatationOptionNever]){
            NSDateComponents *cancellationStartComponents = [preferredCalendar components:units fromDate:timeFrom];
            [cancellationStartComponents setHour:0];
            [cancellationStartComponents setMinute:0];
            [cancellationStartComponents setSecond:1];
            [cancellationStartComponents setTimeZone:[NSTimeZone localTimeZone]];
            cancellationStartTime = [preferredCalendar dateFromComponents:cancellationStartComponents];
            
            NSDateComponents *cancellationEndComponents = [preferredCalendar components:units fromDate:endDate];
            [cancellationEndComponents setHour:24];
            [cancellationEndComponents setMinute:0];
            [cancellationEndComponents setSecond:0];
            [cancellationStartComponents setTimeZone:[NSTimeZone localTimeZone]];
            cancellationEndTime = [preferredCalendar dateFromComponents:cancellationEndComponents];
            
            return  [SCHUtility conflictingAppointmentsForService:service
                                                                       location:nil
                                                                       timeFrom:cancellationStartTime
                                                                         timeTo:cancellationEndTime];
            
            
        } else{
            
            
            NSDateComponents *cancellationStartComponents = [preferredCalendar components:units fromDate:timeFrom];
            [cancellationStartComponents setHour:0];
            [cancellationStartComponents setMinute:0];
            [cancellationStartComponents setSecond:0];
            [cancellationStartComponents setTimeZone:[NSTimeZone localTimeZone]];
            cancellationStartTime = [preferredCalendar dateFromComponents:cancellationStartComponents];
            
            NSDateComponents *cancellationEndComponents = [preferredCalendar components:units fromDate:timeTo];
            [cancellationEndComponents setHour:24];
            [cancellationEndComponents setMinute:0];
            [cancellationEndComponents setSecond:0];
            [cancellationStartComponents setTimeZone:[NSTimeZone localTimeZone]];
            cancellationEndTime = [preferredCalendar dateFromComponents:cancellationEndComponents];
            
            return  [SCHUtility conflictingAppointmentsForService:service
                                                                       location:nil
                                                                       timeFrom:cancellationStartTime
                                                                         timeTo:cancellationEndTime];
            
        }
    } else return @[];

}

-(void)processAvailability{
    
    SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
    if ([action isEqualToString:SCHSelectorAvailabilityActionOptionAvailable]){
        [SCHUtility showProgressWithMessage:SCHProgressMessageCreateAvability];
    } else if ([action isEqualToString:SCHSelectorAvailabilityActionOptionUnavailable]){
        [SCHUtility showProgressWithMessage:SCHProgressMessageCreateUnavailability];
    } else if ([action isEqualToString:SCHSelectorAvailabilityActionOptionChange]){
        [SCHUtility showProgressWithMessage:SCHProgressMessageChangingAvability];
    } else{
        [SCHUtility showProgressWithMessage:@""];
    }

    
    
    
    
    

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
                
                [self beginBackgroundUpdateTask];
                
                
                if ([SCHAvailabilityManager manageAvailableTimeWithAction:action
                                                              service:service
                                                             location:location
                                                        locationPoint:locationPoint
                                                             timeFrom:timeFrom
                                                               timeTo:timeTo
                                                         repeatOption:repeat
                                                   cancelAppointments:CancelAppointments
                                                           repeatDays:repeatDays
                                                                  endDate:endDate]){
                    
                    
                    [SCHUtility createUserLocation:location];
                    
                }
                
                
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
        
    
    
    
    
    
    

    
}

-(NSTimeInterval)getMinimumDuation{
    
    NSTimeInterval defaultDuration = 60*60;
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PFQuery *serviceQuery  = [SCHService query];
    [serviceQuery fromLocalDatastore];
   [serviceQuery whereKey:@"user" equalTo:appDelegate.user];
    
   // NSArray *services =[serviceQuery findObjects];
    
    
    
    PFQuery *serviceOfferingQuery = [SCHServiceOffering query];
    [serviceOfferingQuery fromLocalDatastore];
    [serviceOfferingQuery includeKey:@"service"];
   [serviceOfferingQuery whereKey:@"service" matchesQuery:serviceQuery];
    [serviceOfferingQuery orderByAscending:@"defaultDurationInMin"];
    
    SCHServiceOffering *OfferingWithMinDuration = (SCHServiceOffering *)[serviceOfferingQuery getFirstObject];
    
    
    if (OfferingWithMinDuration){
        defaultDuration = OfferingWithMinDuration.defaultDurationInMin*60;
    }
    
    
    
    
    return defaultDuration;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // create the parent view that will hold header Label
    if(section==0){
        UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
        
        UILabel *lblStr = [[UILabel alloc]initWithFrame:CGRectMake(12, 30, 150, 20)];
        lblStr.text = @"SERVICE";
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
    NSDictionary *blueBodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[UIColor blueColor]};
    
    
    

    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Action"] attributes:blueBodyAttr]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Business"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" and "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Location"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Enter from and to time"] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"For recuuring business schedule, select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Repeat"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" option and "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"End Date"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Tap on Save to publish business schedule."] attributes:bodyAttr]];
    
    
    
    
    
    

    
    
    return content;
    
}




-(NSAttributedString *) helpTitle{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Manage Schedule"]  attributes:titleAttr]];
    return title;
}

@end
