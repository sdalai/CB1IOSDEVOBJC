//
//  SCHUpgradeSubscriptionViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/4/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHUpgradeSubscriptionViewController.h"
#import <PureLayout/PureLayout.h>
#import "SCHUtility.h"
#import <StoreKit/StoreKit.h>

@interface SCHUpgradeSubscriptionViewController ()<SKPaymentTransactionObserver, SKProductsRequestDelegate>

@end

@implementation SCHUpgradeSubscriptionViewController
XLFormRowDescriptor * DescriptionRow;
XLFormRowDescriptor * monthlySubscriptionRow;
XLFormRowDescriptor * quarterlySubscriptionRow;
XLFormRowDescriptor * yearlySubscriptionRow;

NSString * monthlySubscriptionProductId= @"findPros_Plan_1";
NSString * quarterlySubscriptionProductId= @"findPros_Plan_2";
NSString * yearlySubscriptionProductId= @"findPros_Plan_3";


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initializeForm];
    }
    return self;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeForm];
    }
    return self;
}

- (void)initializeForm {
    
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
  //  XLFormRowDescriptor * row;
    form = [XLFormDescriptor formDescriptorWithTitle:@"Premium"];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // Description
    DescriptionRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"PremiumDetail" rowType:XLFormRowDescriptorTypeTextView];
    
    [DescriptionRow.cellConfigAtConfigure setObject:[UIColor lightGrayColor] forKey:@"textView.textColor"];
    // [DescriptionRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [DescriptionRow.cellConfig setObject:@NO forKey:@"textView.editable"];
    [DescriptionRow.cellConfig setObject:@NO forKey:@"textView.selectable"];
    [section addFormRow:DescriptionRow];
    
    
    //Plan Detail's
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Plans";
    [form addFormSection:section];
    
    monthlySubscriptionRow =[XLFormRowDescriptor formRowDescriptorWithTag:@"monthlySubscriptionRow" rowType:XLFormRowDescriptorTypeInfo title:@"monthlySubscriptionRow"];
    monthlySubscriptionRow.selectorTitle = @"Monthly Quarterly Subscription";
    monthlySubscriptionRow.value = @"$5";
    [section addFormRow:monthlySubscriptionRow];

    quarterlySubscriptionRow =[XLFormRowDescriptor formRowDescriptorWithTag:@"quarterlySubscriptionRow" rowType:XLFormRowDescriptorTypeInfo title:@"quarterlySubscriptionRow"];
    quarterlySubscriptionRow.selectorTitle = @"Quarterly Subscription";
    quarterlySubscriptionRow.value = @"$10";
    [section addFormRow:quarterlySubscriptionRow];

    yearlySubscriptionRow =[XLFormRowDescriptor formRowDescriptorWithTag:@"yearlySubscriptionRow" rowType:XLFormRowDescriptorTypeInfo title:@"yearlySubscriptionRow"];
    yearlySubscriptionRow.selectorTitle = @"Yearly Subscription";
    yearlySubscriptionRow.value = @"$30";
    [section addFormRow:yearlySubscriptionRow];

    
    self.form = form;
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    UIEdgeInsets newContentInset = self.tableView.contentInset;
    newContentInset.top = self.topLayoutGuide.length;
    
}







- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    
   

    
    // set support Text
    NSMutableAttributedString *descriptionString = [[NSMutableAttributedString alloc] init];;
    UIFont *titlefont = [SCHUtility getPreferredBodyFont];
    NSDictionary *titleAttr = @{NSFontAttributeName: titlefont,
                                NSForegroundColorAttributeName: [SCHUtility deepGrayColor]};
    [descriptionString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Set Description Text" attributes:titleAttr]];
    [descriptionString appendAttributedString:newline];
    [descriptionString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Set New Line Description Text" attributes:titleAttr]];
    
    [DescriptionRow.cellConfig setObject:descriptionString forKey:@"textView.attributedText"];
    [self updateFormRow:DescriptionRow];
    
    
    //set Monthly Row
    NSMutableAttributedString *monthlyTextString = [[NSMutableAttributedString alloc] init];;
    [monthlyTextString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Monthly Subscription" attributes:titleAttr]];
    [monthlySubscriptionRow.cellConfig setObject:monthlyTextString forKey:@"textLabel.attributedText"];
    [self updateFormRow:monthlySubscriptionRow];
    
    //set Quarterly Row
    NSMutableAttributedString *quarterlyTextString = [[NSMutableAttributedString alloc] init];;
    [quarterlyTextString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Quarterly Subscription" attributes:titleAttr]];
    [quarterlySubscriptionRow.cellConfig setObject:quarterlyTextString forKey:@"textLabel.attributedText"];
    [self updateFormRow:quarterlySubscriptionRow];
    
    
    //set Monthly Row
    NSMutableAttributedString *yearlyTextString = [[NSMutableAttributedString alloc] init];;
    [yearlyTextString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Yearly Subscription" attributes:titleAttr]];
    [yearlySubscriptionRow.cellConfig setObject:yearlyTextString forKey:@"textLabel.attributedText"];
    [self updateFormRow:yearlySubscriptionRow];
    
    
    
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

@end
