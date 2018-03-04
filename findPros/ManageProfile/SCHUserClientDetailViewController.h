//
//  SCHUserClientDetailViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/25/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "SCHServiceProviderClientList.h"
#import "XLForm.h"
@interface SCHUserClientDetailViewController : XLFormViewController
@property (strong, nonatomic) NSString *screenTitle;
@property (strong, nonatomic) SCHServiceProviderClientList *client;
@property (nonatomic,strong)UIImageView* userProfileImageView;

@end
