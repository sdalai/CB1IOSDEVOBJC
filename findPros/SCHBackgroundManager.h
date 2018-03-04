//
//  SCHBackgroundManager.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 5/4/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SCHBackgroundManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@property (nonatomic, strong) dispatch_queue_t SCHconcurrentQueue;
@property (nonatomic, strong) dispatch_queue_t SCHSerialQueue;


- (void) beginBackgroundTask;

- (void) endBackgroundTask;

@end
