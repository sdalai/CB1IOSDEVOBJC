//
//  SCHTimeBlock.m
//  CounterBean
//
//  Created by Sujit Dalai on 8/28/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHTimeBlock.h"

@implementation SCHTimeBlock

@dynamic blockId;
@dynamic startTime;
@dynamic endTime;



+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"SCHTimeBlock";
}


@end
