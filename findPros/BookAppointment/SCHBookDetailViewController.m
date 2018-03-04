//
//  SCHBookDetailViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 7/7/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHBookDetailViewController.h"
#import "SCHBackgroundManager.h"
#import "AppDelegate.h"
#import "SCHServiceProviderAvailabilityViewController.h"
#import "SCHUser.h"
@implementation SCHBookDetailViewController
UIRefreshControl *refreshControl;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    self.title = self.serviceClassification_obj.serviceTypeName;
     self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

}

-(void)internetConnectionChanged{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.serverReachable){
        [self.navigationController popToRootViewControllerAnimated:YES];
        // [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
}


-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title=self.serviceClassification_obj.serviceTypeName;;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    dispatch_queue_t backgroundQueue =  [SCHBackgroundManager sharedManager].SCHSerialQueue;
    dispatch_async(backgroundQueue, ^{
        
        if(self.serviceClassification_obj!=nil)
        {
            self.tableData = [SCHUtility ServiceProviderListForService:self.serviceClassification_obj];
        }else{
            self.tableData = [SCHUtility userFevotiteServices:appDelegate.user];
        }
        self.searchResult = [NSMutableArray arrayWithArray:self.tableData];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            if(self.tableData.count==0 )
            {
                UIView *footrView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0,self.tableView.frame.size.width , 44)];
                UILabel *lbl = [[UILabel alloc]initWithFrame:CGRectMake(0, 0,footrView.frame.size.width , 40)];
                if(self.serviceClassification_obj==nil)
                    [lbl setText:@"No Favorites"];
                else
                  [lbl setText:@"No Service Provider"];
                [lbl setTextAlignment:NSTextAlignmentCenter];
                [lbl setTextColor:[SCHUtility deepGrayColor]];
                [lbl setFont:[SCHUtility getPreferredTitleFont]];
                [footrView addSubview:lbl];
                self.tableView.tableFooterView =footrView;
            }
            
            [self.tableView reloadData];
            
        });
    });
    [self addPullToRefresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.searchResult!=NULL)
    return [self.searchResult count];
    else
        return 0;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   // static NSString *CellIdentifier = @"Cell";
     UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"serviceProviderProfileCell" forIndexPath:indexPath];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"serviceProviderProfileCell"];
    }
    
   // cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    SCHService *serviceObject =  (SCHService *)[self.searchResult objectAtIndex:indexPath.row];
    UITextView *txtServiceProviderDetail = (UITextView*)[cell viewWithTag:2];
    [txtServiceProviderDetail setAttributedText:[self serviceProviderSummaryInfo:serviceObject]];
    
    UIButton *btnBook = (UIButton*)[cell viewWithTag:3];
    [btnBook addTarget:self action:@selector(goToServiceProviderAvaliblity:) forControlEvents:UIControlEventTouchUpInside];

   // [btnBook addTarget:self action:@selector(goToServiceProviderAvaliblity)];
              
//    UILabel *name = (UILabel*)[cell viewWithTag:2];
//    UILabel *serviceName = (UILabel*)[cell viewWithTag:3];
    
    

    
    
     
//    serviceName.text = serviceObject.serviceTitle;
    UIImageView *profilePic = (UIImageView*)[cell viewWithTag:1];
    profilePic.layer.masksToBounds = YES;
    profilePic.contentMode = UIViewContentModeScaleAspectFill;
    profilePic.layer.cornerRadius = 6.0;
    profilePic.layer.borderColor = [[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] CGColor];
    profilePic.layer.borderWidth = 3.0;

    PFFile *imageFile = serviceObject.profilePicture;
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if(!error){
            UIImage *profileImage = [UIImage imageWithData:data];
            profilePic.image  = profileImage;
        }
    }];
   
    //Set selection background color
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    [cell setSelectedBackgroundView:bgColorView];
    
    
    return cell;
}

/*
 self.navigationItem.title = SCHBackkButtonTitle;
 if([segue.identifier isEqualToString:@"ServiceProviderAvailabilitySegue"]){
 SCHServiceProviderAvailabilityViewController *vcToPushTo = segue.destinationViewController;
 vcToPushTo.selectedServiceProvider  = (SCHService *)self.selectedServiceProvider;
 vcToPushTo.parent = self;
 }
 */
 
-(void)goToServiceProviderAvaliblity:(UIButton*)sender
{
    //ServiceProviderAvailabilitySegue
    UITableViewCell* cell = (UITableViewCell*)[sender superview].superview;
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    
    SCHService *selectedObj = [self.searchResult objectAtIndex:indexPath.row];

    [self performSegueWithIdentifier:@"ServiceProviderAvailabilitySegue" sender:selectedObj];
    
    
   // NSLog(@"go to Service Provider Avaliblity");
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"ServiceProviderAvailabilitySegue"]){
        
        SCHServiceProviderAvailabilityViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.selectedServiceProvider  = (SCHService *)sender;
        vcToPushTo.parent = self;
    }
    else if([segue.identifier isEqualToString:@"serviceProvicerDetailSegue"]){
        SCHServiceProviderViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.selectedServiceProvider  = (SCHService *)sender;
    }
}


#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        SCHService *selectedObj = [self.searchResult objectAtIndex:indexPath.row];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [self performSegueWithIdentifier:@"serviceProvicerDetailSegue" sender:selectedObj];
        
    } else{
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                           message:@"Please connect to internet."
                                                          delegate:self
                                                  cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
    }
}





#pragma mark - search bar deligate method
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [self.searchResult removeAllObjects];
    if(searchText.length>0){
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"serviceTitle contains[c] %@", searchText];
        
        self.searchResult = [NSMutableArray arrayWithArray: [self.tableData filteredArrayUsingPredicate:resultPredicate]];
    }else{
        self.searchResult = [NSMutableArray arrayWithArray:self.tableData];
    }
    
}

-(BOOL)searchDisplayController:(UISearchController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:[[controller.searchBar scopeButtonTitles] objectAtIndex:[controller.searchBar selectedScopeButtonIndex]]];
    return YES;
}


#pragma Methord of Pull To Refresh
-(void)addPullToRefresh{
    //to add the UIRefreshControl to UIView
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 0, 0)];
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
    dispatch_queue_t backgroundQueue =  [SCHBackgroundManager sharedManager].SCHSerialQueue;
    dispatch_async(backgroundQueue, ^{
        
        // Perform long running process
        self.tableData = [SCHUtility ServiceProviderListForService:self.serviceClassification_obj];
        self.searchResult = [NSMutableArray arrayWithArray:self.tableData];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            [self.tableView reloadData];
            
        });
    });

    
    [refreshControl endRefreshing];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchResult = [NSMutableArray arrayWithArray:self.tableData];
}

-(NSAttributedString *)serviceProviderSummaryInfo:(SCHService *)service{
    NSMutableAttributedString *message = [[NSMutableAttributedString alloc] init];
    NSString *nextLine = @"\n";
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    NSDictionary *subTitleAttr = @{NSFontAttributeName : [SCHUtility getPreferredSubtitleFont],
                                   NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    NSDictionary *organgeSubTitleAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                                   NSForegroundColorAttributeName :[SCHUtility brightOrangeColor]};
    
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"%@", service.user.preferredName]  attributes:titleAttr]];
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"%@", service.serviceTitle]  attributes:subTitleAttr]];
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    if (service.standardCharge > 0){
        [message appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"$%d", service.standardCharge]  attributes:organgeSubTitleAttr]];
    } else{
        [message appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Free"]  attributes:organgeSubTitleAttr]];
    }
    
    
    
    return message;
}



@end
