//
//  SCHMinorClassificationTableViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/27/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHMinorClassificationTableViewController.h"
#import "AppDelegate.h"
#import "SCHBookDetailViewController.h"
#import "SCHAlert.h"
@interface SCHMinorClassificationTableViewController ()

@end

@implementation SCHMinorClassificationTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    self.tableData = [SCHUtility getServiceClassification:self.majorClassification_obj];
    self.searchResult = [NSMutableArray arrayWithArray:self.tableData];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void)internetConnectionChanged{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.serverReachable){
        [self.navigationController popToRootViewControllerAnimated:YES];
        // [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = self.majorClassification_obj.majorClassification;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
    
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(self.tableData.count == self.searchResult.count)
    {
        return @"";
    }
    return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.searchResult count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    SCHServiceClassification *serviceClassificationObject =  (SCHServiceClassification *)[self.searchResult objectAtIndex:indexPath.row];
    cell.textLabel.text = serviceClassificationObject.serviceTypeName;
    
    
    //Set selection background color
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    [cell setSelectedBackgroundView:bgColorView];
    
    return cell;
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

#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        SCHServiceClassification *selectedObj = [self.searchResult objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ServiceProviderListSegue" sender:selectedObj];
    } else{
        [SCHAlert internetOutageAlert];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    
}


#pragma overriding segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"ServiceProviderListSegue"]){
        SCHBookDetailViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.serviceClassification_obj  = (SCHServiceClassification *)sender;
    }
}




#pragma mark - search bar deligate method
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [self.searchResult removeAllObjects];
    if(searchText.length>0){
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"serviceTypeName contains[c] %@", searchText];
        
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

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchResult = [NSMutableArray arrayWithArray:self.tableData];
}




@end
