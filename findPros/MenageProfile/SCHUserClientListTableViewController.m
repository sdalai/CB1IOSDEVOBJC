//
//  SCHUserClientListTableViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/9/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHUserClientListTableViewController.h"
#import <Parse/Parse.h>
#import "SCHServiceProviderClientList.h"
#import "SCHUtility.h"
#import "SCHScheduleClientDetailViewController.h"
#import "SCHUserClientDetailViewController.h"
#import "SCHClientListViewController.h"
#import <AddressBookUI/AddressBookUI.h>
#import "AppDelegate.h"
#import "MFSideMenu.h"
#import "SCHNewAppointmentBySPViewController.h"
#import "AppDelegate.h"
#import "SCHUser.h"
@interface SCHUserClientListTableViewController () <ABPeoplePickerNavigationControllerDelegate>

@end

@implementation SCHUserClientListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clientList = [[NSMutableArray alloc] init];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    
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
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.menuContainerViewController setPanMode:MFSideMenuPanModeDefault];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.menuContainerViewController setPanMode:MFSideMenuPanModeNone];
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.navigationItem.title = @"Clients";
    [self.clientList removeAllObjects];
    [self.clientList addObjectsFromArray:[SCHUtility GetServiceProviderClientList:appDelegate.user]];
    [self.tableView reloadData];


    if(appDelegate.serverReachable)
    {
        [self.navigationItem setRightBarButtonItem:self.addNewClient animated:YES];
        
    }else {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  100;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.clientList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    static NSString *CellIdentifier = @"ClientCell";
    
    
    if (!cell) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    
    UITextView *txtMessage = (UITextView*)[cell viewWithTag:2];
    UIButton *btnBook = (UIButton*)[cell viewWithTag:3];
    [btnBook addTarget:self action:@selector(goToBookAppointmentWithClient:) forControlEvents:UIControlEventTouchUpInside];

    
    UIImageView *profilePic = (UIImageView*)[cell viewWithTag:1];
    profilePic.layer.masksToBounds = YES;
    profilePic.contentMode = UIViewContentModeScaleAspectFill;
    profilePic.layer.cornerRadius = 6.0;
    profilePic.layer.borderColor = [[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] CGColor];
    profilePic.layer.borderWidth = 3.0;

    
    txtMessage.userInteractionEnabled = false;
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    
    
    NSDictionary *subtittleAttr = @{NSFontAttributeName : [SCHUtility getPreferredSubtitleFont],
                                    NSForegroundColorAttributeName : [SCHUtility deepGrayColor]};
    
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    [txtMessage setEditable:false];
    [txtMessage setSelectable:false];
    
    NSString *name=@"";
    NSString *email=@"";
    NSString *phone=@"";
    
    
    
        SCHServiceProviderClientList *client = (SCHServiceProviderClientList*)[self.clientList objectAtIndex:indexPath.row];
        
        if(client.client){
            SCHUser *user = client.client;
           // NSLog(@" %@", user);
            
            
            name = user.preferredName;
            email = user.email;
            phone =user.phoneNumber;
            
            
            PFFile *imageFile = user.profilePicture;
            [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if(!error){
                    UIImage *profileImage = [UIImage imageWithData:data];
                    profilePic.image  = profileImage;
                }
            }];

            
        }else if(client.nonUserClient){
            name = client.name;
            email = client.nonUserClient.email;
            phone = client.nonUserClient.phoneNumber;
        }
        
    NSMutableAttributedString *detailSubstring = [[NSMutableAttributedString alloc] initWithString:name attributes:titleAttr];
    
    if(email.length > 0){
    [detailSubstring appendAttributedString:newline];
    [detailSubstring appendAttributedString:[[NSAttributedString alloc] initWithString:email attributes:subtittleAttr]];
    
    }
    if (phone.length > 0){
        [detailSubstring appendAttributedString:newline];
        [detailSubstring appendAttributedString:[[NSAttributedString alloc] initWithString:[SCHUtility phoneNumberFormate:phone] attributes:subtittleAttr]];
    }
    
    
    [txtMessage setAttributedText:detailSubstring];
    
    //Set selection background color
    
    /*
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    [cell setSelectedBackgroundView:bgColorView];
    */
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    
        return YES;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCHServiceProviderClientList *client = (SCHServiceProviderClientList*)[self.clientList objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"userClientDetailSegue" sender:client];
}




// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        SCHServiceProviderClientList *client = (SCHServiceProviderClientList*)[self.clientList objectAtIndex:indexPath.row];
        [SCHUtility deleteServiceProviderClient:client];
        [self.clientList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma overriding segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{//appointmentDetailNew
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"userClientDetailSegue"]){
        SCHUserClientDetailViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.client  =(SCHServiceProviderClientList *)sender;
    } else if ([segue.identifier isEqualToString:@"clientToBookAppointment"]){
        SCHNewAppointmentBySPViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.client = (SCHServiceProviderClientList *)sender;
    }
}

-(IBAction)goToBookAppointmentWithClient:(id)sender
{
    UITableViewCell* cell = (UITableViewCell*)[sender superview].superview;
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    SCHServiceProviderClientList *client = (SCHServiceProviderClientList*)[self.clientList objectAtIndex:indexPath.row];
    
    [self performSegueWithIdentifier:@"clientToBookAppointment" sender:client];
    
}

- (IBAction)addNewClient:(id)sender
{
    ABPeoplePickerNavigationController *personPicker = [ABPeoplePickerNavigationController new];
    personPicker.peoplePickerDelegate = self;
    [self presentViewController:personPicker animated:YES completion:nil];
}


@end
