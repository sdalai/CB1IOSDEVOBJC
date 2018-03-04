//
//  SCHUserServicesTableViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/8/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHUserServicesTableViewController.h"
#import "SCHServiceDatailViewController.h"
#import "SCHService.h"
#import "SCHServiceClassification.h"
#import "AppDelegate.h"
#import "SCHUser.h"
@interface SCHUserServicesTableViewController ()

@end

@implementation SCHUserServicesTableViewController


UIBarButtonItem *addNavButton =nil;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    

           self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    

    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Business Profiles";
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.serverReachable )
    {
        [self.navigationItem setRightBarButtonItem:addNavButton animated:YES];
    }else{
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        
    }

    
    
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // loading services List
    if (!self.doNotnavigateToNewServiceScreen){
        self.doNotnavigateToNewServiceScreen = YES;
        [self performSegueWithIdentifier:@"addNewServiceSegue" sender:self];
        
    }
    
    SCHUser *currentUser = appDelegate.user;
    PFQuery *query =[PFQuery queryWithClassName:@"SCHService"];
    [query whereKey:@"user" equalTo:currentUser];
    [query orderByAscending:@"serviceTitle"];
    
    [query includeKey:@"serviceClassification"];
    [query includeKey:@"serviceClassification.majorClassification"];
    [query fromLocalDatastore];
    [query setLimit:500];
    
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.tableData = objects;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
            
        } 
    }];
    
    PFQuery *serviceCountQuery =[PFQuery queryWithClassName:@"SCHService"];
    [serviceCountQuery whereKey:@"user" equalTo:currentUser];
    [serviceCountQuery whereKey:@"active" equalTo:@YES];
    [serviceCountQuery fromLocalDatastore];
    
    addNavButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewService)];

    if(appDelegate.serverReachable && [serviceCountQuery countObjects] <3){
        self.navigationItem.rightBarButtonItem = addNavButton;
    } else{
        self.navigationItem.rightBarButtonItem = nil;
    }
    

    
    
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  50;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"SCHTextViewCell" forIndexPath:indexPath];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SCHTextViewCell"];
    }
    
    
    SCHService *service = self.tableData[indexPath.row];
    cell.textLabel.text = service.serviceTitle;
    if(service.serviceClassification.serviceTypeName)
    cell.detailTextLabel.text = service.serviceClassification.serviceTypeName;
    [cell.detailTextLabel setTextColor:[SCHUtility deepGrayColor]];
    
    
    //Set selection background color
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    [cell setSelectedBackgroundView:bgColorView];
    
    
    return cell;
    

}
- (void)addNewService {
    [self performSegueWithIdentifier:@"addNewServiceSegue" sender:nil];
}


#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    SCHService *service = self.tableData[indexPath.row];
    [self performSegueWithIdentifier:@"ServiceDerailSegue" sender:service];
    
    
}

#pragma overriding segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{//appointmentDetailNew
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"ServiceDerailSegue"]){
        SCHServiceDatailViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.serviceObject  =(SCHService *)sender;
    }
}





/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
