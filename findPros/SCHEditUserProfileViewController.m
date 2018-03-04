//
//  SCHEditUserProfileViewController.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/15/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHEditUserProfileViewController.h"
#import <Parse/Parse.h>
#import "SCHLookup.h"
#import "SCHPaymentFrequency.h"
#import "AppDelegate.h"
#import "SCHConstants.h"
#import "SCHAlert.h"
#import "SCHUser.h"
#import "SCHSyncManager.h"
#import "SCHPhoneVerificationViewController.h"
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
#import <libPhoneNumber-iOS/NBNumberFormat.h>
#import <libPhoneNumber-iOS/NBMetadataCore.h>
#import <libPhoneNumber-iOS/NBPhoneMetaData.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>
#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]
@interface SCHEditUserProfileViewController () <UITextFieldDelegate, FDTakeDelegate>
@property (nonatomic, strong) SCHUser *currentUser;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *savebutton;
@property (nonatomic, strong) SCHConstants *constants;
@property (nonatomic, strong) XLFormSectionDescriptor *subscriptionSection;
@property (nonatomic, strong) PFFile *imageFile;
@property (nonatomic, strong) NBPhoneNumberUtil *phoneUtil;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NBAsYouTypeFormatter *phoneFormatter;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *phoneNumber;

@end

@implementation SCHEditUserProfileViewController
bool isImageChanged;
XLFormRowDescriptor * rowFirstName;
XLFormRowDescriptor * rowLastName;
XLFormRowDescriptor * rowDisplayName;
XLFormRowDescriptor * rowPhoneNo;
XLFormRowDescriptor * rowEmail;
XLFormRowDescriptor * rowSubscription;
XLFormRowDescriptor * rowPaymentFrequency;
XLFormRowDescriptor * rowPayableAmount;
XLFormRowDescriptor * rowStartDate;
XLFormRowDescriptor * rowRenewalDate;
XLFormRowDescriptor * rowExpirationDate;
UILabel *txtMessage;
UITextField *txtPhoneno;
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
    //XLFormRowDescriptor * row;
    form = [XLFormDescriptor formDescriptorWithTitle:@"Edit Profile"];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    section.title = @"";
    [form addFormSection:section];
    
    //For First Name
    rowFirstName = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfileFirstName rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfileFirstName];
    [rowFirstName.cellConfigAtConfigure setObject:@"Example: First Name"forKey:@"textField.placeholder"];
    rowFirstName.disabled = @NO;
    //[rowFirstName.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [rowFirstName.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:rowFirstName];
    
    //For Last Name
    rowLastName = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfileLastName rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfileLastName];
    [rowLastName.cellConfigAtConfigure setObject:@"Example: Last Name"forKey:@"textField.placeholder"];
    rowLastName.disabled = @NO;
    //[rowLastName.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [rowLastName.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:rowLastName];
    
    //For Display Name
    rowDisplayName = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfileDisplayName rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfileDisplayName];
    [rowDisplayName.cellConfigAtConfigure setObject:SCHFieldTitleProfileDisplayName forKey:@"textField.placeholder"];
    
    [rowDisplayName.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:rowDisplayName];
    
    
    //For Phone Number
    rowPhoneNo = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfilePhoneNumber rowType:XLFormRowDescriptorTypePhone title:SCHFieldTitleProfilePhoneNumber];
    [rowPhoneNo.cellConfigAtConfigure setObject:@"Phone Number"forKey:@"textField.placeholder"];
    
    [rowPhoneNo.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [rowPhoneNo.cellConfig setObject:@"99" forKey:@"textField.tag"];

    [section addFormRow:rowPhoneNo];

    
    //For Email
    rowEmail = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfileEmail rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfileEmail];
    [rowEmail.cellConfigAtConfigure setObject:@"Email"forKey:@"textField.placeholder"];
    rowEmail.disabled = @YES;
    //[rowEmail.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [rowEmail.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:rowEmail];
    
//    //For Subscription Type
    rowSubscription = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfileSubscriptionType rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfileSubscriptionType];
    //[rowPayableAmount.cellConfig setObject:@NO forKey:@"textField.enabled"];
    rowSubscription.disabled = @YES;
    [rowSubscription.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];

    [section addFormRow:rowSubscription];
//
//
//    
//    
//    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Subscription Info";
    self.subscriptionSection = section;
    
    [form addFormSection:section];
    
//    // row payment frequency
    rowPaymentFrequency = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfilePaymentFrequency rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfilePaymentFrequency];
   // [rowPaymentFrequency.cellConfig setObject:@NO forKey:@"textField.enabled"];
    rowPaymentFrequency.disabled = @YES;
    [rowPaymentFrequency.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:rowPaymentFrequency];

    
//    //row payment Amount
    rowPayableAmount= [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfilePaymentAmount rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfilePaymentAmount];
    //[rowPayableAmount.cellConfig setObject:@NO forKey:@"textField.enabled"];
    rowPayableAmount.disabled = @YES;
    [rowPayableAmount.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:rowPayableAmount];

    
//    //row start date
    rowStartDate= [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfileStartDate rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfileStartDate];
    
    //[rowStartDate.cellConfig setObject:@NO forKey:@"textField.enabled"];
    rowStartDate.disabled = @YES;
    [rowStartDate.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:rowStartDate];
  
//    //row renewal date
    rowRenewalDate= [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfileRenewalDate rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfileRenewalDate];
    rowRenewalDate.disabled = @YES;
   // [rowRenewalDate.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [rowRenewalDate.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:rowRenewalDate];
    
    
//    //row Expiration date
    
    rowExpirationDate= [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfileExpirationDate rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfileExpirationDate];
    rowExpirationDate.disabled = @YES;
    //[rowExpirationDate.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [rowExpirationDate.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:rowExpirationDate];
    
    
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    self.form = form;
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    
    
   // self.phoneFormatter = [NBAsYouTypeFormatter alloc] ini
    UIEdgeInsets newContentInset = self.tableView.contentInset;
    newContentInset.top = self.topLayoutGuide.length;
    
}


#pragma mark - XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue{
    
    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    [rowDescriptor.cellConfigAtConfigure setObject:[UIColor greenColor] forKey:@"textField.textColor"];
    
    if ([rowDescriptor isEqual:rowPhoneNo]){
        NSLog(@"New Value: %@", newValue);
    }
    
}

- (BOOL)isValidEmail:(NSString *)email
{
    NSString *regex1 = @"\\A[a-z0-9]+([-._][a-z0-9]+)*@([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,6}\\z";
    NSString *regex2 = @"^(?=.{1,64}@.{4,64}$)(?=.{6,100}$).*";
    NSPredicate *test1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex1];
    NSPredicate *test2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex2];
    return [test1 evaluateWithObject:email] && [test2 evaluateWithObject:email];
}




#pragma mark - ViewControllerEvent

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLocale *currentLocale = [NSLocale currentLocale];
    self.countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    
    self.phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    self.phoneFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:self.countryCode];

    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    // Do any additional setup after loading the view.
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.currentUser = appDelegate.user;
    //set initial Values
    
    self.constants = [SCHConstants sharedManager];
    self.imageFile = nil;
    
    
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
    
    
    self.imageFile =  self.currentUser.profilePicture;
    
    
    
    
    self.userProfileImageView.frame = CGRectMake( self.view.frame.size.width/2-65,10,130,130);
    [self.tableView addSubview:self.userProfileImageView];
     txtMessage = [[UILabel alloc]initWithFrame:CGRectMake( self.view.frame.size.width/2-80,135,160,30)];
    [txtMessage setText:@"Change"];
    [txtMessage setFont:[UIFont systemFontOfSize:12]];
    [txtMessage setTextAlignment:NSTextAlignmentCenter];
    [txtMessage setTextColor:[UIColor blueColor]];
    [self.tableView addSubview:txtMessage];

    rowFirstName.value = self.currentUser.firstName;
    rowLastName.value = self.currentUser.lastName;
    rowDisplayName.value = self.currentUser.preferredName;
    rowPhoneNo.value = self.currentUser.phoneNumber ?[SCHUtility phoneNumberFormate:self.currentUser.phoneNumber]: @"";
    rowEmail.value = self.currentUser.email;
   // rowSubscription.value = @"Free";
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

    
    
    
    
    
    self.takeController = [[FDTakeController alloc] init];
    self.takeController.delegate = self;
    // You can optionally override action sheet titles
    self.takeController.takePhotoText = @"Take Photo";
    self.takeController.chooseFromLibraryText = @"Choose Photo";
    self.takeController.cancelText = @"Cancel";
    self.takeController.allowsEditingPhoto = true;

    
    
    // if subscription Type is not Premium then disable section subscription info
    
    
    rowSubscription.value = self.currentUser.subscriptionType.lookupText;
    rowPaymentFrequency.value = (self.currentUser.paymentFrequency) ? self.currentUser.paymentFrequency.paymentFrequency : @"";
    rowPayableAmount.value = (self.currentUser.paymentFrequency) ? [NSString stringWithFormat:@"$%f", self.currentUser.paymentFrequency.amount] : @"";
    
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
    // [toTimeFormatter stringFromDate:appointmentSeries.endTime];
    
    rowStartDate.value = (self.currentUser.premiumStartDate) ? [dayformatter stringFromDate:self.currentUser.premiumStartDate] : @"";
    rowRenewalDate.value = (self.currentUser.premiumRenewalDate) ? [dayformatter stringFromDate:self.currentUser.premiumRenewalDate] : @"";
    rowExpirationDate.value = (self.currentUser.premiumExpirationDate) ? [dayformatter stringFromDate:self.currentUser.premiumExpirationDate] : @"";
    
    
    
    if ([self.currentUser.subscriptionType isEqual:self.constants.SCHSubscriptionTypePremiumUser]) {
        self.subscriptionSection.hidden = @NO;
    } else{
        self.subscriptionSection.hidden = @YES;
    }
    
    [self internetChangeAction];
    
    
    
}

-(void)internetConnectionChanged{
    [self internetChangeAction];
    
}

-(void) internetChangeAction{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appDelegate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
             self.navigationItem.rightBarButtonItem.enabled = NO;
            
        } else {
            [self.navigationItem setPrompt:nil];
             self.navigationItem.rightBarButtonItem.enabled = YES;
        }
    });
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [self.userProfileImageView setImage:photo];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
     NSData *imageData = UIImagePNGRepresentation(photo);
   int timestamp = [[NSDate date] timeIntervalSince1970];
    
    self.imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@-%d.png", appDelegate.user.objectId,timestamp] data:imageData];
    [txtMessage setText:@"Change"];
    
    
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




- (IBAction)saveProfileAction:(id)sender {
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        self.phoneNumber = nil;
        NSError *error = nil;
        BOOL valid = YES;
        
        NSString *phoneNumberFieldValue = rowPhoneNo.value;
        NSString *displayName = rowDisplayName.value;
        NSString *firstName = rowFirstName.value;
        NSString *lastName = rowLastName.value;
        
        if (phoneNumberFieldValue.length > 0){
            NBPhoneNumber *NBNumber = [self.phoneUtil parse:phoneNumberFieldValue defaultRegion:self.countryCode error:&error];
            if (!error){
                if ([self.phoneUtil isValidNumber:NBNumber]){
                    self.phoneNumber = [self.phoneUtil format:NBNumber
                                                 numberFormat:NBEPhoneNumberFormatE164
                                                        error:&error];
                    
                    if (!error){
                        if ([SCHUtility phoneNumberExists:self.phoneNumber]){
                            
                            NSString *message = [NSString stringWithFormat:@"%@ is attched to another user. Please provide another mobile number", phoneNumberFieldValue ];
                            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(message, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                            rowPhoneNo = NULL;
                            
                            valid = NO;
                            
                            return;
                            
                        }
                    } else{
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter a valid mobile phone number", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                        valid = NO;
                        return;
                        
                    }
                }else{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter a valid mobile phone number", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                    valid = NO;
                    return;
                    
                }
                
            } else{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter a valid mobile phone number", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                valid = NO;
                return;
                
            }
            
            
        } else{
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter a valid mobile phone number", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            valid = NO;
            return;
            
        }
        
        
        
        if (displayName.length == 0){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:SCHAppName
                                                            message:@"Please provide your preferred name."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            valid  = NO;
            return;
            
        }
        
        if (firstName.length == 0){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:SCHAppName
                                                            message:@"Please provide your first name."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            valid  = NO;
            return;
            
        }
        
        if (lastName.length == 0){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:SCHAppName
                                                            message:@"Please provide your last name."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            valid  = NO;
            return;
            
        }
        
        if (valid){
            if (self.imageFile){
                self.currentUser.profilePicture = self.imageFile;
            }
            self.currentUser.firstName = firstName;
            self.currentUser.lastName = lastName;
            self.currentUser.preferredName = displayName;
            [self.currentUser save];
            
            
            if (self.phoneNumber){
                BOOL phoneVerified = YES;
                if ([self.phoneNumber isEqualToString:self.currentUser.phoneNumber]){
                    phoneVerified = self.currentUser.phoneNumberVerified;
                } else{
                    phoneVerified = NO;
                }
                
                if ( phoneVerified){
                    self.currentUser.verificationSMSCount = 0;
                    self.currentUser.OTP = nil;
                    [self.currentUser save];
                    BOOL dataSyncRequired = self.currentUser.dataSyncRequired;
                    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    if (dataSyncRequired && appdeligate.serverReachable)
                    {
                        SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
                        dispatch_async(backgroundManager.SCHSerialQueue, ^{
                            [SCHUtility syncPriorNonUserActivities:self.phoneNumber email:self.currentUser.email User:self.currentUser];
                            [SCHSyncManager syncUserData:nil];
                        });
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [self.navigationController popToRootViewControllerAnimated:YES];
                    });
                    
                } else{
                    
                    [self performSegueWithIdentifier:@"verifyPhoneSegue" sender:self];
                    
                }
                
                
            }else{
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self.navigationController popToRootViewControllerAnimated:YES];
                });
                
            }
            
            
        }

    } else{
        
        [SCHAlert internetOutageAlert];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
        
        
    }
    
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    self.navigationItem.title = SCHBackkButtonTitle;
    if ([segue.identifier isEqualToString:@"verifyPhoneSegue"]){
        SCHPhoneVerificationViewController *vcPushTo = segue.destinationViewController;
        vcPushTo.phoneNumber  = self.phoneNumber;
    }
}






@end
