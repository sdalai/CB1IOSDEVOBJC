//
//  SCHLoginOptionViewController.m
//  CounterBean
//
//  Created by Pratap Yadav on 18/07/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHLoginOptionViewController.h"
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

#define BTN_CORNER_RADIUS ((float) .07)
#define BTN_BORDER_WIDTH ((int) 2)

@interface SCHLoginOptionViewController ()

@property(nonatomic, assign) BOOL FBLogin;
@property(nonatomic, assign) BOOL LoginInProgress;
@property (nonatomic, assign) BOOL postloginProcessLaunched;


@end

@implementation SCHLoginOptionViewController

/*****************************************/
#pragma mark - Life Cycle, Initialization and connectivity
/*****************************************/
-(void)setViewDesign
{
    [self.navigationController.navigationBar setHidden:YES];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"email_icon.png"]];
    [imageView setFrame:CGRectMake(10, 10, 20, 20)];
    UIView *view  = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.txtEmail.frame.size.height, self.txtEmail.frame.size.height)];
    [view setBackgroundColor:[UIColor grayColor]];
    [view addSubview:imageView];
    int viewHeight = self.txtPassword.frame.size.height;
    int width= viewHeight/2;
    [imageView setFrame:CGRectMake(width/2, width/2, width, width)];
    
    
    self.txtEmail.leftView = view;
    self.txtEmail.leftViewMode = UITextFieldViewModeAlways;
    self.txtEmail.borderStyle = UITextBorderStyleRoundedRect;
    
    
    imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"password_icon.png"]];
    view  = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.txtPassword.frame.size.height, self.txtPassword.frame.size.height)];
    [view setBackgroundColor:[UIColor grayColor]];
    viewHeight = self.txtPassword.frame.size.height;
    width= viewHeight/2;
    [imageView setFrame:CGRectMake(width/2, width/2, width, width)];
    
    [view addSubview:imageView];
    self.txtPassword.leftView = view;
    self.txtPassword.leftViewMode = UITextFieldViewModeAlways;
    self.txtPassword.borderStyle = UITextBorderStyleRoundedRect;
    
    
    self.btnSignIn.layer.cornerRadius = self.btnSignIn.frame.size.width*BTN_CORNER_RADIUS;
    self.btnSignIn.layer.borderWidth = BTN_BORDER_WIDTH;
    self.btnSignIn.layer.borderColor = [UIColor whiteColor].CGColor;
    self.btnSignIn.clipsToBounds = YES;
    self.postloginProcessLaunched = NO;
    
}

-(void)internetConnectionChanged{
    
    [self userLoginStatus];
    [self PresentLoginView];
    
    
    
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
        [self.LoginView setHidden:NO];
    } else{
        [self.LoginView setHidden:YES];
    }
    
    
}



-(void)setDefaultLoginScreen{
    self.welcomeLabel.text = @"Not Logged in";
    [self.LoginView setHidden:NO];
    
}



-(void)viewDidLoad{
    [super viewDidLoad];
    
   UITapGestureRecognizer *facebookTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(FacebookLoginAction)];
   [self.btnFacebookLogin setUserInteractionEnabled:YES];
   [self.btnFacebookLogin addGestureRecognizer:facebookTap];
    
    UITapGestureRecognizer *loginTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(emalLoginAction)];
    [self.btnSignIn setUserInteractionEnabled:YES];
    [self.btnSignIn addGestureRecognizer:loginTap];
    
    UITapGestureRecognizer *resetPasswordTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetPassword)];
    [self.forgotPassword setUserInteractionEnabled:YES];
    [self.forgotPassword addGestureRecognizer:resetPasswordTap];
    
    
    
    
    

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    //self.userAgreementAgreed = YES;
    //self.privacyPolicyAgreed = YES;
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appdeligate.slideMenu = nil;
    appdeligate.tabBarController = nil;
    
    [self setViewDesign];
    [self.LoginView setHidden:YES];
    self.LoginInProgress = NO;

    
}

-(void)resetPassword{
    
    [PFCloud callFunctionInBackground:@"sendOTP" withParameters:@{@"email" : @"sujitdalai@yahoo.com"} block:^(id  _Nullable object, NSError * _Nullable error) {
        
        
        
        if (!error){
            NSLog(@"Notification Sent");
        } else{
            NSLog(@"Notification was not Sent");
        }
    }];
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"We emailed you temporary password", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    
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
                self.welcomeLabel.text =[NSString stringWithFormat:NSLocalizedString(@"Welcome %@ %@!", nil), firstName, lastName];
            } else{
                self.welcomeLabel.text =[NSString stringWithFormat:NSLocalizedString(@"Welcome", nil)];
            }
        } else {
            self.welcomeLabel.text = NSLocalizedString(@"Not logged in", nil);
            // [self.LoginView setHidden:NO];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    
    if (self.logoutUser){
        [self userLogout];
    }else{
        if ([self userLoginStatus] && !self.LoginInProgress && !self.postloginProcessLaunched){
            [self postLoginProcess];
        }
        
    }
}

-(void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.postloginProcessLaunched = NO;
}

/*****************************************/
#pragma mark - Login with Email
/*****************************************/

-(void)emalLoginAction{
    
    self.LoginInProgress = YES;
    [self PresentLoginView];

    
    if (self.txtEmail.text.length == 0 || self.txtPassword.text.length == 0){
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please provide email and password.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        self.LoginInProgress = NO;
        [self PresentLoginView];
        return;
        
    }
    
    if (![self isValidEmail:self.txtEmail.text]){
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please enter valid email address.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        self.LoginInProgress = NO;
        [self PresentLoginView];
        return;
        
    }
    
    //check if user exists in user table
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"username" equalTo:self.txtEmail.text];
    
    if ([userQuery countObjects] > 0){
        //user email credential exists.
        // check if email validated
        PFUser *user = [userQuery getFirstObject];
        BOOL emailvalidated = [user[@"emailVerified"] boolValue];
        
        if (emailvalidated){
            //start login
            [PFUser logInWithUsernameInBackground:self.txtEmail.text password:self.txtPassword.text
                                            block:^(PFUser *user, NSError *error) {
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    self.txtEmail.text = @"";
                                                    self.txtPassword.text = @"";
                                                });
                                                
                                                
                                                if (user) {
                                                    // Do stuff after successful login.
                                                    [self linkSCHUserWithEmail:self.txtEmail.text
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
            
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"We have sent you email to validate your emaill address. Please validate before login.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            self.LoginInProgress = NO;
            [self PresentLoginView];
            return;
        }
        
    } else{
        // user email credential doesn't exists. sign up
        
        [PFCloud callFunctionInBackground:@"cbSignUp" withParameters:@{@"email" : self.txtEmail.text, @"password": self.txtPassword.text} block:^(id  _Nullable object, NSError * _Nullable error) {
            
            
            
            if (!error){
                 NSLog(@"Notification Sent");
            } else{
                 NSLog(@"Notification was not Sent");
            }
        }];
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"We have sent you email to validate your emaill address. Please validate and login.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        self.LoginInProgress = NO;

        
        [self PresentLoginView];
        return;
        
        
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
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name, first_name, last_name, email"}];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id FBUser, NSError *error) {
            
            if (!error){
                if (!FBUser[@"email"]|| !FBUser[@"first_name"]||!FBUser[@"last_name"]||!FBUser[@"id"]){
                    [self facebookAccessError];
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
                [self facebookAccessError];
            }
            
        }];
    } else{
        //show alert and log out
        [self facebookAccessError];
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


-(void) facebookAccessError{
    self.LoginInProgress = NO;
    [self PresentLoginView];
    [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser]];
    [PFUser currentUser][@"CBUser"] = [NSNull null];
    [[PFUser currentUser] save];
    [SCHUtility logout];
    [self setDefaultLoginScreen];
    
}


/*****************************************/
#pragma mark - Post Login
/*****************************************/


-(void)linkSCHUserWithEmail:(NSString *) email firstName:(NSString *) firstName lastName:(NSString *) lastName facebookId:(NSString *) facebookId twiterId:(NSString *) twitterId{
     SCHUser *user = nil;
     PFUser *currentPraseUser = [PFUser currentUser];
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
            [self facebookAccessError];
        } else{
            if (existingUsers.count > 0){
                user = (SCHUser *)existingUsers[0];
                user.facebookId =facebookId;
                if ([user save]){
                    currentPraseUser[@"CBUser"] = user;
                    if(![currentPraseUser save]){
                        [self facebookAccessError];
                    }
                } else{
                    [self facebookAccessError];
                }
            } else{
                SCHConstants *constants = [SCHConstants sharedManager];
                user = [SCHUser new];
                user.email = email;
                user.firstName = firstName;
                user.lastName = lastName;
                user.preferredName = user.firstName;
                user.facebookId = facebookId;
                user.dataSyncRequired = YES;
                user.subscriptionType = constants.SCHSubscriptionTypeFreeUser;
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
                         }
                     }];
                }
                if ([user save]){
                    currentPraseUser[@"CBUser"] = user;
                    if(![currentPraseUser save]){
                        [self facebookAccessError];
                    }
                } else{
                    [self facebookAccessError];
                }
                
            }
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            appDelegate.user = user;
            [self postLoginProcess];
        }
        
        
       }else{
           PFQuery *schUserQuery = [SCHUser query];
           [schUserQuery whereKey:@"email" equalTo:email];
           if ([schUserQuery countObjects] > 0){
               user = (SCHUser *)[schUserQuery getFirstObject];
               currentPraseUser[@"CBUser"] = user;
               if (![currentPraseUser save]){
                   [self facebookAccessError];
               }
               
           } else{
               SCHConstants *constants = [SCHConstants sharedManager];
               user = [SCHUser new];
               user.email = email;
               user.dataSyncRequired = YES;
               user.subscriptionType = constants.SCHSubscriptionTypeFreeUser;
               [SCHUtility setPublicAllRWACL:user.ACL];
               
               if ([user save]){
                   currentPraseUser[@"CBUser"] = user;
                   if(![currentPraseUser save]){
                       [self facebookAccessError];
                   }
               } else{
                   [self facebookAccessError];
               }
           }
           
           AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
           appDelegate.user = user;
           [self postLoginProcess];
    }
    

}



-(void)postLoginProcess{
    
    
    self.postloginProcessLaunched = YES;
    self.LoginInProgress = NO;

    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appdeligate.user && [SCHConstants sharedManager])
    {
        SCHUser *currentUser = appdeligate.user;
        [self syncLoggedInUserData:currentUser];
       // self.userAgreementAgreed = currentUser.termsOfUseAgreed;
        //self.privacyPolicyAgreed = currentUser.privacyPolicyAgreed;
        //if internet available then check with latest agreement
        //if (appdeligate.serverReachable){
            //[SCHUtility getFacebookUserFriends:currentUser];
          //  [self resetAgrrementStatus];
       // }
        NSString *phoneNumber = currentUser.phoneNumber;
        if(phoneNumber.length ==0|| currentUser.firstName.length == 0 || currentUser.lastName.length == 0 ||!currentUser.phoneNumberVerified){
            [self performSegueWithIdentifier:@"VerifyAccountSegue" sender:self];
        
        } else{
            BOOL dataSyncRequired = currentUser.dataSyncRequired;
            if (dataSyncRequired && appdeligate.serverReachable)
            {
                SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
                dispatch_async(backgroundManager.SCHSerialQueue, ^{
                    [SCHUtility syncPriorNonUserActivities:phoneNumber User:currentUser];
                    [SCHSyncManager syncUserData:nil];
                });
            }
            [SCHUtility setSideMenu];
        }
    
    
       /* else
        {
            if(!self.userAgreementAgreed){
                [self performSegueWithIdentifier:@"loginToTermsOfUseSegue" sender:self];
            }else if(!self.privacyPolicyAgreed){
                [self performSegueWithIdentifier:@"loginToPrivacyPolicySegue" sender:self];
            }else if (self.userAgreementAgreed && self.privacyPolicyAgreed)
            {
               
            }
        } */
    }

}



-(void)syncLoggedInUserData:(SCHUser *) user{
    
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        dispatch_barrier_async(appDelegate.backgroundManager.SCHSerialQueue, ^{
            
            SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
            [backgroundManager beginBackgroundTask];
            if (![SCHUtility initializeSCheduleScreenFilter:user]){
                [SCHUtility logout];
                self.LoginInProgress = NO;
                [self PresentLoginView];
            } else{
                if ([SCHUtility userToDevicelink]){
                    
                    [SCHSyncManager syncUserData:nil];
                    if (appDelegate.dataSyncFailure){
                        [SCHUtility logout];
                        self.LoginInProgress = NO;
                        [self PresentLoginView];
                        
                    }
                } else{
                    [SCHUtility logout];
                    self.LoginInProgress = NO;
                    [self PresentLoginView];
                }
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
                self.welcomeLabel.text = @"Not Logged in";
            });
            [self endBackgroundTask];
            
        });
        
        
    }];
    
    
}


/*****************************************/
#pragma mark - Utilities
/*****************************************/

/*

-(void)resetAgrrementStatus{
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSError *error = nil;
    SCHConstants *constants = [SCHConstants sharedManager];
    PFQuery *userAgreementDocumentQuery = [SCHLegalDocument query];
    [userAgreementDocumentQuery whereKey:@"Active" equalTo:@YES];
    [userAgreementDocumentQuery whereKey:@"documentType" equalTo:constants.SCHLegalDocumentUserAgreement];
    [userAgreementDocumentQuery orderByDescending:@"updatedAt"];
    SCHLegalDocument *userAgreement = nil;
    
    if (appdeligate.serverReachable){
        userAgreement=[userAgreementDocumentQuery getFirstObject:&error];
    }
    
    
    //GetPrivacy Policy
    PFQuery *privacyPolicyDocumentQuery = [SCHLegalDocument query];
    // [privacyPolicyDocumentQuery whereKey:@"objectId" notEqualTo:userAgreement.objectId];
    [privacyPolicyDocumentQuery whereKey:@"Active" equalTo:@YES];
    [privacyPolicyDocumentQuery whereKey:@"documentType" equalTo:constants.SCHLegalDocumentPrivacyPolicy];
    [privacyPolicyDocumentQuery orderByDescending:@"updatedAt"];
    SCHLegalDocument *privacyPolicy = nil;
    if (appdeligate.serverReachable){
        privacyPolicy =[privacyPolicyDocumentQuery getFirstObject:&error];
    }
    
    
    
    
    if (userAgreement){
        self.userAgreementAgreed = (appdeligate.user.termsOfUseAgreed && [userAgreement isEqual:appdeligate.user.termsOfUse]);
    }else{
        self.userAgreementAgreed = NO;
    }
    
    if (privacyPolicy){
        self.privacyPolicyAgreed = (appdeligate.user.privacyPolicyAgreed && [privacyPolicy isEqual:appdeligate.user.privacyPolicy]);
    } else{
        self.privacyPolicyAgreed = NO;
    }
    
    if (self.privacyPolicyAgreed){
        appdeligate.user.privacyPolicyAgreed = YES;
    }else{
        appdeligate.user.privacyPolicyAgreed = NO;
    }
    
    if (self.userAgreementAgreed){
        appdeligate.user.termsOfUseAgreed  = YES;
    } else{
        appdeligate.user.termsOfUseAgreed  = NO;
    }
}
 
 */

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



@end
