//
//  SCHEmailAndTextMessage.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 11/6/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHEmailAndTextMessage.h"
#import "SCHActiveViewControllers.h"



static NSString * const kcommunicationType = @"communicationType";
static NSString * const ksendEmail = @"email";
static NSString * const ksendText = @"Text";
static NSString * const kemailSubject = @"emailSubject";
static NSString * const kemailMessage = @"emailMessage";
static NSString * const kemailReceipients = @"emailReceipients";
static NSString * const ktextMessage = @"textMessage";
static NSString * const ktextReceipients = @"textReceipients";

@interface SCHEmailAndTextMessage ()

@property (strong, nonatomic) NSMutableArray *messageQueue;

@end


@implementation SCHEmailAndTextMessage

static SCHEmailAndTextMessage *sharedManager = nil;

+ (instancetype)sharedManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
        
        sharedManager->_emailAlertaddresses = nil;
        sharedManager->_emailAlertMessage = nil;
        sharedManager->_emailOrTextAlert = nil;
        sharedManager->_textAlert = nil;
        sharedManager->_textAlertMessage = nil;
        sharedManager->_textAlertPhoneNumbers = nil;
        sharedManager->_emailSubject = nil;
        sharedManager->_emailAlert = nil;
        sharedManager->_emailAndTextAlert = nil;
        sharedManager->_messageQueue = [[NSMutableArray alloc] init];
         
        
        
    });
    
    return sharedManager;
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    switch (result) {
            
        case MFMailComposeResultCancelled:
            break;
            
        case MFMailComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send email!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MFMailComposeResultSent:
            break;
        
        default:
            break;
    }
    UIViewController *presentingViewController = [self topMostController];
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self sendMessage];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            break;
            
        default:
            break;
    }
    UIViewController *presentingViewController = [self topMostController];
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self sendMessage];
}
- (void)showSMSToNumber:(NSArray *)phoneNumbers message:(NSString *)message {
    
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    NSArray *recipents = phoneNumbers;
    
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:recipents];
    [messageController setBody:message];
    
    // Present message view controller on screen
    UIViewController *presentingViewController = [self topMostController];
    if (presentingViewController){
        [presentingViewController presentViewController:messageController animated:YES completion:nil];
    }
    
}

- (void)showEmailToAddress:(NSArray *)emailAddresses message:(NSString *)message subject:(NSString *) subject {
    
    if(![MFMailComposeViewController canSendMail]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support email!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    NSArray *recipents = emailAddresses;
    
    
    MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
    [composeViewController setMailComposeDelegate:self];
    [composeViewController setToRecipients:recipents];
    [composeViewController setSubject:subject];
    [composeViewController setMessageBody:message isHTML:NO];
    
    // Present message view controller on screen
    UIViewController *presentingViewController = [self topMostController];
    
    [presentingViewController presentViewController:composeViewController animated:YES completion:nil];
}

- (UIViewController*) topMostController
{
   // UINavigationController *topController =  ((UINavigationController*)([UIApplication sharedApplication].delegate).window.rootViewController);
   // UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    SCHActiveViewControllers *activeVCs = [SCHActiveViewControllers sharedManager];
    
    if ([activeVCs.viewControllers valueForKey:@"scheduleVC"]){
        return [activeVCs.viewControllers valueForKey:@"scheduleVC"];
    } else{
        return nil;
    }
    
    
}


#pragma mark - Alert delegate  to send text or email to non User



- (void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if ([theAlert isEqual:self.emailOrTextAlert]){
        
        if(buttonIndex==1){
            NSDictionary *emailMessgae = @{kcommunicationType : ksendEmail,
                                           kemailSubject: self.emailSubject,
                                           kemailMessage: self.emailAlertMessage,
                                           kemailReceipients: self.emailAlertaddresses};
            [self.messageQueue addObject:emailMessgae];
            
            [self resetValues];

        } else if (buttonIndex == 2){

            NSDictionary *textMessage = @{kcommunicationType: ksendText,
                                          ktextMessage : self.textAlertMessage,
                                          ktextReceipients : self.textAlertPhoneNumbers};
            [self.messageQueue addObject:textMessage];
            [self resetValues];
            
        }
    } else if ([theAlert isEqual:self.textAlert]){
        if (buttonIndex == 1){

            NSDictionary *textMessage = @{kcommunicationType: ksendText,
                                          ktextMessage : self.textAlertMessage,
                                          ktextReceipients : self.textAlertPhoneNumbers};
            [self.messageQueue addObject:textMessage];
            [self resetValues];
            
            
        }
    } else if ([theAlert isEqual:self.emailAlert]){
        if (buttonIndex == 1){
            NSDictionary *emailMessgae = @{kcommunicationType : ksendEmail,
                                           kemailSubject: self.emailSubject,
                                           kemailMessage: self.emailAlertMessage,
                                           kemailReceipients: self.emailAlertaddresses};
            [self.messageQueue addObject:emailMessgae];
            
            [self resetValues];
        }
    }else if ([theAlert isEqual:self.emailAndTextAlert]){
        if (buttonIndex == 1){
            NSDictionary *textMessage = @{kcommunicationType: ksendText,
                                          ktextMessage : self.textAlertMessage,
                                          ktextReceipients : self.textAlertPhoneNumbers};
            [self.messageQueue addObject:textMessage];
            
            NSDictionary *emailMessgae = @{kcommunicationType : ksendEmail,
                                           kemailSubject: self.emailSubject,
                                           kemailMessage: self.emailAlertMessage,
                                           kemailReceipients: self.emailAlertaddresses};
            [self.messageQueue addObject:emailMessgae];
            
            [self resetValues];
            
        }
    }
    [self sendMessage];
    
    
}

-(void)sendMessage{
    if (self.messageQueue.count > 0){
        NSDictionary *message = self.messageQueue.firstObject;
        if ([[message valueForKey:kcommunicationType] isEqualToString:ksendText]){
            NSArray *textReceipients = (NSArray *)[message valueForKey:ktextReceipients];
            NSString *textMessage = [message valueForKey:ktextMessage];
            [self showSMSToNumber:textReceipients message:textMessage];
        } else if ([[message valueForKey:kcommunicationType] isEqualToString:ksendEmail]){
            NSArray *emailReceipients = (NSArray *)[message valueForKey:kemailReceipients];
            NSString *emailSubject = [message valueForKey:kemailSubject];
            NSString *emailMessage = [message valueForKey:kemailMessage];
            [self showEmailToAddress:emailReceipients message:emailMessage subject:emailSubject];
        }
        [self.messageQueue removeObject:message];
    }
}

-(void)resetValues{
    self.emailOrTextAlert = nil;
    self.textAlert = nil;
    self.emailAlert = nil;
    self.emailAndTextAlert = nil;
    self.textAlertMessage = nil;
    self.emailAlertMessage = nil;
    self.textAlertPhoneNumbers = nil;
    self.emailAlertaddresses = nil;
    self.emailSubject = nil;

}


@end
