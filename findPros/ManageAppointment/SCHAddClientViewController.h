//
//  SCHAddClientViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/6/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XLForm/XLForm.h>
@interface SCHAddClientViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *txtName;
@property (strong, nonatomic) IBOutlet UITextField *txtPhone;
@property (strong, nonatomic) IBOutlet UITextField *txtEmail;
@property (nonatomic, weak) id <XLFormRowDescriptorViewController> XLFormdelegate;

- (IBAction)doneButtonAction:(id)sender;
//-(BOOL)validateUserInformationWithName:(NSString *)name andPhoneNumber:(NSString*)phone;
@end
