//
//  SCHUserAddNewClientViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 12/10/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XLForm.h"
@interface SCHUserAddNewClientViewController : UIViewController
@property (strong, nonatomic) IBOutlet UISwitch *btnAutoConfirm;
@property (strong, nonatomic) IBOutlet UITextField *txtEmail;
@property (strong, nonatomic) IBOutlet UITextField *txtPhone;
@property (strong, nonatomic) IBOutlet UITextField *txtName;


- (IBAction)saveClient:(id)sender;

@end
