 //
//  SCHScheduleTableViewController.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 5/27/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHScheduleTableViewController.h"
#import <Parse/Parse.h>
#import "SCHScheduledEventManager.h"
#import "SCHBackgroundManager.h"
#import "SCHUtility.h"
#import "SCHEvent.h"
#import "SCHObjectsForProcessing.h"
#import "SCHScheduleFilterViewController.h"
#import "SCHActiveViewControllers.h"
#import "SCHSyncManager.h"
#import <JTCalendar/JTCalendar.h>
#import "AppDelegate.h"
#import "SCHAlert.h"
#import "SCHUtility.h"
//#import "SCHSignupViewController.h"
#import "MFSideMenu.h"
#import "SCHUser.h"
#import "SCHMeeting.h"


//@"Request Appointment" @"Manage Availability"
static NSString * const kRequestAppoitment =@"Setup Appointment with Client";
static NSString * const kManageSchedule =@"Manage Business Schedule";


@interface SCHScheduleTableViewController () <UITableViewDelegate, UITableViewDataSource,JTCalendarDelegate>
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *calendarContentViewHeight;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *calendarMenuViewHeight;
@property (strong, nonatomic) SCHScheduledEventManager *eventManager;
@property (nonatomic, strong) NSDateFormatter *scheduleHeaderFormatter;
@property (nonatomic, strong) NSDateFormatter *scheduleTimeFormatter;
@property (nonatomic, strong) SCHConstants *constants;
@property (nonatomic, strong) SCHBackgroundManager *backgrounfManager;
@property (nonatomic, strong) NSArray *scheduledEventDays;
@property (nonatomic, strong) NSDictionary *scheduledDaysEvents;
@property (nonatomic, strong) SCHObjectsForProcessing *objectsForProcessing;
@property (nonatomic, strong) UISearchController *searchController;

@property CGFloat rowheight;
@property (weak, nonatomic) IBOutlet JTCalendarMenuView *calendarMenuView;
@property (weak, nonatomic) IBOutlet JTHorizontalCalendarView *calendarContentView;

@property (strong, nonatomic) JTCalendarManager *calendarManager;
@property (strong, nonatomic) NSMutableArray *navigateaRightItems;
@property (nonatomic, assign) BOOL loadingData;

@end

@implementation SCHScheduleTableViewController
UIRefreshControl *refreshControl;
SCHScheduleFilterViewController *filterView;
UIBarButtonItem *addButton =nil;
NSIndexPath *todayIndexPath;
NSDate* todayDate;
NSString *SelectedCurrentView;
NSMutableDictionary *_eventsByDate;
bool isMonthView = false;
NSDate *_todayDate;
NSDate *_minDate;
NSDate *_maxDate;

NSDate *_dateSelected;
NSMutableArray *selectedDayEvent;
NSString *selectedDateEvent;
int selectedView = 1;
UIBarButtonItem *listButton = nil;
- (void)viewDidLoad {
    
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCHUserLogout object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLogout)
                                                 name:SCHUserLogout
                                               object:nil];
    
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appdeligate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });

    
    SCHActiveViewControllers *activeVC = [SCHActiveViewControllers sharedManager];
    self.navigateaRightItems = [[NSMutableArray alloc]init];
    [activeVC.viewControllers setObject:self forKey:@"scheduleVC"];
    
    self.objectsForProcessing = [SCHObjectsForProcessing sharedManager];
    self.scheduleHeaderFormatter = [SCHUtility dateFormatterForFullDate];
    self.scheduleTimeFormatter = [SCHUtility dateFormatterForToTime];
    
    self.eventManager = [SCHScheduledEventManager sharedManager];
    
    self.scheduledEventDays = self.eventManager.scheduledEventDays;
    self.scheduledDaysEvents = self.eventManager.scheduledEvents;
    
     //self.eventManager.delegate = self;
    SelectedCurrentView = SCHScheduleCalenderWeekView;
    
    self.constants = [SCHConstants sharedManager];
    self.backgrounfManager = [SCHBackgroundManager sharedManager];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self addPullToRefresh];
    [self createMinAndMaxDate];
   
    //JT calendar
    _calendarManager = [JTCalendarManager new];
    _calendarManager.delegate = self;
    [_calendarManager setMenuView:_calendarMenuView];
    [_calendarManager setContentView:_calendarContentView];
    [_calendarManager setDate:[NSDate date]];
    _calendarManager.settings.weekModeEnabled = YES;
    self.calendarContentViewHeight.constant = 85;
    self.calendarMenuViewHeight.constant = 0;
    
    [_calendarManager reload];
    
    // JT Calendaer End
    [self setupMenuBarButtonItems];


}

-(void)userLogout{
    SCHActiveViewControllers *activeVC = [SCHActiveViewControllers sharedManager];
    [activeVC.viewControllers removeObjectForKey:@"scheduleVC"];
    [self dismissViewControllerAnimated:NO completion:NULL];
}

- (void)ChangeViewAction:(id)sender {
    
    SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
    if (!self.loadingData){
        dispatch_async(backgroundManager.SCHSerialQueue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if(SelectedCurrentView == SCHScheduleListView)
                {
                    //cange calender View
                    SelectedCurrentView=SCHScheduleCalenderWeekView;
                    
                    if(_dateSelected==nil && todayDate!=nil)
                        _dateSelected = todayDate;
                    else if(_dateSelected==nil)
                        _dateSelected = [NSDate new];
                    [_calendarManager setDate:_dateSelected];
                    
                    
                    self.calendarContentViewHeight.constant = 85;
                    _calendarManager.settings.weekModeEnabled = YES;
                    [self reloadSelectedDay];
                    [_calendarManager reload];
                    [self.tableView reloadData];
                    listButton.image = [UIImage imageNamed:@"month_view.png"];
                    
                }else if(SelectedCurrentView == SCHScheduleCalenderWeekView){
                    
                    _calendarManager.settings.weekModeEnabled = NO;
                    self.calendarContentViewHeight.constant = 280;
                    SelectedCurrentView=SCHScheduleCalenderMonthView;
                    [_calendarManager reload];
                    listButton.image = [UIImage imageNamed:@"list_view.png"];
                    
                }else if(SelectedCurrentView == SCHScheduleCalenderMonthView)
                {
                    
                    SelectedCurrentView = SCHScheduleListView;
                    self.calendarContentViewHeight.constant = 0;
                    [self.tableView reloadData];
                    listButton.image = [UIImage imageNamed:@"week_view.png"];
                }
                
                
            });
            
            
        });

        
    }
    
}

- (void)setupMenuBarButtonItems {
    
    if(self.menuContainerViewController.menuState == MFSideMenuStateClosed &&
       ![[self.navigationController.viewControllers objectAtIndex:0] isEqual:self]) {
        self.navigationItem.leftBarButtonItem = [self backBarButtonItem];
    } else {
        self.navigationItem.leftBarButtonItem = [self leftMenuBarButtonItem];
    }
}

- (UIBarButtonItem *)leftMenuBarButtonItem {
    
    return [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStylePlain
            target:self
            action:@selector(leftSideMenuButtonPressed:)];
}
- (void)leftSideMenuButtonPressed:(id)sender {
    
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
        [self setupMenuBarButtonItems];
    }];
}

- (UIBarButtonItem *)backBarButtonItem {
    
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(backButtonPressed:)];
}


-(void)internetConnectionChanged{
    
    [self screenSetting];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appDelegate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });
    
    if (appDelegate.user && appDelegate.serverReachable){
        
        dispatch_barrier_async(appDelegate.backgroundManager.SCHSerialQueue, ^{
            
            [SCHSyncManager syncUserData:_dateSelected];
            
        });
        
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!_dateSelected){
        _dateSelected = [self setCalendarViewDate:nil];
    }
    
    
    
    
}

-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self screenSetting];
    self.navigationItem.title = @"";//SCHSCreenTitleSchedule;
    
    if(filterView!=NULL)
        
        
    {
        if(filterView.isFilterChanged)
        {
            [self applyFilter];
            filterView.isFilterChanged = NO;
            
        }
    }
    
    [self refreshscheduleScreen:_dateSelected];
    
    
    
}

-(void)screenSetting{
    SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
    
    dispatch_async(backgroundManager.SCHSerialQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [SCHSyncManager syncBadge];
            BOOL is_userSrviceProvider =([SCHUtility hasActiveService] && [SCHUtility BusinessUserAccess] && appDelegate.serverReachable);
            if(is_userSrviceProvider)
            {
                [self addOptionWithServiceProvider];
            }else{
                [self addOptionWithOutServiceProvider];
            }
            
            
            [self initlizeTodayIndexPath];
        });
        
    });
    
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];

}


-(void)addOptionWithServiceProvider
{
   
    if (!self.navigateaRightItems){
        self.navigateaRightItems = [[NSMutableArray alloc]init];
    } else{
        [self.navigateaRightItems removeAllObjects];
    }
    

    
    
    if(listButton==nil)
        listButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"month_view"] style:UIBarButtonItemStylePlain target:self action:@selector(ChangeViewAction:)];

    
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"Filter_Black"] style:UIBarButtonItemStylePlain target:self action:@selector(addFilter)];
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc]
                                     
                                     
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                     
                                     
                                     target:self action:@selector(addSearchBar)];
    
    
    addButton = [[UIBarButtonItem alloc]
                                  
                                  
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                  
                                  
                                  target:self action:@selector(goToNewAppointment)];
    
    
    [self.navigateaRightItems addObject:addButton];
    [self.navigateaRightItems addObject:searchButton];
    [self.navigateaRightItems addObject:filterButton];
    [self.navigateaRightItems addObject:listButton];
    
 

//    if(calenderViewButton!=nil && ![viewButtonImageFile isEqualToString:SCHScheduleCalenderView])
//    {
//        if(![self.navigateaRightItems containsObject:calenderViewButton])
//        [self.navigateaRightItems addObject:calenderViewButton];
//    }
    
    self.navigationItem.rightBarButtonItems =self.navigateaRightItems;
    // @[addButton,searchButton,filterButton,listButton];
    
    
}





-(void)addOptionWithOutServiceProvider
{
    if (!self.navigateaRightItems){
        self.navigateaRightItems = [[NSMutableArray alloc]init];
    } else{
        [self.navigateaRightItems removeAllObjects];
    }
    

    
    
   if(listButton==nil)
    listButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"month_view"] style:UIBarButtonItemStylePlain target:self action:@selector(ChangeViewAction:)];
    
    
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"Filter_Black"] style:UIBarButtonItemStylePlain target:self action:@selector(addFilter)];
    
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(addSearchBar)];
    
    [self.navigateaRightItems addObject:filterButton];
    [self.navigateaRightItems addObject:searchButton];
    [self.navigateaRightItems addObject:listButton];
    

    self.navigationItem.rightBarButtonItems =self.navigateaRightItems;
    
    
}


-(void)addFilter{
    
    filterView = [[SCHScheduleFilterViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:filterView];
    [self presentViewController:navController animated:YES completion:NULL];
}



-(SCHEvent *)checkObjectsBeingProcessed:(SCHEvent *) event{
    
    if ([event.eventType isEqualToString:SCHAppointmentClass]){
        
        SCHAppointment *appointment = event.eventObject;
        if ([self.objectsForProcessing.objectsForProcessing containsObject:appointment]){
            appointment.status = self.constants.SCHappointmentStatusProcessing;
            event.eventObject = appointment;
        }
    }
    
    return event;
}

-(void) refreshscheduleScreen:(NSDate *) CalendarViewDate{
    dispatch_async(dispatch_get_main_queue(), ^{
//        [SCHUtility showProgressWithMessage:@"Loading..."];
        self.loadingData = YES;
        
        self.scheduledDaysEvents = self.eventManager.scheduledEvents;
        self.scheduledEventDays = self.eventManager.scheduledEventDays;
        self.eventManager.scheduleEventsChanged = NO;
        self.loadingData = NO;
        _dateSelected = [self setCalendarViewDate:CalendarViewDate];
        
        
        
        if(SelectedCurrentView == SCHScheduleListView)
        {
            [self.tableView reloadData];
        }else{
            
            [self reloadSelectedDay];
            [_calendarManager reload];
            [self.tableView reloadData];
            
        }
        [SCHUtility completeProgress];
        

    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initlizeTodayIndexPath{
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateStyle = NSDateIntervalFormatterLongStyle;
    
    NSDate *currentDate = [NSDate date];
    fmt.timeZone = [NSTimeZone systemTimeZone];
    NSString *current_date = [fmt stringFromDate:currentDate];
    
    for (int i =0;i<[self.eventManager.scheduledEventDays count];i++)
    {
        
        NSDate *datecompare =[self.eventManager.scheduledEventDays objectAtIndex:i];
        
        NSComparisonResult result = [currentDate compare:datecompare];
        
        if([current_date isEqualToString:[fmt stringFromDate:datecompare]])
        {
            todayIndexPath = [NSIndexPath indexPathForRow:0 inSection:i];
            todayDate = datecompare;
            
            break;
        }else if(todayIndexPath == nil && result == NSOrderedAscending)
        {
            todayIndexPath = [NSIndexPath indexPathForRow:0 inSection:i];
            todayDate = datecompare;
            break;
        }
        else if(result==NSOrderedSame)
        {
            todayIndexPath = [NSIndexPath indexPathForRow:0 inSection:i];
            todayDate = datecompare;
            break;
        }
    }
}


-(void)goToNewAppointment{
    [self performSegueWithIdentifier:@"appointmentSegue" sender:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(SelectedCurrentView == SCHScheduleListView)
    {
    return [self.scheduledEventDays count];
    }else{
//     if(selectedDayEvent!=nil && selectedDayEvent.count==0)
//            return 0;
//        else
            return 1;
    }
    
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(SelectedCurrentView == SCHScheduleListView)
    {
       return [self.scheduleHeaderFormatter stringFromDate:[self.scheduledEventDays objectAtIndex:section]];
    }else{
        
       return  [self.scheduleHeaderFormatter stringFromDate:_dateSelected];
        
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(SelectedCurrentView == SCHScheduleListView)
    {
    // Here it is a problem
        NSString *selectedDate = [self.scheduleHeaderFormatter stringFromDate:[self.scheduledEventDays objectAtIndex:section]];
        NSArray * array = [self.scheduledDaysEvents valueForKey:selectedDate];
        NSInteger rowcount = [array count];
        return rowcount;
    }else{
        return selectedDayEvent.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    SCHEvent *event;
    if(SelectedCurrentView == SCHScheduleListView)
    {
        event = [[self.scheduledDaysEvents valueForKey:[self.scheduleHeaderFormatter stringFromDate:[self.scheduledEventDays objectAtIndex:indexPath.section]]] objectAtIndex:indexPath.row];
    }elseion
    {
        event=[selectedDayEvent objectAtIndex:indexPath.row];
    }
    NSDictionary * cellContent;
    
    if ([event.eventObject isKindOfClass:[SCHAvailability class]]){
        cellContent = [SCHUtility availabilityInfoForScheduleScreen:event];
    } else if ([event.eventObject isKindOfClass:[SCHAppointment class]]){
        cellContent = [SCHUtility appointmentInfoForScheduleScreen:event];
    } else{
        cellContent = [SCHUtility meetupInfoForScheduleScreen:event];
    }
    
    UITextView * txtContent = [UITextView new];
    [txtContent setAttributedText:[cellContent valueForKey:@"content"]];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    
    float rowheight = [SCHUtility tableViewCellHeight:txtContent] +21.0;
     
     */
    return self.rowheight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setFont:[SCHUtility getPreferredTitleFont]];
    [header.textLabel setTextColor:[SCHUtility deepGrayColor]];
    
    if(SelectedCurrentView == SCHScheduleListView)
    {
        [header.textLabel setTextAlignment:NSTextAlignmentLeft];
    }else{
        [header.textLabel setTextAlignment:NSTextAlignmentCenter];
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"SCHScheduleCell" forIndexPath:indexPath];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SCHScheduleCell"];
    }
    UITextView *txtTime =(UITextView *)[cell.contentView viewWithTag:1];
    UIView *splitView =(UIView *)[cell.contentView viewWithTag:2];
    UITextView *txtContent =(UITextView *)[cell.contentView viewWithTag:3];
    SCHEvent *event;
    
    if(SelectedCurrentView == SCHScheduleListView)
    {
     event = [[self.scheduledDaysEvents valueForKey:[self.scheduleHeaderFormatter stringFromDate:[self.scheduledEventDays objectAtIndex:indexPath.section]]] objectAtIndex:indexPath.row];
    }else
    {
        event=[selectedDayEvent objectAtIndex:indexPath.row];
    }
    NSDictionary *cellContent;
    UIColor *txtBackgroundColor;
    UIColor *viewBackgroundColor;
    
    if (event.eventType == SCHAppointmentClass){
        SCHAppointment *appointment = (SCHAppointment*)event.eventObject;
       // NSLog(@"NON User Client: %@", appointment.nonUserClient);
        
        if(appointment.expired) {
            txtBackgroundColor =   [UIColor whiteColor];
            viewBackgroundColor = [UIColor lightGrayColor];
        } else if ([appointment.status isEqual:self.constants.SCHappointmentStatusCancelled]){
            
            txtBackgroundColor =   [UIColor whiteColor];
            viewBackgroundColor = [UIColor lightGrayColor];
        } else if([appointment.status isEqual:self.constants.SCHappointmentStatusConfirmed]){
            viewBackgroundColor = [SCHUtility greenColor];
            txtBackgroundColor = [UIColor whiteColor];
        }else{
            viewBackgroundColor = [SCHUtility brightOrangeColor];
            txtBackgroundColor = [UIColor whiteColor];
        }
        
       cellContent = [SCHUtility appointmentInfoForScheduleScreen:event];

    } else if (event.eventType == SCHAvailabilityClass) {
        cellContent = [SCHUtility availabilityInfoForScheduleScreen:event];
        viewBackgroundColor = [UIColor blueColor];
        txtBackgroundColor = [UIColor whiteColor];
        
    }else if (event.eventType == SCHMeetingClass){
        cellContent = [SCHUtility meetupInfoForScheduleScreen:event];
        if ([[SCHUtility getmeetupStatus:event] isEqualToString:SCHMeetupStatusConfirmed]){
            viewBackgroundColor = [SCHUtility greenColor];
            txtBackgroundColor = [UIColor whiteColor];
        } else{
            viewBackgroundColor = [SCHUtility brightOrangeColor];
            txtBackgroundColor = [UIColor whiteColor];

        }
        
    }
    
    cell.backgroundColor = [UIColor whiteColor];
    txtContent.backgroundColor = txtBackgroundColor;
    splitView.backgroundColor = viewBackgroundColor;
    [txtTime setAttributedText:[cellContent valueForKey:@"time"]];
    [txtContent setAttributedText:[cellContent valueForKey:@"content"]];
    
    
    self.rowheight = [SCHUtility tableViewCellHeight:txtContent width:txtContent.bounds.size.width]+1;
    


    return cell;
}

/*

+(NSString *)getmeetupStatus:(id) object{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHMeeting *meeting = nil;
    if ([object isKindOfClass:[SCHEvent class]]){
        SCHEvent *event = (SCHEvent *)object;
        meeting = event.eventObject;
    } else{
        meeting = (SCHMeeting *) object;
    
    }
    NSString *status = nil;
    
    if ([appDelegate.user isEqual:meeting.organizer]){
        status = [NSString localizedStringWithFormat:@"Confirmed"];
    }else{
        NSPredicate *inviteePredicate = [NSPredicate predicateWithFormat:@" user = %@", appDelegate.user];
        NSArray *inviteies = [meeting.invites filteredArrayUsingPredicate:inviteePredicate];
        NSDictionary *invitee = nil;
        
        if (inviteies.count >0){
            invitee = inviteies[0];
        }
        if (invitee){

            if ([[invitee valueForKey:@"accepted"] isEqualToString:SCHMeetupConfirmed]){
                status = [NSString localizedStringWithFormat:@"Confirmed"];
            } else{
                status = [NSString localizedStringWithFormat:@"Respond"];
            }
        }
        
    }
    return status;


}
 */

#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
   if(self.searchController!=NULL)
   {
       [self hideSerchViewController];
   }
    SCHEvent *event;
    if(SelectedCurrentView == SCHScheduleListView)
    {
    event= [[self.scheduledDaysEvents valueForKey:[self.scheduleHeaderFormatter stringFromDate:[self.scheduledEventDays objectAtIndex:indexPath.section]]] objectAtIndex:indexPath.row];
    }else{
        event=[selectedDayEvent objectAtIndex:indexPath.row];
    }
    

    if (event.eventType == SCHAppointmentClass){
        if (![self.objectsForProcessing.objectsForProcessing containsObject:event.eventObject]){
            [self performSegueWithIdentifier:@"appointmentSummerySegue" sender:event];
        }
        
    } else if (event.eventType == SCHMeetingClass){
        
        
        
        [self performSegueWithIdentifier:@"appointmentSummerySegue" sender:event];
        
        
    }else if (event.eventType == SCHAvailabilityClass)
    {
        //Avaliblity
        [self performSegueWithIdentifier:@"appointmentSummerySegue" sender:event];
    }
}

#pragma overriding segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{//appointmentDetailNew
    
    
     self.navigationItem.title = SCHBackkButtonTitle;
     if([segue.identifier isEqualToString:@"appointmentSummerySegue"]){
           
          SCHScheduleSummeryViewController *vcToPushTo = segue.destinationViewController;
         vcToPushTo.recived_data  =(NSObject *)sender;
         
     }
  }

#pragma Methord of Pull To Refresh
-(void)addPullToRefresh{
    
    //to add the UIRefreshControl to UIView
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,0,100)];
    [self.tableView insertSubview:refreshView atIndex:0]; //the tableView is a IBOutlet
    
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
     NSMutableAttributedString *refreshString = [[NSMutableAttributedString alloc] initWithString:@"Pull To Refresh"];
     [refreshString addAttributes:@{NSForegroundColorAttributeName : [UIColor grayColor]} range:NSMakeRange(0, refreshString.length)];
     refreshControl.attributedTitle = refreshString;
    [refreshView addSubview:refreshControl];
    
    [self.tableView addSubview:refreshView];
}

- (void)refresh:(UIRefreshControl *)refreshControl
{
    [SCHUtility showProgressWithMessage:@"Refreshing..."];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.user && appDelegate.serverReachable){
        
        dispatch_async(appDelegate.backgroundManager.SCHSerialQueue, ^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                 [refreshControl endRefreshing];
            });
            [SCHSyncManager syncUserData:_dateSelected];
        });
        
    }
    

   
}

#pragma mark - Property Overrides
-(void)addSearchBar{
    //    AAPLSearchResultsViewController *searchResultsController = [self.storyboard instantiateViewControllerWithIdentifier:AAPLSearchResultsViewControllerStoryboardIdentifier];
    //
    //    // Create the search controller and make it perform the results updating.
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    [self.searchController.view setTintColor:[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor]];
    [self.searchController.searchBar setTintColor:[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor]];
    self.searchController.searchResultsUpdater = nil;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    // Present the view controller.
    [self presentViewController:self.searchController animated:YES completion:nil];
    
}


- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    
    NSString *searchString = searchController.searchBar.text;
    if(![searchString isEqual:@""]){
    NSMutableArray *filteredScheduleEventDays = [[NSMutableArray alloc] init];
    NSMutableDictionary *filteredScheduledEvents = [[NSMutableDictionary alloc] init];
    
    for (NSDate *scheduledEventDay in self.eventManager.scheduledEventDays){

        NSDateFormatter *formatter = [SCHUtility dateFormatterForFullDate];
        NSString *dayKey = [formatter stringFromDate:scheduledEventDay];
        
        NSArray *daysEvents = [self.eventManager.scheduledEvents valueForKey:dayKey];
        
        NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(SCHEvent *event, NSDictionary<NSString *,id> * _Nullable bindings) {
            if ([event.eventObject isKindOfClass:[SCHAvailability class]]){
                NSString *availabilityString = [NSString stringWithFormat:@"%@", [SCHUtility availabilityInfoForScheduleScreen:event]];
                
                
                if ([availabilityString localizedCaseInsensitiveContainsString:searchString]){
                    return  YES;
                } else {
                    return NO;
                }
                
                
            } else if ([event.eventObject isKindOfClass:[SCHAppointment class]]){
                NSString *appointmentContent = [NSString stringWithFormat:@"%@", [SCHUtility appointmentInfoForScheduleScreen:event]];
                if ([appointmentContent localizedCaseInsensitiveContainsString:searchString]){
                    return  YES;
                } else {
                    return NO;
                }
            }else if ([event.eventObject isKindOfClass:[SCHMeetingClass class]]){
                NSString *meetupContent = [NSString stringWithFormat:@"%@", [SCHUtility meetupInfoForScheduleScreen:event]];
                if ([meetupContent localizedCaseInsensitiveContainsString:searchString]){
                    return  YES;
                } else {
                    return NO;
                }
                
                
                
            }else {
                return NO;
            }
            
            }];
        
        
        
        NSArray *filteredDaysEvents = [daysEvents filteredArrayUsingPredicate:filterPredicate];
        if (filteredDaysEvents.count > 0){
            [filteredScheduleEventDays addObject:scheduledEventDay];
            [filteredScheduledEvents setValue:filteredDaysEvents forKey:dayKey];
            
        }
        
        
        
    }
    
    self.scheduledEventDays = filteredScheduleEventDays;
    self.scheduledDaysEvents = filteredScheduledEvents;
    
    
    
    [self reloadSelectedDay];
    [_calendarManager reload];
    [self.tableView reloadData];
        
    }
}



- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    
    self.scheduledDaysEvents = self.eventManager.scheduledEvents;
    self.scheduledEventDays = self.eventManager.scheduledEventDays;
    [self reloadSelectedDay];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_calendarManager reload];
        [self.tableView reloadData];

        
    });
   
}

-(void)hideSerchViewController{
    
    [self.searchController dismissViewControllerAnimated:YES completion:nil];
    self.scheduledDaysEvents = self.eventManager.scheduledEvents;
    self.scheduledEventDays = self.eventManager.scheduledEventDays;
    [self.tableView reloadData];
}

#pragma mark - Apply Filter


-(void)applyFilter{
    
    
    [SCHUtility showProgressWithMessage:@"Applying Filter"];
    
    
    dispatch_barrier_async(self.backgrounfManager.SCHSerialQueue, ^{
        [self.eventManager buildScheduledEvent];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.scheduledDaysEvents = self.eventManager.scheduledEvents;
            self.scheduledEventDays = self.eventManager.scheduledEventDays;
            [self reloadSelectedDay];
            [_calendarManager reload];
            [self.tableView reloadData];

            [SCHUtility completeProgress];
            [self initlizeTodayIndexPath];
           
        });
    });
}


-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - CalendarManager delegate

-(void)reloadSelectedDay{
    
    if(SelectedCurrentView != SCHScheduleListView  && _dateSelected!=nil)
    {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.timeZone = [NSTimeZone systemTimeZone];
    [df setDateFormat:@"yyyy-MM-dd"];
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    //fmt.dateStyle = NSDateIntervalFormatterFullStyle;
    fmt.timeZone = [NSTimeZone systemTimeZone];
    [fmt setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    
    NSString *selectedDate = [df stringFromDate:_dateSelected];
        selectedDayEvent = [[NSMutableArray alloc]init];
    for (int i =0;i<[self.eventManager.scheduledEventDays count];i++)
    {
        NSDate *datecompare =[self.eventManager.scheduledEventDays objectAtIndex:i];
        NSString *eventDate = [df stringFromDate:datecompare];
        if([selectedDate isEqualToString:eventDate])
        {
            selectedDateEvent = [self.scheduleHeaderFormatter stringFromDate:datecompare];
            selectedDayEvent = [NSMutableArray arrayWithArray:[self.scheduledDaysEvents valueForKey:[self.scheduleHeaderFormatter stringFromDate:datecompare]]];
            break;
        }
    }
       
    // Load the previous or next page if touch a day from another month
    
    if(![_calendarManager.dateHelper date:_calendarContentView.date isTheSameMonthThan:_dateSelected]){
        if([_calendarContentView.date compare:_dateSelected] == NSOrderedAscending){
            [_calendarContentView loadNextPageWithAnimation];
        }
        else{
            [_calendarContentView loadPreviousPageWithAnimation];
        }
    }
        
    }
    
}
// Exemple of implementation of prepareDayView method
// Used to customize the appearance of dayView
- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(JTCalendarDayView *)dayView
{
    // Today
    if([_calendarManager.dateHelper date:[NSDate date] isTheSameDayThan:dayView.date]){
        dayView.circleView.hidden = NO;
        dayView.circleView.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
        dayView.dotView.backgroundColor = [UIColor whiteColor];
        dayView.textLabel.textColor = [UIColor whiteColor];
        dayView.textLabel.text = @"Today";
    }
    // Selected date
    else if(_dateSelected && [_calendarManager.dateHelper date:_dateSelected isTheSameDayThan:dayView.date]){
        dayView.circleView.hidden = NO;
        dayView.circleView.backgroundColor = [SCHUtility brightOrangeColor];
        dayView.dotView.backgroundColor = [UIColor whiteColor];
        dayView.textLabel.textColor = [UIColor whiteColor];
    }
    // Other month
    else if(![_calendarManager.dateHelper date:_calendarContentView.date isTheSameMonthThan:dayView.date]){
        dayView.circleView.hidden = YES;
        dayView.dotView.backgroundColor = [SCHUtility brightOrangeColor];
        dayView.textLabel.textColor = [UIColor blackColor];
    }
    // Another day of the current month
    else{
        dayView.circleView.hidden = YES;
        dayView.dotView.backgroundColor = [SCHUtility brightOrangeColor];
        dayView.textLabel.textColor = [UIColor blackColor];
    }
    
    if([self haveEventForDay:dayView.date]){
        dayView.dotView.hidden = NO;
    }
    else{
        dayView.dotView.hidden = YES;
    }
}



- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(JTCalendarDayView *)dayView
{
    _dateSelected = dayView.date;
    
    
    selectedDayEvent = nil;
    //dayEvent =
    // Animation for the circleView
    dayView.circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
    [UIView transitionWithView:dayView
                      duration:.3
                       options:0
                    animations:^{
                        dayView.circleView.transform = CGAffineTransformIdentity;
                        [_calendarManager reload];
                    } completion:nil];
    
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.timeZone = [NSTimeZone systemTimeZone];
    [df setDateFormat:@"yyyy-MM-dd"];
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    //fmt.dateStyle = NSDateIntervalFormatterFullStyle;
    fmt.timeZone = [NSTimeZone systemTimeZone];
    [fmt setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    
    NSString *selectedDate = [df stringFromDate:_dateSelected];
    for (int i =0;i<[self.eventManager.scheduledEventDays count];i++)
    {
        NSDate *datecompare =[self.eventManager.scheduledEventDays objectAtIndex:i];
        NSString *eventDate = [df stringFromDate:datecompare];
        if([selectedDate isEqualToString:eventDate])
        {
            selectedDateEvent = [self.scheduleHeaderFormatter stringFromDate:datecompare];
            selectedDayEvent = [NSMutableArray arrayWithArray:[self.scheduledDaysEvents valueForKey:[self.scheduleHeaderFormatter stringFromDate:datecompare]]];
            break;
        }
    }
      dispatch_async(dispatch_get_main_queue(), ^{
          [self.tableView reloadData];
      });
    
    // Load the previous or next page if touch a day from another month
    
//    if(![_calendarManager.dateHelper date:_calendarContentView.date isTheSameMonthThan:dayView.date]){
//        if([_calendarContentView.date compare:dayView.date] == NSOrderedAscending){
//            [_calendarContentView loadNextPageWithAnimation];
//        }
//        else{
//            [_calendarContentView loadPreviousPageWithAnimation];
//        }
//    }
}

#pragma mark - CalendarManager delegate - Page mangement

// Used to limit the date for the calendar, optional
- (BOOL)calendar:(JTCalendarManager *)calendar canDisplayPageWithDate:(NSDate *)date
{
    [self createMinAndMaxDate];
    return [_calendarManager.dateHelper date:date isEqualOrAfter:_minDate andEqualOrBefore:_maxDate];
}

- (void)calendarDidLoadNextPage:(JTCalendarManager *)calendar
{
    //    NSLog(@"Next page loaded");
}

- (void)calendarDidLoadPreviousPage:(JTCalendarManager *)calendar
{
    //    NSLog(@"Previous page loaded");
}

#pragma mark - Fake data

- (void)createMinAndMaxDate
{
    _todayDate = [NSDate date];
    
    // Min date will be 2 month before today
    _minDate = [_calendarManager.dateHelper addToDate:_todayDate months:-1];
    
    // Max date will be 2 month after today
    _maxDate = [_calendarManager.dateHelper addToDate:_todayDate months:12];
}

// Used only to have a key for _eventsByDate
- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd-MM-yyyy";
    }
    
    return dateFormatter;
}

- (BOOL)haveEventForDay:(NSDate *)date
{
    NSString *key = [self.scheduleHeaderFormatter stringFromDate:date];
    if(self.scheduledDaysEvents[key] && [self.scheduledDaysEvents[key] count] > 0){
        return YES;
    }
    
    return NO;
    
}

-(NSDate *) setCalendarViewDate:(NSDate *) calendarDate{
    
    if (calendarDate){
        return calendarDate;
    } else{
        if (self.scheduledEventDays.count > 0){
            NSDate *calDate = nil;
            SCHConstants *constants = [SCHConstants sharedManager];
            NSCalendar *currentCalendar = [NSCalendar currentCalendar];
            NSCalendarUnit units = NSCalendarUnitYear| NSCalendarUnitMonth| NSCalendarUnitDay;
            NSDateComponents *components = [currentCalendar components:units fromDate:[NSDate date]];
            NSDate *today = [currentCalendar dateFromComponents:components];
            
            
            for (NSDate *eventDay in self.scheduledEventDays){
                if ([eventDay compare:today] != NSOrderedAscending){
                    NSString *selectedDate = [self.scheduleHeaderFormatter stringFromDate:eventDay];
                    NSArray *events = [self.scheduledDaysEvents valueForKey:selectedDate];
                    for (SCHEvent *event in events){
                        if ([event.eventObject isKindOfClass:[SCHAvailability class]]){
                            calDate = eventDay;
                            break;
                        } else if ([event.eventObject isKindOfClass:[SCHAppointment class]]){
                            SCHAppointment *appointment = (SCHAppointment *)event.eventObject;
                            if (!appointment.expired && ![appointment.status isEqual:constants.SCHappointmentStatusCancelled]){
                                calDate = eventDay;
                                break;
                            }
                        } else if ([event.eventObject isKindOfClass:[SCHMeeting class]]){
                            calDate = eventDay;
                            break;
                        }
                        
                    }
                    
                }
                if (calDate){
                    break;
                }
            }
            
            if (!calDate){
                calDate = today;
            }
            return  calDate;
            
        } else{
            if (_dateSelected){
                return _dateSelected;
            } else{
                return [NSDate date];
            }
            
        }
        
    }
    
}

#pragma mark- group Appointment
- (void)createGroupAppointment:(id)sender{
    [self performSegueWithIdentifier:@"groupAppointmentSegue" sender:nil];
}



@end
