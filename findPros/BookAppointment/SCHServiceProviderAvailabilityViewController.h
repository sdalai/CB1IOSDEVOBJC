//
//  SCHServiceProviderAvailabilityViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 7/8/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHService.h"
#import "SCHScheduledEventManager.h"
#import "SCHUtility.h"
#import "SCHAvailabilityForAppointment.h"
#import "SCHNewAppointmentByClientViewController.h"
#import "SCHAppointment.h"
#import <JTCalendar/JTCalendar.h>

@interface SCHServiceProviderAvailabilityViewController : UIViewController<UITableViewDelegate, UITableViewDataSource,JTCalendarDelegate>
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *calendarContentViewHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *calendarMenuViewHeight;

@property (strong,nonatomic) SCHService* selectedServiceProvider;
@property (strong, nonatomic)SCHAppointment *CurrentAppointment;
@property (strong, nonatomic) NSDictionary *avaliblityDict;
@property (strong, nonatomic) NSArray* availabilityDays;
@property (strong, nonatomic) NSDictionary * availabilities;
@property (nonatomic, strong) NSDateFormatter *scheduleHeaderFormatter;
@property (nonatomic, strong) NSDateFormatter *scheduleTimeFormatter;
@property (nonatomic, strong) SCHConstants *constants;
@property (nonatomic, strong) id parent;
@property CGFloat rowheight;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet JTCalendarMenuView *calendarMenuView;
@property (weak, nonatomic) IBOutlet JTHorizontalCalendarView *calendarContentView;

@property (strong, nonatomic) JTCalendarManager *calendarManager;

@property (strong, nonatomic) NSMutableArray *navigateaRightItems;


@end
