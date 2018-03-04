//
//  SCHUserGroupAppointmentController.m
//  CounterBean
//
//  Created by Pratap Yadav on 16/06/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHMeetupController.h"
#import "SCHConstants.h"
#import "SCHUtility.h"
#import "AppDelegate.h"
#import "SCHLocationSelectorViewController.h"
#import "SPGooglePlacesAutocompleteDemoViewController.h"
#import "LocationValueTrasformer.h"
#import "SCHConfirmMeetup.h"


@interface SCHMeetupController ()



@end


@implementation SCHMeetupController


#pragma mark - XLform
XLFormRowDescriptor *timeFromRow;
XLFormRowDescriptor *timeToRow;
XLFormRowDescriptor *locationRow;
XLFormRowDescriptor *subjectRow;


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
    
    form = [XLFormDescriptor formDescriptorWithTitle:@"Meet-up"];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];

    // Subject
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"Subject" rowType:XLFormRowDescriptorTypeName title:@"Subject"];
    row.required = YES;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    
    subjectRow = row;
    
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
    timeFrom.minimumDate = [SCHUtility startOrEndTime:[NSDate date]];
    timeFrom.minuteInterval = 15;
    
    row.value = timeFrom.minimumDate;
    timeFromRow = row;
    
    [section addFormRow:row];
    
    // Time to
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleToTime rowType:XLFormRowDescriptorTypeDateTimeInline title:SCHFieldTitleToTime];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    timeToRow = row;
    XLFormDateCell *timeTo = (XLFormDateCell *) [row cellForFormController:self];
    NSTimeInterval defaultDuration = SCHTimeBlockDuration;
    timeTo.minuteInterval = 15;
    timeTo.minimumDate = [NSDate dateWithTimeInterval:defaultDuration sinceDate:timeFrom.minimumDate];
    row.value = timeTo.minimumDate;
    [section addFormRow:row];
    self.endTimeRow = row;


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

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue
{    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    if ([rowDescriptor isEqual:timeFromRow] && oldValue != newValue){
        [self resetTime];
        
    }
    if (subjectRow.value && locationRow.value){
        UIBarButtonItem *inviteButton = [[UIBarButtonItem alloc]
                                         initWithTitle:@"Invite" style:UIBarButtonItemStylePlain target:self action:@selector(GoToInviteScreen)];
        
        self.navigationItem.rightBarButtonItem =inviteButton;
        
    } else{
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = @"";
        
         
    }
    
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

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


-(void)GoToInviteScreen{
    
    NSString *subject;
    NSString *location;
    NSDate *fromTime;
    NSDate *toTime;
    
    subject = ([self.formValues valueForKey:@"Subject"] != NULL) ? [[self.formValues valueForKey:@"Subject"] displayText] : @"";
    
    XLFormRowDescriptor *row = [self.formValues valueForKey:SCHFieldTitleLocation] ;
    location = [row isKindOfClass:[NSNull class]]?NULL:[row valueForKey:@"address"];
    
    fromTime = ([self.formValues valueForKey:SCHFieldTitleFromTime] != NULL) ?  (NSDate *)[self.formValues valueForKey:SCHFieldTitleFromTime] : NULL;
    
    toTime = ([self.formValues valueForKey:SCHFieldTitleToTime] != NULL) ? (NSDate *)[self.formValues valueForKey:SCHFieldTitleToTime] : NULL;
   
    NSString *notes = ([self.formValues valueForKey:SCHFieldTitleNote] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleNote] displayText] : @"";

    NSMutableDictionary * meetupDic = [[NSMutableDictionary alloc] init];
    
    if (subject.length == 0 || location.length == 0){
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"please fill out all the information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    } else{
        
        [meetupDic setValue:subject forKey:@"subject"];
        [meetupDic setValue:location forKey:@"location"];
        [meetupDic setValue:fromTime forKey:@"from_date"];
        [meetupDic setValue:toTime forKey:@"to_date"];
        if (notes.length > 0){
            [meetupDic setValue:notes forKey:@"note"];
        }
        
        
    }
    
    
    SCHConfirmMeetup *tokenVC = [[SCHConfirmMeetup alloc] initWithNibName:@"SCHConfirmMeetup" bundle:nil];
    tokenVC.meetupInfo = meetupDic;
    tokenVC.saveAction =kcreateMeetup;
    
    [self.navigationController pushViewController:tokenVC animated:YES];
//    [self performSegueWithIdentifier:@"InviteScegue" sender:nil];
    
//    SCHConfirmGroupAppointment * confirmGroupAppointment = [self.storyboard instantiateViewControllerWithIdentifier:@"SCHConfirmGroupAppointment"];
//    [self.navigationController pushViewController:confirmGroupAppointment animated:true];
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    UIEdgeInsets newContentInset = self.tableView.contentInset;
    newContentInset.top = self.topLayoutGuide.length;
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title =@"Meet-up";
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.title =@"";
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

}

-(void)resetTime{
    XLFormDateCell *timeToCell = (XLFormDateCell *) [timeToRow cellForFormController:self];
    
    NSDate *timefromDate = timeFromRow.value;
    timeToCell.minimumDate = [NSDate dateWithTimeInterval:SCHTimeBlockDuration sinceDate:timefromDate];
    
    if (timeToRow.value){
        NSDate *timetoDate = timeToRow.value;
        if ([timefromDate compare:timetoDate] != NSOrderedAscending){
            timeToRow.value = timeToCell.minimumDate;
            [timeToCell update];
        }
    }else{
        timeToRow.value = timeToCell.minimumDate;
        [timeToCell update];
    }
    
    
}






@end
