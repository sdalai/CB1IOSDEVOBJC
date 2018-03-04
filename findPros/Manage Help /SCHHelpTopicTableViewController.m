//
//  SCHHelpTopicTableViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/5/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHHelpTopicTableViewController.h"
#import "SCHUtility.h"
@interface SCHHelpTopicTableViewController ()

@end

@implementation SCHHelpTopicTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    UIFont *titlefont = [SCHUtility getPreferredBodyFont];
    NSDictionary *titleAttr = @{NSFontAttributeName: titlefont,
                                NSForegroundColorAttributeName: [SCHUtility deepGrayColor]};
  
    NSMutableAttributedString *bookString = [[NSMutableAttributedString alloc] init];;
    [bookString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Book Appointment" attributes:titleAttr]];
    self.lblBookAppointment.attributedText = bookString;
    
    NSMutableAttributedString *menageAppointmentString = [[NSMutableAttributedString alloc] init];;
    [menageAppointmentString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Manage Appointment" attributes:titleAttr]];
    self.lblManageAppointment.attributedText = menageAppointmentString;
    
    NSMutableAttributedString *serviceProviderString = [[NSMutableAttributedString alloc] init];;
    [serviceProviderString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Service Provider" attributes:titleAttr]];
    self.lblServiceProvider.attributedText = serviceProviderString;

    NSMutableAttributedString *manageServiceString = [[NSMutableAttributedString alloc] init];;
    [manageServiceString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Manage Service" attributes:titleAttr]];
    self.lblMenageService.attributedText = manageServiceString;
  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
//    return 0;
//}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
