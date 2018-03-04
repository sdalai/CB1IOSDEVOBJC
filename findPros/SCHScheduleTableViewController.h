//
//  SCHScheduleTableViewController.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 5/27/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHScheduleSummeryViewController.h"
@interface SCHScheduleTableViewController : UIViewController<UIActionSheetDelegate,UISearchResultsUpdating,UISearchBarDelegate>

@property (nonatomic, copy) NSString *filterString;
@property (readonly, copy) NSArray *visibleResults;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

//- (IBAction)showActionSheet:(id)sender;
//- (void)willPresentActionSheet:(UIActionSheet *)actionSheet;
//- (IBAction)showTodayAppointment:(id)sender;
-(void)applyFilter;
-(void) refreshscheduleScreen:(NSDate *) CalendarViewDate;
-(void)addOptionWithServiceProvider;
-(void)addOptionWithOutServiceProvider;
- (void)ChangeViewAction:(id)sender;
- (void)createGroupAppointment:(id)sender;

@end
