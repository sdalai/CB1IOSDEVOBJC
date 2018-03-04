//
//  SCHUserClientDetailViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/25/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//
#import "SCHUserClientDetailViewController.h"
#import "SCHUtility.h"
#import <Parse/Parse.h>
#import "MFSideMenu.h"
#import "AppDelegate.h"
#import "SCHUser.h"
@interface SCHUserClientDetailViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation SCHUserClientDetailViewController
NSString *name;
NSString *phoneno=@"";
NSString *email=@"";



XLFormRowDescriptor *phoneRow;
XLFormRowDescriptor *emailRow;
XLFormRowDescriptor *autoconfirmRow;
XLFormDescriptor * XLForm;
XLFormRowDescriptor * row;
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
    
    form = [XLFormDescriptor formDescriptorWithTitle:@""];
    XLForm = form;
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section = [XLFormSectionDescriptor formSection];
    section.title = @"Client Details";
    [form addFormSection:section];
    
    
    //Phone No
    phoneRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfilePhoneNumber rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfilePhoneNumber];
    [phoneRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [phoneRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [phoneRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [section addFormRow:phoneRow];
    
    //name
    emailRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleProfileEmail rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleProfileEmail];
    [emailRow.cellConfigAtConfigure setObject:[UIColor lightGrayColor] forKey:@"textField.textColor"];
    [emailRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    
    [emailRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [emailRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [section addFormRow:emailRow];
    

    //
    autoconfirmRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"Auto_confirm" rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Auto Confirm"];
    autoconfirmRow.required = YES;
    [section addFormRow:autoconfirmRow];
    
    self.form = form;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    SCHUser *user = nil;
    SCHNonUserClient *nonUser = nil;
    NSString *name = nil;
    user = self.client.client;
    nonUser = self.client.nonUserClient;
    name = self.client.name;;
    
        self.form.delegate = self;
    //SCHConstants *constants = [SCHConstants sharedManager];
    
    
    UIImage* image = [UIImage imageNamed:@"dummy_img.png"];
    self.userProfileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 130, 130)];
    [self.userProfileImageView setImage:image];
    self.userProfileImageView.layer.masksToBounds = YES;
    self.userProfileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.userProfileImageView.layer.cornerRadius = 6.0;
    self.userProfileImageView.layer.borderColor = [[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] CGColor];
    self.userProfileImageView.layer.borderWidth = 3.0;
    
    self.userProfileImageView.userInteractionEnabled = NO;
    
    PFFile *imageFile = user.profilePicture;
    
    if(imageFile!=nil)
        {
            [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(!error)
            {
                UIImage *profileImage = [UIImage imageWithData:data];
                self.userProfileImageView.image = profileImage;
            }
            }];
        }
    self.userProfileImageView.frame = CGRectMake( self.view.frame.size.width/2-65,20,130,130);
    [self.tableView addSubview:self.userProfileImageView];
    if (user){
        name = user.preferredName;
        NSString  *phoneNumber = user.phoneNumber;
        if(phoneNumber.length > 0){
            phoneno =[SCHUtility phoneNumberFormate:phoneNumber] ;
        }
        
        email = user.email;
        
    } else if (nonUser){
        if(nonUser.phoneNumber.length>0){
            phoneno = [SCHUtility phoneNumberFormate:nonUser.phoneNumber];
        }
        if(nonUser.email.length>0)
        {
            email = nonUser.email;
        }
    }
    
   // NSLog(@"Auto confirm: %d", self.client.autoConfirmAppointment);
    
    if (self.client.autoConfirmAppointment){
        autoconfirmRow.value = @1;
    } else{
        autoconfirmRow.value = @0;
    }
    
    
    phoneRow.value = phoneno;
    emailRow.value = email;
    
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
     self.navigationItem.title = name;
}



-(void)callClient {
    if (phoneno.length > 0){
        NSMutableCharacterSet *charSet = [NSMutableCharacterSet new];
        [charSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
        [charSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
        [charSet formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
        NSArray *arrayWithNumbers = [phoneno componentsSeparatedByCharactersInSet:charSet];
        NSString *numberStr = [arrayWithNumbers componentsJoinedByString:@""];
        NSString *cellNumber =[NSString stringWithFormat:@"tel:%@",numberStr];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cellNumber]];
        
    }
    
}

-(void)emailClient {
    if(email.length>0)
    {
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setSubject:@"CounterBean Contact"];
    [controller setToRecipients:[NSArray arrayWithObjects: email,nil]];
    [controller setMessageBody:@"Hello there." isHTML:NO];
        if (controller) {
            [self presentViewController:controller animated:YES completion:NULL];
        }
        
    }
}


- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        [self showMailSuccessAlert];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        NULL;
    }];
}

-(void)showMailSuccessAlert{
    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                       message:@"Your mail sent successfully"
                                                      delegate:self
                                             cancelButtonTitle:@"ok"
                                             otherButtonTitles:nil];
    [theAlert show];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue{
    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    
    [rowDescriptor.cellConfigAtConfigure setObject:[UIColor greenColor] forKey:@"textField.textColor"];
    
    if([rowDescriptor.tag isEqualToString:@"Auto_confirm"] && (newValue != oldValue))
    {
        BOOL autoConfirm = [[newValue valueData] boolValue];
        self.client.autoConfirmAppointment = autoConfirm;
        [self.client save];
        
    }
    
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
   if(indexPath.row==0)
   {
       [self callClient];
   }else if(indexPath.row==1)
   {
       [self emailClient];
   }
}

@end
