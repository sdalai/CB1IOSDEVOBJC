//
//  SCHLocationSelectorViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 9/28/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XLForm.h"
#import "SCHAppointment.h"
#import "SPGooglePlacesAutocompleteDemoViewController.h"
@interface SCHLocationSelectorViewController : UITableViewController<XLFormRowDescriptorViewController>
@property (strong, nonatomic) NSMutableArray *userAddress;
@property (strong, nonatomic) NSString *selectedAddress;
@property (assign) BOOL isUserLocation;
@property (strong, nonatomic) SCHAppointment *appointment;
@end
