//
//  SCHServiceProviderViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 7/8/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHService.h"
#import "SCHServiceProviderAvailabilityViewController.h"
#import <MessageUI/MFMailComposeViewController.h>
@interface SCHServiceProviderViewController : UIViewController <MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UITextView *txtServiceDetail;
@property (strong, nonatomic) IBOutlet UITextView *txtServiceDescription;

@property (strong,nonatomic) SCHService* selectedServiceProvider;
@property (strong, nonatomic) IBOutlet UIImageView *serviceProviderImage;
@property (strong, nonatomic) IBOutlet UIButton *btnBook;
@property (strong, nonatomic) IBOutlet UIButton *btnEmail;
@property (strong, nonatomic) IBOutlet UIButton *btnCall;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *favButton;
@property (strong, nonatomic) IBOutlet UIView *headerView;


- (IBAction)callAction:(id)sender;
- (IBAction)emailAction:(id)sender;
- (IBAction)favButtonAction:(id)sender;


@end
