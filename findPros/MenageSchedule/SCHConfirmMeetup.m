//
//  SCHConfirmGroupAppointment.m
//  CounterBean
//
//  Created by Pratap Yadav on 17/06/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//


#import "SCHConfirmMeetup.h"
#import "CLToken.h"
#import "SCHUtility.h"
#import "AppDelegate.h"
#import "SCHMeeting.h"
#import "SCHMeetingManager.h"
#import "SCHSyncManager.h"
#import "UIAlertView+Blocks.h"
#import <IQKeyboardManager/IQKeyboardManager.h>
#import "SCHEmailAndTextMessage.h"
#import "SCHAlert.h"
#import <AddressBook/AddressBook.h>
#import <AddressBook/ABMultiValue.h>
#import <KVNProgress/KVNProgress.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
#import <libPhoneNumber-iOS/NBNumberFormat.h>
#import <libPhoneNumber-iOS/NBMetadataCore.h>
#import <libPhoneNumber-iOS/NBPhoneMetaData.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>


@interface SCHConfirmMeetup ()

@property (strong, nonatomic) NSMutableArray *invities;
@property (copy, nonatomic) UIAlertViewCompletionBlock tapBlock;
@property (copy, nonatomic) UIAlertViewCompletionBlock willDismissBlock;
@property (copy, nonatomic) UIAlertViewCompletionBlock didDismissBlock;
@property (nonatomic, assign) BOOL proceessInvititation;
@property (nonatomic, strong) NBAsYouTypeFormatter *phoneFormatter;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NBPhoneNumberUtil *phoneUtil;



@end


@implementation SCHConfirmMeetup
AppDelegate *appDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.navigationItem.title = @"Invite";
       
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLocale *currentLocale = [NSLocale currentLocale];
    self.countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    
    self.phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    self.phoneFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:self.countryCode];
    
    
    
    
    self.proceessInvititation = NO;
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        
        self.automaticallyAdjustsScrollViewInsets=YES;
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.navigationController.view.backgroundColor = [UIColor lightGrayColor];
        self.navigationController.navigationBar.translucent = YES;
    }
    
    
    self.selectedNames = [[NSMutableArray alloc]init];
     appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.invities = [[NSMutableArray alloc]init];
    self.contactArray = [self getContactAuthorizationFromUser];

        // Do any additional setup after loading the view from its nib.
        if (![self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
            self.tokenInputTopSpace.constant = 0.0;
        }
        UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [infoButton addTarget:self action:@selector(onFieldInfoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.tokenInputView.fieldName = @"To:";
        //    self.tokenInputView.fieldView = infoButton;
        self.tokenInputView.placeholderText = @"Contact, phone or email";
    self.tokenInputView.accessoryView = nil;
        //    self.tokenInputView.accessoryView = [self contactAddButton];
//        self.tokenInputView.drawBottomBorder = YES;
//
//        [self.textView setText:@"set formated message with all information hare"];
        UIBarButtonItem *inviteButton = [[UIBarButtonItem alloc]
                                     initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(sendInvitation)];
    
        self.navigationItem.rightBarButtonItem =inviteButton;
    self.tokenInputView.delegate = self;
    
    [self.textView setAttributedText:[self meetupDetail]];
    
    
}


-(void)sendInvitation{
    
   // NSLog(@"string: %@", self.tokenInputView.text);
    
    if (self.tokenInputView.text.length > 0){
        self.proceessInvititation = YES;

        [self tokenInputView:self.tokenInputView tokenForText:self.tokenInputView.text];
    }
    if (self.tokenInputView.text.length == 0){
        self.proceessInvititation = NO;
        [self processInvitation];
    }
    
}

-(void) processInvitation{
    if (appDelegate.serverReachable){
        if ([self.saveAction isEqualToString:kcreateMeetup]){
            NSString *subject = [self.meetupInfo valueForKey:@"subject"];
            NSString *location = [self.meetupInfo valueForKey:@"location"];
            NSDate *startTime = [self.meetupInfo valueForKey:@"from_date"];
            NSDate *endTime = [self.meetupInfo valueForKey:@"to_date"];
            NSString *note = [self.meetupInfo valueForKey:@"note"];
            
            if ([[NSDate date] compare:endTime] != NSOrderedAscending){
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                        message:@"Meet-up time is already past."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles:nil];
                    [alertView show];
                });
                
                
                
                return;
                
                
            }
            
            
            if (self.invities.count > 0){
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SCHUtility showProgressWithMessage:SCHProgressMessageCreateMeetup];
                });
                
                
                
                SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
                dispatch_async(backgroundManager.SCHSerialQueue, ^{
                    [backgroundManager beginBackgroundTask];
                    NSDictionary *output = [SCHMeetingManager createMeetingWithSubject:subject
                                                                             organizer:appDelegate.user
                                                                              location:location
                                                                             startTime:startTime
                                                                               endTime:endTime
                                                                               invites:self.invities
                                                                                  note:note];
                    
                    if (output){
                        [SCHUtility createUserLocation:location];
                        
                        
                        [SCHSyncManager syncUserData:startTime];
                        
                        
                        self.meeting = [output valueForKey:@"meeting"];
                        NSArray *textList = [output valueForKey:@"nonUsetTextList"];
                        NSArray *emailList = [output valueForKey:@"nonUserEmailList"];
                        
                        if (textList.count > 0 && emailList.count > 0){
                            [SCHMeetingManager sendEmailAndText:self.meeting emailList:emailList textList:textList messageType:kNewMeetingNotification];
                        } else if (textList.count > 0 && emailList.count == 0){
                             [SCHMeetingManager sendTextMessage:self.meeting textList:textList messageType:kNewMeetingNotification];
                        } else if (textList.count == 0 && emailList.count > 0){
                            [SCHMeetingManager sendEmail:self.meeting emailList:emailList messageType:kNewMeetingNotification];
                        }
                        
                        
                    } else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                                message:@"Meet-up was not created. Try again."
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"Ok"
                                                                      otherButtonTitles:nil];
                            [alertView show];
                        });
                        
                        
                    }
                    
                    
                    
                    [KVNProgress dismissWithCompletion:^{
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            
                            
                            NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithObjects:self.navigationController.viewControllers[0], nil];
                            
                            UIViewController *firstVC = navigationArray[0];
                            
                            self.navigationController.viewControllers = navigationArray;
                            
                            
                            UITabBarController *tabBar =  firstVC.navigationController.tabBarController;
                            [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
                            
                            
                        });
                    }];
                    [backgroundManager endBackgroundTask];
                });
                
                
                
                
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                        message:@"Please add invities."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles:nil];
                    [alertView show];
                });
                
                
                
                return;
                
            }
            
            
        } else if ([self.saveAction isEqualToString:kaddInvites]){
            
            
            SCHConstants *constants = [SCHConstants sharedManager];
            [self.meeting fetch];
            if (self.invities.count > 0 && ![self.meeting.status isEqual:constants.SCHappointmentStatusCancelled]){
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SCHUtility showProgressWithMessage:SCHProgressMessageGeneric];
                });
                
                
                
                SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
                dispatch_async(backgroundManager.SCHSerialQueue, ^{
                    [backgroundManager beginBackgroundTask];
                    if ([self.meeting.organizer isEqual:appDelegate.user]){
                        NSDictionary *output =[SCHMeetingManager addInvities:self.invities toMeeting:self.meeting];
                        if (output){
                            self.meeting = [output valueForKey:@"meeting"];
                            NSArray *textList = [output valueForKey:@"nonUsetTextList"];
                            
                            [SCHSyncManager syncUserData:self.meeting.startTime];
                            
                            NSArray *emailList = [output valueForKey:@"nonUserEmailList"];
                            
                            if (textList.count > 0 && emailList.count > 0){
                                [SCHMeetingManager sendEmailAndText:self.meeting emailList:emailList textList:textList messageType:kNewMeetingNotification];
                            } else if (textList.count > 0 && emailList.count == 0){
                                [SCHMeetingManager sendTextMessage:self.meeting textList:textList messageType:kNewMeetingNotification];
                            } else if (textList.count == 0 && emailList.count > 0){
                                [SCHMeetingManager sendEmail:self.meeting emailList:emailList messageType:kNewMeetingNotification];
                            }

                            
                        } else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                                    message:@"Invites couldn't be added. Try again."
                                                                                   delegate:nil
                                                                          cancelButtonTitle:@"Ok"
                                                                          otherButtonTitles:nil];
                                [alertView show];
                            });
                            
                            
                        }
                        
                        
                        
                        
                        
                        
                        
                    } else{
                        if ([SCHMeetingManager changeMeetingRequest:self.meeting
                                                          requester:appDelegate.user
                                                             CRType:SCHMeetupCRTypeAddInvitee
                                                        newInvitees:self.invities
                                                   changedStartTime:nil
                                                     changedEndTime:nil
                                                    changedLocation:nil]){
                            [SCHSyncManager syncUserData:self.meeting.startTime];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                UIAlertView *nvavigationAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                                           message:[NSString localizedStringWithFormat:@"%@ has been notified.", self.meeting.organizer.preferredName]
                                                                                          delegate:nil
                                                                                 cancelButtonTitle:@"Ok"
                                                                                 otherButtonTitles:nil];
                                [nvavigationAlert show];
                                
                            });
                            
                        } else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                                    message:@"Invites couldn't be added. Try again."
                                                                                   delegate:nil
                                                                          cancelButtonTitle:@"Ok"
                                                                          otherButtonTitles:nil];
                                [alertView show];
                            });
                            
                            
                        }
                        
                        
                        
                    }
                    
                    
                    [self.meeting fetch];
                    
                    [KVNProgress dismissWithCompletion:^{
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            
                            /*
                             NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithObjects:self.navigationController.viewControllers[0], nil];
                             
                             UIViewController *firstVC;
                             
                             
                             if (navigationArray.count >0){
                             firstVC = navigationArray[0];
                             
                             }else{
                             firstVC = self;
                             }
                             
                             
                             self.navigationController.viewControllers = navigationArray;
                             
                             
                             UITabBarController *tabBar =  self.navigationController.tabBarController;
                             [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
                             
                             */
                            [self.navigationController popViewControllerAnimated:YES];
                            
                            
                        });
                        
                    }];
                    [backgroundManager endBackgroundTask];
                });
                
                
                
            } else{
                if (self.invities.count == 0){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                            message:@"Please add invities."
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    });
                    
                } else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                            message:@"Meet-up is already cancelled"
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    });
                    
                }
                
                
                return;
                
            }
            
            
        }
        
        
        
    }else{
        [SCHAlert internetOutageAlert];
        return;
    }
    

}

- (void)didReceiveMemoryWarning{
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:NO];
    self.navigationController.navigationBar.topItem.title = @"Back";
}

- (void)viewDidAppear:(BOOL)animated{
    if (!self.tokenInputView.editing) {
        [self.tokenInputView beginEditing];
    }
    [super viewDidAppear:animated];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
}
    
    
#pragma mark - CLTokenInputViewDelegate
    
- (void)tokenInputView:(CLTokenInputView *)view didChangeText:(NSString *)searchText{
    
        if ([searchText isEqualToString:@""]){
            self.filteredNames = nil;
            self.tableView.hidden = YES;
        } else {

            self.filteredNames = [SCHUtility searchContact:searchText contects:self.contactArray];
            //Remove all selected names
            if(self.filteredNames!=nil && [self.filteredNames count]>0)
            {
             self.tableView.hidden = NO;
            }
        }
        
        [self.tableView reloadData];
    }
    
- (void)tokenInputView:(CLTokenInputView *)view didAddToken:(CLToken *)token{
    
        NSString *name = token.displayText;
        NSDictionary *context = (NSDictionary *)token.context;
        [self.selectedNames addObject:name];
    NSDictionary *existingInvitee = [self findInvitee:context];
    if (!existingInvitee){
        [self.invities addObject:context];
    }
    
    
}


    
- (void)tokenInputView:(CLTokenInputView *)view didRemoveToken:(CLToken *)token
{
    
    
        NSString *name = token.displayText;
        [self.selectedNames removeObject:name];
    NSDictionary *context = (NSDictionary *)token.context;
    NSDictionary *existingInvitee = [self findInvitee:context];
    if (existingInvitee){
        [self.invities removeObject:existingInvitee];
    }
    
    
}

-(NSDictionary *)findInvitee:(NSDictionary *)invitee{
    
    NSDictionary *existingInvitee = nil;
    NSPredicate *DictPredicate = [NSPredicate predicateWithFormat:@" name = %@", [invitee valueForKey:@"name"]];
    NSArray *result = [self.invities filteredArrayUsingPredicate:DictPredicate];
    
    if (result.count > 0){
        existingInvitee = result[0];
    }
    
    return existingInvitee;
}


    
- (CLToken *)tokenInputView:(CLTokenInputView *)view tokenForText:(NSString *)text{
    
    
    NSMutableDictionary *invitee = [[NSMutableDictionary alloc] init];
    
        if (self.filteredNames.count > 0) {
//            NSString *matchingName = self.filteredNames[0];
            NSDictionary *contact = self.filteredNames[0];
            NSString *matchingName =[contact valueForKey:@"name"];
            [invitee setObject:[contact valueForKey:@"name"] forKey:@"name"];
            if ([contact valueForKey:@"phone"]){
                [invitee setObject:[contact valueForKey:@"phone"] forKey:@"phone"];
            }
            if ([contact valueForKey:@"email"]){
                [invitee setObject:[contact valueForKey:@"email"] forKey:@"email"];
            }

            
            
            CLToken *match = [[CLToken alloc] initWithDisplayText:matchingName context:invitee];
            //return match;
            [self.tokenInputView addToken:match];

        }else
        {
            BOOL valid = NO;
            NSString *phone = nil;
            NSString *email = nil;
            
            
            if ([self NSStringIsValidEmail:text]){
                email = text;
                valid = YES;
            } else{
                NSError *error = nil;
                NBPhoneNumber *nbNumber = [self.phoneUtil parse:text defaultRegion:self.countryCode error:&error];
                if (!error){
                    if ([self.phoneUtil isValidNumber:nbNumber]){
                        phone = [self.phoneUtil format:nbNumber
                                          numberFormat:NBEPhoneNumberFormatE164
                                                 error:&error];
                        valid = YES;
                        if (error){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                                    message:@"Please enter valid phone number or email."
                                                                                   delegate:nil
                                                                          cancelButtonTitle:@"Ok"
                                                                          otherButtonTitles:nil];
                                [alertView show];
                            });
                            
                        }
                        
                        
                    } else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                                message:@"Please enter valid phone number or email."
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"Ok"
                                                                      otherButtonTitles:nil];
                            [alertView show];
                        });
                        
                    }
                    
                } else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                            message:@"Please enter valid phone number or email."
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    });
                }
                
            }
            
            if (valid){
                NSString *message = [NSString stringWithFormat:@"Please Enter Name of %@",text];
                
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Counter Bean"
                                                             message:message
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"OK", nil];
                
                av.alertViewStyle = UIAlertViewStylePlainTextInput;
                
                av.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if (buttonIndex == alertView.firstOtherButtonIndex) {
                        if (phone.length > 0){
                            [invitee setObject:phone forKey:@"phone"];
                        }
                        if (email.length > 0){
                            [invitee setObject:email forKey:@"email"];
                        }
                        [invitee setObject:[[alertView textFieldAtIndex:0] text] forKey:@"name"];
                        CLToken *token = [[CLToken alloc] initWithDisplayText:[[alertView textFieldAtIndex:0] text] context:invitee];
                        [self.tokenInputView addToken:token];
                        
                        
                    } else if (buttonIndex == alertView.cancelButtonIndex) {
                        
                        if (phone.length){
                            NSString *phoneNumber = [SCHUtility phoneNumberFormate:phone];
                            [invitee setObject:phoneNumber forKey:@"phone"];
                            [invitee setObject:phoneNumber forKey:@"name"];
                            CLToken *token = [[CLToken alloc] initWithDisplayText:phoneNumber context:invitee];
                            [self.tokenInputView addToken:token];
                        }else{
                            [invitee setObject:email forKey:@"email"];
                            [invitee setObject:email forKey:@"name"];
                            CLToken *token = [[CLToken alloc] initWithDisplayText:email context:invitee];
                            [self.tokenInputView addToken:token];
                            
                        }
                        
                    }
                };
                
                av.shouldEnableFirstOtherButtonBlock = ^BOOL(UIAlertView *alertView) {
                    return ([[[alertView textFieldAtIndex:0] text] length] > 2);
                };
                
                [av show];
                
            }
            

        }
        return nil;
}


-(BOOL) NSStringIsValidEmail:(NSString *)checkString{
        
        BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
        NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
        NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
        NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        return [emailTest evaluateWithObject:checkString];
}
- (void)tokenInputViewDidEndEditing:(CLTokenInputView *)view{
    
       // NSLog(@"token input view did end editing: %@", view);
        view.accessoryView = nil;
        self.tableView.hidden = YES;
        
    }
    
- (void)tokenInputViewDidBeginEditing:(CLTokenInputView *)view{
    
        
       // NSLog(@"token input view did begin editing: %@", view);
        view.accessoryView = nil;
        [self.view removeConstraint:self.tableViewTopLayoutConstraint];
        self.tableViewTopLayoutConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        [self.view addConstraint:self.tableViewTopLayoutConstraint];
        
        [self.view layoutIfNeeded];
    }
    
    
#pragma mark - UITableViewDataSource
    
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
        if(self.filteredNames==nil)
            return 0;
        return self.filteredNames.count;
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        static NSString *simpleTableIdentifier = @"SimpleTableItem";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
        }
//        NSString *name = self.filteredNames[indexPath.row];
        NSDictionary *contact = [self.filteredNames objectAtIndex:indexPath.row];
    NSString *phone = nil;
    NSString *email = nil;

        NSString *name =[contact valueForKey:@"name"];
    if ([contact valueForKey:@"phone"]){
        phone  = [SCHUtility phoneNumberFormate:[contact valueForKey:@"phone"]];
        
    }
    if ([contact valueForKey:@"email"]){
        email = [contact valueForKey:@"email"];
    }
    cell.textLabel.text = name;
    
    /*
    if (phone.length > 0 && email.length > 0){
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@", [SCHUtility phoneNumberFormate:phone],email];
    }else if (phone.length > 0){
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [SCHUtility phoneNumberFormate:phone]];
    } else{
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", email];
    }
    */
    
    if ([[contact objectForKey:@"show"] isEqualToString:@"phone"]){
        if (phone.length > 0){
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [SCHUtility phoneNumberFormate:phone]];
        }
        
    } else{
        if (email.length > 0){
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", email];

        }
    }
    
    
        NSString *tokenText = [NSString stringWithFormat:@"%@(%@)",name,phone];
        
    
    
        if ([self.selectedNames containsObject:tokenText]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    
    
#pragma mark - UITableViewDelegate
    
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        NSDictionary *contact = [self.filteredNames objectAtIndex:indexPath.row];
        NSString *name =[contact valueForKey:@"name"];
        //NSString *phone = [contact valueForKey:@"phone"];
      
        NSString *tokenText = [NSString stringWithFormat:@"%@",name];
        NSMutableDictionary *invitee = [[NSMutableDictionary alloc] init];
    
    [invitee setObject:[contact valueForKey:@"name"] forKey:@"name"];
    if ([contact valueForKey:@"phone"]){
        [invitee setObject:[contact valueForKey:@"phone"] forKey:@"phone"];
    }
    if ([contact valueForKey:@"email"]){
        [invitee setObject:[contact valueForKey:@"email"] forKey:@"email"];
    }
    
        if(![self.selectedNames containsObject:tokenText])
        {
            CLToken *token = [[CLToken alloc] initWithDisplayText:tokenText context:invitee];
            if (self.tokenInputView.isEditing) {
                [self.tokenInputView addToken:token];
            }
        }
        
}
    
    
#pragma mark - Demo Button Actions
    
    
    - (void)onFieldInfoButtonTapped:(id)sender
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Field View Button"
                                                            message:@"This view is optional and can be a UIButton, etc."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    
    
    - (void)onAccessoryContactAddButtonTapped:(id)sender
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Accessory View Button"
                                                            message:@"This view is optional and can be a UIButton, etc."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    
#pragma mark - Demo Buttons
    - (UIButton *)contactAddButton
    {
        UIButton *contactAddButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [contactAddButton addTarget:self action:@selector(onAccessoryContactAddButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        return contactAddButton;
    }

#pragma mark - Contact API
-(NSMutableArray *)getContactAuthorizationFromUser{
    
    NSMutableArray *finalContactList = [[NSMutableArray alloc] init];
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                [finalContactList addObjectsFromArray:[SCHUtility getAllContacts]];
                
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        finalContactList = [[NSMutableArray alloc]initWithArray:[SCHUtility getAllContacts]];
        [self.tableView reloadData];
        // NSLog(@"Authorize");
    }
    else {
        // NSLog(@"UnAuthorize");
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
    }
    return finalContactList;
    
}



-(NSAttributedString *) meetupDetail{
    NSMutableAttributedString *meetupDetail = [[NSMutableAttributedString alloc] init];
    
    
    NSString *nextLine = @"\n";
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};

    
    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                                   NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    
    NSString *subject;
    NSString *location;
    NSDate *startTime;
    NSDate *endTime;
    NSString *note ;
    NSMutableString *meetingInvites;
    NSString *inviteeTitle;

    
    if (self.meetupInfo){
        subject = [self.meetupInfo valueForKey:@"subject"];
        location = [self.meetupInfo valueForKey:@"location"];
        startTime = [self.meetupInfo valueForKey:@"from_date"];
        endTime = [self.meetupInfo valueForKey:@"to_date"];
        note = [self.meetupInfo valueForKey:@"note"];
        
    }else{
        subject = self.meeting.subject;
        location = self.meeting.location;
        startTime = self.meeting.startTime;
        endTime = self.meeting.endTime;
        note = self.meeting.notes;
    }
    
    if (self.meeting){

        
        if (self.meeting.invites.count > 0){
            meetingInvites = [[NSMutableString alloc] init];
            int numberOfInvitees = (int)self.meeting.invites.count ;
            int counter = 0;
            for (NSDictionary *invitee in self.meeting.invites){
                if (numberOfInvitees == 1){
                    [meetingInvites appendString:[invitee valueForKey:SCHMeetupInviteeName]];
                    inviteeTitle = [NSString localizedStringWithFormat:@"Invitee"];
                } else{
                    inviteeTitle = [NSString localizedStringWithFormat:@"Invitees"];
                    if ((numberOfInvitees -counter) == 1){
                        [meetingInvites appendString:[NSString localizedStringWithFormat:@"%@ and ", [invitee valueForKey:SCHMeetupInviteeName]]];
                        
                    } else if (numberOfInvitees == counter){
                        [meetingInvites appendString:[invitee valueForKey:SCHMeetupInviteeName]];
                    } else{
                        [meetingInvites appendString:[NSString localizedStringWithFormat:@"%@, ", [invitee valueForKey:SCHMeetupInviteeName]]];
                    }
                }

                
            }
        }
        
    }

    
    [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:subject attributes:titleAttr]];
    [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    if (meetingInvites.length > 0){
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:inviteeTitle attributes:bodyAttr]];
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:meetingInvites attributes:bodyAttr]];
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        
        
    }
    
    
    NSString *meetupDate = [[SCHUtility dateFormatterForFullDate] stringFromDate:startTime];
    NSString *meetupStartTime = [[SCHUtility dateFormatterForShortTime] stringFromDate:startTime];
    NSString *meetupEndTime = [[SCHUtility dateFormatterForShortTime] stringFromDate:endTime];
    NSString *endTimeDateString = [SCHUtility getEndDate:endTime comparingStartDate:startTime];
    
    [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:meetupDate attributes:bodyAttr]];
    [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    if(endTimeDateString.length > 0){
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"from %@ to %@ %@", meetupStartTime, meetupEndTime, endTimeDateString] attributes:bodyAttr]];
        
    } else{
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"from %@ to %@", meetupStartTime, meetupEndTime] attributes:bodyAttr]];
    }
    
    
    
    [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"at %@", location] attributes:bodyAttr]];
    
    if(note.length > 0){
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [meetupDetail appendAttributedString:[[NSAttributedString alloc] initWithString:note attributes:bodyAttr]];
        
    }
    
    
    
    return meetupDetail;
}



@end
