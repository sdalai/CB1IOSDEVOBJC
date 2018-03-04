//
//  SCHServiceDatailViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 8/13/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHUtility.h"
#import "SCHService.h"
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
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"

@interface SCHServiceDatailViewController : XLFormViewController<CNPPopupControllerDelegate>
@property (nonatomic, strong) CNPPopupController *popupController;

@property (strong,nonatomic) SCHService* serviceObject;
@property FDTakeController *takeController;
@property (nonatomic,strong)UIImageView* userProfileImageView;
@property(nonatomic, assign) BOOL popUpAlertToPublishAvailability;
@property (nonatomic, assign) BOOL popUpAlertForPrivacyControl;


@end
