//
//  SCHHelpViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/27/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHHelpViewController.h"
#import "SCHUtility.h"
#import <MessageUI/MessageUI.h>

@interface SCHHelpViewController ()

@end

@implementation SCHHelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIFont *titlefont = [SCHUtility getPreferredBodyFont];
    NSDictionary *titleAttr = @{NSFontAttributeName: titlefont,
                                NSForegroundColorAttributeName: [SCHUtility deepGrayColor]};
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    
    NSMutableAttributedString *supportString = [[NSMutableAttributedString alloc] init];;
    [supportString appendAttributedString:[[NSAttributedString alloc] initWithString:@"For Support Please Conatact" attributes:titleAttr]];
    [supportString appendAttributedString:newline];
    [supportString appendAttributedString:[[NSAttributedString alloc] initWithString:@"contact@counterbean.com" attributes:titleAttr]];
   // [supportString appendAttributedString:newline];
   // [supportString appendAttributedString:[[NSAttributedString alloc] initWithString:@"(555) 555-5555" attributes:titleAttr]];
    self.lblSupportDetail.attributedText = supportString;
    
//    NSMutableAttributedString *HelpString = [[NSMutableAttributedString alloc] init];;
//    [HelpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Help" attributes:titleAttr]];
//    self.lblHelp.attributedText = HelpString;

    NSMutableAttributedString *agrementString = [[NSMutableAttributedString alloc] init];;
    [agrementString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Agreement" attributes:titleAttr]];
    self.lblAgreement.attributedText = agrementString;

    NSMutableAttributedString *suggestString = [[NSMutableAttributedString alloc] init];;
    [suggestString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Issue and Suggestions" attributes:titleAttr]];
    self.lblSuggestAndSuggestion.attributedText = suggestString;



}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
  //  [self.lblHelp setFont:[SCHUtility getPreferredBodyFont]];
    
    
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Help";
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationItem.title = SCHBackkButtonTitle;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section==0 && indexPath.row==0)
    {
        NSLog(@"Print log");
        
        if(![MFMailComposeViewController canSendMail]) {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support email!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            return;
        }
        
        NSArray *recipents = @[@"contact@counterbean.com"];
        
        
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
        [composeViewController setMailComposeDelegate:self];
        [composeViewController setToRecipients:recipents];
        [composeViewController setSubject:@"CounterBean Support"];
        [composeViewController setMessageBody:@"" isHTML:NO];
        
        [self.navigationController presentViewController:composeViewController animated:YES completion:nil];

        
    }
}


-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    switch (result) {
        case MFMailComposeResultCancelled:
            break;
            
        case MFMailComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send email!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MFMailComposeResultSent:
            break;
            
        default:
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}




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
