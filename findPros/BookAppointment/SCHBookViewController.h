//
//  SCHBookAppointmentViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 7/7/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHUtility.h"
#import "SCHServiceClassification.h"
#import "SCHBookDetailViewController.h"
#import "SCHBackgroundManager.h"
@interface SCHBookViewController : UITableViewController
@property (nonatomic, strong) NSArray *tableData;
@property (nonatomic, strong) NSMutableArray *searchResult;
@property (nonatomic, assign) BOOL  activeServiceProvider;

-(void)loadData;

@end
