//
//  SCHUserLocationTableViewController.h
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 11/5/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHLocationSelectorViewController.h"
#import "SCHUtility.h"
#import "SCHUserLocation.h"
#import "SPGooglePlacesAutocompleteDemoViewController.h"

@interface SCHUserLocationTableViewController : UITableViewController<UIAlertViewDelegate>
@property (strong, nonatomic) NSMutableArray *userAddress;
@property (strong, nonatomic) NSString *selectedAddress;

@end
