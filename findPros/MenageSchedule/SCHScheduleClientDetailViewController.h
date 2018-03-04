//
//  SCHScheduleClientDetailViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/19/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "XLForm.h"
#import "SCHAppointment.h"
#import "SCHAppointmentSeries.h"
@interface SCHScheduleClientDetailViewController : XLFormViewController
@property (strong, nonatomic) NSString *screenTitle;
@property (strong, nonatomic) NSDictionary *clientInfo;
@property (nonatomic,strong)UIImageView* userProfileImageView;
@property (nonatomic,strong)SCHAppointment *appointment;
@property (nonatomic,strong) SCHAppointmentSeries *series;

@end
