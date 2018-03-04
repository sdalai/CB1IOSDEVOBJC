//
//  SCHUserFevoriteService.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 12/6/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"
#import "SCHService.h"
#import "SCHUser.h"

@interface SCHUserFevoriteService : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property(nonatomic, strong) SCHUser *user;
@property(nonatomic, strong) SCHService *service;

@end
