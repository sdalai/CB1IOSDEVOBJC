//
//  SCHServiceProviderViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 7/8/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHServiceProviderViewController.h"
#import "SCHUserFevoriteService.h"
#import "SCHUser.h"
#import "AppDelegate.h"

@implementation SCHServiceProviderViewController
bool isFav = false;
-(void)viewDidLoad{
    [super viewDidLoad];
    isFav = [self isServiceUserFevorite];
    
    if(isFav)
    {
        [self.favButton setImage:[UIImage imageNamed:@"after_fav.png" ]];
    }
    
    self.title =self.selectedServiceProvider.user.preferredName;
    self.serviceProviderImage.layer.masksToBounds = YES;
    self.serviceProviderImage.contentMode = UIViewContentModeScaleAspectFill;
    self.serviceProviderImage.layer.borderColor = [[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] CGColor];
    [[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] CGColor];
    
    
    self.serviceProviderImage.layer.borderWidth = 3.0;
    self.serviceProviderImage.layer.cornerRadius = 4;//self.serviceProviderImage.frame.size.height / 2;
    
    NSDictionary *serviceDetail = [SCHUtility serviceProviderProfileContentForService:self.selectedServiceProvider];
    [self.txtServiceDetail setAttributedText:[serviceDetail objectForKey:@"title"]];
   // [self.txtServiceDescription setAttributedText:[serviceDetail objectForKey:@"description"]];
    
    NSDictionary *descriptionAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    
    
    if (self.selectedServiceProvider.serviceDescription){
        [self.txtServiceDescription setAttributedText:[[NSAttributedString alloc] initWithString:self.selectedServiceProvider.serviceDescription attributes:descriptionAttr]];
    }
    

    //loading profile pic
    PFFile *imageFile = self.selectedServiceProvider.profilePicture;
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if(!error){
            UIImage *profileImage = [UIImage imageWithData:data];
            self.serviceProviderImage.image = profileImage;
        }
    }];
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

}

- (IBAction)callAction:(id)sender {
    NSString *cellNumber =[NSString stringWithFormat:@"tel:%@",self.selectedServiceProvider.businessPhone];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cellNumber]];

}

- (IBAction)emailAction:(id)sender {
    NSString *to  = self.selectedServiceProvider.businessEmail;
    
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setSubject:@"CounterBean Contact"];
    [controller setToRecipients:[NSArray arrayWithObjects: to,nil]];
    [controller setMessageBody:@"Hello there." isHTML:NO];
    if (controller) [self presentViewController:controller animated:YES completion:NULL];
   
}

- (IBAction)favButtonAction:(id)sender
{
if(isFav)
{
    
    [self removeServiceFromFevorite];
    [self.favButton setImage:[UIImage imageNamed:@"before_fav.png" ]];
    isFav = false;
}else{
    [self addServiceToUserFevotite];
    [self.favButton setImage:[UIImage imageNamed:@"after_fav.png" ]];
    isFav = true;
    
}

}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        [self showMailSuccessAlert];
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}
- (IBAction)shareWithFriend:(id)sender {
    
    NSString *texttoshare = [SCHUtility referMessage:self.selectedServiceProvider]; //this is your text string to share
    NSArray *activityItems = @[texttoshare];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
    [self presentViewController:activityVC animated:TRUE completion:nil];
    
    
}


-(void)showMailSuccessAlert{
    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                       message:@"Your mail sent successfully"
                                                      delegate:self
                                             cancelButtonTitle:@"ok"
                                             otherButtonTitles:nil];
    [theAlert show];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = [NSString stringWithFormat:@"%@",self.selectedServiceProvider.user.preferredName];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"ServiceProviderAvailabilitySegue"]){
        SCHServiceProviderAvailabilityViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.selectedServiceProvider  = (SCHService *)self.selectedServiceProvider;
        vcToPushTo.parent = self;
    }
}

-(BOOL)isServiceUserFevorite{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PFQuery *userFevotriteQuery = [SCHUserFevoriteService query];
    [userFevotriteQuery whereKey:@"user" equalTo:appDelegate.user];
    [userFevotriteQuery whereKey:@"service" equalTo:self.selectedServiceProvider];
    int fevoriteCount = (int)[userFevotriteQuery countObjects];
    
    if (fevoriteCount == 0){
        return NO;
    }else {
        return YES;
    }
    
    
}

-(void)removeServiceFromFevorite{
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PFQuery *userFevotriteQuery = [SCHUserFevoriteService query];
    [userFevotriteQuery whereKey:@"user" equalTo:appDelegate.user];
    [userFevotriteQuery whereKey:@"service" equalTo:self.selectedServiceProvider];
    for (PFObject *object in [userFevotriteQuery findObjects]){
        [object deleteInBackground];
    }

}

-(void)addServiceToUserFevotite{
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHUserFevoriteService *fevorite = [SCHUserFevoriteService object];
    fevorite.user = appDelegate.user;
    fevorite.service = self.selectedServiceProvider;
    [fevorite saveInBackground];
}





@end
