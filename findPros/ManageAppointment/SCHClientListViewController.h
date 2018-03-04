//
//  SCHClientListViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/2/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XLForm.h"
@interface SCHClientListViewController : UIViewController<UISearchBarDelegate,UITableViewDelegate,UITableViewDataSource,XLFormRowDescriptorViewController>
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UISegmentedControl *OptionButton;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *contactList;
@property (strong, nonatomic) NSMutableArray *clientList;

@property CGFloat rowheight;

@end
