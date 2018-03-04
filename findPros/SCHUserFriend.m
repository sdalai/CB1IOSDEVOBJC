//
//  SCHUserFriend.m
//  CounterBean
//
//  Created by Sujit Dalai on 3/27/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHUserFriend.h"

@implementation SCHUserFriend

@dynamic user;
@dynamic CBFriend;
@dynamic facebookId;



+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHUserFriendClass;
}

@end
