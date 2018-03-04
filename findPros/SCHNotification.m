//
//  SCHNotification.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 6/22/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHNotification.h"

@implementation SCHNotification

@dynamic user;
@dynamic notificationType;
@dynamic notificationTitle;
@dynamic message;
@dynamic referenceObject;
@dynamic referenceObjectType;
@dynamic seen;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHNotificationClass;
}


@end
