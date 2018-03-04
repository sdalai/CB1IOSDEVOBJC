//
//  SCHTermsOfUseViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/10/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCHHelpTermOfUseTableViewController : UIViewController
- (IBAction)DisAgreeAction:(id)sender;
- (IBAction)agreeAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIWebView *termOfUserWebView;


@end
