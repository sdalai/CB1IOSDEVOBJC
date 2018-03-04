//
//  SCHPhoneVerificationViewController.h
//  CounterBean
//
//  Created by Sujit Dalai on 8/16/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "SCHScheduledEventManager.h"
#import <PFFacebookUtils.h>
#import "SCHUtility.h"
#import "SCHUser.h"

@interface SCHPhoneVerificationViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *verificationInstruction;

@property (weak, nonatomic) IBOutlet UIButton *btnVerify;
@property (weak, nonatomic) IBOutlet UIButton *btnResendVerificationCode;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) id parentVC;

@end
