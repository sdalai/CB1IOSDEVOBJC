//
//  SCHServiceOfferingDetailsViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 8/13/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHService.h"
#import "XLForm.h"
#import "SCHAddServiceDescription.h"
#import <Parse/Parse.h>
#import "SCHServiceClassification.h"
#import "SCHService.h"
#import "SCHServiceOffering.h"
#import "SCHservicePictureTableViewCell.h"
@interface SCHServiceOfferingDetailsViewController : XLFormViewController
@property (strong,nonatomic) SCHService* serviceObject;
@property (strong,nonatomic) SCHServiceOffering* selectedOffering;
@end
