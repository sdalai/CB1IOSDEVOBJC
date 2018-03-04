//
//  SCHUserAppointmentHistory.h
//  CounterBean
//
//  Created by Pratap Yadav on 26/05/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHConstants.h"
#import "SCHUser.h"
#import "SCHService.h"

@interface SCHUserAppointmentHistory : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating,UISearchBarDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSDateFormatter *scheduleHeaderFormatter;
@property (nonatomic, strong) NSDateFormatter *scheduleTimeFormatter;
@property (nonatomic, strong) SCHConstants *constants;
@property (strong, nonatomic) NSDictionary * historyData;
@property (strong, nonatomic) NSDictionary *appointmentDict;
@property (strong, nonatomic) NSArray* appointmentDays;
@property CGFloat rowheight;
@property (nonatomic, copy) NSString *filterString;
@property (nonatomic, strong) SCHUser *user;
@property (nonatomic, strong) SCHUser *serviceProvider;
@property (nonatomic, strong) SCHService  *service;


@end
