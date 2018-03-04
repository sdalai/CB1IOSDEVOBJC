//
//  SCHEditUserProfileViewController.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/15/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHUtility.h"
#import "XLForm.h"
#import "FDTakeController.h"

@interface SCHEditUserProfileViewController : XLFormViewController

@property FDTakeController *takeController;
@property (nonatomic,strong)UIImageView* userProfileImageView;

@property (nonatomic,strong) id parentVC;


- (IBAction)saveProfileAction:(id)sender;

@end
