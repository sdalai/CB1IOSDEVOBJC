//
//  SCHLocationSelectorViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 9/28/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHLocationSelectorViewController.h"
#import "SCHUtility.h"
#import "SCHUserLocation.h"
#import "SCHEditAppointmentViewController.h"
#import "SCHUser.h"
#import "AppDelegate.h"
@interface SCHLocationSelectorViewController ()

@end

@implementation SCHLocationSelectorViewController
@synthesize rowDescriptor = _rowDescriptor;
SPGooglePlacesAutocompleteDemoViewController *mapViewController;
NSMutableArray *userPreviousLocations;
- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self != nil) {
        // Initialisation code
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.userAddress = [[NSMutableArray alloc]init];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.title = @"Locations";
    
    NSArray *viewcontrollers = self.navigationController.viewControllers;
    
    int parentVCIndex = ((int)viewcontrollers.count -2);
    
    id parentVC = viewcontrollers[parentVCIndex];
    
    if ([parentVC isKindOfClass:[SCHEditAppointmentViewController class]]){
        SCHEditAppointmentViewController *parent = parentVC;
        self.appointment = parent.appointment;
    }
    
    
    
    
    
     userPreviousLocations =[[NSMutableArray alloc] initWithArray:[SCHUtility getUserLocations:appDelegate.user]];
    
    
    
   
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    if(mapViewController!=NULL)
//    {
//     [self.navigationController popViewControllerAnimated:YES];   
//    }
    [self.userAddress removeAllObjects];
    
    if(self.rowDescriptor.value){
       self.selectedAddress = (NSString*)[self.rowDescriptor.value valueForKey:@"address"];
        SCHUserLocation *userLocation = [[SCHUserLocation alloc]init];
        [userLocation setUser:appDelegate.user];
        [userLocation setLocation:self.selectedAddress];
        
        bool isExist=false;
        for(int i=0 ;i<userPreviousLocations.count;i++)
        {
            SCHUserLocation *userLocation = (SCHUserLocation*)[userPreviousLocations objectAtIndex:i];

            if([userLocation.location isEqualToString:self.selectedAddress])
            {
                isExist = true;
            }
        }
        if(!isExist)
        {
            
            [userPreviousLocations addObject:userLocation];
            
        }
    }
    
    if (self.appointment.location){
        
        SCHUserLocation *userLocation = [[SCHUserLocation alloc]init];
        [userLocation setUser:appDelegate.user];
        [userLocation setLocation:self.appointment.location];
        bool isExist=false;
        for(int i=0 ;i<userPreviousLocations.count;i++)
        {
            SCHUserLocation *userLocation = (SCHUserLocation*)[userPreviousLocations objectAtIndex:i];
            
            if([userLocation.location isEqualToString:self.appointment.location])
            {
                isExist = true;
            }
        }
        if(!isExist)
        {
            
            [userPreviousLocations addObject:userLocation];
            
        }
    }
    if (self.appointment.proposedLocation){
        
        SCHUserLocation *userLocation = [[SCHUserLocation alloc]init];
        [userLocation setUser:appDelegate.user];
        [userLocation setLocation:self.appointment.location];
        bool isExist=false;
        for(int i=0 ;i<userPreviousLocations.count;i++)
        {
            SCHUserLocation *userLocation = (SCHUserLocation*)[userPreviousLocations objectAtIndex:i];
            
            if([userLocation.location isEqualToString:self.appointment.proposedLocation])
            {
                isExist = true;
            }
        }
        if(!isExist)
        {
            
            [userPreviousLocations addObject:userLocation];
            
        }
    }

    
    

        [self.userAddress addObjectsFromArray:userPreviousLocations];
    
    //cleanup empty location string
    
    
    
    [self.tableView reloadData];
    
    UIBarButtonItem *addLocButton = [[UIBarButtonItem alloc]
                                  
                                  
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                  
                                  
                                  target:self action:@selector(goToMapViewController)];
    
    
    
    
    
    self.navigationItem.rightBarButtonItem = addLocButton;
    

}


-(void)goToMapViewController
{
    mapViewController = [[SPGooglePlacesAutocompleteDemoViewController alloc]init];
    if(!self.isUserLocation)
    mapViewController.XLFormdelegate = self;
    [self.navigationController pushViewController:mapViewController animated:YES];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.userAddress.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    return nil;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"locationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSString *location=NULL;
    
    SCHUserLocation *userLocation = (SCHUserLocation*)[self.userAddress objectAtIndex:indexPath.row];
        location = userLocation.location;
        if([self.selectedAddress isEqualToString:userLocation.location])
        {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            
        }else{
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
        
    
    [cell.textLabel setText:location];
    
    
    return cell;
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        SCHUserLocation *userLocation = (SCHUserLocation*)[self.userAddress objectAtIndex:indexPath.row];
        [self.rowDescriptor setValue:@{@"address": userLocation.location  }];
        [self.navigationController popViewControllerAnimated:YES];
}


/*
#pragma mark - Navigation
*/
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
