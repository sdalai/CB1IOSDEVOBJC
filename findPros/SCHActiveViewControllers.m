//
//  SCHActiveViewControllers.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 10/25/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHActiveViewControllers.h"

@implementation SCHActiveViewControllers

static SCHActiveViewControllers *ViewControllerManager = nil;
+ (instancetype)sharedManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ViewControllerManager = [[[self class] alloc] init];
        ViewControllerManager->_viewControllers = [[NSMutableDictionary alloc] init];
        
        
    });
    
    return ViewControllerManager;
}




@end
