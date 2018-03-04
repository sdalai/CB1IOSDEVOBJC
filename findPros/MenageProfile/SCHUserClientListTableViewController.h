//
//  SCHUserClientListTableViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/9/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCHUserClientListTableViewController : UITableViewController
@property (strong, nonatomic) NSMutableArray *clientList;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addNewClient;
- (IBAction)addNewClient:(id)sender;

@end
