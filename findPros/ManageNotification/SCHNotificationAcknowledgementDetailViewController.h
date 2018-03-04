//
//  SCHNotificationAcknowledgementDetailViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/1/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHNotification.h"
@interface SCHNotificationAcknowledgementDetailViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextView *txtMessage;
@property(nonatomic,strong) SCHNotification *notification;
@end
