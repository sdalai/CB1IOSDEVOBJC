//
//  SCHBackgroundManager.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 5/4/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHBackgroundManager.h"


@implementation SCHBackgroundManager
static SCHBackgroundManager *sharedBackgroundManager = nil;
+ (instancetype)sharedManager
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBackgroundManager = [[SCHBackgroundManager alloc] init];
        sharedBackgroundManager->_SCHconcurrentQueue = dispatch_queue_create("SCH concurrent Queue", DISPATCH_QUEUE_CONCURRENT);
        sharedBackgroundManager->_SCHSerialQueue = dispatch_queue_create("SCH Serial Queue", DISPATCH_QUEUE_SERIAL);
        
    });
    
    return sharedBackgroundManager;
}

- (void) beginBackgroundTask
{
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void) endBackgroundTask
{
    [[UIApplication sharedApplication] endBackgroundTask: self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
}


@end
