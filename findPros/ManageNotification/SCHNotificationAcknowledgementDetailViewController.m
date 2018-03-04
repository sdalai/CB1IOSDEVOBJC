//
//  SCHNotificationAcknowledgementDetailViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/1/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHNotificationAcknowledgementDetailViewController.h"
#import "SCHUtility.h"
@interface SCHNotificationAcknowledgementDetailViewController ()

@end

@implementation SCHNotificationAcknowledgementDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIFont *titlefont = [SCHUtility getPreferredTitleFont];
    UIFont *bodyFont = [SCHUtility getPreferredBodyFont];
    NSDictionary *titleAttr =
    [NSDictionary dictionaryWithObject:titlefont
                                forKey:NSFontAttributeName];
    
    NSDictionary *bodyAttr = @{NSFontAttributeName: bodyFont,
                               NSForegroundColorAttributeName: [UIColor grayColor]};
    
    NSAttributedString *nextLine = [[NSAttributedString alloc] initWithString:@"\n"];
    
    NSMutableAttributedString *notificationMessage = [[NSMutableAttributedString alloc] init];
    
    [notificationMessage appendAttributedString:[[NSAttributedString alloc] initWithString:self.notification.notificationTitle attributes:titleAttr]];
    [notificationMessage appendAttributedString:nextLine];
    
    if([self.notification.message length]>0){
        [notificationMessage appendAttributedString:[[NSAttributedString alloc] initWithString:self.notification.message attributes:bodyAttr]];
    }
    
    [self.txtMessage setAttributedText:notificationMessage];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewDidLayoutSubviews {
    [self.txtMessage setContentOffset:CGPointZero animated:NO];
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
