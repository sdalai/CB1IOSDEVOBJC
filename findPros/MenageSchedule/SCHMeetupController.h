//
//  SCHUserGroupAppointmentController.h
//  CounterBean
//
//  Created by Pratap Yadav on 16/06/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XLForm.h"
@interface SCHMeetupController : XLFormViewController
@property (nonatomic) NSTimeInterval minimumDuration;
@property (nonatomic) NSTimeInterval maximumDuration;
@property (nonatomic) NSTimeInterval currentDuration;
@property (nonatomic, strong)XLFormRowDescriptor *endTimeRow;

@end
