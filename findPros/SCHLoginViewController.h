//
//  SCHLoginViewController.h
//  CounterBean
//
//  Created by Sujit Dalai on 8/17/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHBackgroundManager.h"

@interface SCHLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *loginView;
@property (weak, nonatomic) IBOutlet UIView *loginWithEmailView;

@property (strong, nonatomic) IBOutlet UIView *btnFBLogin;
@property (weak, nonatomic) IBOutlet UIView *btnEmailLogin;
@property (weak, nonatomic) IBOutlet UIButton *btnEmailLoginCancel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextView;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextView;
@property (weak, nonatomic) IBOutlet UIButton *btnForgotPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnEmailLoginSignup;
@property(nonatomic, strong) NSString *loginViewMode;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic, assign) BOOL logoutUser;
@property (nonatomic, strong) SCHBackgroundManager *backgroundManager;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;

@property (weak, nonatomic) IBOutlet UITextView *termsAndConditionMessage;

@end
