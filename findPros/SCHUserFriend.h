//
//  SCHUserFriend.h
//  CounterBean
//
//  Created by Sujit Dalai on 3/27/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"
#import "SCHUser.h"

@interface SCHUserFriend : PFObject <PFSubclassing>
+ (NSString *)parseClassName;

@property (nonatomic, strong) SCHUser *user;
@property (nonatomic, strong) SCHUser *CBFriend;
@property (nonatomic, strong) NSString *facebookId;

@end
