//
//  SCHEditServiceViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/23/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XLFormViewController.h"
#import "FDTakeController.h"
#import "SCHService.h"
#import "XLForm.h"
#import "SCHAddServiceDescription.h"
#import <Parse/Parse.h>
#import "SCHServiceClassification.h"
#import "SCHService.h"
#import "SCHServiceOffering.h"
#import "SCHservicePictureTableViewCell.h"
#import "SCHServiceNewOfferingsViewController.h"
#import "SCHServiceDatailViewController.h"
@interface SCHEditServiceViewController : XLFormViewController
@property FDTakeController *takeController;
@property (nonatomic,strong)UIImageView* userProfileImageView;
@property (strong,nonatomic) SCHService* serviceObject;
@property (strong, nonatomic) SCHServiceDatailViewController *sendingVC;


- (IBAction)saveAction:(id)sender;

@end
