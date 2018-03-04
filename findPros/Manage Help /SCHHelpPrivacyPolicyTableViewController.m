//
//  SCHPrivacyPolicyViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/10/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHHelpPrivacyPolicyTableViewController.h"
#import "SCHLegalDocument.h"
#import "SCHLoginViewController.h"


@interface SCHHelpPrivacyPolicyTableViewController ()
@property(nonatomic, strong) SCHLegalDocument *privacyPolicy;

@end

@implementation SCHHelpPrivacyPolicyTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //Getlatest User Agreement
      //  NSString *privacyPolicyURL = [self.privacyPolicy.document url];

  //  [self.privacyPolicyWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:privacyPolicyURL]]];
    }

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(appDelegate.serverReachable)
    {
        SCHConstants *constants = [SCHConstants sharedManager];
        PFQuery *privacyPolicyDocumentQuery = [SCHLegalDocument query];
        [privacyPolicyDocumentQuery whereKey:@"Active" equalTo:@YES];
        [privacyPolicyDocumentQuery whereKey:@"documentType" equalTo:constants.SCHLegalDocumentPrivacyPolicy];
        [privacyPolicyDocumentQuery orderByDescending:@"updatedAt"];
        
        self.privacyPolicy =[privacyPolicyDocumentQuery getFirstObject];
   
        PFFile *privacyPilicyFile = self.privacyPolicy.document;
        NSData *pdfData = [privacyPilicyFile getData];
        [self.privacyPolicyWebView loadData:pdfData
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

-(void) agreedProcess{
    [self.navigationController popoverPresentationController];
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
