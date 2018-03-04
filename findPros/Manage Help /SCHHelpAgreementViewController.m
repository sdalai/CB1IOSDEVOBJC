//
//  SCHHelpAgreementViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/6/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHHelpAgreementViewController.h"
#import "SCHUtility.h"
#import "SCHLoginViewController.h"
@interface SCHHelpAgreementViewController ()

@end

@implementation SCHHelpAgreementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //yourTextField.contentVerticalAlignment = UIControlContentVerticalAlignment.Top
    
    UIFont *titlefont = [SCHUtility getPreferredBodyFont];
    NSDictionary *titleAttr = @{NSFontAttributeName: titlefont,
                                NSForegroundColorAttributeName: [SCHUtility deepGrayColor]};
    
    NSMutableAttributedString *TermsOfUseString = [[NSMutableAttributedString alloc] init];;
    [TermsOfUseString appendAttributedString:[[NSAttributedString alloc] initWithString:@"User Agreement" attributes:titleAttr]];
    self.lblTermOfUse.attributedText = TermsOfUseString;
    NSMutableAttributedString *PrivacyPolicyString = [[NSMutableAttributedString alloc] init];;
    [PrivacyPolicyString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Privacy Policy" attributes:titleAttr]];
    self.lblPrivacyPolicy.attributedText = PrivacyPolicyString;
   
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Agreement";
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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




@end
