//
//  SCHAddServiceViewController.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/22/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAddServiceViewController.h"
#import "XLForm.h"
#import "SCHAddServiceDescription.h"
#import <Parse/Parse.h>
#import "SCHServiceClassification.h"
#import "SCHService.h"
#import "SCHServiceOffering.h"
#import "SCHservicePictureTableViewCell.h"
#import "SCHServiceNewOfferingsViewController.h"
#import "SCHUser.h"
#import "AppDelegate.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
#import <IODProfanityFilter/IODProfanityFilter.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
#import <libPhoneNumber-iOS/NBNumberFormat.h>
#import <libPhoneNumber-iOS/NBMetadataCore.h>
#import <libPhoneNumber-iOS/NBPhoneMetaData.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>

static NSString * const kScreenTitle = @"New Business";

@interface SCHAddServiceViewController () <FDTakeDelegate, UITextFieldDelegate,CNPPopupControllerDelegate>

@property (nonatomic, strong) CNPPopupController *popupController;



@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (nonatomic, strong) PFFile *imageFile;
@property (nonatomic, strong) NBPhoneNumberUtil *phoneUtil;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NBAsYouTypeFormatter *phoneFormatter;
@property (nonatomic, strong) NSString *countryCode;

@end

@implementation SCHAddServiceViewController
XLFormRowDescriptor * rowPhoneNo;
XLFormRowDescriptor * rowEmail;
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
    XLFormRowDescriptor * row;
    form = [XLFormDescriptor formDescriptorWithTitle:kScreenTitle];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    section.title=@"help";
    [form addFormSection:section];
    
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"Title" rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleBusinessName];
    [row.cellConfigAtConfigure setObject:@"Business Name"forKey:@"textField.placeholder"];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:row];

    
    //Major Classification
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleMajorServiceClassification rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleMajorServiceClassification];
    row.required = YES;
    row.selectorTitle = SCHFieldTitleMajorServiceClassification ;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.selectorOptions = [SCHUtility getMajorServiceClassificationList];
    [section addFormRow:row];
    
    // Minor Classification
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleMinorServiceClassification rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleMinorServiceClassification];
    row.disabled = @YES;
    row.selectorTitle = SCHFieldTitleMinorServiceClassification ;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    XLFormRowDescriptor *serviceRow = [self.form formRowWithTag:SCHFieldTitleMajorServiceClassification];
    if (serviceRow.valueData){
        row.selectorOptions =[SCHUtility getServiceClassificationList:(SCHServiceMajorClassification *)serviceRow.valueData];
    }
    row.required = YES;
    [section addFormRow:row];

    
    //For Phone Number
    rowPhoneNo = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfilePhoneNumber rowType:XLFormRowDescriptorTypePhone title:SCHFieldTitleProfilePhoneNumber];
    [rowPhoneNo.cellConfigAtConfigure setObject:@"Business phone"forKey:@"textField.placeholder"];
    
    [rowPhoneNo.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [rowPhoneNo.cellConfig setObject:@"99" forKey:@"textField.tag"];
    
    [section addFormRow:rowPhoneNo];
    
    
    //For Email
    rowEmail = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldBusinessEmail rowType:XLFormRowDescriptorTypeEmail title:SCHFieldBusinessEmail];
    [rowEmail.cellConfigAtConfigure setObject:@"Business Email"forKey:@"textField.placeholder"];
    [rowEmail.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [rowEmail.cellConfig setObject:@"999" forKey:@"textField.tag"];
    [section addFormRow:rowEmail];
    
    //price
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"standaedCharge" rowType:XLFormRowDescriptorTypeInteger title:SCHFieldTitlePrice];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [row.cellConfigAtConfigure setObject:@"Ex: $100"forKey:@"textField.placeholder"];
    [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:row];
    
    //website
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"Website" rowType:XLFormRowDescriptorTypeURL title:@"Website"];
    [row.cellConfigAtConfigure setObject:@"Website"forKey:@"textField.placeholder"];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [row.cellConfig setObject:@"900" forKey:@"textField.tag"];
    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Privacy Options";
    section.hidden = @YES;
    [form addFormSection:section];
    
    
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"profileVisibiltyControl" rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleBusinessProfileVisibility];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.selectorOptions = [SCHUtility privacyPrefrences];
    row.value = [SCHUtility privacyPrefrences][1];
    row.selectorTitle = @"Privacy Preference";

    [section addFormRow:row];
    
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"AvailabilityVisibiltyControl" rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleScheduleVisibility];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.selectorOptions = [SCHUtility privacyPrefrences];
    row.value = [SCHUtility privacyPrefrences][1];
    row.selectorTitle = @"Options";
    
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"Auto confirm Appointment Request" rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleAutoConfirm];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.selectorOptions = [SCHUtility autoConfirmOptions];
    row.value = [SCHUtility autoConfirmOptions][0];
    row.selectorTitle = @"Options";
    
    [section addFormRow:row];
    

    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Desription";
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingDescripition rowType:XLFormRowDescriptorTypeTextView];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textView.textColor"];
    [row.cellConfigAtConfigure setObject:@"Provide your credential and detail description of Business " forKey:@"textView.placeholder"];
    [section addFormRow:row];

    
    self.form = form;
}


#pragma mark - XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue{
    
    [rowDescriptor.cellConfigAtConfigure setObject:[UIColor greenColor] forKey:@"textField.textColor"];
    
    if ([rowDescriptor.tag isEqualToString:@"standaedCharge"] && oldValue != newValue) {
        
        int fieldvalue = [newValue intValue];
        if (fieldvalue > 100000){
            
            rowDescriptor.value = oldValue;
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                   message:@"Maximum value is $100000."
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [theAlert show];
                
            });
            
        }
        
        
        
    }
    
    
    
    
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
    if ([rowDescriptor.tag isEqualToString:@"Auto confirm Appointment Request"]) {
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
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
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

    
    SCHUser *user = appDelegate.user;
    PFFile *imageFile = user.profilePicture;
    if (imageFile){
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if(!error){
            UIImage *profileImage = [UIImage imageWithData:data];
            self.userProfileImageView.image = profileImage;
            [txtMessage setText:@"Change"];
        }
    }];
    }else{
        [txtMessage setText:@"Change"];
    }
    
    
    self.userProfileImageView.frame = CGRectMake( self.view.frame.size.width/2-65,10,130,130);
    [self.tableView addSubview:self.userProfileImageView];
    txtMessage = [[UILabel alloc]initWithFrame:CGRectMake( self.view.frame.size.width/2-80,135,160,30)];
    [txtMessage setText:@"Change"];
    [txtMessage setFont:[UIFont systemFontOfSize:12]];
    [txtMessage setTextAlignment:NSTextAlignmentCenter];
    [txtMessage setTextColor:[UIColor blueColor]];
    [self.tableView addSubview:txtMessage];
    
    // Do any additional setup after loading the view.
    
    
    self.takeController = [[FDTakeController alloc] init];
    self.takeController.delegate = self;
    // You can optionally override action sheet titles
    self.takeController.takePhotoText = @"Take Photo";
    self.takeController.chooseFromLibraryText = @"Choose Photo";
    self.takeController.cancelText = @"Cancel";
    self.takeController.allowsEditingPhoto = true;
    
    
   // rowPhoneNo.value = [SCHUtility phoneNumberFormate:currentUser.phoneNumber];
   // rowEmail.value = currentUser.email;
    
    
    
    
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"New Business";
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationItem.title = SCHBackkButtonTitle;
    
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"goToAddNewOffering"]){
        SCHServiceNewOfferingsViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.serviceObject  =(SCHService *)sender;
        vcToPushTo.is_New_From_Service = YES;
    }
}


- (IBAction)goToNext:(id)sender {
        NSError *error = nil;
    
     
//    SCHServiceMajorClassification *serviceMajorClassification = ([self.formValues valueForKey:SCHFieldTitleMajorServiceClassification] != NULL) ? [[self.formValues valueForKey:SCHFieldTitleMajorServiceClassification] valueData] : nil;
//    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
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

    NSString *description =(![[[self.formValues valueForKey:SCHFieldTitleOfferingDescripition] displayText] isEqualToString:@""]) ? [[self.formValues valueForKey:SCHFieldTitleOfferingDescripition] valueData] : nil;
    
    SCHConstants *constants = [SCHConstants sharedManager];
    
  //  SCHLookup *businessProfileVisibility = [[self.formValues valueForKey:@"profileVisibiltyControl"] valueData];
 //   SCHLookup *availabilityVisibility = [[self.formValues valueForKey:@"AvailabilityVisibiltyControl"] valueData];
  //  SCHLookup *autoconfirmControl = [[self.formValues valueForKey:@"Auto confirm Appointment Request"] valueData];
    
    SCHLookup *businessProfileVisibility = constants.SCHPrivacyOptionClient;
    SCHLookup *availabilityVisibility = constants.SCHPrivacyOptionClient;
    SCHLookup *autoconfirmControl = constants.SCHAutoConfirmOptionNone;
    
    
    
    
    
    NSString *phoneNumberFieldValue = rowPhoneNo.value;
    NSString *phoneNumber = nil;
    
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

    NSString *email = rowEmail.value;
    if (email.length == 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                               message:@"Please enter your business email address."
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
            [theAlert show];
            
        });
        
        
        return;
        
    }else if (![self isValidEmail:email]){
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
        

        
        SCHUser *user = appDelegate.user;
        BOOL active = YES;
        // create service for user
        SCHService *newService = [SCHService object];
        
        newService.user = user;
        newService.active = active;
        newService.serviceClassification = serviceClassification;
        newService.serviceTitle = [IODProfanityFilter stringByFilteringString:title];
        newService.businessPhone = phoneNumber;
        newService.businessEmail = email;
        newService.standardCharge = charge;
        newService.website = website;
        newService.serviceDescription = [IODProfanityFilter stringByFilteringString:description];
        newService.profileVisibilityControl = businessProfileVisibility;
        newService.availabilityVisibilityControl = availabilityVisibility;
        newService.autoConfirmAppointment =  autoconfirmControl;
        newService.suspended = NO;
        newService.restrictPublicVisibility = YES;
        [SCHUtility setPublicAllROACL:newService.ACL];
        
        if (self.imageFile){
            newService.profilePicture = self.imageFile;
        } else{
            newService.profilePicture = user.profilePicture;
        }
        
                  //  newService.profilePicture = [PFFile fileWithData:UIImagePNGRepresentation(self.userProfileImageView.image)];
                     [self performSegueWithIdentifier:@"goToAddNewOffering" sender:newService];
               
        
    }else{
        
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                           message:@"Please provide all required information."
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
                }
    
    
    
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
    
    return YES;

}

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
    if(section==4){
        UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
        // create the button object
        UIButton *headerBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-150, 10,150-10 , 20.0)];
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
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] init];
    NSString *nextLine = @"\n";
    
    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    NSDictionary *blueBodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[UIColor blueColor]};
    
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Tap on the picture to change your profile picture."] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Enter business "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"name"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" and select business "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"category"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" and "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"sub-category"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Enter business "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"phone"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@", "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"email"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@", "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"website"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" and "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"price"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" for service."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"business profile and schedule visibility"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" options."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Auto Confirm"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" for appointment option."] attributes:bodyAttr]];
    

    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Give the details of your business."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Tap Next to create your business offering."] attributes:bodyAttr]];
    
    return content;
    
}




-(NSAttributedString *) helpTitle{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"New Business"]  attributes:titleAttr]];
    return title;
}


@end
