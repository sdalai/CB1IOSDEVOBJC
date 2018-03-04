//
//  SCHAvailabilityRefreshQueue.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 9/7/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAvailabilityRefreshQueue.h"

@implementation SCHAvailabilityRefreshQueue
static SCHAvailabilityRefreshQueue *availabilityRefreshQueue = nil;
+ (instancetype)sharedManager
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        availabilityRefreshQueue = [[SCHAvailabilityRefreshQueue alloc] init];
        availabilityRefreshQueue->_availabilityRefreshQueue = [[NSMutableArray alloc]init];

        
    });
    
    return availabilityRefreshQueue;
}

- (void) refresh{
    [self.availabilityRefreshQueue removeAllObjects];
}


@end
