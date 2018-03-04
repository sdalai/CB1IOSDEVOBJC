//
//  SCHResetPasswordViewController.m
//  CounterBean
//
//  Created by Sujit Dalai on 8/21/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHResetPasswordViewController.h"
#import "SCHUtility.h"
#import "AppDelegate.h"
#import "SCHSyncManager.h"
#import "SCHAlert.h"
#import <IQKeyboardManager/IQKeyboardManager.h>
#import <IQKeyboardManager/IQUIView+Hierarchy.h>

@interface SCHResetPasswordViewController () <UITextFieldDelegate>

@property (nonatomic, strong) PFUser *currentUser;

@end

@implementation SCHResetPasswordViewController

-(void)initializeScreen{

    self.passwordTextField.textColor = [SCHUtility deepGrayColor];
    self.passwordTextField.delegate = self;
    self.confirmPasswordTextField.textColor = [SCHUtility deepGrayColor];
    self.confirmPasswordTextField.delegate = self;
    
    self.resetButton.layer.cornerRadius = self.resetButton.bounds.size.height/2;
    self.resetButton.layer.masksToBounds = YES;
    [self.resetButton layoutIfNeeded];
    self.cancelResetButton.layer.cornerRadius = self.cancelResetButton.bounds.size.height/2;
    self.cancelResetButton.layer.masksToBounds = YES;
    [self.cancelResetButton layoutIfNeeded];
    
    
   // [self.passwordTextField becomeFirstResponder];
    
     
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.currentUser = [PFUser currentUser];
   // [self.currentUser fetch];
   self.confirmPasswordTextField.enabled = NO;
    [self.navigationController.navigationBar setHidden:NO];
    self.navigationItem.title = @"Change Password";
    self.navigationItem.hidesBackButton =YES;

    
    //hide keyboard
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    IQKeyboardManager *keyboardManager = [IQKeyboardManager sharedManager];
    [keyboardManager setEnableAutoToolbar:YES];
    keyboardManager.shouldHidePreviousNext = YES;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appDelegate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            self.resetButton.hidden = YES;
            self.resetButton.enabled = NO;
            self.cancelResetButton.hidden = NO;
            self.cancelResetButton.enabled = YES;

            
            
            
            
        } else {
            [self.navigationItem setPrompt:nil];
            self.resetButton.hidden = NO;
            self.resetButton.enabled = YES;
            self.cancelResetButton.hidden = NO;
            self.cancelResetButton.enabled = YES;
            
        }
        
    });

    
    

    
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}

-(void)viewDidLayoutSubviews{
    [self initializeScreen];
}

-(void)internetConnectionChanged{
    
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appdeligate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            self.resetButton.hidden = YES;
            self.resetButton.enabled = NO;
            self.cancelResetButton.hidden = NO;
            self.cancelResetButton.enabled = YES;
            
        } else {
            [self.navigationItem setPrompt:nil];
            self.resetButton.hidden = NO;
            self.resetButton.enabled = YES;
            self.cancelResetButton.hidden = NO;
            self.cancelResetButton.enabled = YES;

            
        }
        
    });
    
    
    
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

- (IBAction)resetPassword:(id)sender {
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ( self.passwordTextField.text.length == 0 || self.confirmPasswordTextField.text == 0){
         [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please provide all information before resetting.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    if (![self.passwordTextField.text isEqualToString:self.confirmPasswordTextField.text]){
         [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CounterBean", nil) message:NSLocalizedString(@"Please confirm your new password correctly.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    
    // call Program to reset password
    
    if (appdeligate.serverReachable){
        [PFCloud callFunctionInBackground:@"changePassword" withParameters:@{@"email" : self.currentUser.email, @"password" : self.passwordTextField.text} block:^(id  _Nullable object, NSError * _Nullable error) {
            
            
            
            if (error){
                // The login failed. Check error to see why.
                NSString *errorString = [error userInfo][@"error"]; // Show the errorString somewhere and let the user try again.
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Password Change Error!", nil) message:NSLocalizedString(errorString, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            }else{
                [self.currentUser fetch];
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
        
    }
    
}

- (IBAction)cancelResetPassword:(id)sender {
    
    
    BOOL enforcePasswordReset = [self.currentUser[@"enforcePasswordreset"] boolValue];
 
    
    
    if (enforcePasswordReset){
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                           message:@""
                                                          delegate:self
                                                 cancelButtonTitle:@"Logout"
                                                 otherButtonTitles:@"Cancel",nil];
        [theAlert show];
    } else{
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    
}


- (void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if ([theAlert.title isEqualToString:@"CounterBean"]){
        if(buttonIndex==0)
        {
            [SCHUtility logout];
            [self.navigationController popViewControllerAnimated:YES];
            
            
        }
    }
    
}


#pragma mark - UI TextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
 if([textField isEqual:self.confirmPasswordTextField]){
        if (self.confirmPasswordTextField.isEnabled){
            [self.confirmPasswordTextField becomeFirstResponder];
        }
        
    }
    
    return YES;
  
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    textField.textColor = [SCHUtility deepGrayColor];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    textField.textColor = [SCHUtility deepGrayColor];
    
    if ([textField isEqual:self.passwordTextField]){
        if (textField.text.length > 0){
            self.confirmPasswordTextField.enabled = YES;
        }else{
            self.confirmPasswordTextField.enabled = NO;
        }
    }
    
    if ([textField isEqual:self.confirmPasswordTextField]){
        if (textField.text.length> 0){
            if ([textField.text isEqualToString:self.passwordTextField.text]){
                textField.textColor = [SCHUtility greenColor];
                self.passwordTextField.textColor = [SCHUtility greenColor];
            }else{
                textField.textColor = [SCHUtility deepGrayColor];
                self.passwordTextField.textColor = [SCHUtility deepGrayColor];
                
            }
            
        }else{
            textField.textColor = [SCHUtility deepGrayColor];
            self.passwordTextField.textColor = [SCHUtility deepGrayColor];
        }
        
    }
    
    
    return YES;
    
    
}




-(void)dismissKeyboard {
    
    if  ([self.passwordTextField isFirstResponder]){
        [self.passwordTextField resignFirstResponder];
    } else if ([self.confirmPasswordTextField isFirstResponder]){
        [self.confirmPasswordTextField resignFirstResponder];
    }
}











@end
