//
//  SCHTimeBlock.h
//  CounterBean
//
//  Created by Sujit Dalai on 8/28/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>

@interface SCHTimeBlock : PFObject <PFSubclassing>

+ (NSString *)parseClassName;


@property (nonatomic, assign) int blockId;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;




@end
