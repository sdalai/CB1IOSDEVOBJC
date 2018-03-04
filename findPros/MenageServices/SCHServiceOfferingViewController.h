//
//  SCHServiceOfferingViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 8/13/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHService.h"
#import "SCHServiceClassification.h"
@interface SCHServiceOfferingViewController : UITableViewController
@property (strong,nonatomic) SCHService* serviceObject;
@property (strong,nonatomic) NSArray *offeringArray;
@end
