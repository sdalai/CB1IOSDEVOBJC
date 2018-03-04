//
//  SCHUserProfileViewController.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/15/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCHUserProfileViewController : UIViewController
- (IBAction)unwindToSCHUserProfile:(UIStoryboardSegue *)segue;
@property (strong, nonatomic) IBOutlet UILabel *userSummary;
@property (strong, nonatomic) IBOutlet UITableView *serviceListTableView;
- (IBAction)EditAcount:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *btnUpgradeToPremium;
@property (strong, nonatomic) IBOutlet UITextView *txtViewSubscriptionDetail;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnEdit;

@property (weak, nonatomic) IBOutlet UILabel *expirationNotice;
- (IBAction)Close:(UIBarButtonItem *)sender;

@end
