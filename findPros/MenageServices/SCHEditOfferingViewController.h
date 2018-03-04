//
//  SCHEditOfferingViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/24/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHService.h"
#import "XLForm.h"
#import <Parse/Parse.h>
#import "SCHService.h"
#import "SCHServiceOffering.h"
#import "SCHUtility.h"
#import "SCHAppointmentManager.h"
#import "SCHBackgroundManager.h"
#import "SCHAppointmentSeries.h"
#import "SPGooglePlacesAutocompleteDemoViewController.h"
#import "LocationValueTrasformer.h"
#import "SCHSyncManager.h"

@interface SCHEditOfferingViewController : XLFormViewController
@property (strong,nonatomic) SCHService* serviceObject;
@property (strong,nonatomic) SCHServiceOffering* selectedOffering;


@end
