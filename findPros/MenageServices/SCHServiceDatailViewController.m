//
//  SCHServiceDatailViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 8/13/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHServiceDatailViewController.h"
#import "XLForm.h"
#import "SCHAddServiceDescription.h"
#import <Parse/Parse.h>
#import "SCHServiceClassification.h"
#import "SCHService.h"
#import "SCHServiceOffering.h"
#import "SCHservicePictureTableViewCell.h"
#import "SCHServiceOfferingViewController.h"
#import "SCHEditServiceViewController.h"
#import "SCHServiceMajorClassification.h"
#import "SCHManageAvailabilityViewController.h"
#import "SCHUserFeedback.h"


static NSString * const kRequestPublicVisibility = @"Request Public Visibility";
static NSString * const kRequestPublicVisibilityPending =  @"Public Visibility Request Pending";

@implementation SCHServiceDatailViewController

XLFormRowDescriptor *availabilityButtonRow;
XLFormRowDescriptor *PublicVisibilityButtonRow;
XLFormRowDescriptor *statusRow;
//XLFormRowDescriptor *ClassificationRow;
XLFormRowDescriptor *majorClassificationRow;
XLFormRowDescriptor *minorClassificationRow;
XLFormRowDescriptor *titleRow;
XLFormRowDescriptor *standerdChargeRow;
XLFormRowDescriptor *websiteRow;
XLFormRowDescriptor *profileVisibiltyControlRow;
XLFormRowDescriptor *AvailabilityVisibiltyControlRow;
XLFormRowDescriptor *AutoConfirmAppointmentRequestRow;
XLFormRowDescriptor *descriptionRow;
XLFormRowDescriptor *phoneNumberRow;
XLFormRowDescriptor *emailRow;
XLFormDescriptor * XLForm;
XLFormRowDescriptor * row;
XLFormSectionDescriptor *preferenceScection;
UIAlertView *privacyAlert;
UIAlertView *addAvailabilityAlert;


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

- (void)initializeForm {
    
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    
    form = [XLFormDescriptor formDescriptorWithTitle:@""];
    XLForm = form;
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"service";
    [form addFormSection:section];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"menageAvailability" rowType:XLFormRowDescriptorTypeButton title:@"Manage Business Schedule"];
    [row.cellConfig setObject:[UIColor blueColor] forKey:@"textLabel.textColor"];
    
    row.action.formSelector = @selector(AddAvaliblity);
    
    availabilityButtonRow = row;
    
    [section addFormRow:availabilityButtonRow];
    
    
    

    //Offering
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleViewOffering rowType:XLFormRowDescriptorTypeButton title:SCHFieldTitleViewOffering];
    [row.cellConfig setObject:[UIColor blueColor] forKey:@"textLabel.textColor"];
    
//    row.action.formSelector = @selector(AddAvaliblity);
    
//    availabilityButtonRow = row;
    
    [section addFormRow:row];

    
//    row =[XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleBusinessServices rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleBusinessServices];
//    row.selectorTitle = SCHFieldTitleBusinessServices;
//    row.required = YES;
//    row.selectorOptions = nil;//[self servicelist];
//    [section addFormRow:row];
    
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"RequestPublicVisibility" rowType:XLFormRowDescriptorTypeButton title:kRequestPublicVisibility];
    [row.cellConfig setObject:[UIColor blueColor] forKey:@"textLabel.textColor"];
    
    row.action.formSelector = @selector(requestPublicVisibility);
    
    PublicVisibilityButtonRow = row;
    
    [section addFormRow:PublicVisibilityButtonRow];
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"";
    [form addFormSection:section];
    
    
    titleRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"Title" rowType:XLFormRowDescriptorTypeText];
    titleRow.title = SCHFieldTitleBusinessName;
    [titleRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [titleRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [titleRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];

    [section addFormRow:titleRow];
    
    

    
    //status
    statusRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingStatus rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleOfferingStatus];
    [statusRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [statusRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [statusRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [section addFormRow:statusRow];
    
    
    
    
    //Service Type
    //Major Classification
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleMajorServiceClassification rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleMajorServiceClassification];
    row.required = YES;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    //row.selectorOptions = [SCHUtility getMajorServiceClassificationList];
    majorClassificationRow = row;
    [section addFormRow:row];
    
    
    
    // Minor Classification
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleMinorServiceClassification rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleMinorServiceClassification];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.required = YES;
    minorClassificationRow = row;
    [section addFormRow:row];
    
    //For Phone Number
    phoneNumberRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldBusinesPhone rowType:XLFormRowDescriptorTypePhone title:SCHFieldBusinesPhone];
    [phoneNumberRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    [phoneNumberRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [phoneNumberRow.cellConfig setObject:@NO forKey:@"textField.enabled"];

    [section addFormRow:phoneNumberRow];
    
    //For Email
    emailRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldBusinessEmail rowType:XLFormRowDescriptorTypeEmail title:SCHFieldBusinessEmail];
    [emailRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    [emailRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [emailRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    
    [section addFormRow:emailRow];
    
    

    
    
    standerdChargeRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"standaedCharge" rowType:XLFormRowDescriptorTypeInteger title:SCHFieldTitlePrice];
    [standerdChargeRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [standerdChargeRow.cellConfigAtConfigure setObject:@"Example: $100"forKey:@"textField.placeholder"];
    [standerdChargeRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [standerdChargeRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    
    [section addFormRow:standerdChargeRow];
    
    
    websiteRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"Website" rowType:XLFormRowDescriptorTypeURL title:@"Website"];
    [websiteRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    
    [websiteRow.cellConfigAtConfigure setObject:@"Website"forKey:@"textField.placeholder"];
    [websiteRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [websiteRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    
    [section addFormRow:websiteRow];
    
    //Preferences
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Privacy Options";
    preferenceScection = section;
    
    [form addFormSection:section];
    
    profileVisibiltyControlRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"profileVisibiltyControl" rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleBusinessProfileVisibility];
    [profileVisibiltyControlRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [profileVisibiltyControlRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    
    [profileVisibiltyControlRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    
    [section addFormRow:profileVisibiltyControlRow];
    
    
    AvailabilityVisibiltyControlRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"AvailabilityVisibiltyControl" rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleScheduleVisibility];
    [AvailabilityVisibiltyControlRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    
    [AvailabilityVisibiltyControlRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [AvailabilityVisibiltyControlRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [section addFormRow:AvailabilityVisibiltyControlRow];
    
    
    AutoConfirmAppointmentRequestRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"AutoConfirmAppointmentRequest" rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleAutoConfirm];
    [AutoConfirmAppointmentRequestRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    
    [AutoConfirmAppointmentRequestRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [AutoConfirmAppointmentRequestRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [section addFormRow:AutoConfirmAppointmentRequestRow];
    
    
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Desription";
    [form addFormSection:section];
    descriptionRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingDescripition rowType:XLFormRowDescriptorTypeTextView];
    [descriptionRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textView.textColor"];
    [descriptionRow.cellConfigAtConfigure setObject:@"Provide your credential and detail description of service" forKey:@"textView.placeholder"];
    [descriptionRow.cellConfig setObject:@NO forKey:@"textView.editable"];
    
    [section addFormRow:descriptionRow];
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    self.form = form;
    }
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    UIEdgeInsets newContentInset = self.tableView.contentInset;
    newContentInset.top = self.topLayoutGuide.length;
    
}

#pragma mark - XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue{
    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    
//    [rowDescriptor.cellConfigAtConfigure setObject:[UIColor greenColor] forKey:@"textField.textColor"];
    
}


-(void)AddAvaliblity{
    if (!self.serviceObject.suspended){
        [self performSegueWithIdentifier:@"availabilitySegue" sender:nil];
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

-(NSArray *) servicelist {
    NSMutableArray *serviceList = [[NSMutableArray alloc] init];
    PFQuery *query =[PFQuery queryWithClassName:@"SCHServiceClassification"];
    [query fromLocalDatastore];
    
    for (SCHServiceClassification *classification in [query findObjects]){
        XLFormOptionsObject *optionobject = [XLFormOptionsObject formOptionsObjectWithValue:classification displayText:classification.serviceTypeName];
        [serviceList addObject:optionobject];
    }
    
    
    return serviceList;
    
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
   

}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self promptToPublishAvailability];
    [self promptForPrivacyControl];
    if (self.serviceObject.suspended){
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

                [self.navigationItem setPrompt:@"Suspended. Email contact@counterbean.com"];
                
        });
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = @"";
        
    }
    
    
    
    
     self.form.delegate = self;
   // NSLog(@"%@", self.serviceObject);
    SCHConstants *constants = [SCHConstants sharedManager];
    
    self.navigationItem.title = self.serviceObject.serviceTitle;
    
    UIImage* image = [UIImage imageNamed:@"dummy_img.png"];
    self.userProfileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 130, 130)];
    [self.userProfileImageView setImage:image];
    self.userProfileImageView.layer.masksToBounds = YES;
    self.userProfileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.userProfileImageView.layer.cornerRadius = 6.0;
    self.userProfileImageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.userProfileImageView.layer.borderWidth = 2.0;
    
    self.userProfileImageView.userInteractionEnabled = NO;
    
    
    

    PFFile *imageFile = self.serviceObject.profilePicture;
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if(!error){
            UIImage *profileImage = [UIImage imageWithData:data];
            self.userProfileImageView.image = profileImage;
        }
    }];
    
    
    self.userProfileImageView.frame = CGRectMake( self.view.frame.size.width/2-65,20,130,130);
    [self.tableView addSubview:self.userProfileImageView];
    
    
    
    // setting service value
    statusRow.value = NULL;
   // NSLog(@"status Row Value: %@", statusRow.value);
   // NSLog(@"status Row Value: %@", statusRow.valueData);
    
    
    row = [self.form formRowWithTag:SCHFieldTitleOfferingStatus];
    
    if(self.serviceObject.active)
    {
        row.value = @"Active";
        [row.cellConfig setObject:[SCHUtility greenColor] forKey:@"textField.textColor"];
        availabilityButtonRow.hidden = @NO;
    }else{
        row.value = @"InActive";
        [row.cellConfig setObject:[SCHUtility brightOrangeColor] forKey:@"textField.textColor"];
        availabilityButtonRow.hidden = @YES;
    }
    
    [self updateFormRow:row];
    

    
    
    majorClassificationRow.value = self.serviceObject.serviceClassification.majorClassification.majorClassification;
    [self updateFormRow:majorClassificationRow];
    
    minorClassificationRow.value = self.serviceObject.serviceClassification.serviceTypeName;
    [self updateFormRow:minorClassificationRow];
    
//    row = [self.form formRowWithTag:@"serViceClassification"];
//    row.value = self.serviceObject.serviceClassification.serviceTypeName;
//    //row.disabled = @YES;
//    [self updateFormRow:row];
    
    row = [self.form formRowWithTag:@"Title"];
    row.value = self.serviceObject.serviceTitle;
    [row.cellConfigAtConfigure setObject:[UIColor redColor] forKey:@"textLabel.textColor"];
    [self updateFormRow:row];
    
    
    row = [self.form formRowWithTag:SCHFieldBusinesPhone];
    row.value = [SCHUtility phoneNumberFormate:self.serviceObject.businessPhone];
    [row.cellConfigAtConfigure setObject:[UIColor redColor] forKey:@"textLabel.textColor"];
    [self updateFormRow:row];
    
    row = [self.form formRowWithTag:SCHFieldBusinessEmail];
    row.value = self.serviceObject.businessEmail;
    [row.cellConfigAtConfigure setObject:[UIColor redColor] forKey:@"textLabel.textColor"];
    [self updateFormRow:row];
    

    row = [self.form formRowWithTag:@"standaedCharge"];
    row.value = [NSString stringWithFormat:@"%d",self.serviceObject.standardCharge ];
    //row.disabled = @YES;
    [self updateFormRow:row];
    
    row = [self.form formRowWithTag:@"Website"];
    row.value = self.serviceObject.website;
    //row.disabled = @YES;
    [self updateFormRow:row];
    
    row = [self.form formRowWithTag:@"profileVisibiltyControl"];
    row.value = (self.serviceObject.profileVisibilityControl) ? self.serviceObject.profileVisibilityControl.lookupText : constants.SCHPrivacyOptionPublic.lookupText;
    //row.disabled = @YES;
    [self updateFormRow:row];
    
    row = [self.form formRowWithTag:@"AvailabilityVisibiltyControl"];
    row.value = (self.serviceObject.availabilityVisibilityControl) ? self.serviceObject.availabilityVisibilityControl.lookupText : constants.SCHPrivacyOptionPublic.lookupText;
    //row.disabled = @YES;
    [self updateFormRow:row];
    
    row = [self.form formRowWithTag:@"AutoConfirmAppointmentRequest"];
    row.value = (self.serviceObject.autoConfirmAppointment) ? self.serviceObject.autoConfirmAppointment.lookupText : constants.SCHAutoConfirmOptionNone.lookupText;
    //row.disabled = @YES;
    [self updateFormRow:row];
    
 

    
    [self updateFormRow:row];
    
    
    
    row = [self.form formRowWithTag:SCHFieldTitleOfferingDescripition];
    row.value = self.serviceObject.serviceDescription;
    row.disabled = @YES;
    [self updateFormRow:row];
    
    if (self.serviceObject.restrictPublicVisibility){
        preferenceScection.hidden = @YES;
        if (self.serviceObject.publicVisibilityRequested){
            PublicVisibilityButtonRow.title = kRequestPublicVisibilityPending;
            [PublicVisibilityButtonRow.cellConfig setObject:[SCHUtility brightOrangeColor] forKey:@"textLabel.textColor"];
            PublicVisibilityButtonRow.disabled = @YES;
        }
        
    } else{
        PublicVisibilityButtonRow.hidden = @YES;
    }
    
    [self.tableView reloadData];
    
    
    
    NSMutableArray *newStack = [NSMutableArray arrayWithArray:[[self navigationController] viewControllers]];
    if([[newStack objectAtIndex:newStack.count-2] isKindOfClass:[SCHServiceNewOfferingsViewController class]])
    {
        [newStack removeObjectAtIndex:(newStack.count-2)];
        [newStack removeObjectAtIndex:(newStack.count-2)];
        [self.navigationController setViewControllers:newStack animated:YES];
    }
    [self.tableView reloadData];
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationItem.title = SCHBackkButtonTitle;
    
}

#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.serviceObject.active){
        if(indexPath.section==4 && indexPath.row==1){
            [self performSegueWithIdentifier:@"serviceOfferingSegue" sender:self.serviceObject];
        } else if(indexPath.section==4 && indexPath.row==0){
            [self AddAvaliblity];
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        }else if(indexPath.section==4 && indexPath.row==2){
            [self requestPublicVisibility];
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        }else{
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        }
    } else{
        if(indexPath.section==4 && indexPath.row==0){
            [self performSegueWithIdentifier:@"serviceOfferingSegue" sender:self.serviceObject];
        }else if(indexPath.section==4 && indexPath.row==1){
            [self requestPublicVisibility];
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        
        }else
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        
    }
}

#pragma overriding segue method
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{//appointmentDetailNew
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"serviceOfferingSegue"]){
        SCHServiceOfferingViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.serviceObject  =(SCHService *)sender;
    }else if([segue.identifier isEqualToString:@"EditServiceSegue"])
    {
        SCHEditServiceViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.serviceObject  =(SCHService *)self.serviceObject;
        vcToPushTo.sendingVC = self;
        
    } else if ([segue.identifier isEqualToString:@"availabilitySegue"]){
        SCHManageAvailabilityViewController *vcPushTo = segue.destinationViewController;
        vcPushTo.serviceForAvailability = self.serviceObject;
    }
}

-(void)promptToPublishAvailability{

    if (self.popUpAlertToPublishAvailability){
        dispatch_async(dispatch_get_main_queue(), ^{
            addAvailabilityAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                               message:[NSString localizedStringWithFormat:@"Publish Schedule for %@?", self.serviceObject.serviceTitle ]
                                                              delegate:self
                                                     cancelButtonTitle:@"No"
                                                     otherButtonTitles:@"Yes", nil];
            [addAvailabilityAlert show];
            
        });
        self.popUpAlertToPublishAvailability = NO;
    
        
    }
    
}

-(void)promptForPrivacyControl{
    
    if (self.serviceObject.restrictPublicVisibility && self.popUpAlertForPrivacyControl){
        dispatch_async(dispatch_get_main_queue(), ^{
            privacyAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                               message:@"Profile is prvate and visible only to your clients. \nEnable public Visibility?."
                                                              delegate:self
                                                     cancelButtonTitle:@"No"
                                                     otherButtonTitles:@"Yes",nil];
            [privacyAlert show];
            
        });
        self.popUpAlertForPrivacyControl = NO;
        
    }
    
}

-(void)requestPublicVisibility{
    if (!self.serviceObject.publicVisibilityRequested){
        SCHConstants *constants = [SCHConstants sharedManager];
        SCHUserFeedback *feedback = [SCHUserFeedback object];
        feedback.user = self.serviceObject.user;
        feedback.feedbackType = constants.SCHUserFeedbackIssue;
        feedback.feedbackTitle = @"Public Visibility Request";
        feedback.feedbackDetail = self.serviceObject.serviceTitle;
        
        if ([feedback save]){
            self.serviceObject.publicVisibilityRequested = YES;
            [self.serviceObject pin];
            [self.serviceObject save];
            PublicVisibilityButtonRow.title = kRequestPublicVisibilityPending;
            [PublicVisibilityButtonRow.cellConfig setObject:[SCHUtility brightOrangeColor] forKey:@"textLabel.textColor"];
            PublicVisibilityButtonRow.disabled = @YES;
            [self.tableView reloadData];
        }

        
    }
    
}



- (void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if ([theAlert isEqual:addAvailabilityAlert] && buttonIndex == 1){
        [self AddAvaliblity];
    } else if([theAlert isEqual:privacyAlert]&& buttonIndex == 1){
        [self requestPublicVisibility];
    }
        
    
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // create the parent view that will hold header Label
    
    /*
    if(section==4){
        UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
        // create the button object
        UIButton *headerBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-150,10,150-10 , 20.0)];
        headerBtn.backgroundColor = [UIColor clearColor];
        headerBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [headerBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        headerBtn.titleLabel.font = [SCHUtility getPreferredSubtitleFont];//[UIFont boldSystemFontOfSize:13];
        [headerBtn setTitle:@"Help" forState:UIControlStateNormal];
        [headerBtn addTarget:self action:@selector(helpAction) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:headerBtn];
        return customView;
        
    }
    */
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
    

        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"This screen gives details of your business profile"] attributes:bodyAttr]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Tap on Manage Schedule to manage your availability for business."] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Tap on View Offerings to view and manage offerings of this business. "] attributes:bodyAttr]];
    
    
    
    return content;
}




-(NSAttributedString *) helpTitle{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Business Profile"]  attributes:titleAttr]];
    return title;
}


@end
