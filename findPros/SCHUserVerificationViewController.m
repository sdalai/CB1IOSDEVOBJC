//
//  SCHUserVerificationViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 8/6/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHUserVerificationViewController.h"
#import "AppDelegate.h"
#import "SCHAlert.h"
#import <IQKeyboardManager/IQKeyboardManager.h>
#import <IQKeyboardManager/IQUIView+Hierarchy.h>
#import "SlideMenuViewController.h"
#import "MFSideMenu.h"
#import "SCHSyncManager.h"
#import "SCHPhoneVerificationViewController.h"
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
#import <libPhoneNumber-iOS/NBNumberFormat.h>
#import <libPhoneNumber-iOS/NBMetadataCore.h>
#import <libPhoneNumber-iOS/NBPhoneMetaData.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]
@interface SCHUserVerificationViewController () <UITextFieldDelegate, FDTakeDelegate>
@property (nonatomic, strong) PFFile *imageFile;
@property (nonatomic, strong) NBPhoneNumberUtil *phoneUtil;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NBAsYouTypeFormatter *phoneFormatter;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *phoneNumber;
@end

@implementation SCHUserVerificationViewController

  

#pragma mark - TextFieldDelegate


-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([textField isEqual:self.firstName]){
            [self.lastName becomeFirstResponder];
        
            
        } else if ([textField isEqual:self.lastName]){
            
            [self.mobileNumber becomeFirstResponder];
            
        } else if ([textField isEqual:self.mobileNumber]){
            [textField resignFirstResponder];
            [self nextBtnAction:NULL];
        }else{
            [textField resignFirstResponder];
            
        }
    
    });
    
    return YES;
    
}



-(void)setNextBtnVisibility{
        AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL validPhoneNumber = NO;
    
    if (self.mobileNumber.text.length > 0){
        NSError *error = nil;
        NBPhoneNumber *phoneNumber = [self.phoneUtil parse:self.mobileNumber.text defaultRegion:self.countryCode error:&error];
        
        if (!error){
            validPhoneNumber = [self.phoneUtil isValidNumber:phoneNumber];
        }
    }
    
    
    if (self.firstName.text.length > 0 && self.lastName.text.length >0 && validPhoneNumber && appdeligate.serverReachable){
        self.btnNext.hidden = NO;
        self.btnNext.enabled = YES;
    } else{
        self.btnNext.hidden = YES;
        self.btnNext.enabled = NO;
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.mobileNumber) {
        
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
                [self.mobileNumber resignFirstResponder];
            }
        }
        
       return NO;
    
        
    }
    
    return YES;
}





#pragma mark - ViewControllerEvent

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageFile = nil;
    self.error = nil;
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    self.countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    
    self.phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    self.phoneFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:self.countryCode];

    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    //Dispalys for connectivity
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [self.firstName addTarget:self
                  action:@selector(setNextBtnVisibility)
        forControlEvents:UIControlEventAllEvents];
    
    [self.lastName addTarget:self
                       action:@selector(setNextBtnVisibility)
             forControlEvents:UIControlEventAllEvents];
    
    [self.mobileNumber addTarget:self
                      action:@selector(setNextBtnVisibility)
            forControlEvents:UIControlEventAllEvents];
    
    
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appdeligate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];

            self.navigationItem.leftBarButtonItem.title = @"";
            self.navigationItem.leftBarButtonItem.enabled = NO;

            
        } else {
            [self.navigationItem setPrompt:nil];

            self.navigationItem.leftBarButtonItem.title = @"Cancel";
            self.navigationItem.leftBarButtonItem.enabled = YES;
        }
    });
    self.firstName.delegate = self;
    self.lastName.delegate = self;
    self.mobileNumber.delegate = self;
    if (![PFUser currentUser]){
        [self.navigationController popoverPresentationController];
    }
 
    [ self setNextBtnVisibility];
    


    


    
    
    //hide keyboard
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
     [self initializeFieldValues];

    
}

-(void)internetConnectionChanged{
    
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    

    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appdeligate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];

            self.navigationItem.leftBarButtonItem.title =  @"";
            self.navigationItem.leftBarButtonItem.enabled = NO;
            
            
        } else {
            [self.navigationItem setPrompt:nil];
            self.navigationItem.leftBarButtonItem.title = @"Cancel";
            self.navigationItem.leftBarButtonItem.enabled = YES;
        }

    });
    [ self setNextBtnVisibility];
    
    
}

-(void) setFirstResponder{
    
     if (self.currentUser.firstName.length == 0){
     [self.firstName becomeFirstResponder];
     }else if (self.currentUser.lastName.length == 0){
     [self.lastName becomeFirstResponder];
     }else if (self.currentUser.phoneNumber.length == 0){
     [self.mobileNumber becomeFirstResponder];
     }
     

    
}




-(void)dismissKeyboard {
    
    if ([self.firstName isFirstResponder]){
        [self.firstName resignFirstResponder];
    } else if ([self.lastName isFirstResponder]){
        [self.lastName resignFirstResponder];
    }else if ([self.mobileNumber isFirstResponder]){
        [self.mobileNumber resignFirstResponder];
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    
    [self.navigationController.navigationBar setHidden:NO];
    self.navigationItem.rightBarButtonItem = nil;

    IQKeyboardManager *keyboardManager = [IQKeyboardManager sharedManager];
    [keyboardManager setEnableAutoToolbar:YES];
    keyboardManager.shouldHidePreviousNext = YES;
    self.navigationItem.title = @"Profile Info";
   

    [self setNextBtnVisibility];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) initializeFieldValues{
    //set initial Values
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.user){
        [appDelegate.user fetch];
    }
    // Do any additional setup after loading the view.
    self.currentUser = appDelegate.user;

    self.imageFile =  self.currentUser.profilePicture;
    
    if (self.imageFile){

        [self.imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(!error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImage *profileImage = [UIImage imageWithData:data];
                    self.profilePicture.image = profileImage;
                    [self.txtPhotoMessage setText:@"Change"];
                });
                
            }
        }];
    }else{
        [self.txtPhotoMessage setText:@"Change"];
    }


    
    
    
    //self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.height / 2;
    self.profilePicture.layer.masksToBounds = YES;
    self.profilePicture.layer.borderWidth = 0;
    self.profilePicture.contentMode = UIViewContentModeScaleAspectFill;
    
    self.profilePicture.layer.cornerRadius = 6.0;
    self.profilePicture.layer.borderColor = [[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] CGColor];
    self.profilePicture.layer.borderWidth = 3.0;
    
    // self.userInfoView.layer.borderColor=[Rgb2UIColor(230,230,230) CGColor];
    //  self.userInfoView.layer.borderWidth = 1.0;
    
    self.profilePicture.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openImageSelecter)];
    
    [self.profilePicture addGestureRecognizer:tap];
    
    self.takeController = [[FDTakeController alloc] init];
    self.takeController.delegate = self;
    // You can optionally override action sheet titles
    self.takeController.takePhotoText = @"Take Photo";
    self.takeController.chooseFromLibraryText = @"Choose Photo";
    self.takeController.cancelText = @"Cancel";
    self.takeController.allowsEditingPhoto = true;
    
    
    

    self.firstName.text = self.currentUser.firstName;

    self.lastName.text = self.currentUser.lastName;
    
    self.mobileNumber.text = self.currentUser.phoneNumber;
    
    
    
    
}


#pragma mark - Navigation


- (IBAction)nextBtnAction:(UIButton *)sender {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.phoneNumber = nil;
    NSError *error = nil;
    BOOL valid = YES;
    
    if (self.mobileNumber.text.length > 0){
        NBPhoneNumber *NBNumber = [self.phoneUtil parse:self.mobileNumber.text defaultRegion:self.countryCode error:&error];
        
        if (!error){
            if ([self.phoneUtil isValidNumber:NBNumber]){
                self.phoneNumber = [self.phoneUtil format:NBNumber
                                        numberFormat:NBEPhoneNumberFormatE164
                                               error:&error];
                
                if (!error){
                    if ([SCHUtility phoneNumberExists:self.phoneNumber]){
                        
                        NSString *message = [NSString stringWithFormat:@"%@ is attched to another user. Please provide another mobile number", self.mobileNumber.text];
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(message, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                        self.mobileNumber.text = @"";
                        [self.mobileNumber becomeFirstResponder];
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
        
        
        
    }

        
    
    
    if (self.firstName.text.length == 0){
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter your first name", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        
        valid = NO;
        return;
    }
    if (self.lastName.text.length == 0){
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter your last name", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        
        valid = NO;
        return;
    }
    
    
    if (valid){
        self.currentUser.firstName = self.firstName.text;
        self.currentUser.lastName = self.lastName.text;
        
        if (self.currentUser.preferredName.length == 0){
            self.currentUser.preferredName = self.firstName.text;
        }
        if (self.phoneNumber){
            if ([self.currentUser.phoneNumber isEqualToString:self.phoneNumber]){
                self.currentUser.phoneNumber = self.phoneNumber;
                self.currentUser.phoneNumberVerified = YES;
            }
        }
        
        
        
        if (self.imageFile){
            self.currentUser.profilePicture = self.imageFile;
        }
        
        [self.currentUser save];
        
        
        
        if (self.phoneNumber){
            BOOL phoneVerified = self.currentUser.phoneNumberVerified;
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
                appDelegate.userJustSignedUp = NO;
                [self.navigationController popToRootViewControllerAnimated:YES];
                
            } else{
                
                [self performSegueWithIdentifier:@"toPhoneVerificationSegue" sender:self];
                
            }

            
        }else{
            appDelegate.userJustSignedUp = NO;
            [self.navigationController popToRootViewControllerAnimated:YES];
            
        }
        
        
    }


    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    self.navigationItem.title = SCHBackkButtonTitle;
    if ([segue.identifier isEqualToString:@"toPhoneVerificationSegue"]){
        SCHPhoneVerificationViewController *vcPushTo = segue.destinationViewController;
        
        vcPushTo.phoneNumber = self.phoneNumber;
    }
}






- (IBAction)cancelVerification:(id)sender {
    
    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                       message:@""
                                                      delegate:self
                                             cancelButtonTitle:@"Logout"
                                             otherButtonTitles:@"Cancel",nil];
    [theAlert show];
    

}

- (void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if ([theAlert.title isEqualToString:@"CounterBean"]){
        if(buttonIndex==0)
        {
            [self dismissKeyboard];
            [SCHUtility logout];
            [self performSegueWithIdentifier:@"accountVCTologinSignUpVC" sender:self];
            
            
        }
    }
    
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.profilePicture setImage:photo];
    });
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSData *imageData = UIImagePNGRepresentation(photo);
    int timestamp = [[NSDate date] timeIntervalSince1970];
    
    self.imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@-%d.png", appDelegate.user.objectId,timestamp] data:imageData];
    
    [self.txtPhotoMessage setText:@"Change"];
    

    
}



@end
