//
//  SCHTermsOfUseViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/10/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHHelpTermOfUseTableViewController.h"
#import "SCHUtility.h"
#import "AppDelegate.h"
#import <PassKit/PassKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "SCHLegalDocument.h"
#import "SCHConstants.h"

@interface SCHHelpTermOfUseTableViewController ()
@property(nonatomic, strong) SCHLegalDocument *userAgreement;

@end

@implementation SCHHelpTermOfUseTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    

 //  NSString *userAgreementURL = [NSString stringWithFormat:@"%@.pdf", userAgreement];
//    [self.termOfUserWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:userAgreement]]];
    
    
    
    
   // NSData *userAgreementData = [self.userAgreement.document getData];
    
   // NSString *userAgreementText = [NSString stringWithUTF8String:[userAgreementData bytes]];
    
   // NSAttributedString *attributedUserAagreementString = [[NSAttributedString alloc] initWithString:userAgreementText];
    
    
    //[self.txtPrivacyPolicy setAttributedText:[SCHUtility termsOfUse]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(appDelegate.serverReachable)
    {
        //Getlatest User Agreement
        SCHConstants *constants = [SCHConstants sharedManager];
        PFQuery *userAgreementDocumentQuery = [SCHLegalDocument query];
        [userAgreementDocumentQuery whereKey:@"Active" equalTo:@YES];
        [userAgreementDocumentQuery whereKey:@"documentType" equalTo:constants.SCHLegalDocumentUserAgreement];
        [userAgreementDocumentQuery orderByDescending:@"updatedAt"];
        
        self.userAgreement =[userAgreementDocumentQuery getFirstObject];
        // NSString *userAgreement = [self.userAgreement.document url];
        
        PFFile *tearmsOfUse = self.userAgreement.document;
        NSData *pdfData = [tearmsOfUse getData];
        [self.termOfUserWebView loadData:pdfData
                                MIMEType:@"application/pdf"
                        textEncodingName:@"UTF-8"
                                 baseURL:[NSURL URLWithString:@"http://"]];
        
    }else{
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                           message:@"Please connect to internet."
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        
    }

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)DisAgreeAction:(id)sender {
    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                       message:@""
                                                      delegate:self
                                             cancelButtonTitle:@"Logout"
                                             otherButtonTitles:@"Cancel",nil];
    [theAlert show];
    
    
}

- (IBAction)agreeAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    [self.navigationController popViewControllerAnimated:YES];    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
