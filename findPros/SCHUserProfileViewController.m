//
//  SCHUserProfileViewController.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/15/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHUserProfileViewController.h"
#import "SCHEditUserProfileViewController.h"
#import <Parse/Parse.h>
#import <PFFacebookUtils.h>
#import "SCHBackgroundManager.h"
#import "SCHUtility.h"
#import "SCHScheduledEventManager.h"
#import "SCHServiceClassification.h"
#import "SCHServiceDatailViewController.h"
#import "SCHLocationSelectorViewController.h"
#import "SCHLookup.h"
#import "AppDelegate.h"
#import "SCHControl.h"
#import "SCHAlert.h"
#import "SCHLoginViewController.h"
#import "MFSideMenu.h"
#import <MessageUI/MessageUI.h>
#import "SCHUser.h"


//,@"Agreement", @"Feedback", @"Contact CounterBean"
static NSString * const kChangePassword = @"Change Password";
static NSString * const kFriends = @"Friends";
static NSString * const kAgreement = @"Agreement";
static NSString * const kFeedback = @"Feedback";
static NSString * const kContactCounterBean = @"Contact CounterBean";


@interface SCHUserProfileViewController () <MFMailComposeViewControllerDelegate>
@property (nonatomic, strong) SCHUser *currentUser;
@property (weak, nonatomic) IBOutlet UINavigationItem *profileName;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;

@property (nonatomic, strong) NSArray *tableData;


@end

@implementation SCHUserProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appdeligate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });
    //[self setupMenuBarButtonItems];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)internetConnectionChanged{
    
    // [self viewDidLoad];
    [self viewWillAppear:YES];
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appdeligate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });
    
    
}




-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        [appDelegate.user fetch];
    }
    
    self.currentUser = appDelegate.user;
    
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.title = self.currentUser.preferredName;
    // Bring Data
    
    // Do any additional setup after loading the view.
    
    
    
    
    //set expiration Notice if any
    [self setExpirationMessage];
    
    
    
    
    
    self.profileName.title = @"Profile";
    
    
    
    PFFile *imageFile = self.currentUser.profilePicture;
    
    
    if (appDelegate.serverReachable){
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(!error){
                UIImage *profileImage = [UIImage imageWithData:data];
                self.profilePicture.image = profileImage;
            }
        }];
        
        
    }
    
    [self.userSummary setAttributedText:[self getUserSummary]];
    
    
    self.profilePicture.layer.masksToBounds = YES;
    self.profilePicture.contentMode = UIViewContentModeScaleAspectFill;
    self.profilePicture.layer.cornerRadius = 5.0;
    self.profilePicture.layer.borderColor = [[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] CGColor];
    self.profilePicture.layer.borderWidth = 3.0;
    // self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.height / 2;
    
    PFUser *currentUser = [PFUser currentUser];
    
    if ([currentUser.username isEqualToString:appDelegate.user.email]){
        self.tableData = [[NSArray alloc]initWithObjects:kChangePassword,kFriends, kAgreement, kFeedback, kContactCounterBean,nil];
    } else{
        self.tableData = [[NSArray alloc]initWithObjects:kFriends, kAgreement, kFeedback, kContactCounterBean,nil];
    }
    
    
    
    
    
    
    self.serviceListTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    
    
    SCHConstants *constants = [SCHConstants sharedManager];
    
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] init];;
    UIFont *titlefont = [SCHUtility getPreferredTitleFont];
    NSDictionary *titleAttr = @{NSFontAttributeName: titlefont,
                                NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    [titleString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Business Upgrade" attributes:titleAttr]];
    
    [self.btnUpgradeToPremium setAttributedTitle:titleString forState:UIControlStateNormal];
    
    
    if([self.currentUser.subscriptionType isEqual:constants.SCHSubscriptionTypePremiumUser])
    {
        [self.txtViewSubscriptionDetail setAttributedText:[SCHUtility userSubscriptionInfo]];
        
    }else{
        [self.txtViewSubscriptionDetail setText:@""];
        
        // reduce Textview height
        
    }
    
    
    BOOL enablePaymentOption = NO;
    SCHControl *control = nil;
    if (appDelegate.serverReachable){
        PFQuery *controlQuery = [SCHControl query];
        control = [controlQuery getFirstObject];
    }
    enablePaymentOption = control.enablePaymentOption;
    
    if (!enablePaymentOption){
        [self.btnUpgradeToPremium setHidden:true];
    }else {
        if ([self.currentUser.subscriptionType isEqual:constants.SCHSubscriptionTypeFreeUser]){
            [self.btnUpgradeToPremium setHidden:false];
            self.txtViewSubscriptionDetail.frame = CGRectMake(self.txtViewSubscriptionDetail.frame.origin.x, self.txtViewSubscriptionDetail.frame.origin.y, self.txtViewSubscriptionDetail.frame.size.width, 40);
        } else {
            [self.btnUpgradeToPremium setHidden:true];
            self.txtViewSubscriptionDetail.frame = CGRectMake(self.txtViewSubscriptionDetail.frame.origin.x, self.txtViewSubscriptionDetail.frame.origin.y, self.txtViewSubscriptionDetail.frame.size.width, 80);
        }
        
    }
    
    
    
    if(appDelegate.serverReachable)
    {
        [self.navigationItem setRightBarButtonItem:self.btnEdit animated:YES];
    }else {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        
    }
    
    
    
    
    
}


-(void)viewWillDisappear:(BOOL)animated{
    self.navigationItem.title = SCHBackkButtonTitle;
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)unwindToSCHUserProfile:(UIStoryboardSegue *)segue {
    
    //  SCHEditUserProfileViewController *source = [segue sourceViewController];
    self.profileName.title = [NSString stringWithFormat:@"%@ %@", self.currentUser.firstName, self.currentUser.lastName];
    
    
    [self.userSummary setAttributedText:[self getUserSummary]];
    
    
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"SCHTextViewCell" forIndexPath:indexPath];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SCHTextViewCell"];
    }
    NSString *cellData = self.tableData[indexPath.row];
    cell.textLabel.text = cellData;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
    
}
#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:1];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if([label.text isEqualToString:kChangePassword])
    {
        [self performSegueWithIdentifier:@"changePasswordSegue" sender:self.tableData[indexPath.row]];
        
    }else if([label.text isEqualToString:kFriends])
    {
        [self performSegueWithIdentifier:@"userFriendSegue" sender:self.tableData[indexPath.row]];

    }else if([label.text isEqualToString:kAgreement])
    {
        [self performSegueWithIdentifier:@"profileToAgreement" sender:self.tableData[indexPath.row]];
    }else if([label.text isEqualToString:kFeedback])
    {
        
        [self performSegueWithIdentifier:@"profileTosuggestion" sender:self.tableData[indexPath.row]];
    }else if([label.text isEqualToString:kContactCounterBean])
    {
        
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


-(NSAttributedString *) getUserSummary{
    
    SCHConstants *constants = [SCHConstants sharedManager];
    NSMutableAttributedString *userSummary = [[NSMutableAttributedString alloc] init];
    NSString *name = [NSString stringWithFormat:@"%@ %@", self.currentUser.firstName, self.currentUser.lastName];
    NSString *phoneNumber = (self.currentUser.phoneNumber) ? [SCHUtility phoneNumberFormate:self.currentUser.phoneNumber] : @"";
    
    NSString *email = self.currentUser.email;
    NSString *nextLine = [NSString stringWithFormat:@"\n"];
    
    NSString *userType =@" ";
    if (self.currentUser.subscriptionType != nil) {
        if ([self.currentUser.subscriptionType isEqual:constants.SCHSubscriptionTypePremiumUser]){
            userType = self.currentUser.subscriptionType.lookupText;
        } else if ([self.currentUser.subscriptionType isEqual:constants.SCHSubscriptionTypeFreeUser]){
            if (self.currentUser.freeTrialExpirationDate){
                if ([self.currentUser.freeTrialExpirationDate compare:[NSDate date]] == NSOrderedDescending){
                    userType = @"Free Trial";
                }
            }
            
            
        }
        
    }
    
    //Define Format for User Summary
    
    NSDictionary *nameAttribute = @{NSForegroundColorAttributeName: [SCHUtility deepGrayColor],
                                    NSFontAttributeName: [SCHUtility getPreferredTitleFont]};
    
    
    NSDictionary *phoneNumberAttribute = @{NSForegroundColorAttributeName: [SCHUtility deepGrayColor],
                                           NSFontAttributeName: [SCHUtility getPreferredSubtitleFont]};
    
    NSDictionary *emailAttrbute = @{NSForegroundColorAttributeName: [UIColor blueColor],
                                    NSFontAttributeName: [SCHUtility getPreferredSubtitleFont]};
    
    NSDictionary *userTypeAtribute = @{NSForegroundColorAttributeName: [SCHUtility deepGrayColor],
                                       NSFontAttributeName: [SCHUtility getPreferredSubtitleFont]};
    
    
    //Build User Profile
    [userSummary appendAttributedString:[[NSAttributedString alloc] initWithString:name attributes:nameAttribute]];
    [userSummary appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [userSummary appendAttributedString:[[NSAttributedString alloc] initWithString:email attributes:emailAttrbute]];
    
    if (phoneNumber.length > 0){
        [userSummary appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [userSummary appendAttributedString:[[NSAttributedString alloc] initWithString:phoneNumber attributes:phoneNumberAttribute]];
    }
    if (userType.length > 0){
        [userSummary appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [userSummary appendAttributedString:[[NSAttributedString alloc] initWithString:userType attributes:userTypeAtribute]];
    }
    
    
    
    return userSummary;
    
}

-(void)setExpirationMessage{
    
    SCHConstants *constants = [SCHConstants sharedManager];
    NSAttributedString *expirationString = nil;
    NSString *expirationText = nil;
    NSDictionary *textAttribute = @{NSForegroundColorAttributeName: [SCHUtility deepGrayColor],
                                    NSFontAttributeName: [SCHUtility getPreferredBodyFont]};
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForMediumDate];
    
    if ([self.currentUser.subscriptionType isEqual:constants.SCHSubscriptionTypeAllAccessFreeUser]){
        expirationText = nil;
    } else if ([self.currentUser.subscriptionType isEqual:constants.SCHSubscriptionTypeFreeUser]){
        if (self.currentUser.freeTrialExpirationDate){
            if ([self.currentUser.freeTrialExpirationDate compare:[NSDate date]] == NSOrderedDescending){
                //give subscription expiration
                NSString *expirationDay = [dayformatter stringFromDate:self.currentUser.freeTrialExpirationDate];
                expirationText = [NSString localizedStringWithFormat:@" Free trial expires on %@", expirationDay];
            } else{
                // expired
                expirationText = [NSString localizedStringWithFormat:@"Free trial has expired"];
            }
        } else{
            expirationText = nil;
        }
        
    } else if ([self.currentUser.subscriptionType isEqual:constants.SCHSubscriptionTypePremiumUser]){
        
        if (!([self.currentUser.premiumExpirationDate compare:[NSDate date]] == NSOrderedDescending)){
            // Give Premimum expiration message
            expirationText = [NSString localizedStringWithFormat:@"Subscription has expired"];
        }else {
            expirationText = nil;
        }
        
    }
    
    if (expirationText){
        // set expiration message
        
        expirationString = [[NSAttributedString alloc] initWithString:expirationText attributes:textAttribute];
        [self.expirationNotice setAttributedText:expirationString];
    }
    
    
    
}

-(NSAttributedString *) premimumSubscriptionDetail{
    NSMutableAttributedString *premiumSubscriptionDetail = [[NSMutableAttributedString alloc] init];
    //    NSDictionary *nameAttribute = @{NSForegroundColorAttributeName: [SCHUtility deepGrayColor],
    //                                    NSFontAttributeName: [SCHUtility getPreferredTitleFont]};
    
    
    
    
    return premiumSubscriptionDetail;
}








- (IBAction)EditAcount:(id)sender {
}
- (IBAction)UpgradeToPremiumAction:(id)sender {
    
    
}
- (IBAction)Close:(UIBarButtonItem *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
@end
