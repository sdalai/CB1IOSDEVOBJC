//
//  SCHEditServiceViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/23/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHEditServiceViewController.h"
#import "AppDelegate.h"
#import "SCHAlert.h"
#import "SCHUser.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
#import <IODProfanityFilter/IODProfanityFilter.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
#import <libPhoneNumber-iOS/NBNumberFormat.h>
#import <libPhoneNumber-iOS/NBMetadataCore.h>
#import <libPhoneNumber-iOS/NBPhoneMetaData.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>


@interface SCHEditServiceViewController () <UITextFieldDelegate,CNPPopupControllerDelegate, FDTakeDelegate>
@property (nonatomic, strong) PFFile *imageFile;
@property (nonatomic, strong) CNPPopupController *popupController;
@property (nonatomic, strong) NBPhoneNumberUtil *phoneUtil;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NBAsYouTypeFormatter *phoneFormatter;
@property (nonatomic, strong) NSString *countryCode;

@end

@implementation SCHEditServiceViewController
XLFormRowDescriptor *statusRow;
XLFormRowDescriptor *majorClassificationRow;
XLFormRowDescriptor *minorClassificationRow;
XLFormRowDescriptor *titleRow;
XLFormRowDescriptor *standerdChargeRow;
XLFormRowDescriptor *websiteRow;
XLFormRowDescriptor *profileVisibiltyControlRow;
XLFormRowDescriptor *AvailabilityVisibiltyControlRow;
XLFormRowDescriptor *AutoConfirmAppointmentRequestRow;
XLFormRowDescriptor *descriptionRow;
XLFormRowDescriptor * phoneNoRow;
XLFormRowDescriptor * emailRow;
XLFormSectionDescriptor *privacyOptionSection;
UITextField *txtPhoneno;
UITextField *txtEmail;
UILabel *txtMessage;

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
//    XLFormRowDescriptor * row;
    form = [XLFormDescriptor formDescriptorWithTitle:@"Edit Business"];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    section.title=@"service";
    [form addFormSection:section];
    
    
    //Title
    
    titleRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"Title" rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleBusinessName];
    [titleRow.cellConfigAtConfigure setObject:@"required"forKey:@"textField.placeholder"];
    [titleRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [titleRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:titleRow];
    
    
    //For Status
    statusRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingStatus rowType:XLFormRowDescriptorTypeBooleanSwitch title:SCHFieldTitleOfferingStatus];
    
    statusRow.required = YES;
   
  
    [section addFormRow:statusRow];
    
    
    
    //Service Type
    //Major Classification
    majorClassificationRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleMajorServiceClassification rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleMajorServiceClassification];
    majorClassificationRow.required = YES;
    majorClassificationRow.selectorTitle = SCHFieldTitleMajorServiceClassification;
    [majorClassificationRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
   // majorClassificationRow.selectorOptions = [SCHUtility getMajorServiceClassificationList];
    [section addFormRow:majorClassificationRow];
    

    
    // Minor Classification
    minorClassificationRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleMinorServiceClassification rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleMinorServiceClassification];
    minorClassificationRow.selectorTitle = SCHFieldTitleMinorServiceClassification ;
    [minorClassificationRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
   
    minorClassificationRow.required = YES;
    [section addFormRow:minorClassificationRow];
    
    //For Phone Number
    phoneNoRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfilePhoneNumber rowType:XLFormRowDescriptorTypePhone title:SCHFieldTitleProfilePhoneNumber];
    [phoneNoRow.cellConfigAtConfigure setObject:@"Business phone number"forKey:@"textField.placeholder"];
    
    [phoneNoRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [phoneNoRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [phoneNoRow.cellConfig setObject:@"99" forKey:@"textField.tag"];
    [section addFormRow:phoneNoRow];
    
    
    //For Email
    emailRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldBusinessEmail rowType:XLFormRowDescriptorTypeEmail title:SCHFieldBusinessEmail];
    [emailRow.cellConfigAtConfigure setObject:@"Business Email"forKey:@"textField.placeholder"];
    [emailRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [emailRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [emailRow.cellConfig setObject:@"999" forKey:@"textField.tag"];
    [section addFormRow:emailRow];
 
    
    standerdChargeRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"standaedCharge" rowType:XLFormRowDescriptorTypeInteger title:SCHFieldTitlePrice];
    [standerdChargeRow.cellConfigAtConfigure setObject:@"Example: $100"forKey:@"textField.placeholder"];
    [standerdChargeRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [standerdChargeRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [section addFormRow:standerdChargeRow];
    
    websiteRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"Website" rowType:XLFormRowDescriptorTypeURL title:@"Website"];
    [websiteRow.cellConfigAtConfigure setObject:@"Website"forKey:@"textField.placeholder"];
    [websiteRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [websiteRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [websiteRow.cellConfig setObject:@"900" forKey:@"textField.tag"];
    [section addFormRow:websiteRow];
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Privacy Options";
    privacyOptionSection = section;
    [form addFormSection:privacyOptionSection];
    
    
    
    profileVisibiltyControlRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"profileVisibiltyControl" rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleBusinessProfileVisibility];
    profileVisibiltyControlRow.selectorOptions = [SCHUtility privacyPrefrences];
    profileVisibiltyControlRow.selectorTitle = @"Privacy Preference";
    [profileVisibiltyControlRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    [section addFormRow:profileVisibiltyControlRow];
    
    
    AvailabilityVisibiltyControlRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"AvailabilityVisibiltyControl" rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleScheduleVisibility];
    AvailabilityVisibiltyControlRow.selectorOptions = [SCHUtility privacyPrefrences];
    AvailabilityVisibiltyControlRow.selectorTitle = @"Options";
    [AvailabilityVisibiltyControlRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    [section addFormRow:AvailabilityVisibiltyControlRow];
    

    AutoConfirmAppointmentRequestRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"AutoConfirmAppointmentRequest" rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleAutoConfirm];
    AutoConfirmAppointmentRequestRow.selectorOptions = [SCHUtility autoConfirmOptions];
    AutoConfirmAppointmentRequestRow.selectorTitle = @"Options";
    [AutoConfirmAppointmentRequestRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    [section addFormRow:AutoConfirmAppointmentRequestRow];
 
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Desription";
    [form addFormSection:section];
   
    descriptionRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingDescripition rowType:XLFormRowDescriptorTypeTextView];
    [descriptionRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textView.textColor"];
    [descriptionRow.cellConfigAtConfigure setObject:@"Provide your credential and detail description of Business" forKey:@"textView.placeholder"];
    [section addFormRow:descriptionRow];
    
    
    
    
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
    
    [rowDescriptor.cellConfigAtConfigure setObject:[UIColor greenColor] forKey:@"textField.textColor"];
    if ([rowDescriptor.tag isEqualToString:SCHFieldTitleMajorServiceClassification] && oldValue != newValue) {
        XLFormRowDescriptor *minorClassificationRow = [self.form formRowWithTag:SCHFieldTitleMinorServiceClassification];
        minorClassificationRow.disabled = @NO;
        
        SCHServiceMajorClassification *selectedMajorClassificationObject = (SCHServiceMajorClassification *)[newValue valueData];
        NSArray* minorClassificationList = [SCHUtility getServiceClassificationList:selectedMajorClassificationObject];
        minorClassificationRow.selectorOptions = minorClassificationList;
        if (minorClassificationList.count == 1){
            XLFormTextFieldCell *serviceTypeRow = (XLFormTextFieldCell *) [minorClassificationRow cellForFormController:self];
            minorClassificationRow.value = (XLFormOptionsObject *)minorClassificationList[0];
            [serviceTypeRow update];
        }
        
        if (oldValue != newValue){
            minorClassificationRow.value = NULL;
            [self.tableView reloadData];
        }
        
    }
    
    if ([rowDescriptor.tag isEqualToString:@"profileVisibiltyControl"]) {
        if (newValue == [NSNull null]){
            
            rowDescriptor.value = oldValue;
        }
        
    }
    if ([rowDescriptor.tag isEqualToString:@"AvailabilityVisibiltyControl"]) {
        if (newValue == [NSNull null]){
            
            rowDescriptor.value = oldValue;
        }
        
    }
    if ([rowDescriptor.tag isEqualToString:@"AutoConfirmAppointmentRequest"]) {
        if (newValue == [NSNull null]){
            
            rowDescriptor.value = oldValue;
        }
        
    }
    
    
}


-(NSArray *) servicelist {
    NSMutableArray *serviceList = [[NSMutableArray alloc] init];
    PFQuery *query =[PFQuery queryWithClassName:@"SCHServiceClassification"];
    
    for (SCHServiceClassification *classification in [query findObjects]){
        XLFormOptionsObject *optionobject = [XLFormOptionsObject formOptionsObjectWithValue:classification displayText:classification.serviceTypeName];
        [serviceList addObject:optionobject];
    }
    
    
    return serviceList;
    
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    self.countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    
    self.phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    self.phoneFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:self.countryCode];
    
    SCHConstants *constants = [SCHConstants sharedManager];
    
    
    
    UIImage* image = [UIImage imageNamed:@"dummy_img.png"];
    self.userProfileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 130, 130)];
    [self.userProfileImageView setImage:image];
    self.userProfileImageView.layer.masksToBounds = YES;
    self.userProfileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.userProfileImageView.layer.cornerRadius = 6.0;
    self.userProfileImageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.userProfileImageView.layer.borderWidth = 2.0;
    
    self.userProfileImageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openImageSelecter)];
    
    [self.userProfileImageView addGestureRecognizer:tap];
    
    
    self.imageFile = self.serviceObject.profilePicture;
    
    
    self.userProfileImageView.frame = CGRectMake( self.view.frame.size.width/2-65,10,130,130);
    [self.tableView addSubview:self.userProfileImageView];
    txtMessage = [[UILabel alloc]initWithFrame:CGRectMake( self.view.frame.size.width/2-80,135,160,30)];
    [txtMessage setText:@"Change"];
    [txtMessage setFont:[UIFont systemFontOfSize:12]];
    [txtMessage setTextAlignment:NSTextAlignmentCenter];
    [txtMessage setTextColor:[UIColor blueColor]];
    [self.tableView addSubview:txtMessage];
    
    
    if (self.imageFile){
        [self.imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(!error){
                UIImage *profileImage = [UIImage imageWithData:data];
                self.userProfileImageView.image = profileImage;
                [txtMessage setText:@"Change"];
            }
        }];
    }else{
        [txtMessage setText:@"Change"];
    }


    
    // Do any additional setup after loading the view.
    
    
    
    self.takeController = [[FDTakeController alloc] init];
    self.takeController.delegate = self;
    // You can optionally override action sheet titles
    self.takeController.takePhotoText = @"Take Photo";
    self.takeController.chooseFromLibraryText = @"Choose Photo";
    self.takeController.cancelText = @"Cancel";
    self.takeController.allowsEditingPhoto = true;
    
    PFQuery *serviceCountQuery =[PFQuery queryWithClassName:@"SCHService"];
    [serviceCountQuery whereKey:@"user" equalTo:self.serviceObject.user];
    [serviceCountQuery whereKey:@"active" equalTo:@YES];
    [serviceCountQuery fromLocalDatastore];
    
    
    
    
    
    // setting service valuse
    if(self.serviceObject.active)
    {
        statusRow.value = @1;
    }else{
         statusRow.value = @0;
    }
    
    
    if (!self.serviceObject.active && [serviceCountQuery countObjects] >= 3){
        statusRow.disabled = @YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                               message:@"Active businesses allowed: 3.\nPlease deactivate other businessess in order to activate this business."
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
            [theAlert show];
            
        });

    }
    
    
    //Major Classification
    
     NSArray *majorClassifications = [SCHUtility getMajorServiceClassificationList];
    majorClassificationRow.selectorOptions = majorClassifications;
    SCHServiceMajorClassification *selctedMajorClassification = self.serviceObject.serviceClassification.majorClassification;
    XLFormOptionsObject *selectedMajVlaueData = nil;
    for (XLFormOptionsObject *object in majorClassifications){
        if ([object.valueData isEqual:selctedMajorClassification ]){
            selectedMajVlaueData = object;
            break;
        }
    
    }
    
    if (selectedMajVlaueData){
        majorClassificationRow.value = selectedMajVlaueData;
    } else{
        majorClassificationRow.value = selctedMajorClassification.majorClassification;
    }

    //Minor Classification
    NSArray *minorClassifications = minorClassificationRow.selectorOptions;
    
    if (minorClassifications.count  ==0){
        XLFormOptionsObject *serviceType = [XLFormOptionsObject formOptionsObjectWithValue:self.serviceObject.serviceClassification displayText:self.serviceObject.serviceClassification.serviceTypeName];
        
        minorClassificationRow.value = serviceType;
        
    } else {
        for (XLFormOptionsObject *minorClassObj in minorClassifications){
            if ([minorClassObj.valueData isEqual:self.serviceObject.serviceClassification]){
                minorClassificationRow.value = minorClassObj;
                break;
            }
            
        }
        if (!minorClassificationRow.value){
            XLFormOptionsObject *serviceType = [XLFormOptionsObject formOptionsObjectWithValue:self.serviceObject.serviceClassification displayText:self.serviceObject.serviceClassification.serviceTypeName];
            
            minorClassificationRow.value = serviceType;

        }
    }
    
     

     
    titleRow.value = self.serviceObject.serviceTitle;
    if(self.serviceObject.standardCharge){
        standerdChargeRow.value = [NSString stringWithFormat:@"%d",self.serviceObject.standardCharge ];
    }else {
        standerdChargeRow.value = [NSString stringWithFormat:@"%d",0];
    }
 
    SCHLookup *profileVisibilityControl = (self.serviceObject.profileVisibilityControl) ? self.serviceObject.profileVisibilityControl : constants.SCHPrivacyOptionPublic;
    XLFormOptionsObject *profileVisibilityValue = [XLFormOptionsObject formOptionsObjectWithValue:profileVisibilityControl  displayText:profileVisibilityControl.lookupText];
    profileVisibiltyControlRow.value = profileVisibilityValue;
    if (self.serviceObject.restrictPublicVisibility){
        profileVisibiltyControlRow.disabled = @YES;
    }
    
    
    SCHLookup *availabilityVisibilityControl = (self.serviceObject.availabilityVisibilityControl) ? self.serviceObject.availabilityVisibilityControl : constants.SCHPrivacyOptionPublic;
    XLFormOptionsObject *availabilityVisibilityValue = [XLFormOptionsObject formOptionsObjectWithValue:availabilityVisibilityControl  displayText:availabilityVisibilityControl.lookupText];
    AvailabilityVisibiltyControlRow.value = availabilityVisibilityValue;
    
    if (self.serviceObject.restrictPublicVisibility){
        AvailabilityVisibiltyControlRow.disabled = @YES;
    }
    
    
    SCHLookup *autoConfirmAppointment = (self.serviceObject.autoConfirmAppointment) ? self.serviceObject.autoConfirmAppointment : constants.SCHAutoConfirmOptionNone;
    XLFormOptionsObject *autoConfirmValue = [XLFormOptionsObject formOptionsObjectWithValue:autoConfirmAppointment  displayText:autoConfirmAppointment.lookupText];
    AutoConfirmAppointmentRequestRow.value =autoConfirmValue;
    
    
    websiteRow.value = self.serviceObject.website;
    descriptionRow.value = self.serviceObject.serviceDescription;
    
    
    phoneNoRow.value = [SCHUtility phoneNumberFormate:self.serviceObject.businessPhone];
    emailRow.value = self.serviceObject.businessEmail;
    if (self.serviceObject.restrictPublicVisibility){
        privacyOptionSection.hidden = @YES;
    }
    /*
    if(self.serviceObject.phoneRequiredForBooking)
    {
        CustomerPhoneNumberRequiredRow.value = @1;
    }else{
        CustomerPhoneNumberRequiredRow.value = @0;
    }
*/
    
    
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationItem.title = SCHBackkButtonTitle;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Edit Profile";
}

#pragma mark - FDTakeDelegate
-(void)openImageSelecter{
    [self.takeController takePhotoOrChooseFromLibrary];
}


- (void)takeController:(FDTakeController *)controller didCancelAfterAttempting:(BOOL)madeAttempt
{
    //    UIAlertView *alertView;
    //        alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean Says" message:@"Action Canceled By You" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //
    //    [alertView show];
}

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.userProfileImageView setImage:photo];
    NSData *imageData = UIImagePNGRepresentation(photo);
    int timestamp = [[NSDate date] timeIntervalSince1970];
    
    self.imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@-%d.png", appDelegate.user.objectId,timestamp] data:imageData];
    [txtMessage setText:@"Change"];
}

//[self performSegueWithIdentifier:@"goToAddNewOffering" sender:service];



#pragma mark - Navigation




- (IBAction)saveAction:(id)sender {
    

    
    SCHServiceClassification *serviceClassification = ([self.formValues valueForKey:SCHFieldTitleMinorServiceClassification] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleMinorServiceClassification] valueData] : nil;
    
  
    
    
    
    NSString *title = (![[[self.formValues valueForKey:@"Title"] displayText] isEqualToString:@""]) ? [[self.formValues valueForKey:@"Title"] valueData] : nil;
    
    int charge =(![[[self.formValues objectForKey:@"standaedCharge"] displayText] isEqualToString:@""]) ? [[[self.formValues objectForKey:@"standaedCharge"] displayText] intValue] : 0;
    
    NSString *website = (![[[self.formValues valueForKey:@"Website"] displayText] isEqualToString:@""]) ? [[self.formValues valueForKey:@"Website"] valueData] : nil;
    
    
    if (website){
        if (![self urlIsValiad:website]){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                   message:@"Please enter valid URL."
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [theAlert show];
                
            });
            
            
            return;
            
        }
        
    }

    
    
    NSString *description =(![[[self.formValues valueForKey:SCHFieldTitleOfferingDescripition] displayText] isEqualToString:@""]) ? [[self.formValues valueForKey:SCHFieldTitleOfferingDescripition] displayText] : nil;
    
    BOOL status = [[self.formValues valueForKey:SCHFieldTitleOfferingStatus] boolValue];
    
    
    SCHLookup *businessProfileVisibility = [[self.formValues valueForKey:@"profileVisibiltyControl"] valueData];
    SCHLookup *availabilityVisibility = [[self.formValues valueForKey:@"AvailabilityVisibiltyControl"] valueData];
    SCHLookup *autoconfirmControl = [[self.formValues valueForKey:@"AutoConfirmAppointmentRequest"] valueData];
    
    NSString *phoneNumberFieldValue = phoneNoRow.value;
    NSString *phoneNumber = nil;
    NSError *error = nil;
    
    if (phoneNumberFieldValue.length == 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                               message:@"Please enter your business phone Number."
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
            [theAlert show];
            
        });
        
        return;
        
        
    } else {
        NBPhoneNumber *NBNumber = [self.phoneUtil parse:phoneNumberFieldValue defaultRegion:self.countryCode error:&error];
        if (!error){
            if ([self.phoneUtil isValidNumber:NBNumber]){
                phoneNumber = [self.phoneUtil format:NBNumber
                                        numberFormat:NBEPhoneNumberFormatE164
                                               error:&error];
                if (error){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                           message:@"Please enter your business phone Number."
                                                                          delegate:self
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
                        [theAlert show];
                        
                    });
                    return;
                    
                }
                
            } else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                       message:@"Please enter your business phone Number."
                                                                      delegate:self
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                    [theAlert show];
                    
                });
                return;
                
            }
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                   message:@"Please enter your business phone Number."
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [theAlert show];
                
            });
            return;
        }
        
        
        
        
        
    }
    
    NSString *email = emailRow.value;
    if (![self isValidEmail:email]){
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                               message:@"Please enter valid email address."
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
            [theAlert show];
            
        });
        
        
        return;
        
        
    }
    
    
    
    
    if(serviceClassification && title)
    {
         // create service for user
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if(appDelegate.serverReachable){
            self.serviceObject.serviceClassification = serviceClassification;
            self.serviceObject.serviceTitle = [IODProfanityFilter stringByFilteringString:title];
            self.serviceObject.businessPhone = phoneNumber;
            self.serviceObject.businessEmail = email;
            self.serviceObject.standardCharge = charge;
            self.serviceObject.website = website;
            self.serviceObject.profileVisibilityControl = (businessProfileVisibility) ? businessProfileVisibility : self.serviceObject.profileVisibilityControl;
            self.serviceObject.availabilityVisibilityControl = (availabilityVisibility) ? availabilityVisibility : self.serviceObject.availabilityVisibilityControl;
            self.serviceObject.autoConfirmAppointment = (autoconfirmControl) ? autoconfirmControl : self.serviceObject.autoConfirmAppointment;
            self.serviceObject.serviceDescription = [IODProfanityFilter stringByFilteringString:description];
            self.serviceObject.active = status;
            if (self.imageFile){
                self.serviceObject.profilePicture = self.imageFile;
            }
            
            [self.serviceObject pin];
            [self.serviceObject save];
            
            
            [SCHUtility setServiceProviderStatus];
            
            [SCHUtility setServiceCategoryVisibility:self.serviceObject.serviceClassification.majorClassification serviceClassification:self.serviceObject.serviceClassification];
            
            if (self.sendingVC){
                self.sendingVC.serviceObject = self.serviceObject;
            }
            
            [self.navigationController popViewControllerAnimated:YES];
            
        }else{
            [SCHAlert internetOutageAlert];
        }
        
    }else{
        
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                           message:@"Please provide all details"
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
    }
    
    
    
}
- (IBAction)cancelEdit:(id)sender
{
[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Text Feild Deligate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField.tag==99) {
        NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"()- "];
        
        // NSString *stripppedNumber = [newText stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [newText length])];
        NSString *stripppedNumber = [[newText componentsSeparatedByCharactersInSet: doNotWant] componentsJoinedByString: @""];
        
        UITextRange *selectedRange = [textField selectedTextRange];
        NSInteger oldLength = [textField.text length];
        
        
        /*
         
         if (digits == 0)
         textField.text = @"";
         else if (digits < 3 || (digits == 3 && deleting))
         textField.text = [NSString stringWithFormat:@"(%@", stripppedNumber];
         
         else if (digits < 6 || (digits == 6 && deleting))
         textField.text = [NSString stringWithFormat:@"(%@) %@", [stripppedNumber substringToIndex:3], [stripppedNumber substringFromIndex:3]];
         else
         textField.text = [NSString stringWithFormat:@"(%@) %@-%@", [stripppedNumber substringToIndex:3], [stripppedNumber substringWithRange:NSMakeRange(3, 3)], [stripppedNumber substringFromIndex:6]];
         
         */
        
        if (range.length ==0){
            textField.text = [self.phoneFormatter inputString:stripppedNumber];
            
        } else{
            textField.text = [self.phoneFormatter removeLastDigit];
        }
        
        
        
        
        UITextPosition *newPosition = [textField positionFromPosition:selectedRange.start offset:[textField.text length] - oldLength];
        UITextRange *newRange = [textField textRangeFromPosition:newPosition toPosition:newPosition];
        [textField setSelectedTextRange:newRange];
        
        // if (digits == 10)
        NSError *error = nil;
        
        NBPhoneNumber *phoneNumber = [self.phoneUtil parse:stripppedNumber defaultRegion:self.countryCode error:&error];
        
        if (!error){
            if ([self.phoneUtil isValidNumber:phoneNumber]){
                [textField resignFirstResponder];
            }
        }
        
        return NO;
        
    }else{
        txtPhoneno = nil;
    }
    
    return YES;}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    
    if (textField.tag == 999){
        if (![self isValidEmail:textField.text]){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                   message:@"Please enter valid email address."
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [theAlert show];
                
            });
            
            
            return NO;
            
        }
    }
    if (textField.tag == 99){
        NSString *phoneNumber = [textField.text stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, textField.text.length)];
        if (phoneNumber.length != 10){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                   message:@"Please enter valid phone Number."
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [theAlert show];
                
            });
            
            return NO;
        }
        
    }
    if (textField.tag == 900){
        if (textField.text.length > 0){
            if (![self urlIsValiad:textField.text]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                       message:@"Please enter valid URL."
                                                                      delegate:self
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                    [theAlert show];
                    
                });
                
                
                return NO;
                
            }
            
        }
        
    }

    
    return YES;
    
}




- (BOOL)isValidEmail:(NSString *)email
{
    NSString *regex1 = @"\\A[a-z0-9]+([-._][a-z0-9]+)*@([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,6}\\z";
    NSString *regex2 = @"^(?=.{1,64}@.{4,64}$)(?=.{6,100}$).*";
    NSPredicate *test1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex1];
    NSPredicate *test2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex2];
    return [test1 evaluateWithObject:email] && [test2 evaluateWithObject:email];
}

- (BOOL) urlIsValiad: (NSString *) url
{
    NSString *regex =
    @"((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?";
    /// OR use this
    ///NSString *regex = "(http|ftp|https)://[\w-_]+(.[\w-_]+)+([\w-.,@?^=%&:/~+#]* [\w-\@?^=%&/~+#])?";
    NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    /*
     
     if ([regextest evaluateWithObject: url] == YES) {
     NSLog(@"URL is valid!");
     } else {
     NSLog(@"URL is not valid!");
     }
     
     */
    return [regextest evaluateWithObject:url];
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
    
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
    
    
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
    UIFont *bodyFont = [SCHUtility getPreferredBodyFont];
    UIImage *calendarIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"calender.png"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *calendarAttachment = [SCHTextAttachment new];
    calendarAttachment.image = calendarIcon;
    
    UIImage *bookIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"book@1x.png"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *bookAttachment = [SCHTextAttachment new];
    bookAttachment.image = bookIcon;
    
    UIImage *notificationIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"notification@3x.png"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *notificationAttachment = [SCHTextAttachment new];
    notificationAttachment.image = notificationIcon;
    
    UIImage *businessIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"business@1x.png"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *businessAttachment = [SCHTextAttachment new];
    businessAttachment.image = businessIcon;
    
    
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] init];
    NSString *nextLine = @"\n";
    
    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    
    
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:calendarAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@": Event Calendar"] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:bookAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@": Setup Appointment with Professional or client"] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:notificationAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@": Your messages"] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:businessAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@": Register new business or manage existing business"] attributes:bodyAttr]];
    
    
    return content;
    
}




-(NSAttributedString *) helpTitle{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"CounterBean"]  attributes:titleAttr]];
    return title;
}




@end
