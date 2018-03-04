//
//  SCHUserAppointmentHistory.m
//  CounterBean
//
//  Created by Pratap Yadav on 26/05/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHUserAppointmentHistory.h"
#import "AppDelegate.h"
#import "SCHUtility.h"

@interface SCHUserAppointmentHistory ()
@property (nonatomic, strong) UISearchController *searchController;

@end
@implementation SCHUserAppointmentHistory

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc]
                                     
                                     
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                     
                                     
                                     target:self action:@selector(addSearchBar)];
    self.navigationItem.rightBarButtonItem = searchButton;
    
    self.scheduleHeaderFormatter = [SCHUtility dateFormatterForFullDate];
    self.scheduleTimeFormatter = [SCHUtility dateFormatterForToTime];
    self.constants = [SCHConstants sharedManager];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [SCHUtility showProgressWithMessage:@"Loading..."];
    dispatch_queue_t backgroundQueue = [SCHBackgroundManager sharedManager].SCHconcurrentQueue;
    dispatch_barrier_async(backgroundQueue, ^{
        
        /*
        if (self.serviceProvider){
            self.historyData = [SCHUtility getAppointmentHistoryForUser:nil serviceProvider:self.serviceProvider service:nil];
        } else if (self.service){
            self.historyData = [SCHUtility getAppointmentHistoryForUser:nil serviceProvider:nil service:self.service];
        } else{
            self.historyData = [SCHUtility getAppointmentHistoryForUser:appDelegate.user serviceProvider:nil service:nil];
        }
        */
        self.historyData = [SCHUtility getAppointmentHistoryForUser:self.user serviceProvider:self.serviceProvider service:nil];
        
        self.appointmentDays = [self.historyData valueForKey:@"eventDays"];
        self.appointmentDict = (NSDictionary*)[self.historyData valueForKey:@"appointments"];
        
        dispatch_async (dispatch_get_main_queue(), ^{
            
            if(self.appointmentDays.count==0 )
            {
                UIView *footrView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0,self.tableView.frame.size.width , 44)];
                UILabel *lbl = [[UILabel alloc]initWithFrame:CGRectMake(0, 0,footrView.frame.size.width , 40)];
                [lbl setText:@"No Recent Appointment"];
                [lbl setTextAlignment:NSTextAlignmentCenter];
                [lbl setTextColor:[SCHUtility deepGrayColor]];
                [lbl setFont:[SCHUtility getPreferredTitleFont]];
                [footrView addSubview:lbl];
                self.tableView.tableFooterView =footrView;
            }
            
            [self.tableView reloadData];
            [SCHUtility completeProgress];
        });
        
        
    });

}

-(void)internetConnectionChanged{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.serverReachable){
        [self.navigationController popToRootViewControllerAnimated:YES];
        // [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"Appointment History";
}



-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    }


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.title =@"";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self.appointmentDays!=nil)
        return [self.appointmentDays count];
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [self.scheduleHeaderFormatter stringFromDate:[self.appointmentDays objectAtIndex:section]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.appointmentDays !=nil){
        NSString *selectedDate = [self.scheduleHeaderFormatter stringFromDate:[self.appointmentDays objectAtIndex:section]];
        
        NSArray * array =[self.appointmentDict valueForKey:selectedDate];
        if(array==nil)
        {
            return 0;
        }
        NSInteger rowcount = [array count];
        return rowcount;
    }
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   /* SCHEvent *event;
    event = [[self.appointmentDict valueForKey:[self.scheduleHeaderFormatter stringFromDate:[self.appointmentDays objectAtIndex:indexPath.section]]] objectAtIndex:indexPath.row];
    
    NSDictionary * cellContent = [SCHUtility appointmentInfoForScheduleScreen:event];
    UITextView * txtContent = [UITextView new];
    [txtContent setAttributedText:[cellContent valueForKey:@"content"]];
    float rowheight = [SCHUtility tableViewCellHeight:txtContent] +1;
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
    [header.textLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    
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
    
    
    event = [[self.appointmentDict valueForKey:[self.scheduleHeaderFormatter stringFromDate:[self.appointmentDays objectAtIndex:indexPath.section]]] objectAtIndex:indexPath.row];
    
    
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
        
    }
    cell.backgroundColor = [UIColor whiteColor];
    txtContent.backgroundColor = txtBackgroundColor;
    splitView.backgroundColor = viewBackgroundColor;
    [txtTime setAttributedText:[cellContent valueForKey:@"time"]];
    [txtContent setAttributedText:[cellContent valueForKey:@"content"]];
    self.rowheight = [SCHUtility tableViewCellHeight:txtContent width:txtContent.bounds.size.width] +10;
    
    return cell;
    
}
#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.searchController!=NULL)
    {
        [self hideSerchViewController];
    }

    
    NSArray *avaliblityArray =  [self.appointmentDict valueForKey:[self.scheduleHeaderFormatter stringFromDate:[self.appointmentDays objectAtIndex:indexPath.section]]];
    SCHEvent *event = (SCHEvent *)[avaliblityArray objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"appointmentHistoryDetailSegue" sender:event];
    
}

#pragma overriding segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"appointmentHistoryDetailSegue"]){
        
        SCHScheduleSummeryViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.recived_data  =sender;
        
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
        

        
        NSArray *appointmentHistoryDays = [self.historyData valueForKey:@"eventDays"];
        NSDictionary *appointmentHistoryDict = (NSDictionary*)[self.historyData valueForKey:@"appointments"];
        
        
        
        for (NSDate *scheduledEventDay in appointmentHistoryDays){
            
            NSDateFormatter *formatter = [SCHUtility dateFormatterForFullDate];
            NSString *dayKey = [formatter stringFromDate:scheduledEventDay];
            
            NSArray *daysEvents = [appointmentHistoryDict valueForKey:dayKey];
            
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
                } else {
                    return NO;
                }
                
            }];
            
            
            
            NSArray *filteredDaysEvents = [daysEvents filteredArrayUsingPredicate:filterPredicate];
            if (filteredDaysEvents.count > 0){
                [filteredScheduleEventDays addObject:scheduledEventDay];
                [filteredScheduledEvents setValue:filteredDaysEvents forKey:dayKey];
                
            }
            
            
            
        }
        
        self.appointmentDays = filteredScheduleEventDays;
        self.appointmentDict = filteredScheduledEvents;
        
        

        [self.tableView reloadData];
        
    }
}



- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    
    self.appointmentDays = [self.historyData valueForKey:@"eventDays"];
    self.appointmentDict = (NSDictionary*)[self.historyData valueForKey:@"appointments"];

    dispatch_async(dispatch_get_main_queue(), ^{

        [self.tableView reloadData];
        
        
    });
    
}

-(void)hideSerchViewController{
    
    [self.searchController dismissViewControllerAnimated:YES completion:nil];
    self.appointmentDays = [self.historyData valueForKey:@"eventDays"];
    self.appointmentDict = (NSDictionary*)[self.historyData valueForKey:@"appointments"];
    [self.tableView reloadData];
}




@end
