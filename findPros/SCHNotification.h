//
//  SCHNotification.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 6/22/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"
#import "SCHLookup.h"
#import "SCHUser.h"

@interface SCHNotification : PFObject <PFSubclassing>

+ (NSString *)parseClassName;


@property(nonatomic, strong) SCHUser *user;
@property(nonatomic, strong) SCHLookup *notificationType;
@property(nonatomic, strong) NSString *notificationTitle;
@property(nonatomic, strong) NSString *message;
@property(nonatomic, strong) NSString *referenceObject;
@property(nonatomic, strong) NSString *referenceObjectType;
@property(nonatomic, assign) BOOL seen;


@end
