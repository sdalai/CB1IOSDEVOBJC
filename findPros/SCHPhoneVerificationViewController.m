//
//  SCHPhoneVerificationViewController.m
//  CounterBean
//
//  Created by Sujit Dalai on 8/16/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHPhoneVerificationViewController.h"
#import "AppDelegate.h"
#import "SlideMenuViewController.h"
#import "MFSideMenu.h"
#import "SCHSyncManager.h"
#import "SCHAlert.h"
#import <IQKeyboardManager/IQKeyboardManager.h>
#import <IQKeyboardManager/IQUIView+Hierarchy.h>
#import "SCHLoginViewController.h"

#import "SCHPhoneVerificationViewController.h"
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
#import <libPhoneNumber-iOS/NBNumberFormat.h>
#import <libPhoneNumber-iOS/NBMetadataCore.h>
#import <libPhoneNumber-iOS/NBPhoneMetaData.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>



@interface SCHPhoneVerificationViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *phoneVerificationField;
@property(nonatomic, strong) SCHUser *currentUser;
@property(nonatomic, strong) UIAlertView *verificationCodeSentAlert;
@property(nonatomic, assign) BOOL verificationSMSSuspended;
@property (nonatomic, strong) NBPhoneNumberUtil *phoneUtil;
@property (nonatomic, strong) NBAsYouTypeFormatter *phoneFormatter;
@property (nonatomic, strong) NSString *countryCode;


@end

@implementation SCHPhoneVerificationViewController



#pragma mark - TextFieldDelegate


-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    NSLocale *currentLocale = [NSLocale currentLocale];
    self.countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    
    self.phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    self.phoneFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:self.countryCode];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    self.currentUser = appDelegate.user;
    // Do any additional setup after loading the view.
    [self.navigationController.navigationBar setHidden:NO];
    self.navigationItem.title = @"Verification";
    [self.phoneVerificationField addTarget:self
                       action:@selector(verificationCodeCount)
             forControlEvents:UIControlEventAllEvents];
    
    self.phoneVerificationField.delegate = self;

    
    //hide keyboard
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    [self resetButtons];
    
    
    
    
    
    
}

-(void)internetConnectionChanged{
    
    [self resetButtons];
    
    
}




-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self VerificationScreenLabelText];
    IQKeyboardManager *keyboardManager = [IQKeyboardManager sharedManager];
    [keyboardManager setEnableAutoToolbar:YES];
    keyboardManager.shouldHidePreviousNext = YES;
    
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.btnVerify.layer.cornerRadius = 15.0;
    self.btnVerify.layer.masksToBounds = YES;
    self.btnResendVerificationCode.layer.cornerRadius = 15.0;
    self.btnResendVerificationCode.layer.masksToBounds = YES;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (![PFUser currentUser]){
        [self.navigationController popoverPresentationController];
    }
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.phoneVerificationTimer){
        [self sendVerificationCodeAlert];
    }
    
    
    
    
    
}

-(void)sendVerificationCodeAlert{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.user fetch];
    if (appDelegate.user.verificationSMSCount >= 5){
        [SCHUtility suspendAccountDueOTPLimt];
        if (appDelegate.user.suspended){
            NSString *message = nil;
            if (appDelegate.user.suspensionExpirationTime){
                NSDateFormatter *formatter = [SCHUtility dateFormatterForLongDateAndTime];
                NSString *expirationTime = [formatter stringFromDate:appDelegate.user.suspensionExpirationTime ];
                message = [NSString localizedStringWithFormat:@"Your account is suspended till %@.", expirationTime];
            } else{
                
                message = [NSString localizedStringWithFormat:@"Account is suspended. Please email contact@counterbean.com."];
            }
            
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                               message:message
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil,nil];
            [theAlert show];
            
        }
        
        id vc =[self.navigationController.viewControllers firstObject];
        if([vc isKindOfClass:[SCHLoginViewController class]]){
            SCHLoginViewController *parentVC = (SCHLoginViewController *)vc;
            parentVC.logoutUser = YES;
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else{
            if (appDelegate.slideMenu){
                [appDelegate.slideMenu dismissViewControllerAnimated:NO completion:NULL];
                [appDelegate.slideMenu performSegueWithIdentifier:@"logoutSegue" sender:self];
                
            } else{
                [SCHUtility logout];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            
        }
        
        
        
    } else{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.verificationCodeSentAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                        message:[NSString localizedStringWithFormat:@"Verification code willbe sent to %@.\nIt might take couple of minutes to receive", [SCHUtility phoneNumberFormate:self.phoneNumber] ]
                                                                       delegate:self
                                                              cancelButtonTitle:@"No"
                                                              otherButtonTitles:@"Yes", nil];
            [self.verificationCodeSentAlert show];
        });
        
    }
    
}

-(void)dismissKeyboard {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.phoneVerificationField resignFirstResponder];
    });
    
    
    

    
}

- (void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 1 && [theAlert isEqual:self.verificationCodeSentAlert]){
        [self sendVerificationCode];
    } else{
        [self dismissKeyboard];
    }
    
}
         
-(void) sendVerificationCode{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

        if (appDelegate.serverReachable){
            
            self.btnResendVerificationCode.hidden = YES;
            self.btnResendVerificationCode.enabled = NO;
            appDelegate.phoneVerificationTimer = nil;
            NSTimeInterval nextFiringTime = 15;
            appDelegate.phoneVerificationTimer = [NSTimer scheduledTimerWithTimeInterval:nextFiringTime
                                                                                  target:self
                                                                                selector:@selector(resetButtons)
                                                                                userInfo:NULL
                                                                                 repeats:NO];
            
            NSLog(@"firingtime: %@", appDelegate.phoneVerificationTimer.fireDate);
                
            
            
            
            
            
            [PFCloud callFunctionInBackground:@"sendOTP" withParameters:@{@"email" : self.currentUser.email, @"phonenumber": self.phoneNumber} block:^(id  _Nullable object, NSError * _Nullable error) {
                
                
                if (!error){
                    //NSLog(@"Verification Code Sent");
                } else{
                    //NSLog(@"Verification Code was not Sent");
                }
            }];
            
            
        }
             
}


-(void)verificationCodeCount{
    if (self.phoneVerificationField.text.length >= 6){
        [self.phoneVerificationField resignFirstResponder];
    }
}




- (IBAction)verifyPhoneNumber:(id)sender {
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appdeligate.serverReachable){
        [self.currentUser fetch];
        
        if ([SCHUtility phoneNumberExists:self.phoneNumber]){
            
            NSString *message = [NSString stringWithFormat:@"%@ is attched to another user. Please provide another mobile number", [SCHUtility phoneNumberFormate:self.phoneNumber]];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(message, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            self.phoneVerificationField.text = @"";
            
            return;
            
        }else{
            if (self.phoneVerificationField.text.length == 6){
                if ([self.phoneVerificationField.text isEqualToString:self.currentUser.OTP]){
                    //phone verified
                    self.currentUser.phoneNumber = self.phoneNumber;
                    self.currentUser.phoneNumberVerified = YES;
                    self.currentUser.verificationSMSCount = 0;
                    self.currentUser.OTP = nil;
                    self.currentUser.dataSyncRequired = YES;
                    [self.currentUser save];
                    self.phoneVerificationField.text = @"";
                    if (self.parentVC){
                        [self.navigationController popToViewController:self.parentVC animated:YES];
                        
                    }else{
                        id vc = [self.presentingViewController.childViewControllers firstObject];
                        
                        if ([vc isKindOfClass:[SCHLoginViewController class]]){
                            [self.navigationController popToRootViewControllerAnimated:YES];
                        } else{
                            if (self.currentUser.dataSyncRequired){
                                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                if (appDelegate.serverReachable){
                                    dispatch_barrier_async(appDelegate.backgroundManager.SCHSerialQueue, ^{
                                        [SCHUtility syncPriorNonUserActivities:appDelegate.user.phoneNumber email:appDelegate.user.email User:appDelegate.user];
                                        [SCHSyncManager syncUserData:nil];
                                    });
                                }
                                
                            }
                            appdeligate.userJustSignedUp = NO;
                            [self.navigationController popToRootViewControllerAnimated:YES];
                            
                        }
                        
                    }
                    
                    
                } else{
                    
                    [self invalidCodeAlert];
                    self.phoneVerificationField.text = @"";
                    return;
                    
                }
                
                
            }else{
                [self invalidCodeAlert];
                self.phoneVerificationField.text = @"";
                return;
                
            }
            
            
        }

        
    }
    

    
    
}

-(void)invalidCodeAlert{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                           message:[NSString localizedStringWithFormat:@"Invalid verification Code."]
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles: nil];
        
        [theAlert show];
    });

    
}




- (IBAction)resendVerificationCode:(id)sender {
    
 [self sendVerificationCodeAlert];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)VerificationScreenLabelText{
    
    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName: [SCHUtility deepGrayColor]};
    
    
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Please enter verification code sent to phone number %@. In case you haven't received SMS message please tap Resend button.", [SCHUtility phoneNumberFormate:self.phoneNumber]] attributes:bodyAttr];
    
    self.verificationInstruction.attributedText = attrString;
    

    
   
    
    
}

-(void)phoneVerificationTimerAction{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.phoneVerificationTimer){
        [self resetButtons];
        
        
    }
    
}


-(void) resetButtons{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appDelegate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            self.btnVerify.hidden = YES;
            self.btnVerify.enabled = NO;

                self.btnResendVerificationCode.hidden = YES;
                self.btnResendVerificationCode.enabled = NO;
                
            
            
        } else {
            self.btnVerify.hidden = NO;
            self.btnVerify.enabled = YES;
            [self.navigationItem setPrompt:nil];
            
            if (appDelegate.phoneVerificationTimer){
                NSLog(@"firingtime: %@", appDelegate.phoneVerificationTimer.fireDate);
                if ([appDelegate.phoneVerificationTimer.fireDate compare:[NSDate date]] != NSOrderedDescending){
                    self.btnResendVerificationCode.hidden = NO;
                    self.btnResendVerificationCode.enabled = YES;
                    appDelegate.phoneVerificationTimer = nil;
                }else{
                    self.btnResendVerificationCode.hidden = YES;
                    self.btnResendVerificationCode.enabled = NO;
                    
                }
                
            }else{
                self.btnResendVerificationCode.hidden = NO;
                self.btnResendVerificationCode.enabled = YES;
            }
            
            
            
        }
        
    });

    
    
}








/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
