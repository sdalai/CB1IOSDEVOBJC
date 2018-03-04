//
//  SCHUserServicesTableViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/8/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
@interface SCHUserServicesTableViewController : UITableViewController
@property (nonatomic, strong) NSArray *tableData;
@property (nonatomic, assign) BOOL doNotnavigateToNewServiceScreen;


@end
