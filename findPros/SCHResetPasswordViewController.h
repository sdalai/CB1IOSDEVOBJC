//
//  SCHResetPasswordViewController.h
//  CounterBean
//
//  Created by Sujit Dalai on 8/21/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface SCHResetPasswordViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *passwordResetView;


@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@property (weak, nonatomic) IBOutlet UIButton *cancelResetButton;


@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;

@end
