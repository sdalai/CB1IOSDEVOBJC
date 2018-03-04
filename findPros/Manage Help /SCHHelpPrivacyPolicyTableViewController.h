//
//  SCHPrivacyPolicyViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/10/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHUtility.h"
#import "AppDelegate.h"
#import <PassKit/PassKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface SCHHelpPrivacyPolicyTableViewController : UIViewController
- (IBAction)DisAgreeAction:(id)sender;
- (IBAction)agreeAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIWebView *privacyPolicyWebView;


@end
