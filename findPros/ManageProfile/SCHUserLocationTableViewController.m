//
//  SCHUserLocationTableViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/5/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHUserLocationTableViewController.h"
#import "AppDelegate.h"
#import "MFSideMenu.h"
#import "SCHUser.h"
@interface SCHUserLocationTableViewController ()
@property CGFloat rowheight;

@end

@implementation SCHUserLocationTableViewController

SPGooglePlacesAutocompleteDemoViewController *mapViewController;
NSArray *userPreviousLocations;
NSString *selectedLocation;
UIBarButtonItem *addUerLocationButton;
//- (id)init
//{
//    self = [super initWithStyle:UITableViewStyleGrouped];
//    if (self != nil) {
//        // Initialisation code
//    }
//    return self;
//}
- (void)viewDidLoad {
    [super viewDidLoad];
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.userAddress = [[NSMutableArray alloc]init];
    self.title = @"Locations";
   userPreviousLocations = [SCHUtility getUserLocations:appDelegate.user];
    
    
    addUerLocationButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(userLocationToMapViewController)];
    self.navigationItem.rightBarButtonItem = addUerLocationButton;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

}

-(void)internetConnectionChanged{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (self.view.window){
        [self viewWillAppear:YES];
    } else{
        if (!appDelegate.serverReachable){
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
        
    }
    
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.menuContainerViewController setPanMode:MFSideMenuPanModeDefault];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.menuContainerViewController setPanMode:MFSideMenuPanModeNone];
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    

    if(appDelegate.serverReachable)
    {
        [self.navigationItem setRightBarButtonItem:addUerLocationButton animated:YES];
        
    }else {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        
    }

    

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHUser *user = appDelegate.user;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.userAddress removeAllObjects];
        [self.userAddress addObjectsFromArray:[self userLocations:user]];
        if(self.userAddress.count==0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIView *footrView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0,self.tableView.frame.size.width , 44)];
                UILabel *lbl = [[UILabel alloc]initWithFrame:CGRectMake(0, 0,footrView.frame.size.width , 40)];
                [lbl setText:@"No Location Exists"];
                [lbl setTextAlignment:NSTextAlignmentCenter];
                [lbl setTextColor:[SCHUtility deepGrayColor]];
                [lbl setFont:[SCHUtility getPreferredTitleFont]];
                [footrView addSubview:lbl];
                self.tableView.tableFooterView =footrView;
            });
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
    });
    

}


-(void)userLocationToMapViewController
{
    mapViewController = [[SPGooglePlacesAutocompleteDemoViewController alloc]init];
    mapViewController.isFromUserLocation = true;
    [self.navigationController pushViewController:mapViewController animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return self.rowheight+15;
    
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.userAddress.count;
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
    
    // set support Text
    NSMutableAttributedString *locationString = [[NSMutableAttributedString alloc] init];;
    UIFont *titlefont = [SCHUtility getPreferredTitleFont];
    NSDictionary *titleAttr = @{NSFontAttributeName: titlefont,
                                NSForegroundColorAttributeName: [SCHUtility deepGrayColor]};
    [locationString appendAttributedString:[[NSAttributedString alloc] initWithString:location attributes:titleAttr]];
    
    UITextView *txLocation = (UITextView*)[cell viewWithTag:1];
    [txLocation setAttributedText:locationString];
    
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    self.rowheight = [SCHUtility tableViewCellHeight:txLocation width:txLocation.bounds.size.width];
    
    //Set selection background color
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    [cell setSelectedBackgroundView:bgColorView];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCHUserLocation *userLocation = (SCHUserLocation*)[self.userAddress objectAtIndex:indexPath.row];
    selectedLocation = userLocation.location;
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:SCHAppName
                                                          message:@"You will be redirected to Navigation app.\n Do you want to continue ?"
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"Continue", nil];
        [message show];
        
       
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
   // [self openMapWithAddress:userLocation.location];
    
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        [self openMapWithAddress:selectedLocation];
        
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        SCHUserLocation *userLocation = (SCHUserLocation*)[self.userAddress objectAtIndex:indexPath.row];
        [SCHUtility deleteUserLocation:userLocation];
        [self.userAddress removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}











-(void) openMapWithAddress:(NSString*)address
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
          //  NSLog(@"%@", error);
        } else {
            
            CLPlacemark* placemark = [placemarks lastObject];
            
            MKPlacemark *endLocation = [[MKPlacemark alloc] initWithCoordinate:placemark.location.coordinate addressDictionary:nil];
            MKMapItem *endingItem = [[MKMapItem alloc] initWithPlacemark:endLocation];
            
            NSMutableDictionary *launchOptions = [[NSMutableDictionary alloc] init];
            [launchOptions setObject:MKLaunchOptionsDirectionsModeDriving forKey:MKLaunchOptionsDirectionsModeKey];
            
            [endingItem openInMapsWithLaunchOptions:launchOptions];
        }
    }];
    
    
    
}

-(NSArray *)userLocations:(SCHUser *) user{
    PFQuery *userLocationQuery = [SCHUserLocation query];
    //[userLocationQuery whereKey:@"user" equalTo:user.objectId];
    [userLocationQuery fromLocalDatastore];
    
    NSArray *userLocations = [userLocationQuery findObjects];
    
    
    return userLocations;
    
}



/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
