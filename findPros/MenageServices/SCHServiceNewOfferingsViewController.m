//
//  SCHServiceNewOfferingsViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 8/13/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHServiceNewOfferingsViewController.h"
#import "SCHUtility.h"
#import "SCHServiceOfferingViewController.h"
#import "SCHAddServiceViewController.h"
#import "SCHServiceDatailViewController.h"
#import "SCHUserServicesTableViewController.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
#import <IODProfanityFilter/IODProfanityFilter.h>
@interface SCHServiceNewOfferingsViewController ()<CNPPopupControllerDelegate>
@property (nonatomic, strong) CNPPopupController *popupController;


@property (nonatomic, strong) XLFormRowDescriptor *isFixedDuration;

@end
@implementation SCHServiceNewOfferingsViewController

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
    
    form = [XLFormDescriptor formDescriptorWithTitle:@"New Service Offering"];
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHFieldTitleBusinessServices;
    [form addFormSection:section];
    
    
    //Service Offering Name

    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleService rowType:XLFormRowDescriptorTypeName title:SCHFieldTitleOfferingName];
    
    [row.cellConfigAtConfigure setObject:@"e.g. Private Session" forKey:@"textField.placeholder"];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    

    row.required = YES;
    [section addFormRow:row];

    //For Standard duration
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingStanderdDuration rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleOfferingStanderdDuration];
    row.selectorTitle = SCHFieldTitleOfferingStanderdDuration;
    row.required = YES;
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
    row.selectorOptions = @[@"15 min", @"30 min", @"45 min", @"1 hour" , @"1 hour 15 min", @"1 hour 30 min", @"1 hour 45 min" , @"2 hours", @"2 hours 30 min",@"3 hours",@"3 hours 30 min",@"4 hours"];
    [section addFormRow:row];


    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingDurationStatus rowType:XLFormRowDescriptorTypeBooleanSwitch title:SCHFieldTitleOfferingDurationStatus];
    row.value = @NO;
    row.required = YES;
    self.isFixedDuration = row;
    [section addFormRow:row];
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHFieldTitleOfferingDescripition;
    [form addFormSection:section];
    
    // Notes
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"serviceOfferingDescription" rowType:XLFormRowDescriptorTypeTextView];
    [row.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textView.textColor"];
    [row.cellConfigAtConfigure setObject:@"Business Service Description" forKey:@"textView.placeholder"];
    [section addFormRow:row];
    
    
    
    self.form = form;
    
}



- (void)viewDidLoad {
    [super viewDidLoad];
        
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    UIEdgeInsets newContentInset = self.tableView.contentInset;
    newContentInset.top = self.topLayoutGuide.length;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title =@"New Business Offering";
    
}

#pragma overriding segue method
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{//appointmentDetailNew
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"addOfferingFinishSegue"]){
        SCHServiceDatailViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.serviceObject  =(SCHService *)sender;
        vcToPushTo.popUpAlertToPublishAvailability = YES;
        vcToPushTo.popUpAlertForPrivacyControl = YES;
        
    }
    
}


-(void)goServiceOffingList{
    
    if(_is_New_From_Service)
    {
    [self performSegueWithIdentifier:@"addOfferingFinishSegue" sender:self.serviceObject];
    
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (IBAction)saveOfferingOption:(id)sender {
    
    
    NSString *offeringName = (![[[self.formValues valueForKey:SCHFieldTitleService] displayText] isEqualToString:@""]) ? [[self.formValues valueForKey:SCHFieldTitleService] valueData] : nil;
    
    NSString *offeringDuration=(![[[self.formValues valueForKey:SCHFieldTitleOfferingStanderdDuration] displayText] isEqualToString:@""]) ? [[self.formValues valueForKey:SCHFieldTitleOfferingStanderdDuration] displayText] : @"";
    
    int duration  = 0;
    if ([offeringDuration isEqualToString:@"15 min"]){
        duration = 15;
    } else if ([offeringDuration isEqualToString:@"30 min"]){
        duration = 30;
    }else if ([offeringDuration isEqualToString:@"45 min"]){
        duration = 45;
        
    }else if ([offeringDuration isEqualToString:@"1 hour"]){
        duration = 60;
    }else if ([offeringDuration isEqualToString:@"1 hour 15 min"]){
        duration = 75;
    }else if ([offeringDuration isEqualToString:@"1 hour 30 min"]){
        duration = 90;
    }else if ([offeringDuration isEqualToString:@"1 hour 45 min"]){
        duration = 105;
    }else if ([offeringDuration isEqualToString:@"2 hours"]){
        duration = 120;
    }else if ([offeringDuration isEqualToString:@"2 hours 30 min"]){
        duration = 150;
    }else if ([offeringDuration isEqualToString:@"3 hours"]){
        duration = 180;
    }else if ([offeringDuration isEqualToString:@"3 hours 30 min"]){
        duration = 210;
    }else if ([offeringDuration isEqualToString:@"4 hours"]){
        duration = 240;
    }
    

    BOOL isFixedDuration= [self.isFixedDuration.value boolValue];
    
    NSString *description  =  ([self.formValues valueForKey:@"serviceOfferingDescription"] != NULL) ? [[self.formValues valueForKey:@"serviceOfferingDescription"] displayText] : @"";
    
   // NSString *description = [self.formValues valueForKey:SCHFieldTitleOfferingDescripition] ;//isEqual:[NSNull null]] && (![[self.formValues valueForKey:SCHFieldTitleOfferingDescripition] isEqualToString:@""]) ) ? [self.formValues valueForKey:SCHFieldTitleOfferingDescripition] : @"";
    
    
    if(offeringName && !(duration == 0))
    {
        SCHServiceOffering *newOffering = [SCHServiceOffering object];
        newOffering.serviceOfferingName = [IODProfanityFilter stringByFilteringString:offeringName];
        newOffering.active = YES;
        newOffering.defaultDurationInMin = duration;
        newOffering.service = self.serviceObject;
        newOffering.fixedDuration = isFixedDuration;
        [SCHUtility setPublicAllROACL:newOffering.ACL];

        if (![description isEqualToString:@""]){
            newOffering.detailDescription = [IODProfanityFilter stringByFilteringString:description];
        }
        
      
        [SCHUtility saveServieAndOffering:self.serviceObject serviceOffering:newOffering];
        

        
        
        
        
        
        
    }
    else
    {
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                           message:@"Please Provide all Details"
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        
        return;
  
    }
        
    [self goServiceOffingList];
    

}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // create the parent view that will hold header Label
    if(section==0){
        UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
        
        UILabel *lblStr = [[UILabel alloc]initWithFrame:CGRectMake(12, 32, 150, 20)];
        lblStr.text = @"OFFERING";
        lblStr.textColor=[UIColor grayColor];
        lblStr.font = [UIFont systemFontOfSize:13];
        [customView addSubview:lblStr];
        
        // create the button object
        UIButton *headerBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-150, 32,150-10 , 20.0)];
        headerBtn.backgroundColor = [UIColor clearColor];
        headerBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [headerBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        headerBtn.titleLabel.font = [SCHUtility getPreferredSubtitleFont];//[UIFont boldSystemFontOfSize:13];
        [headerBtn setTitle:@"Help" forState:UIControlStateNormal];
        [headerBtn addTarget:self action:@selector(helpAction) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:headerBtn];
        return customView;
        
    }
    
    return nil;
}


-(void)helpAction{
    [self showPopupWithStyle:CNPPopupStyleCentered];
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)showPopupWithStyle:(CNPPopupStyle)popupStyle {
    
    //Define Button
    CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [button setTitle:@"OK" forState:UIControlStateNormal];
    button.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    button.layer.cornerRadius = 4;
    button.selectionHandler = ^(CNPPopupButton *button){
        [self.popupController dismissPopupControllerAnimated:YES];
        NSLog(@"Block for button: %@", button.titleLabel.text);
    };
    // Define View
    
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
    
    
    /*
     NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
     paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
     paragraphStyle.alignment = NSTextAlignmentCenter;
     
     NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"It's A Popup!" attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:24], NSParagraphStyleAttributeName : paragraphStyle}];
     NSAttributedString *lineOne = [[NSAttributedString alloc] initWithString:@"You can add text and images" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSParagraphStyleAttributeName : paragraphStyle}];
     NSAttributedString *lineTwo = [[NSAttributedString alloc] initWithString:@"With style, using NSAttributedString" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSForegroundColorAttributeName : [UIColor colorWithRed:0.46 green:0.8 blue:1.0 alpha:1.0], NSParagraphStyleAttributeName : paragraphStyle}];
     
     */
    
    
    
    
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = [self helpTitle];
    
    
    // UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"info"]];
    
    
    
    // customView.backgroundColor = [UIColor lightGrayColor];
    
    
    
    [textView setEditable:NO];
    [textView setSelectable:NO];
    [textView setAttributedText:[self helpContent]];
    [customView addSubview:textView];
    
    self.popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, customView, button]];
    self.popupController.theme = [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle = popupStyle;
    self.popupController.theme.cornerRadius = 20;
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];
}

-(NSAttributedString *) helpContent{
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] init];
    NSString *nextLine = @"\n";
    
    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    NSDictionary *blueBodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[UIColor blueColor]};
    
    
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Enter "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"offering Name"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"."] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Enter "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Service Duration"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" and chose if service duration if fixed or flexible."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Give detail description of your offering."] attributes:bodyAttr]];
    
    
    return content;
    
}




-(NSAttributedString *) helpTitle{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Business Offering"]  attributes:titleAttr]];
    return title;
}



@end
