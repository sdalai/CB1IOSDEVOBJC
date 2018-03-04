//
//  SCHEditOfferingViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/24/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHEditOfferingViewController.h"
#import "SCHServiceOfferingDetailsViewController.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
#import <IODProfanityFilter/IODProfanityFilter.h>
@interface SCHEditOfferingViewController ()<CNPPopupControllerDelegate>

@property (nonatomic, strong) CNPPopupController *popupController;


@end

@implementation SCHEditOfferingViewController
XLFormRowDescriptor * rowStatus;
XLFormRowDescriptor * rowName;
XLFormRowDescriptor * rowStandurdDuration;
XLFormRowDescriptor * rowIsDurationFixed;
XLFormRowDescriptor * rowDescription;

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
  //  XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptorWithTitle:@"Edit Business Service"];
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHFieldTitleBusinessServices;
    [form addFormSection:section];
  
    // service status
    rowStatus = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingStatus rowType:XLFormRowDescriptorTypeBooleanSwitch title:SCHFieldTitleOfferingStatus];

    rowStatus.required = YES;
    [section addFormRow:rowStatus];
    
    //Service Offering Name
    
    
    rowName = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleService rowType:XLFormRowDescriptorTypeName title:SCHFieldTitleOfferingName];
    
    [rowName.cellConfigAtConfigure setObject:@"Example: Private Training" forKey:@"textField.placeholder"];
    
    [rowName.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [rowName.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    
    
    rowName.required = YES;
    [section addFormRow:rowName];
    
    //For Standard duration
    rowStandurdDuration = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingStanderdDuration rowType:XLFormRowDescriptorTypeSelectorPush title:SCHFieldTitleOfferingStanderdDuration];
    rowStandurdDuration.selectorTitle = SCHFieldTitleOfferingStanderdDuration;
    rowStandurdDuration.required = YES;
    rowStandurdDuration.selectorOptions = @[@"15 min", @"30 min", @"45 min", @"1 hour" , @"1 hour 15 min", @"1 hour 30 min", @"1 hour 45 min" , @"2 hours", @"2 hours 30 min",@"3 hours",@"3 hours 30 min",@"4 hours"];
    [rowStandurdDuration.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"detailTextLabel.textColor"];
     

    [section addFormRow:rowStandurdDuration];
    
    
    
    rowIsDurationFixed = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingDurationStatus rowType:XLFormRowDescriptorTypeBooleanSwitch title:SCHFieldTitleOfferingDurationStatus];

    rowIsDurationFixed.required = YES;
    [section addFormRow:rowIsDurationFixed];
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHFieldTitleOfferingDescripition;
    [form addFormSection:section];
    
    // Notes
    rowDescription = [XLFormRowDescriptor formRowDescriptorWithTag:@"serviceOfferingDescription" rowType:XLFormRowDescriptorTypeTextView];
    [rowDescription.cellConfigAtConfigure setObject:@"Business Service Description" forKey:@"textView.placeholder"];
    [rowDescription.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textView.textColor"];

    [section addFormRow:rowDescription];
    
    
    
    self.form = form;
    
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    
    if(self.selectedOffering.active)
    {
        rowStatus.value = @YES;
    }else{
        rowStatus.value = @NO;
        
    }
    
    rowName.value = self.selectedOffering.serviceOfferingName;
    rowStandurdDuration.value = [self getTimeStringFromDuration:self.selectedOffering.defaultDurationInMin];//[NSString stringWithFormat:@"%d",self.selectedOffering.defaultDurationInMin];
    
    if(self.selectedOffering.fixedDuration)
    {
        rowIsDurationFixed.value = @YES;
    }else{
        rowIsDurationFixed.value = @NO;
        
    }
    
    rowDescription.value = self.selectedOffering.detailDescription;
    
    
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
    self.navigationItem.title =@"Edit Offering";
    
}

-(int)getDurationValueByTimeString:(NSString *)offeringDuration
{
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
    
    return duration;
}


-(NSString *)getTimeStringFromDuration:(int )offeringDuration
{
    NSString * tiemString = @"";
    if (offeringDuration== 15){
        tiemString = @"15 min";
    } else if (offeringDuration== 30){
        tiemString = @"30 min";
    }else  if (offeringDuration== 45){
        tiemString = @"45 min";
        
    }else  if (offeringDuration==60){
        tiemString = @"1 hour";
        
    }else if (offeringDuration== 75){
        tiemString = @"1 hour 15 min";
    }else if (offeringDuration== 90){
        tiemString = @"1 hour 30 min";
    }else if (offeringDuration== 105){
        tiemString = @"1 hour 45 min";
    }else if (offeringDuration== 120){
        tiemString = @"2 hours";
    }else if (offeringDuration== 150){
        tiemString = @"2 hours 30 min";
    }else if (offeringDuration== 180){
        tiemString = @"3 hours";
    }else if (offeringDuration== 210){
        tiemString = @"3 hours 30 min";
    }else if (offeringDuration== 240){
        tiemString = @"4 hours";
    }
    
    return tiemString;
}


- (IBAction)saveOfferingOption:(id)sender {
    
    
    NSString *offeringName = (![[[self.formValues valueForKey:SCHFieldTitleService] displayText] isEqualToString:@""]) ? [[self.formValues valueForKey:SCHFieldTitleService] valueData] : nil;
    
    NSString *offeringDuration=(![[[self.formValues valueForKey:SCHFieldTitleOfferingStanderdDuration] displayText] isEqualToString:@""]) ? [[self.formValues valueForKey:SCHFieldTitleOfferingStanderdDuration] displayText] : @"";
    
    int duration  = [self getDurationValueByTimeString:offeringDuration];
    
    BOOL isFixedDuration= [rowIsDurationFixed.value boolValue];
    
    BOOL Status = [rowStatus.value boolValue];
    
    NSString *description  =  ([self.formValues valueForKey:@"serviceOfferingDescription"] != NULL) ? [[self.formValues valueForKey:@"serviceOfferingDescription"] displayText] : @"";
    
    if(offeringName && !(duration == 0))
    {
        self.selectedOffering.serviceOfferingName = [IODProfanityFilter stringByFilteringString:offeringName];
        self.selectedOffering.active = Status;
        self.selectedOffering.defaultDurationInMin = duration;
        self.selectedOffering.service = self.serviceObject;
        self.selectedOffering.fixedDuration = isFixedDuration;
        if (![description isEqualToString:@""]){
            self.selectedOffering.detailDescription = [IODProfanityFilter stringByFilteringString:description];
        }
        [self.selectedOffering pin];
        [self.selectedOffering save];
        
        
    
        
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                           message:@"Please provide all Details"
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        
    }
    
    
    
    
    
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // create the parent view that will hold header Label
    
    /*
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
     */
    
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
    UIFont *bodyFont = [SCHUtility getPreferredBodyFont];
    UIImage *calendarIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"calender.png"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *calendarAttachment = [SCHTextAttachment new];
    calendarAttachment.image = calendarIcon;
    
    UIImage *bookIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"book@1x.png"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *bookAttachment = [SCHTextAttachment new];
    bookAttachment.image = bookIcon;
    
    UIImage *notificationIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"notification@3x.png"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *notificationAttachment = [SCHTextAttachment new];
    notificationAttachment.image = notificationIcon;
    
    UIImage *businessIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"business@1x.png"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *businessAttachment = [SCHTextAttachment new];
    businessAttachment.image = businessIcon;
    
    
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] init];
    NSString *nextLine = @"\n";
    
    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    
    
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:calendarAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@": Event Calendar"] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:bookAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@": Setup Appointment with Professional or client"] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:notificationAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@": Your messages"] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:businessAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@": Register new business or manage existing business"] attributes:bodyAttr]];
    
    
    return content;
    
}




-(NSAttributedString *) helpTitle{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"CounterBean"]  attributes:titleAttr]];
    return title;
}



@end
