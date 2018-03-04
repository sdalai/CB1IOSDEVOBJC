//
//  SCHappointmentSummaryCell.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/31/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import"XLFormBaseCell.h"

extern NSString * const XLFormRowDescriptorTypeAppointmentSummary;

@interface SCHappointmentSummaryCell : XLFormBaseCell

@property (weak, nonatomic) IBOutlet UITextView *SCHAppointmentSummaryTextView;




@end
