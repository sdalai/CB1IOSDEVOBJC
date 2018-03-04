//
//  SCHAvailabilityForAppointmentManager.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/13/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "SCHBackgroundManager.h"
#import "SCHService.h"
#import "SCHAppointment.h"
#import "SCHUser.h"

@interface SCHAvailabilityForAppointmentManager : NSObject

+(NSDictionary *)availabilityForAppointment:(SCHUser *) serviceProvider service:(SCHService *) service appointment:(SCHAppointment *) currentAppointment;

@end
