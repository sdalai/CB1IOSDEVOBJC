//
//  SCHAddServiceViewController.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/22/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "XLFormViewController.h"
#import "FDTakeController.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
@interface SCHAddServiceViewController : XLFormViewController

@property FDTakeController *takeController;
@property (nonatomic,strong)UIImageView* userProfileImageView;

- (IBAction)goToNext:(id)sender;

@end
