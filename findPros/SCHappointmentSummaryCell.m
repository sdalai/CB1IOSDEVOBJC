//
//  SCHappointmentSummaryCell.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/31/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHappointmentSummaryCell.h"
#import "SelectedObjects.h"
#import "SCHUtility.h"
#import "SCHMeeting.h"

NSString * const XLFormRowDescriptorTypeAppointmentSummary = @"XLFormRowDescriptorTypeAppointmentSummary";

static CGFloat rowHeight = 20;

@implementation SCHappointmentSummaryCell



+(void) load{
            [XLFormViewController.cellClassesForRowDescriptorTypes setObject:NSStringFromClass([SCHappointmentSummaryCell class]) forKey:XLFormRowDescriptorTypeAppointmentSummary];
    
}

- (void)configure

{
    [super configure];
    
   // NSLog(@"Configure");

    SelectedObjects *selectedObject = [SelectedObjects sharedManager];
    NSAttributedString *appointmentSummaryString = nil;
    if (selectedObject.selectedAppointment){
         appointmentSummaryString= [SCHUtility summaryForAppointmentedit:selectedObject.selectedAppointment];

    } else if (selectedObject.selectedMeeting){
        appointmentSummaryString = [SCHUtility summaryForMeetingEdit:selectedObject.selectedMeeting];
    }
    
    [self.SCHAppointmentSummaryTextView setAttributedText:appointmentSummaryString];
    
    rowHeight = [SCHUtility tableViewCellHeight:self.SCHAppointmentSummaryTextView width:self.SCHAppointmentSummaryTextView.bounds.size.width] + 10.0;
    
    
}

-(void) update{
    [super update];
}

+(CGFloat)formDescriptorCellHeightForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor {
    
    
    
    return rowHeight;
}


@end
