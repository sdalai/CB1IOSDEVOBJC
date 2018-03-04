//
//  SCHLoginOptionViewController.h
//  CounterBean
//
//  Created by Pratap Yadav on 18/07/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHBackgroundManager.h"

@interface SCHLoginOptionViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;

@property (weak, nonatomic) IBOutlet UITextField *txtEmail;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnSignIn;
@property (weak, nonatomic) IBOutlet UIImageView *btnGoogleLogin;
@property (weak, nonatomic) IBOutlet UIView *LoginView;

@property (weak, nonatomic) IBOutlet UIImageView *btnFacebookLogin;
@property (weak, nonatomic) IBOutlet UIButton *forgotPassword;

@property (nonatomic, assign) BOOL logoutUser;

//@property(nonatomic) BOOL userAgreementAgreed;
//@property (nonatomic) BOOL privacyPolicyAgreed;

@property (nonatomic, strong) SCHBackgroundManager *backgroundManager;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@end
