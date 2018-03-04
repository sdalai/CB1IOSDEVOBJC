//
//  SCHUserVerificationViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 8/6/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "SCHScheduledEventManager.h"
#import <PFFacebookUtils.h>
#import "SCHUtility.h"
#import "SCHUser.h"
#import "FDTakeController.h"
@interface SCHUserVerificationViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *profilePicture;

@property (weak, nonatomic) IBOutlet UITextField *firstName;

@property (weak, nonatomic) IBOutlet UITextField *lastName;
@property (weak, nonatomic) IBOutlet UITextField *mobileNumber;

@property (nonatomic, strong) SCHUser *currentUser;
@property (strong, nonatomic) IBOutlet UIView *userInfoView;
@property (weak, nonatomic) IBOutlet UILabel *firstNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *mobileLabel;

@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property FDTakeController *takeController;

@property (weak, nonatomic) IBOutlet UILabel *txtPhotoMessage;
-(void) initializeFieldValues;








- (IBAction)cancelVerification:(id)sender;

@end
