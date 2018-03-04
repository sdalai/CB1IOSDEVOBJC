//
//  SCHActiveViewControllers.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 10/25/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCHActiveViewControllers : NSObject

@property(nonatomic, strong) NSMutableDictionary *viewControllers;

+ (instancetype) sharedManager;

@end
