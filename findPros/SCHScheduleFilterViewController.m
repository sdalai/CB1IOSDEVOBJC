//
//  SCHScheduleFilterViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 9/16/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHScheduleFilterViewController.h"
#import "SCHScheduleScreenFilter.h"
#import "SCHScheduledEventManager.h"
@implementation SCHScheduleFilterViewController
@synthesize isFilterChanged;
static NSString *const XLFormRowDescriptorTypeBooleanSwitch = @"booleanSwitch";
XLFormRowDescriptor *confirmendMyAppointmentRowDescriptor;
XLFormRowDescriptor *pendingMyResponceMyAppointmentRowDescriptor;
XLFormRowDescriptor *AwatingMyResoponceMyAppointmentRowDescriptor;
XLFormRowDescriptor *confirmendIAppointmentRowDescriptor;
XLFormRowDescriptor *pendingMyResponceIAppointmentRowDescriptor;
XLFormRowDescriptor *AwatingMyResoponceIAppointmentRowDescriptor;
XLFormRowDescriptor *expiredAppointmentRowDescriptor;
XLFormRowDescriptor *cancelledAppointmentRowDescriptor;
XLFormRowDescriptor *AvailabilitiesAppointmentRowDescriptor;
SCHScheduleScreenFilter *filterObj;
SCHScheduledEventManager *eventManager;

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
    
    eventManager = [SCHScheduledEventManager sharedManager];
    
    PFQuery *filterQuery = [SCHScheduleScreenFilter query];
    [filterQuery fromLocalDatastore];
     filterObj= [filterQuery getFirstObject];

    
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    //XLFormRowDescriptor * row;
    form = [XLFormDescriptor formDescriptorWithTitle:@"Filter"];
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Service Appointments";
    [form addFormSection:section];
    //Confirmed Appointments
     confirmendMyAppointmentRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:@"Confirmed Appointments" rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Confirmed appointments"];
    confirmendMyAppointmentRowDescriptor.value = filterObj.confirmedAppointmentsForMyServices?@1:@0;
    [section addFormRow:confirmendMyAppointmentRowDescriptor];
    //Pending Appointments awaiting my response
    pendingMyResponceMyAppointmentRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:@"Pending for my response" rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Awaiting other's response"];
    pendingMyResponceMyAppointmentRowDescriptor.value = filterObj.pendingAppointmentsForMyServicesNotAwaitingMyResponse?@1:@0;
    [section addFormRow:pendingMyResponceMyAppointmentRowDescriptor];
    
    //Pending Appointments not awaiting my response
    AwatingMyResoponceMyAppointmentRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:@"Awaiting my response" rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Awaiting my response"];
    AwatingMyResoponceMyAppointmentRowDescriptor.value =filterObj.pendingAppointmentsForMyServicesAwaitingMyResponse?@1:@0;
    [section addFormRow:AwatingMyResoponceMyAppointmentRowDescriptor];
    
    //section 2
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Personal Appointments";
    [form addFormSection:section];
    
    //Confirmed Appointments
    confirmendIAppointmentRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:@"Confirmed Appointments" rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Confirmed Appointments"];
    confirmendIAppointmentRowDescriptor.value = filterObj.confirmedAppointmentsIHaveBooked?@1:@0;
    [section addFormRow:confirmendIAppointmentRowDescriptor];
    
    //Pending Appointments awaiting my response
     pendingMyResponceIAppointmentRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:@"Pending for my response" rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Awaiting other's response"];
    pendingMyResponceIAppointmentRowDescriptor.value = filterObj.pendingAppointmentsIHaveBookedAwaitingMyResponse?@1:@0;
    [section addFormRow:pendingMyResponceIAppointmentRowDescriptor];
    
    //Pending Appointments not awaiting my response
     AwatingMyResoponceIAppointmentRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:@"Awaiting my response" rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Awaiting my response"];
    AwatingMyResoponceIAppointmentRowDescriptor.value = filterObj.pendingAppointmentsIHaveBookedNotAwaitingMyResponse?@1:@0;;
    [section addFormRow:AwatingMyResoponceIAppointmentRowDescriptor];
    
    //section 3
    section = [XLFormSectionDescriptor formSection];
    section.title = @"";
    [form addFormSection:section];
    
    //Pending Appointments not awaiting my response
    expiredAppointmentRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:@"Expired Appointments" rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Expired appointments"];
    expiredAppointmentRowDescriptor.value = filterObj.expiredAppointments?@1:@0;
    [section addFormRow:expiredAppointmentRowDescriptor];
    
    
    //Pending Appointments not awaiting my response
    cancelledAppointmentRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:@"Cancelled Appointments" rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Cancelled appointments"];
    cancelledAppointmentRowDescriptor.value = filterObj.cancelledAppointments?@1:@0;
    [section addFormRow:cancelledAppointmentRowDescriptor];
    
    //Pending Appointments not awaiting my response
    AvailabilitiesAppointmentRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:@"Availabilities" rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Availabilities"];
    AvailabilitiesAppointmentRowDescriptor.value = filterObj.availabilities?@1:@0;
    [section addFormRow:AvailabilitiesAppointmentRowDescriptor];

    
    self.form = form;
    
    
}



-(void)applyAction{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.serverReachable){
        isFilterChanged = NO;
        
        if(!(confirmendMyAppointmentRowDescriptor.value == (filterObj.confirmedAppointmentsForMyServices?@1:@0))){
            isFilterChanged = YES;
            filterObj.confirmedAppointmentsForMyServices = filterObj.confirmedAppointmentsForMyServices?NO:YES;
            
        }
        
        if(!(pendingMyResponceMyAppointmentRowDescriptor.value == (filterObj.pendingAppointmentsForMyServicesNotAwaitingMyResponse?@1:@0))){
            isFilterChanged = YES;
            filterObj.pendingAppointmentsForMyServicesNotAwaitingMyResponse = filterObj.pendingAppointmentsForMyServicesNotAwaitingMyResponse?NO:YES;
            
        }
        if(!(AwatingMyResoponceMyAppointmentRowDescriptor.value == (filterObj.pendingAppointmentsForMyServicesAwaitingMyResponse?@1:@0))){
            isFilterChanged = YES;
            filterObj.pendingAppointmentsForMyServicesAwaitingMyResponse = filterObj.pendingAppointmentsForMyServicesAwaitingMyResponse?NO:YES;
            
        }
        if(!(confirmendIAppointmentRowDescriptor.value == (filterObj.confirmedAppointmentsIHaveBooked?@1:@0))){
            isFilterChanged = YES;
            filterObj.confirmedAppointmentsIHaveBooked = filterObj.confirmedAppointmentsIHaveBooked?NO:YES;
            
        }
        if(!(pendingMyResponceIAppointmentRowDescriptor.value == (filterObj.pendingAppointmentsIHaveBookedNotAwaitingMyResponse?@1:@0))){
            isFilterChanged = YES;
            filterObj.pendingAppointmentsIHaveBookedNotAwaitingMyResponse = filterObj.pendingAppointmentsIHaveBookedNotAwaitingMyResponse?NO:YES;
            
        }
        if(!(AwatingMyResoponceIAppointmentRowDescriptor.value == (filterObj.pendingAppointmentsIHaveBookedAwaitingMyResponse?@1:@0))){
            isFilterChanged = YES;
            filterObj.pendingAppointmentsIHaveBookedAwaitingMyResponse = filterObj.pendingAppointmentsIHaveBookedAwaitingMyResponse?NO:YES;
            
        }
        if(!(cancelledAppointmentRowDescriptor.value == (filterObj.cancelledAppointments?@1:@0))){
            isFilterChanged = YES;
            filterObj.cancelledAppointments = filterObj.cancelledAppointments?NO:YES;
            
        }
        if(!(expiredAppointmentRowDescriptor.value == (filterObj.expiredAppointments?@1:@0))){
            isFilterChanged = YES;
            filterObj.expiredAppointments = filterObj.expiredAppointments?NO:YES;
            
        }
        if(!(AvailabilitiesAppointmentRowDescriptor.value == (filterObj.availabilities?@1:@0))){
            isFilterChanged = YES;
            filterObj.availabilities = filterObj.availabilities?NO:YES;
        }
        
        if (isFilterChanged){
            [filterObj pin];
            [filterObj save];
            
        }

    } else {
        UIAlertView *theView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                         message:@"Server is not Reachable!"
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil, nil];
        [theView show];
    }
    
    
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}

#pragma mark - viewController

-(void)viewWillAppear:(BOOL)animated{
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc]
                                  initWithTitle:@"Cancel"
                                  style:UIBarButtonItemStylePlain
                                  target:self
                                  action:@selector(cancelAction)];
    
    self.navigationItem.leftBarButtonItem = cancelBtn;
    
    UIBarButtonItem *applyBtn = [[UIBarButtonItem alloc]
                                  initWithTitle:@"Apply"
                                  style:UIBarButtonItemStylePlain
                                  target:self
                                  action:@selector(applyAction)];
    
    self.navigationItem.rightBarButtonItem = applyBtn;
    

    
}

-(void)cancelAction{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
