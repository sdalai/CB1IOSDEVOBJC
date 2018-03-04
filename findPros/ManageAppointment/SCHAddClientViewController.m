  //
//  SCHAddClientViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/6/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHAddClientViewController.h"
#import "SCHUtility.h"
#import "SCHUser.h"
#import "AppDelegate.h"
#import "SCHPhoneVerificationViewController.h"
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
#import <libPhoneNumber-iOS/NBNumberFormat.h>
#import <libPhoneNumber-iOS/NBMetadataCore.h>
#import <libPhoneNumber-iOS/NBPhoneMetaData.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>
@interface SCHAddClientViewController () <UITextFieldDelegate>

@property(nonatomic, strong) SCHUser *serviceProvider;
@property (nonatomic, strong) NBAsYouTypeFormatter *phoneFormatter;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NBPhoneNumberUtil *phoneUtil;

@end

@implementation SCHAddClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLocale *currentLocale = [NSLocale currentLocale];
    self.countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    
    self.phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    self.phoneFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:self.countryCode];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.serviceProvider = appDelegate.user;
    
    
    self.txtPhone.delegate = self;
    
    
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = NO;
    UIBarButtonItem *addClientButton = [[UIBarButtonItem alloc]
                                  
                                  
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                  
                                  
                                  target:self action:@selector(CancelAction)];

    self.navigationItem.leftBarButtonItem = addClientButton;
    
    [self.txtName becomeFirstResponder];
    
   
    
}

-(void)CancelAction
{
    [self.navigationController popViewControllerAnimated:YES];
}



- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.txtPhone) {
        NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"()- "];
        
        // NSString *stripppedNumber = [newText stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [newText length])];
        NSString *stripppedNumber = [[newText componentsSeparatedByCharactersInSet: doNotWant] componentsJoinedByString: @""];
        
        UITextRange *selectedRange = [textField selectedTextRange];
        NSInteger oldLength = [textField.text length];
        
        
        /*
         
         if (digits == 0)
         textField.text = @"";
         else if (digits < 3 || (digits == 3 && deleting))
         textField.text = [NSString stringWithFormat:@"(%@", stripppedNumber];
         
         else if (digits < 6 || (digits == 6 && deleting))
         textField.text = [NSString stringWithFormat:@"(%@) %@", [stripppedNumber substringToIndex:3], [stripppedNumber substringFromIndex:3]];
         else
         textField.text = [NSString stringWithFormat:@"(%@) %@-%@", [stripppedNumber substringToIndex:3], [stripppedNumber substringWithRange:NSMakeRange(3, 3)], [stripppedNumber substringFromIndex:6]];
         
         */
        
        if (range.length ==0){
            textField.text = [self.phoneFormatter inputString:stripppedNumber];
            
        } else{
            textField.text = [self.phoneFormatter removeLastDigit];
        }
        
        
        
        
        UITextPosition *newPosition = [textField positionFromPosition:selectedRange.start offset:[textField.text length] - oldLength];
        UITextRange *newRange = [textField textRangeFromPosition:newPosition toPosition:newPosition];
        [textField setSelectedTextRange:newRange];
        
        // if (digits == 10)
        NSError *error = nil;
        
        NBPhoneNumber *phoneNumber = [self.phoneUtil parse:stripppedNumber defaultRegion:self.countryCode error:&error];
        
        if (!error){
            if ([self.phoneUtil isValidNumber:phoneNumber]){
                [textField resignFirstResponder];
            }
        }

        
        return NO;
    }
    
    return YES;
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    //NSLog(@"touchesBegan:withEvent:");
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    return YES;
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)doneButtonAction:(id)sender
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *nameFieldValue = (self.txtName.text.length) ? self.txtName.text : nil;
    NSString *phoneFieldValue = (self.txtPhone.text.length) ? self.txtPhone.text : nil;
    NSString *emailFieldValue = (self.txtEmail.text.length) ? self.txtEmail.text : nil;
    
    if (nameFieldValue.length == 0){
        //show Alert
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                           message:[NSString localizedStringWithFormat:@"Please provice name."]
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        return;

    }
    if (!phoneFieldValue){
        //show Alert
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                           message:[NSString localizedStringWithFormat:@"PLease provide Phone Number."]
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        return;

    }
    
    //validate phone Number
    NSString *phoneNumber = nil;
    NSError *error = nil;
    
    if (phoneFieldValue.length > 0){
        if ([appDelegate.user.phoneNumber isEqualToString:phoneFieldValue]){
            //show Alert
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                               message:[NSString localizedStringWithFormat:@"%@ is your phone Nmber.You can't be your client!", self.txtPhone.text]
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
            [theAlert show];
            return;
            
        } else{
            NBPhoneNumber *NBNumber = [self.phoneUtil parse:phoneFieldValue defaultRegion:self.countryCode error:&error];
            if (!error){
                if ([self.phoneUtil isValidNumber:NBNumber]){
                    phoneNumber = [self.phoneUtil format:NBNumber
                                            numberFormat:NBEPhoneNumberFormatE164
                                                   error:&error];
                    if (error){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                               message:@"Please enter phone number correctly."
                                                                              delegate:self
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil];
                            [theAlert show];
                            return;
                        });
                        return;
                        
                    }
                } else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                           message:@"Please enter phone number correctly."
                                                                          delegate:self
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
                        [theAlert show];
                        
                        
                    });
                    return;
                    
                }
                
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                       message:@"Please enter phone number correctly."
                                                                      delegate:self
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                    [theAlert show];
                    
                });
                return;
            }

        }
        
        if ([phoneNumber isEqualToString:appDelegate.user.phoneNumber]){
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Not a Client" message:[NSString localizedStringWithFormat:@"%@ is your phone Number!", [SCHUtility phoneNumberFormate:phoneNumber]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [theAlert show];
            return;
        }

        
    }
    
    NSString *email = nil;
    
    if (emailFieldValue.length > 0){
        if ([SCHUtility NSStringIsValidEmail:emailFieldValue]){
            email = emailFieldValue;
            
        } else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                   message:@"Please enter valid email address."
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [theAlert show];
                
            });
            return;
        }
        
    }
    
    NSDictionary *cloudFunctionDict = nil;
    if (phoneNumber.length > 0 && email.length > 0){
        cloudFunctionDict = @{@"email": email, @"phoneNumber" : phoneNumber};
    } else if (email.length > 0 && phoneNumber.length == 0){
        cloudFunctionDict = @{@"email": email, @"phoneNumber" : @""};
    } else if (email.length == 0 && phoneNumber.length > 0){
        cloudFunctionDict = @{@"email": @"", @"phoneNumber" : phoneNumber};
    }
    [PFCloud callFunctionInBackground:@"NonUserDetails" withParameters:cloudFunctionDict block:^(id  _Nullable object, NSError * _Nullable error) {
        if (!error){
            NSLog(@"%@", object);
            NSString *objectType = [object valueForKey:@"Type"];
            NSString *objectId = [object valueForKey:@"ObjectID"];
            PFQuery *objectQuery = nil;
            if ([objectType isEqualToString:@"User"]){
                objectQuery = [SCHUser query];
            } else{
                objectQuery = [SCHNonUserClient query];
            }
            
            id client = [objectQuery getObjectWithId:objectId];
            [client pin];
            if (client){
                SCHUser *user = nil;
                SCHNonUserClient *nonUser = nil;
                if ([client isKindOfClass:[SCHUser class]]){
                    user = client;
                } else{
                    nonUser = client;
                }
                SCHServiceProviderClientList *SPClient = [SCHUtility addClientToServiceProvider:appDelegate.user client:user name:nameFieldValue nonUserClient:nonUser autoConfirm:NO];
                [self.XLFormdelegate.rowDescriptor setValue:@{@"name": nameFieldValue,@"client":SPClient}];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSMutableArray *newStack = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
                    if(self.XLFormdelegate!=NULL)
                        [newStack removeLastObject];
                    [newStack removeLastObject];
                    
                    [self.navigationController setViewControllers:newStack animated:YES];
                });
                
                
            } else{
                
            }
            
            
        }else{
            return;
        }
        
        
        
    }];


}


-(BOOL)validateUserInformationWithName:(NSString *)name phoneNumber:(NSString*)phone andEmail:(NSString * ) email{
    
    NSString *phoneNumber =  [[phone componentsSeparatedByCharactersInSet:
                               [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                              componentsJoinedByString:@""];
   
   
    if(name.length>0 && phoneNumber.length >=10)
    {
        return  true;
    }
        return false;
    
}


@end
