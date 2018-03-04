//
//  SCHEmailAndTextMessage.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 11/6/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>


@interface SCHEmailAndTextMessage : NSObject <MFMessageComposeViewControllerDelegate, UIAlertViewDelegate,MFMailComposeViewControllerDelegate>

+ (instancetype) sharedManager;
- (void)showSMSToNumber:(NSArray *)phoneNumbers message:(NSString *)message;
- (void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex;
-(void)resetValues;
@property (nonatomic, strong) UIAlertView *emailOrTextAlert;
@property (nonatomic, strong) UIAlertView *textAlert;
@property (nonatomic, strong) UIAlertView *emailAlert;
@property (nonatomic, strong) UIAlertView *emailAndTextAlert;
@property (nonatomic, strong) NSString *textAlertMessage;
@property (nonatomic, strong) NSString *emailAlertMessage;
@property (nonatomic, strong) NSArray *textAlertPhoneNumbers;
@property (nonatomic, strong) NSArray *emailAlertaddresses;
@property (nonatomic, strong) NSString *emailSubject;

@end
