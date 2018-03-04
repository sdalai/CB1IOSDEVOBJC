//
//  SCHEditMeetupViewController.h
//  CounterBean
//
//  Created by Sujit Dalai on 7/2/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <XLForm/XLForm.h>
#import "SCHMeeting.h"
#import "SCHMeetingManager.h"

@interface SCHEditMeetupViewController : XLFormViewController<XLFormViewControllerDelegate>

@property(nonatomic, strong) SCHMeeting *meeting;

@end
