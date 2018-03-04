//
//  SCHAvailabilityRefreshQueue.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 9/7/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCHAvailabilityRefreshQueue : NSObject

+ (instancetype)sharedManager;

- (void) refresh;

@property(nonatomic, strong) NSMutableArray  *availabilityRefreshQueue;



@end
