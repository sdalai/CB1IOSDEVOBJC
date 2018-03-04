//
//  SCHMinorClassificationTableViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/27/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHServiceMajorClassification.h"

@interface SCHMinorClassificationTableViewController : UITableViewController
@property (nonatomic, strong) NSArray *tableData;
@property (nonatomic, strong) NSMutableArray *searchResult;
@property (nonatomic, strong) SCHServiceMajorClassification *majorClassification_obj;

@end
