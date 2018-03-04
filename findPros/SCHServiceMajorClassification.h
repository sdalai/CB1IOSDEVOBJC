//
//  SCHServiceMajorClassification.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 11/26/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"

@interface SCHServiceMajorClassification : PFObject <PFSubclassing>
+ (NSString *)parseClassName;
@property (nonatomic, strong) NSString *majorClassification;
@property (nonatomic,assign) BOOL visible;


@end
