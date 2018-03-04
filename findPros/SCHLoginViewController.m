//
//  SCHLoginViewController.m
//  CounterBean
//
//  Created by Sujit Dalai on 8/17/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHLoginViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "SCHUser.h"
#import "SCHUtility.h"
#import "AppDelegate.h"
#import "SCHSyncManager.h"
#import "SCHConstants.h"
#import "SCHResetPasswordViewController.h"
#import "SCHUserVerificationViewController.h"
#import <QuartzCore/QuartzCore.h>


static NSString * const kLoginOption = @"LoginOption";
static NSString * const kEmailLogin = @"EmailLogin";
static NSString * const kHideLoginView = @"HideLoginView";


@interface SCHLoginViewController () <UITextFieldDelegate, UITextViewDelegate>

@property(nonatomic, assign) BOOL LoginInProgress;
@property (nonatomic, assign) BOOL postloginProcessLaunched;
@property (nonatomic, strong) UIAlertView *remindEmailVerificationAlertView;
@property (nonatomic, strong) UIAlertView *reenterPasswordAlert;
@property (nonatomic, strong) UIAlertView *forgotPasswordAlert;

@end

@implementation SCHLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = YES;
    [self setTermsAndConditionMessage];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appdeligate.slideMenu = nil;
    appdeligate.tabBarController = nil;
    self.LoginInProgress = NO;
    self.postloginProcessLaunched = NO;
    self.loginViewMode = kHideLoginView;
    [self changeLoginView];
    
    //hide keyboard
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.emailTextView.delegate = self;
    self.passwordTextView.delegate = self;
    self.termsAndConditionMessage.delegate = self;


}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.navigationController.navigationBar setHidden:YES];
    
    if (self.logoutUser){
        self.welcomeLabel.text = NSLocalizedString(@"Logging out", nil);
    }else{
        if (appDelegate.user) {
            NSString *firstName = nil;
            NSString *lastName  = nil;
            if (appDelegate.user.firstName){
                firstName = appDelegate.user.firstName;
            }
            if (appDelegate.user.lastName){
                lastName = appDelegate.user.lastName;
            }
            if (firstName.length > 0 && lastName.length > 0){
                self.welcomeLabel.text =[NSString stringWithFormat:NSLocalizedString(@"Welcome %@!", nil), firstName];
            } else{
                self.welcomeLabel.text =[NSString stringWithFormat:NSLocalizedString(@"Welcome", nil)];
            }
        } else {
            self.welcomeLabel.text = NSLocalizedString(@"Welcoeme", nil);
            
        }
    }
}

-(void)viewDidLayoutSubviews{
   // [super viewDidLayoutSubviews];
    [self inititalizeLoginView];
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    
    if (self.logoutUser){
        [self userLogout];
    }else{
        if ([self userLoginStatus] && !(self.LoginInProgress || self.postloginProcessLaunched)){
            [self postLoginProcess];
        }
        
    }
}

-(void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.postloginProcessLaunched = NO;
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






/*****************************************/
#pragma mark - Button Actions
/*****************************************/
- (IBAction)startFacebookLogin:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.serverReachable){
        [self FacebookLoginAction];
    }
    
    
    
}

- (IBAction)changeToEmailLoginView:(id)sender {
    self.loginViewMode = kEmailLogin;
    [self changeLoginView];
}
- (IBAction)initiateForgotPasswordProcess:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.serverReachable){
        self.forgotPasswordAlert= [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                             message:@"Pleease enter your registered email address."
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"OK", nil];
        
        self.forgotPasswordAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *emailTextField = [self.forgotPasswordAlert textFieldAtIndex:0];
        emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
        
        
        [self.forgotPasswordAlert show];
    }
    
    
    
    return;
    

    
}
- (IBAction)startEmailLoginSignup:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (self.emailTextView.text.length == 0 || self.passwordTextView.text.length == 0){
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please provide email and password.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];

        return;
        
    }
    
    if (![self isValidEmail:self.emailTextView.text]){
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter valid email address.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        
        self.emailTextView.textColor = [SCHUtility brightOrangeColor];
        

        return;
        
    }
    
    //Check if User exists
    
    if (appDelegate.serverReachable){
        PFQuery *userQuery = [PFUser query];
        [userQuery whereKey:@"username" equalTo:self.emailTextView.text];
        if ([userQuery countObjects] > 0){
            PFUser *user = [userQuery getFirstObject];
            BOOL emailvalidated = [user[@"emailVerified"] boolValue];
            if (emailvalidated){
                // Login Process
                [self emalLoginAction:self.emailTextView.text password:self.passwordTextView.text];
            }else{
                self.remindEmailVerificationAlertView =[ [UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil)
                                                                                   message:[NSString localizedStringWithFormat:@"We have already sent email to %@ for verification. It may take few minutes. Please verify using the link provided", self.emailTextView.text]
                                                                                  delegate:self
                                                                         cancelButtonTitle:@"Ok"
                                                                         otherButtonTitles:@"Resend", nil];
                [self.remindEmailVerificationAlertView show];
                return;
                
            }
            
            
        } else{
            //signup
            // user email credential doesn't exists. sign up
            
            
            
            self.reenterPasswordAlert= [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                  message:@"Please confirm your password."
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                        otherButtonTitles:@"OK", nil];
            
            self.reenterPasswordAlert.alertViewStyle = UIAlertViewStyleSecureTextInput;
            
            [self.reenterPasswordAlert show];
            
            return;
            
            
            
        }

    }
 
    

    
}
- (IBAction)cancelEmailLoginView:(id)sender {
    self.loginViewMode = kLoginOption;
    [self changeLoginView];
}

/*****************************************/
#pragma mark - Login with Email
/*****************************************/

-(void)emalLoginAction:(NSString *) email password:(NSString *) password{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        self.LoginInProgress = YES;
        [self PresentLoginView];
        //start login
        [PFUser logInWithUsernameInBackground:email password:password
                                        block:^(PFUser *user, NSError *error) {
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                self.emailTextView.text = @"";
                                                self.passwordTextView.text = @"";
                                            });
                                            
                                            
                                            if (user) {
                                                // Do stuff after successful login.
                                                [self linkSCHUserWithEmail:email
                                                                 firstName:nil
                                                                  lastName:nil
                                                                facebookId:nil
                                                                  twiterId:nil];
                                                
                                                
                                            } else {
                                                // The login failed. Check error to see why.
                                                NSString *errorString = [error userInfo][@"error"]; // Show the errorString somewhere and let the user try again.
                                                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login Error!", nil) message:NSLocalizedString(errorString, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                                                self.LoginInProgress = NO;
                                                [self PresentLoginView];
                                                return;
                                                
                                            }
                                        }];

        
    } else{
        self.welcomeLabel.text = [NSString stringWithFormat:@"Please Connect to Internet."];
        self.LoginInProgress = NO;
        [self PresentLoginView];
    }
    
    

    
   
    
}


-(void)resetPassword:(NSString *) email{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.serverReachable){
        [PFCloud callFunctionInBackground:@"resetPassword" withParameters:@{@"email" : email} block:^(id  _Nullable object, NSError * _Nullable error) {
            
            
            
            if (error){
                // The login failed. Check error to see why.
                NSString *errorString = [error userInfo][@"error"]; // Show the errorString somewhere and let the user try again.
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Password Reset Error!", nil) message:NSLocalizedString(errorString, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            }
        }];
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"We emailed you temporary password. It may take few minutes.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        
    }
    
    
    
}

/*****************************************/
#pragma mark - Facebooklogin
/*****************************************/

-(void)FacebookLoginAction
{
    self.LoginInProgress = YES;
    [self PresentLoginView];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable)
    {
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login logInWithReadPermissions: @[@"public_profile"]
                     fromViewController:self
                                handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                    
                                    
                                    
                                    
                                    if (error) {
                                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Login with Facebook failed.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                                        self.LoginInProgress = NO;
                                        [self PresentLoginView];
                                    } else if (result.isCancelled) {
                                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Login with Facebook was cancelled.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                                        self.LoginInProgress = NO;
                                        [self PresentLoginView];
                                    } else
                                    {
                                        [PFFacebookUtils logInInBackgroundWithAccessToken:result.token block:^(PFUser * _Nullable user, NSError * _Nullable error) {
                                            if (!error){
                                                [self getUserFacebookData];
                                            }else{
                                                [SCHUtility completeProgress];
                                                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                                                   message:@"Login Failed Try Again"
                                                                                                  delegate:self
                                                                                         cancelButtonTitle:@"OK"
                                                                                         otherButtonTitles:nil];
                                                [theAlert show];
                                                self.LoginInProgress = NO;
                                                [self PresentLoginView];
                                                
                                            }
                                            
                                        }];
                                    }
                                }];
    }else{
        self.welcomeLabel.text = [NSString stringWithFormat:@"Please Connect to Internet."];
        self.LoginInProgress = NO;
        [self PresentLoginView];
    }
}

-(void)getUserFacebookData{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name, first_name, last_name, email"}];
            [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id FBUser, NSError *error) {
                
                if (!error){
                    if (!FBUser[@"email"]|| !FBUser[@"first_name"]||!FBUser[@"last_name"]||!FBUser[@"id"]){
                        [self logoutDueToError];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                               message:@"Please change Facebook setting to share email and name."
                                                                              delegate:self
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil];
                            [theAlert show];
                        });
                    } else {
                        [self linkSCHUserWithEmail:FBUser[@"email"]
                                         firstName:FBUser[@"first_name"]
                                          lastName:FBUser[@"last_name"]
                                        facebookId:FBUser[@"id"]
                                          twiterId:nil];
                        
                    }
                } else {
                    [self logoutDueToError];
                    
                    
                }
                
            }];
        } else{
            //show alert and log out
            [self logoutDueToError];
            
        }
    } else{
      [self logoutDueToError];
        self.welcomeLabel.text = [NSString stringWithFormat:@"Please Connect to Internet."];
        
    }
    
    
}


-(NSArray *)getExistingUsersForFacebookLogin:(NSString *) email facebookId:(NSString *) facebookId{
    
    NSError *error = nil;
    NSArray *existingUsers = nil;
    PFQuery *existingUserQueryWithFBId = [SCHUser query];
    [existingUserQueryWithFBId whereKey:@"facebookId" equalTo:facebookId];
    existingUsers = [existingUserQueryWithFBId findObjects:&error];
    if (error){
        return  @[error];
        
    }
    if (existingUsers.count > 1){
        error = [[NSError alloc] init];
        
        return @[error];
    } else if (existingUsers.count == 1){
        return existingUsers;
        
    } else{
        PFQuery *existingUserQueryWithEmail = [SCHUser query];
        [existingUserQueryWithEmail whereKey:@"email" equalTo:email];
        existingUsers = [existingUserQueryWithEmail findObjects:&error];
        if (error){
            return  @[error];
        }
        if (existingUsers.count > 1){
            error = [[NSError alloc] init];
            
            return @[error];
        } else if (existingUsers.count == 1){
            return existingUsers;
            
        } else{
            existingUsers = nil;
            return existingUsers;
        }
    }
}


-(void) logoutDueToError{
    self.LoginInProgress = NO;
    self.postloginProcessLaunched = NO;
    id topmostVC = [self topMostController];
    if (![topmostVC isEqual:self]){
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser]];
    [PFUser currentUser][@"CBUser"] = [NSNull null];
    [[PFUser currentUser] saveInBackground];
    
    [SCHUtility logout];
    [self PresentLoginView];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                           message:@"Login failed. Please make sure to have good internet connectivity during login."
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
    });

    
    
}



/*****************************************/
#pragma mark - Post Login
/*****************************************/


-(void)linkSCHUserWithEmail:(NSString *) email firstName:(NSString *) firstName lastName:(NSString *) lastName facebookId:(NSString *) facebookId twiterId:(NSString *) twitterId{
    SCHUser *user = nil;
    PFUser *currentPraseUser = [PFUser currentUser];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //Check if there is user
    
    if (facebookId){
        NSArray *existingUsers = [self getExistingUsersForFacebookLogin:email facebookId:facebookId];
        NSError *parseQueryError = nil;
        if (existingUsers.count > 0){
            if ([existingUsers[0] isKindOfClass:[NSError class]]){
                parseQueryError = existingUsers[0];
            }
        }
        if (parseQueryError){
            [self logoutDueToError];
            return;
        } else{
            if (existingUsers.count > 0){
                user = (SCHUser *)existingUsers[0];
                user.facebookId =facebookId;
                if ([user save]){
                    currentPraseUser[@"CBUser"] = user;
                    if(![currentPraseUser save]){
                        [self logoutDueToError];
                        return;
                    } else{
                        appDelegate.userJustLoggedIn = YES;
                    
                    }
                } else{
                    [self logoutDueToError];
                    return;
                }
            } else{
                SCHConstants *constants = [SCHConstants sharedManager];
                
                user = [SCHUser new];
                user.email = email;
                user.firstName = firstName;
                user.lastName = lastName;
                user.preferredName = user.firstName;
                user.facebookId = facebookId;
                user.dataSyncRequired = NO;
                user.subscriptionType = constants.SCHSubscriptionTypeFreeUser;
                user.suspended = NO;
                user.phoneNumberVerified = NO;
                [SCHUtility setPublicAllRWACL:user.ACL];
                if (!user.profilePicture ){
                    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookId]];
                    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:pictureURL];
                    [NSURLConnection sendAsynchronousRequest:urlRequest
                                                       queue:[NSOperationQueue mainQueue]
                                           completionHandler:
                     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                         if (connectionError == nil && data != nil) {
                             // Set the image in the header imageView
                             NSData *imageData = UIImagePNGRepresentation([UIImage imageWithData:data]);
                             PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@.png", user.objectId] data:imageData];
                             user.profilePicture = imageFile;
                             [user save];
                             
                             id vc = self.navigationController.viewControllers.lastObject;
                             if ([vc isKindOfClass:[SCHUserVerificationViewController class]]){
                                 SCHUserVerificationViewController *userinfoVC = vc;
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     [userinfoVC initializeFieldValues ];
                                 });
                                 
                             }
                             
                         }
                     }];
                }
                if ([user save]){
                    
                    currentPraseUser[@"CBUser"] = user;
                    if(![currentPraseUser save]){
                        [self logoutDueToError];
                        return;
                    }else{
                        appDelegate.userJustLoggedIn = YES;
                        appDelegate.userJustSignedUp = YES;
                    }
                } else{
                    [self logoutDueToError];
                    return;
                    
                }
                
            }
            if (![SCHUtility initializeSCheduleScreenFilter:user]){
                [self logoutDueToError];
                return;
            }
            
            appDelegate.user = user;
            self.LoginInProgress = NO;
            if (![SCHUtility removeAccountSuspensionWithExpirationDate]){
                [self logoutDueToError];
                return;
            }
            
            if (user.verificationSMSCount >= 5){
                [SCHUtility suspendAccountDueOTPLimt];
            }
            
            if (user.suspended){
                
                NSString *message = nil;
                if (user.suspensionExpirationTime){
                    NSDateFormatter *formatter = [SCHUtility dateFormatterForLongDateAndTime];
                    NSString *expirationTime = [formatter stringFromDate:user.suspensionExpirationTime ];
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
                [self logoutDueToError];
                return;
            } else{
                [self postLoginProcess];
                
            }

        }
        
        
    }else{
        PFQuery *schUserQuery = [SCHUser query];
        [schUserQuery whereKey:@"email" equalTo:email];
        if ([schUserQuery countObjects] > 0){
            user = (SCHUser *)[schUserQuery getFirstObject];
            currentPraseUser[@"CBUser"] = user;
            
            if (![currentPraseUser save]){
                [self logoutDueToError];
                return;
            } else{
               appDelegate.userJustLoggedIn = YES;
            }
            
        } else{
            SCHConstants *constants = [SCHConstants sharedManager];
            user = [SCHUser new];
            user.email = email;
            user.dataSyncRequired = NO;
            user.subscriptionType = constants.SCHSubscriptionTypeFreeUser;
            user.suspended = NO;
            user.phoneNumberVerified = NO;
            [SCHUtility setPublicAllRWACL:user.ACL];
            
            if ([user save]){
                
                currentPraseUser[@"CBUser"] = user;
                if(![currentPraseUser save]){
                    [self logoutDueToError];
                    return;
                }else{
                    appDelegate.userJustLoggedIn = YES;
                    appDelegate.userJustSignedUp = YES;
                }
            } else{
                [self logoutDueToError];
                return;
            }
        }
        if (![SCHUtility initializeSCheduleScreenFilter:user]){
            [self logoutDueToError];
            return;
        }

        
        appDelegate.user = user;
        self.LoginInProgress = NO;
        if (![SCHUtility removeAccountSuspensionWithExpirationDate]){
            [self logoutDueToError];
            return;
        }
        
        if (user.verificationSMSCount >= 5){
            [SCHUtility suspendAccountDueOTPLimt];
        }
        
        if (user.suspended){
            
            NSString *message = nil;
            if (user.suspensionExpirationTime){
                NSDateFormatter *formatter = [SCHUtility dateFormatterForLongDateAndTime];
                NSString *expirationTime = [formatter stringFromDate:user.suspensionExpirationTime ];
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
            [self logoutDueToError];
            return;
        } else{
            [self postLoginProcess];
            
        }
        
    }
    
    
}



-(void)postLoginProcess{
    
    PFUser *parseUser = [PFUser currentUser];
    
    BOOL enforcePasswordReset =[parseUser[@"enforcePasswordreset"] boolValue];
    
    if (enforcePasswordReset){
        
        [self performSegueWithIdentifier:@"loginToResetPasswordSegue" sender:self];
        
        
    }else{
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
       if (appDelegate.serverReachable){
            self.postloginProcessLaunched = YES;
            if (appDelegate.user && [SCHConstants sharedManager])
            {
                SCHUser *currentUser = appDelegate.user;
                
                NSString *phoneNumber = currentUser.phoneNumber;
                if(currentUser.firstName.length == 0 || currentUser.lastName.length == 0 ||(!currentUser.phoneNumber || !currentUser.phoneNumberVerified)){
                    
                    if (phoneNumber.length > 0 && !currentUser.phoneNumberVerified){
                        currentUser.phoneNumber = nil;
                        [currentUser saveInBackground];
                    }
                    self.postloginProcessLaunched = NO;
                    [self performSegueWithIdentifier:@"VerifyAccountSegue" sender:self];
                    
                } else{
                    BOOL dataSyncRequired = currentUser.dataSyncRequired;
                    [self syncLoggedInUserData:appDelegate.user datasysnRequired:dataSyncRequired];
                    
                    self.postloginProcessLaunched = NO;
                    [SCHUtility setSideMenu];
                }
                
            }

            
       } else{
           [self logoutDueToError];
       }
        
        
    }
    
    
    
    
}



-(void)syncLoggedInUserData:(SCHUser *) user datasysnRequired:(BOOL) dataSyncRequired{
    
    

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        dispatch_barrier_async(appDelegate.backgroundManager.SCHSerialQueue, ^{
            
            SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
            [backgroundManager beginBackgroundTask];
            if ([SCHUtility userToDevicelink]){
                if (dataSyncRequired){
                    if ([SCHUtility syncPriorNonUserActivities:user.phoneNumber email:user.email User:user]){
                        [SCHSyncManager syncUserData:nil];
                        if (appDelegate.dataSyncFailure){
                            [self logoutDueToError];
                            
                        }
                        
                    }else{
                        [self logoutDueToError];
                        
                    }
                    
                }else{
                    [SCHSyncManager syncUserData:nil];
                    if (appDelegate.dataSyncFailure){
                        [self logoutDueToError];
                        
                    }
                    
                }
                
                
            } else{
                [self logoutDueToError];
            }
            
            
            
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:NULL];
            });
             
            
            [backgroundManager endBackgroundTask];
            
        });
        
    }
}



/*****************************************/
#pragma mark - logout
/*****************************************/

-(void)userLogout{
    
    //logout user then process
    SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
    
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        
        if (error) {
            AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            if (appdeligate.serverReachable){
                [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser]];
                [PFUser currentUser][@"CBUser"] = [NSNull null];
                [[PFUser currentUser] saveEventually];
            }
            
            
        }
        
        
        
        dispatch_async(backgroundManager.SCHSerialQueue, ^{
            
            [self beginBackgroundTask];
            dispatch_async(dispatch_get_main_queue(), ^{
                AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                if (appdeligate.serverReachable){
                    [SCHUtility logout];
                }
                self.logoutUser = NO;
                if ([self userLoginStatus] && !self.LoginInProgress){
                    [self postLoginProcess];
                }
                self.welcomeLabel.text = @"Welcome";
            });
            [self endBackgroundTask];
            
        });
        
        
    }];
    
    
}

#pragma mark - UI TextFieldDelegate




-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ([textField isEqual:self.emailTextView]){
        if (self.emailTextView.text.length > 0){
        
            if([self isValidEmail:self.emailTextView.text]){
                [textField resignFirstResponder];
                [self.passwordTextView becomeFirstResponder];
                
                return YES;
            }else{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter valid email address.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                textField.textColor = [SCHUtility brightOrangeColor];
                return NO;
            }
            
        }else{
            [textField resignFirstResponder];
            [_passwordTextView becomeFirstResponder];
            return YES;
        }
       
    }else if ([textField isEqual:self.passwordTextView]){
        
        if (textField.text.length >0 && self.emailTextView.text.length > 0){
            
            [textField resignFirstResponder];
            
            [self startEmailLoginSignup:NULL];
            return YES;
            
        } else if (_emailTextView.text.length == 0){
            [textField resignFirstResponder];
            [self.emailTextView becomeFirstResponder];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter valid email address.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];

            return YES;
            
            
        }else
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter password.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];

        return NO;
        
        

            
            
    } else{
        [textField resignFirstResponder];
        return YES;
        
    }
        


}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    textField.textColor = [SCHUtility deepGrayColor];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    textField.textColor = [SCHUtility deepGrayColor];
   /*
    if (self.emailTextView.text.length > 0 && self.passwordTextView.text.length > 0){
        self.btnEmailLoginSignup.userInteractionEnabled = YES;
        
    }else{
        self.btnEmailLoginSignup.userInteractionEnabled = NO;
    }
    */
    
    return YES;
    
    
}




-(void)dismissKeyboard {
    
    if ([self.emailTextView isFirstResponder]){
        [self.emailTextView resignFirstResponder];
    } else if ([self.passwordTextView isFirstResponder]){
        [self.passwordTextView resignFirstResponder];
    }
}






#pragma mark - UI Configurations and utilities

-(void) inititalizeLoginView{
    //self.loginWithEmailView.hidden = YES;
    //login View
    self.loginView.layer.borderColor = [[UIColor whiteColor] CGColor];
    
    // FBLogingButton
    self.btnFBLogin.layer.cornerRadius = self.btnFBLogin.frame.size.height/2;
    self.btnFBLogin.layer.masksToBounds = YES;
    self.btnFBLogin.layer.borderWidth = 2;
    self.btnFBLogin.layer.borderColor = [UIColor whiteColor].CGColor;
    self.btnFBLogin.clipsToBounds = YES;
//    [self.btnFBLogin.layer layoutIfNeeded];
    

    //Email btn
    self.btnEmailLogin.layer.cornerRadius = self.btnEmailLogin.frame.size.height/2;
    self.btnEmailLogin.layer.masksToBounds = YES;
    
    self.btnEmailLogin.layer.borderWidth = 2;
    self.btnEmailLogin.layer.borderColor = [UIColor whiteColor].CGColor;
    self.btnEmailLogin.clipsToBounds = YES;
//    [self.btnEmailLogin.layer layoutIfNeeded];
    
  //Email btn
    self.btnEmailLoginSignup.layer.cornerRadius = self.btnEmailLoginSignup.frame.size.height/2;
    self.btnEmailLoginSignup.layer.masksToBounds = YES;
    self.btnEmailLoginSignup.layer.borderWidth = 2;
    self.btnEmailLoginSignup.layer.borderColor = [UIColor whiteColor].CGColor;
    self.btnEmailLoginSignup.clipsToBounds = YES;
//    [self.btnEmailLoginSignup.layer layoutIfNeeded];
    
    

    
   UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"email_icon.png"]];
//    [imageView setFrame:CGRectMake(10, 10, 20, 20)];
    UIView *view  = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.emailTextView.frame.size.height, self.emailTextView.frame.size.height)];
    [view setBackgroundColor:[SCHUtility colorFromHexString:@"#118273"]];
    int viewHeight = self.emailTextView.frame.size.height;
    int width= viewHeight/2;
    [imageView setFrame:CGRectMake(width/2, width/2, width, width)];
    
    
    
    [view addSubview:imageView];
    
    self.emailTextView.leftView = view;
    self.emailTextView.leftViewMode = UITextFieldViewModeAlways;
    self.emailTextView.borderStyle = UITextBorderStyleRoundedRect;
    
    
    // border radius
    [view.layer setCornerRadius:width];
    [self.emailTextView.layer setCornerRadius:width];
    [self.emailTextView.layer setBorderWidth:1];
    [self.emailTextView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    
    [view layoutIfNeeded];
   [self.emailTextView layoutIfNeeded];
    
    imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"password_icon.png"]];
    view  = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.passwordTextView.frame.size.height, self.passwordTextView.frame.size.height)];
    [view setBackgroundColor:[SCHUtility colorFromHexString:@"#118273"]];
    viewHeight = self.passwordTextView.frame.size.height;
    width= viewHeight/2;
    [imageView setFrame:CGRectMake(width/2, width/2, width, width)];
    
    [view addSubview:imageView];
    [view layoutIfNeeded];
    self.passwordTextView.leftView = view;
    self.passwordTextView.leftViewMode = UITextFieldViewModeAlways;
    self.passwordTextView.borderStyle = UITextBorderStyleRoundedRect;
    [self.passwordTextView.layer setBorderWidth:1];
    [self.passwordTextView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
 
    // border radius
    [view.layer setCornerRadius:width];
    [self.passwordTextView.layer setCornerRadius:width];
    [view layoutIfNeeded];
    [self.passwordTextView layoutIfNeeded];
    
    
    
    
    //EmailtextView
    self.emailTextView.backgroundColor = [UIColor whiteColor];
    
    //passwordView
    self.passwordTextView.backgroundColor = [UIColor whiteColor];
    
    //cancel email login view
    self.btnEmailLoginCancel.layer.cornerRadius = 7.0;
    self.btnEmailLoginCancel.layer.masksToBounds = YES;

    
//    //sign in signup
//    self.btnEmailLoginSignup.layer.cornerRadius = 20.0;
//    self.btnEmailLoginSignup.layer.masksToBounds = YES;
////    self.btnEmailLoginSignup.backgroundColor = [UIColor whiteColor];
    
  
}

-(void) changeLoginView{
//
   
    if ([self.emailTextView isFirstResponder]){
        [self.emailTextView resignFirstResponder];
    } else if ([self.passwordTextView isFirstResponder]){
        [self.passwordTextView isFirstResponder];
    }
    self.btnFBLogin.hidden = YES;
    self.btnFBLogin.userInteractionEnabled = NO;
    self.btnEmailLogin.hidden = YES;
    self.btnEmailLogin.userInteractionEnabled = NO;
    self.btnForgotPassword.hidden = YES;
    self.btnForgotPassword.userInteractionEnabled = NO;
    self.btnEmailLoginSignup.hidden = YES;
    self.btnEmailLoginSignup.userInteractionEnabled = NO;
    self.btnEmailLoginCancel.hidden = YES;
    self.btnEmailLoginCancel.userInteractionEnabled = NO;
    self.emailTextView.hidden = YES;
    self.emailTextView.userInteractionEnabled = NO;
    self.emailTextView.text = @"";
    self.passwordTextView.hidden = YES;
    self.passwordTextView.userInteractionEnabled = NO;
    self.passwordTextView.text = @"";
    self.imageView.image = [UIImage imageNamed:@"back.png"];
    if (self.emailTextView.firstBaselineAnchor){
        [self.emailTextView resignFirstResponder];
    }
    if (self.passwordTextView.isFirstResponder){
        [self.passwordTextView resignFirstResponder];
    }
    
    [self disbaleLogingViwBorder];
    
    if ([self.loginViewMode isEqualToString:kLoginOption]){
        //disable and hide all email login stuff
        self.loginWithEmailView.hidden = YES;
        self.loginView.hidden = NO;
        self.btnFBLogin.hidden = NO;
        self.btnFBLogin.userInteractionEnabled = YES;
        self.btnEmailLogin.hidden = NO;
        self.btnEmailLogin.userInteractionEnabled = YES;
        

        
        
        
    } else if ([self.loginViewMode isEqualToString:kEmailLogin]){
        self.loginView.hidden = YES;
        self.loginWithEmailView.hidden = NO;
        self.btnForgotPassword.hidden = NO;
        self.btnForgotPassword.userInteractionEnabled = YES;
        self.btnEmailLoginSignup.hidden = NO;
        self.btnEmailLoginSignup.userInteractionEnabled = YES;
        self.btnEmailLoginCancel.hidden = NO;
        self.btnEmailLoginCancel.userInteractionEnabled = YES;
        self.emailTextView.hidden = NO;
        self.emailTextView.userInteractionEnabled = YES;
        self.passwordTextView.hidden = NO;
        self.passwordTextView.userInteractionEnabled = YES;
        [self enableLoginViewborder];
        
        CGFloat height = self.view.frame.size.height;
    
        
        if (height < 568.0){
            self.imageView.image = nil;
        }else if (height == 568.0){
            self.imageView.image = [UIImage imageNamed:@"back1.png"];
        }
       
        
    }
    
    
}

-(void) enableLoginViewborder{
    self.loginView.layer.borderWidth = 1.0;
    
}

-(void)disbaleLogingViwBorder{
    
    self.loginView.layer.borderWidth = 0.0;
    
}

-(BOOL) userLoginStatus{
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL userStatus = NO;
    if ([SCHConstants sharedManager]){
        PFUser *currentUser = [PFUser currentUser];
        if (!currentUser) { // No user logged in
            if (appdeligate.serverReachable){
                if (![SCHUtility IsMandatoryUpgradeRequired]){
                    [self PresentLoginView];
                } else{
                    self.welcomeLabel.text = [NSString stringWithFormat:@"Please upgrade to latest version."];
                    self.LoginInProgress = NO;
                }
            } else{
                self.welcomeLabel.text = [NSString stringWithFormat:@"Please Connect to Internet."];
                [self PresentLoginView];
                self.LoginInProgress = NO;
            }
        } else{
            userStatus = YES;
        }
    } else {
        self.welcomeLabel.text = [NSString stringWithFormat:@"Please Connect to Internet."];
        self.LoginInProgress = NO;
        
    }
    
    return userStatus;
}

-(void)PresentLoginView{
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appdeligate.serverReachable && !self.LoginInProgress){
        self.loginViewMode = kLoginOption;
        [self changeLoginView];
        self.welcomeLabel.text = @"Welcome";

    } else{
        self.loginViewMode = kHideLoginView;
        [self changeLoginView];
    }
    
    
}

-(void)internetConnectionChanged{
    
    if ([[self topMostController] isEqual:self]){
         [self viewDidAppear:YES];
    }
    
   
    
    
    
}
-(void) setTermsAndConditionMessage{
    
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.alignment                = NSTextAlignmentCenter;

    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName: [UIColor whiteColor],
                               NSParagraphStyleAttributeName:paragraphStyle};
    
    UIFontDescriptor *bodyFontDescriptor = [[SCHUtility getPreferredBodyFont] fontDescriptor];
    UIFontDescriptorSymbolicTraits traits = bodyFontDescriptor.symbolicTraits;
    traits |= UIFontDescriptorTraitBold;
    

    
     
    NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor],
                                     NSUnderlineColorAttributeName: [UIColor whiteColor],
                                     NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
 
    
   NSURL *termsOfUseURL = [NSURL URLWithString: @"http://www.counterbean.com/Docs/counterBeanTermsOfUse.pdf"];
    NSURL *PrivacyPolicyUseURL = [NSURL URLWithString: @"http://www.counterbean.com/Docs/counterBeanPrivacyPolicy.pdf"];
    
    
    NSMutableAttributedString *termsOfUseString = [[NSMutableAttributedString alloc] initWithString:@"By signing up, I agree to CounterBean's Terms of use and Privacy Policy" attributes:bodyAttr];
    
    
    [termsOfUseString addAttribute:NSLinkAttributeName
                             value:termsOfUseURL
                             range:[[termsOfUseString string] rangeOfString:@"Terms of use"]];
    [termsOfUseString addAttribute:NSLinkAttributeName
                             value:PrivacyPolicyUseURL
                             range:[[termsOfUseString string] rangeOfString:@"Privacy Policy"]];
    
    
    
    
    [self.termsAndConditionMessage setAttributedText:termsOfUseString];
    self.termsAndConditionMessage.linkTextAttributes = linkAttributes;
    self.termsAndConditionMessage.delegate = self;
    
    
}


- (void) endBackgroundTask
{
    [[UIApplication sharedApplication] endBackgroundTask: self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
}
- (void) beginBackgroundTask
{
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}


- (BOOL)isValidEmail:(NSString *)email
{
    NSString *regex1 = @"\\A[a-z0-9]+([-._][a-z0-9]+)*@([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,6}\\z";
    NSString *regex2 = @"^(?=.{1,64}@.{4,64}$)(?=.{6,100}$).*";
    NSPredicate *test1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex1];
    NSPredicate *test2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex2];
    return [test1 evaluateWithObject:email] && [test2 evaluateWithObject:email];
}

- (void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (buttonIndex == 1 && [theAlert isEqual:self.remindEmailVerificationAlertView]){
        if (appDelegate.serverReachable){
            [PFCloud callFunctionInBackground:@"resendVerificationEmail" withParameters:@{@"email" : self.emailTextView.text} block:^(id  _Nullable object, NSError * _Nullable error) {
                [self.emailTextView setText:@""];
                [self.passwordTextView setText:@""];
                
                
            }];

        }
        
        
        
    }
    
    if (buttonIndex == 1 && [theAlert isEqual:self.reenterPasswordAlert]){
        
        NSString *password =[[theAlert textFieldAtIndex:0] text];
        if ([password isEqualToString:self.passwordTextView.text]){
            
            if (appDelegate.serverReachable){
                [PFCloud callFunctionInBackground:@"cbSignUp" withParameters:@{@"email" : self.emailTextView.text, @"password": self.passwordTextView.text} block:^(id  _Nullable object, NSError * _Nullable error) {
                    
                    
                    if (error){
                       // NSLog(@"%@", error);
                    }
                    
                    
                }];
                
                
                
                
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:[NSString localizedStringWithFormat:@"We sent email to %@. It may take few minutes. Please verify using the link provided", self.emailTextView.text] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                
            }
            
            
            self.loginViewMode = kLoginOption;
            [self changeLoginView];
            
        } else{
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"password doesn't match.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            self.passwordTextView.text = @"";
        }
        
    }
    
    
    if (buttonIndex == 1 && [theAlert isEqual:self.forgotPasswordAlert]){
        //check if user exist for the emai
        
        NSString *email =[[theAlert textFieldAtIndex:0] text];
        if (email.length > 0){
            if (![self isValidEmail:email]){
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"This is not valid email address.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                
            } else{
                //chack if user exists
                
                if (appDelegate.serverReachable){
                    PFQuery *userQuery = [PFUser query];
                    [userQuery whereKey:@"username" equalTo:email];
                    
                    if ([userQuery countObjects] == 0){
                        NSString *message = [NSString localizedStringWithFormat:@"%@ is not a valid user. Please signup.", email];
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                        
                    }else{
                        [self resetPassword:email];
                    }

                    
                }
                
                
                
            }
            
        }
        
        
        
    }
}

-(UIViewController*) topMostController
{

    
    return self.navigationController.topViewController;
}









@end
