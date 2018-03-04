//
//  SlideMenuViewController.m
//  CounterBean
//
//  Created by Pratap Yadav on 19/04/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SlideMenuViewController.h"
#import "SCHConstants.h"
#import "SCHUtility.h"
#import "MFSideMenu.h"
#import "SCHActiveViewControllers.h"
#import "AppDelegate.h"
#import "SCHAlert.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/ParseFacebookUtilsV4.h>
#import "SCHUser.h"
#import "SCHLoginViewController.h"
#import "SCHScheduleTableViewController.h"
#import "SCHLoginViewController.h"

static NSString * const kNewMeetup = @"Meet-up";
static NSString * const kBookAppointment = @"Book Appointment";
static NSString * const kManageBusiness = @"Manage Business";
static NSString * const kProfile = @"Profile";
static NSString * const kCalendar = @"Calendar";
static NSString * const kMessages = @"Messages";
static NSString * const kHelp = @"Help";
static NSString * const kLogout = @"Logout";

@interface SlideMenuViewController ()
@property (weak, nonatomic) IBOutlet UILabel *LblName;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UITapGestureRecognizer *imageTap;

@end

@implementation SlideMenuViewController
NSArray *stringArray;
static NSString *CellIdentifier = @"sideMenuCell";
- (void)viewDidLoad {
    [super viewDidLoad];
    [self dataSynceFailure];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCHsyncFailure object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataSynceFailure)
                                                 name:SCHsyncFailure
                                               object:nil];
    
    
    
    
    self.imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pictureTapped)];
    [self.imageView setUserInteractionEnabled:YES];
    [self.imageView addGestureRecognizer:self.imageTap];
    stringArray = [NSArray arrayWithObjects:kNewMeetup, kBookAppointment, kManageBusiness, kCalendar, kMessages, kLogout , nil];
    //
        //[self.LblName setTextColor:[SCHUtility deepGrayColor]];
    
    //self.imageView.layer.masksToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.layer.cornerRadius = 6.0;
    self.imageView.layer.borderColor = [[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] CGColor];
    self.imageView.layer.borderWidth = 2.0;
    //self.imageView.layer.cornerRadius = self.imageView.frame.size.height / 2;
    self.imageView.clipsToBounds = YES;
    
    

    
   
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.scrollEnabled = NO;
   // [self.tableView setContentOffset:self.tableView.contentOffset animated:NO];
    // Do any additional setup after loading the view.
    
}

-(void) viewDidAppear:(BOOL)animated{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [super viewDidAppear:animated];
    SCHUser *currentUser = appDelegate.user;
    [self.LblName setText:currentUser.preferredName];
    
    PFFile *imageFile = currentUser.profilePicture;
    UIImage *profileImage = [UIImage imageNamed:@"dummy_img.png"];
    
    CGSize size=CGSizeMake(80, 80);//set the width and height
    UIImage *resizedImage= [self resizeImage:profileImage imageSize:size];
    [self.imageView setImage:resizedImage];
    //
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if(!error){
            UIImage *profileImage = [UIImage imageWithData:data];
            self.imageView.image = profileImage;
        }
    }];

    
}


-(UIImage*)resizeImage:(UIImage *)image imageSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0,size.width,size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    //here is the scaled image which has been changed to the size specified
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark- table View Delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [stringArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure Cell
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:1];
    [label setText:[stringArray objectAtIndex:indexPath.row]];
    [label setHighlightedTextColor:[UIColor whiteColor]];
   // [label setTextColor:[SCHUtility deepGrayColor]];
    
    //Set selection background color
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    [cell setSelectedBackgroundView:bgColorView];
    
    
    
    //cell.selectedBackgroundView
    
    return cell;
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
     UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:1];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([label.text isEqualToString:kCalendar]){
        [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
        }];
        
        UITabBarController *tabBar = (UITabBarController*)self.menuContainerViewController.centerViewController;
        [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
    } else if ([label.text isEqualToString:kBookAppointment]){
        [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
        }];
        
        UITabBarController *tabBar = (UITabBarController*)self.menuContainerViewController.centerViewController;
        [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 2]];
    } else if ([label.text isEqualToString:kMessages]){
        [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
        }];
        
        UITabBarController *tabBar = (UITabBarController*)self.menuContainerViewController.centerViewController;
        [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 3]];
    } else if ([label.text isEqualToString:kManageBusiness]){
        [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
        }];
        
        UITabBarController *tabBar = (UITabBarController*)self.menuContainerViewController.centerViewController;
        [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 4]];
    } else if ([label.text isEqualToString:kProfile]){
        [self performSegueWithIdentifier:@"menuToAccount" sender:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if ([label.text isEqualToString:kNewMeetup]){
        if (appDelegate.serverReachable){
            [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
            }];
            
            //menuToMeetupSegue
            
            UITabBarController *tabBar = (UITabBarController*)self.menuContainerViewController.centerViewController;
            [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
            //
            
            UINavigationController *Navcontrller = (UINavigationController *)tabBar.selectedViewController;
            SCHScheduleTableViewController *vc = Navcontrller.viewControllers[0];
            [vc createGroupAppointment:nil];

            
        } else{
             [SCHAlert internetOutageAlert];
        }
        
        
    } else if ([label.text isEqualToString:kLogout]){
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if (appDelegate.serverReachable){
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                               message:@""
                                                              delegate:self
                                                     cancelButtonTitle:@"Logout"
                                                     otherButtonTitles:@"Cancel",nil];
            [theAlert show];
        }else {
            
            
            [SCHAlert internetOutageAlert];
        }
    }
    
    
}
- (void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if ([theAlert.title isEqualToString:@"CounterBean"]){
        if(buttonIndex==0)
        {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SCHUserLogout
                                                                    object:self];
                [self dismissViewControllerAnimated:NO completion:NULL];
                [self performSegueWithIdentifier:@"logoutSegue" sender:self];
                
            });
            
        }
    }
    
}

-(void)pictureTapped{
    
    [self performSegueWithIdentifier:@"menuToAccount" sender:nil];
    
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"logoutSegue"]){
        
        UINavigationController *pushToVC = segue.destinationViewController;
        SCHLoginViewController *rootVC = pushToVC.viewControllers[0];
        rootVC.logoutUser = YES;

        
        
    }
}

-(void)dataSynceFailure{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.dataSyncFailure){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SCHUserLogout
                                                                    object:self];
            [self dismissViewControllerAnimated:NO completion:NULL];
            [self performSegueWithIdentifier:@"logoutSegue" sender:self];
            
        });
        
    }
    
    
}







@end
