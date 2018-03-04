//
//  SCHHelpSuggestionViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/27/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHHelpSuggestionViewController.h"
#import "SCHLookup.h"
#import "SCHConstants.h"
#import "SCHUtility.h"
#import "SCHUserFeedback.h"
#import "AppDelegate.h"
#import "SCHUser.h"

@interface SCHHelpSuggestionViewController ()

@end

@implementation SCHHelpSuggestionViewController

#pragma mark - XLform

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



- (void)initializeForm
{
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptorWithTitle:@"Issues & Suggestions"];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
   
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"Type" rowType:XLFormRowDescriptorTypeSelectorPush title:@"Type"];
    
    row.selectorOptions = [SCHUtility userFeedbackType];
    row.required = YES;
    

    [section addFormRow:row];
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Description Title";
    [form addFormSection:section];
    
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"ShortDescription" rowType:XLFormRowDescriptorTypeText];
    [row.cellConfigAtConfigure setObject:@"Description Title" forKey:@"textField.placeholder"];
    row.required = YES;
    [section addFormRow:row];
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Description";
    [form addFormSection:section];
    
    
    // Notes
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"SuggestionRow" rowType:XLFormRowDescriptorTypeTextView];
    [row.cellConfigAtConfigure setObject:@"Write Your Description Hare..." forKey:@"textView.placeholder"];
    row.required = YES;
    
    [section addFormRow:row];
    
    
    self.form = form;
    
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (IBAction)sumitSuggestion:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
    SCHLookup *feedbackType = [[self.formValues valueForKey:@"Type"] valueData];
    SCHUser *user = appDelegate.user;
    NSString *feedbackTitle = [[self.formValues valueForKey:@"ShortDescription"] displayText];
    NSString *feedbackDetail = [[self.formValues valueForKey:@"SuggestionRow"] displayText];
    
    if (!feedbackType || feedbackTitle.length == 0 || feedbackDetail.length == 0){
        // send message
        
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                           message:[NSString stringWithFormat:@"Please provide all information."]
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        
        return;
    }else{
        
        SCHUserFeedback *feedback = [SCHUserFeedback object];
        feedback.user = user;
        feedback.feedbackType = feedbackType;
        feedback.feedbackTitle = feedbackTitle;
        feedback.feedbackDetail = feedbackDetail;
        
        [feedback saveInBackground];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *alertMessage = nil;
            
            if ([feedbackType isEqual:constants.SCHUserFeedbackSuggestion]){
                alertMessage = [NSString stringWithFormat:@"Information received. We appreciate your support."];
            } else {
                alertMessage = [NSString stringWithFormat:@"Information received. Will revert ASAP."];
            }
            
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Thank you"
                                                               message:alertMessage
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
            [theAlert show];
            
        });
        
        
        
    }
    
    
    
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.navigationController popViewControllerAnimated:YES];
    
}
@end
