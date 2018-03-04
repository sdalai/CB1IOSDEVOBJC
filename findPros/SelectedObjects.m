//
//  SelectedObjects.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 7/30/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SelectedObjects.h"


@implementation SelectedObjects

static SelectedObjects *selectedObjdManager = nil;

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        selectedObjdManager = [[[self class] alloc] init];
        selectedObjdManager->_selectedAppointment = [SCHAppointment object];
        selectedObjdManager->_selectedMeeting = [SCHMeeting object];

        
    });
    
    return selectedObjdManager;
}



@end
