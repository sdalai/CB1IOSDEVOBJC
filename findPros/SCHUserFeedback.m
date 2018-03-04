//
//  SCHUserFeedback.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 12/6/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHUserFeedback.h"

@implementation SCHUserFeedback

@dynamic user;
@dynamic feedbackType;
@dynamic feedbackTitle;
@dynamic feedbackDetail;



+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHUserFeedbackClass;
}


@end
