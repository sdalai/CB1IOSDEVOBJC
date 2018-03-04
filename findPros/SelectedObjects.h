//
//  SelectedObjects.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/30/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCHAppointment.h"
#import "SCHMeeting.h"

@interface SelectedObjects : NSObject

@property(nonatomic, strong) SCHAppointment *selectedAppointment;
@property(nonatomic, strong) SCHMeeting *selectedMeeting;


+ (instancetype) sharedManager;

@end
