//
//  SCHServiceNewOfferingsViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 8/13/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
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

@interface SCHServiceNewOfferingsViewController : XLFormViewController
@property (strong,nonatomic) SCHService* serviceObject;
@property (nonatomic, assign) BOOL is_New_From_Service;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveOffering;
- (IBAction)saveOfferingOption:(id)sender;

@end
