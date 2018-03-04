//
//  SCHServiceOfferingDetailsViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 8/13/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHServiceOfferingDetailsViewController.h"
#import "SCHServiceNewOfferingsViewController.h"
#import "SCHEditOfferingViewController.h"
@implementation SCHServiceOfferingDetailsViewController
XLFormRowDescriptor * statusRow;
XLFormRowDescriptor * standerdDurationRow;
XLFormRowDescriptor * isDurationFixedRow;
XLFormRowDescriptor * DescriptionRow;


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

    
    form = [XLFormDescriptor formDescriptorWithTitle:SCHSCreenTitleNewAppointment];
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHFieldTitleBusinessServices;
    [form addFormSection:section];
    
    //status
    // service status
    statusRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingStatus rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleOfferingStatus];
    [statusRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [statusRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [statusRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [section addFormRow:statusRow];


    
    //For Standard duration
    standerdDurationRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingStanderdDuration rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleOfferingStanderdDuration];
    [standerdDurationRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [standerdDurationRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [standerdDurationRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    

    [section addFormRow:standerdDurationRow];
    
    
    
    isDurationFixedRow = [XLFormRowDescriptor formRowDescriptorWithTag:SCHFieldTitleOfferingDurationStatus rowType:XLFormRowDescriptorTypeText title:SCHFieldTitleOfferingDurationStatus];
    [isDurationFixedRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textField.textColor"];
    [isDurationFixedRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [isDurationFixedRow.cellConfig setObject:@NO forKey:@"textField.enabled"];
    [section addFormRow:isDurationFixedRow];
    
    
    
    section = [XLFormSectionDescriptor formSection];
    section.title = SCHFieldTitleOfferingDescripition;
    [form addFormSection:section];
    
    
    // Notes
    DescriptionRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"serviceOfferingDescription" rowType:XLFormRowDescriptorTypeTextView];
    [DescriptionRow.cellConfig setObject:[SCHUtility deepGrayColor] forKey:@"textView.textColor"];
   // [DescriptionRow.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    [DescriptionRow.cellConfig setObject:@NO forKey:@"textView.editable"];
    //DescriptionRow.disabled = @YES;
    [section addFormRow:DescriptionRow];
    
    
    
    self.form = form;
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationItem setTitle:self.selectedOffering.serviceOfferingName];
    
    XLFormRowDescriptor *row = [self.form formRowWithTag:SCHFieldTitleOfferingStatus];
    if(self.selectedOffering.active)
    {
        row.value = @"Active";
    }else{
        row.value = @"Inactive";
    }
    [self updateFormRow:row];
    
    row = [self.form formRowWithTag:SCHFieldTitleOfferingStanderdDuration];
    row.value =[self getTimeStringFromDuration:self.selectedOffering.defaultDurationInMin];
    [self updateFormRow:row];
    
    
    row = [self.form formRowWithTag:SCHFieldTitleOfferingDurationStatus];
    if(self.selectedOffering.fixedDuration)
    {
        row.value = @"Yes";
    }else{
        row.value = @"No";
    }
    [self updateFormRow:row];
    
    row = [self.form formRowWithTag:@"serviceOfferingDescription"];
    row.value = self.selectedOffering.detailDescription;
    [self updateFormRow:row];
    

}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    UIEdgeInsets newContentInset = self.tableView.contentInset;
    newContentInset.top = self.topLayoutGuide.length;
    
}


#pragma overriding segue method
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{//appointmentDetailNew
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"EditOfferingSegue"]){
        SCHEditOfferingViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.serviceObject  =self.serviceObject;
        vcToPushTo.selectedOffering = self.selectedOffering;
    }
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







@end
