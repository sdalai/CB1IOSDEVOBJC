//
//  SCHServiceProviderAvailabilityViewController.m
//  findPros
//
//  Created by Pratap Yadav on 7/8/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHServiceProviderAvailabilityViewController.h"
#import "SCHEvent.h"
#import "SCHAvailabilityForAppointmentManager.h"
#import "SCHScheduleSummeryViewController.h"
#import "SCHServiceProviderViewController.h"
#import "SCHEditAppointmentViewController.h"
#import "SCHNewAppointmentBySPViewController.h"
#import "SCHBookDetailViewController.h"
#import "SCHUser.h"
#import "AppDelegate.h"



@implementation SCHServiceProviderAvailabilityViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    self.rowheight = 100.00;
    
    self.scheduleHeaderFormatter = [SCHUtility dateFormatterForFullDate];
    self.scheduleTimeFormatter = [SCHUtility dateFormatterForToTime];
    self.constants = [SCHConstants sharedManager];
    
    //Initiliaze background queue
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //NSLog(@"%@", self.CurrentAppointment);
    if (!self.CurrentAppointment){
        self.CurrentAppointment = nil;
    }
    
    
    
}

-(void)internetConnectionChanged{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.serverReachable){
        [self.navigationController popToRootViewControllerAnimated:YES];
        // [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
}


-(NSIndexPath *)initlizeAppointmentDaysIndexPathWithAppointmentWithAvailabilityScheduleDays:(NSArray *) availabilityScheduleDays{
    NSIndexPath *appointDayIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSSortDescriptor *availabilityDaysAsc = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    NSArray *sortedAvailabilitiesDays = [availabilityScheduleDays sortedArrayUsingDescriptors:@[availabilityDaysAsc]];
    NSDate *appointmentDate = nil;
    //[availabilityScheduleDays ]
    
    if (self.CurrentAppointment){
        appointmentDate = self.CurrentAppointment.proposedStartTime ? self.CurrentAppointment.proposedStartTime : self.CurrentAppointment.startTime;
    } else{
        appointmentDate = [NSDate date];
    }
    
    
    
    NSString *appointment_date = [self.scheduleHeaderFormatter stringFromDate:appointmentDate];
    
    for (int i =0;i<[sortedAvailabilitiesDays count];i++)
    {
        
        NSDate *datecompare =[availabilityScheduleDays objectAtIndex:i];
        
        NSString *dateCompareDate = [self.scheduleHeaderFormatter stringFromDate:datecompare];
        
        
        
        if([dateCompareDate isEqualToString:appointment_date])
        {
            appointDayIndexPath = [NSIndexPath indexPathForRow:0 inSection:i];
            break;
        }
    }
    
    
    return appointDayIndexPath;
    
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SCHUser *serviceProvider = self.selectedServiceProvider.user;
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@'s Availability", serviceProvider.preferredName];
    
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    dispatch_queue_t backgroundQueue = [SCHBackgroundManager sharedManager].SCHSerialQueue;
    dispatch_barrier_async(backgroundQueue, ^{
        if ([self userHasAccessToAvailability:appDelegate.user service:self.selectedServiceProvider]){
            self.avaliblityDict =[SCHAvailabilityForAppointmentManager availabilityForAppointment:self.selectedServiceProvider.user service:self.selectedServiceProvider appointment:self.CurrentAppointment];
            
            
            self.availabilityDays = [self.avaliblityDict valueForKey:@"availabilityDays"];
            self.availabilities = (NSDictionary*)[self.avaliblityDict valueForKey:@"availabilities"];
            
            if (self.availabilityDays.count > 0){
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    
                    
                    // [self.tableView reloadData];
                    
                    if (self.CurrentAppointment){
                        NSIndexPath *appointmentDayIndexPath = [self initlizeAppointmentDaysIndexPathWithAppointmentWithAvailabilityScheduleDays:self.availabilityDays];
                        
                        
                        
                        [self.tableView reloadData];
                        
                        
                        [self.tableView scrollToRowAtIndexPath:appointmentDayIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                        
                        
                    } else{
                        [self.tableView reloadData];
                    }
                    
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *alertMessage= [NSString stringWithFormat:@"%@ does not have schedules published. Please check later.", self.selectedServiceProvider.user.preferredName];
                    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"No Availability!"
                                                                       message:alertMessage
                                                                      delegate:self
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                    [theAlert show];
                    [self.navigationController popViewControllerAnimated:YES];
                });
                
            }
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *alertMessage= [NSString stringWithFormat:@"Please call or email %@ ", self.selectedServiceProvider.user.preferredName];
                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                   message:alertMessage
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [theAlert show];
                [self.navigationController popViewControllerAnimated:YES];
            });
            
        }
        
        
        
        
    });
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.title =@"";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self.availabilityDays!=nil)
        return [self.availabilityDays count];
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [self.scheduleHeaderFormatter stringFromDate:[self.availabilityDays objectAtIndex:section]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.availabilityDays !=nil){
        NSString *selectedDate = [self.scheduleHeaderFormatter stringFromDate:[self.availabilityDays objectAtIndex:section]];
        
        NSArray * array =[self.availabilities valueForKey:selectedDate];
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
    
    /*
     SCHEvent *event;
     event = [[self.availabilities valueForKey:[self.scheduleHeaderFormatter stringFromDate:[self.availabilityDays objectAtIndex:indexPath.section]]] objectAtIndex:indexPath.row];
     
     NSDictionary * cellContent = [SCHUtility availabilityInfoForScheduleScreen:event];
     UITextView * txtContent = [UITextView new];
     [txtContent setAttributedText:[cellContent valueForKey:@"content"]];
     CGRect screenRect = [[UIScreen mainScreen] bounds];
     CGFloat screenWidth = screenRect.size.width;
     //determine width
     
     float rowheight = [SCHUtility tableViewCellHeight:txtContent width:<#(CGFloat)#>] +1;
     
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
    
    
    event = [[self.availabilities valueForKey:[self.scheduleHeaderFormatter stringFromDate:[self.availabilityDays objectAtIndex:indexPath.section]]] objectAtIndex:indexPath.row];
    
    
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
    
    
    NSArray *avaliblityArray =  [self.availabilities valueForKey:[self.scheduleHeaderFormatter stringFromDate:[self.availabilityDays objectAtIndex:indexPath.section]]];
    SCHEvent *event = (SCHEvent *)[avaliblityArray objectAtIndex:indexPath.row];
    if([self.parent isKindOfClass:[SCHServiceProviderViewController class]] || [self.parent isKindOfClass:[SCHBookDetailViewController class]]){
        if (event.eventType == SCHAppointmentClass){
            
            [self performSegueWithIdentifier:@"appointmentSummerySegue" sender:event];
            
        }else if (event.eventType == SCHAvailabilityClass)
        {
            
            [self performSegueWithIdentifier:@"newAppointmentByClientSegue" sender:[avaliblityArray objectAtIndex:indexPath.row]];
        }
    }else if([self.parent isKindOfClass:[SCHNewAppointmentBySPViewController class]]){
        NSDate *from_time = nil;
        if (event.eventType == SCHAvailabilityClass)
        {
            
            SCHAvailabilityForAppointment * obj = [avaliblityArray objectAtIndex:indexPath.row];
            from_time= obj.startTime;
        }else{
            from_time = event.startTime;
        }
        
        SCHNewAppointmentBySPViewController *newAppointmentViewController = (SCHNewAppointmentBySPViewController *)self.parent;
        newAppointmentViewController.startTime = from_time;
        //    newAppointmentViewController.rowStartTime.value = from_time;
        //   [newAppointmentViewController changeScheduleTimeToAvaliableSchedule:from_time];
        [newAppointmentViewController changeScheduleTimeToAvaliableSchedule:from_time location:event.location];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        NSDate *from_time = [NSDate new];
        SCHAvailabilityForAppointment * obj = nil;
        
        if (event.eventType == SCHAvailabilityClass)
        {
            
            obj = [avaliblityArray objectAtIndex:indexPath.row];
            
            
            from_time= obj.startTime;
        }else{
            from_time = event.startTime;
        }
        
        SCHEditAppointmentViewController *editeView = (SCHEditAppointmentViewController *)self.parent;
        editeView.selectedAvailabilityForAppointment = obj;
        [editeView resetWhenNewAvailabilityIsSelected];
        // [editeView changeScheduleTimeToAvaliableSchedule:from_time];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(BOOL) userHasAccessToAvailability:(SCHUser *)user service:(SCHService *) service{
    BOOL userHasAccess = YES;
    SCHConstants *constants  = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([service.availabilityVisibilityControl isEqual:constants.SCHPrivacyOptionPublic]|| !service.availabilityVisibilityControl||[service.user isEqual:user]){
        userHasAccess = YES;
    } else if ([service.availabilityVisibilityControl isEqual:constants.SCHPrivacyOptionClient]){
        PFQuery *ClientListsQuery = [SCHServiceProviderClientList query];
        [ClientListsQuery whereKey:@"serviceProvider" equalTo:service.user];
        [ClientListsQuery whereKey:@"client" equalTo:appDelegate.user];
        
        int clientlistCount = (int)[ClientListsQuery countObjects];
        
        if (clientlistCount> 0){
            userHasAccess = YES;
        } else userHasAccess = NO;
        
    } else userHasAccess = YES;
    
    return userHasAccess;
}
#pragma overriding segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"appointmentSummerySegue"]){
        
        SCHScheduleSummeryViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.recived_data  =sender;
        
    }else if([segue.identifier isEqualToString:@"newAppointmentByClientSegue"]){
        SCHNewAppointmentByClientViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.selectedServiceProvider  = self.selectedServiceProvider;
        vcToPushTo.selectedAvailability = (SCHAvailabilityForAppointment*)sender;
        
    }
}

@end
