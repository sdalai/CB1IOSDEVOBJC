//
//  SCHHelpViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/27/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SCHHelpViewController : UITableViewController<MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *lblSupportDetail;
//@property (strong, nonatomic) IBOutlet UILabel *lblHelp;
@property (strong, nonatomic) IBOutlet UILabel *lblAgreement;
@property (strong, nonatomic) IBOutlet UILabel *lblSuggestAndSuggestion;

@end
