//
//  SCHUserFeedback.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 12/6/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHLookup.h"
#import "SCHConstants.h"
#import "SCHUser.h"

@interface SCHUserFeedback : PFObject <PFSubclassing>
+ (NSString *)parseClassName;

@property(nonatomic, strong) SCHUser *user;
@property(nonatomic, strong) SCHLookup *feedbackType;
@property(nonatomic, strong) NSString *feedbackTitle;
@property (nonatomic, strong) NSString *feedbackDetail;



@end
