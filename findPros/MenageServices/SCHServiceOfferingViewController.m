//
//  SCHServiceOfferingViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 8/13/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHServiceOfferingViewController.h"
#import "SCHServiceOfferingDetailsViewController.h"
#import "SCHServiceNewOfferingsViewController.h"
#import "SCHUtility.h"
@implementation SCHServiceOfferingViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
   
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title =@"Business Offerings";
    PFQuery *offeringsQuery = [SCHServiceOffering query];
    [offeringsQuery whereKey:@"service" equalTo:self.serviceObject];
    [offeringsQuery fromLocalDatastore];
    
    self.offeringArray = [offeringsQuery findObjects];
    
    [self.tableView reloadData];
   
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.offeringArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"SCHServiceOfferingCell" forIndexPath:indexPath];
        UILabel *lblStatus = (UILabel*)[cell viewWithTag:1];
   
    
    SCHServiceOffering *offeringObject = self.offeringArray[indexPath.row];
    
    [lblStatus setText:offeringObject.serviceOfferingName];
    return cell;
    
}
#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    
    SCHServiceOffering *offeringObject = self.offeringArray[indexPath.row];
    
    [self performSegueWithIdentifier:@"OfferingDetailsSegue" sender:offeringObject];
}

#pragma overriding segue method
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{//appointmentDetailNew
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"OfferingDetailsSegue"]){
        SCHServiceOfferingDetailsViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.serviceObject  =self.serviceObject;
        vcToPushTo.selectedOffering = (SCHServiceOffering *)sender;
    }else if([segue.identifier isEqualToString:@"newOfferingSegue"]){
        SCHServiceNewOfferingsViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.serviceObject  =self.serviceObject;
        vcToPushTo.is_New_From_Service = NO;
        
    }
}




@end
