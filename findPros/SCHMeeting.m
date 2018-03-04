//
//  SCHMeeting.m
//  CounterBean
//
//  Created by Sujit Dalai on 6/19/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHMeeting.h"

@implementation SCHMeeting
@dynamic subject;
@dynamic organizer;
@dynamic status;
@dynamic expired;
@dynamic invites;
@dynamic attendees;
@dynamic location;
@dynamic startTime;
@dynamic endTime;
@dynamic notes;
@dynamic changeRequests;


+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHMeetingClass;
}


@end
