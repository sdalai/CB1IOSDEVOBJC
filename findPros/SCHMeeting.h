//
//  SCHMeeting.h
//  CounterBean
//
//  Created by Sujit Dalai on 6/19/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"
#import "SCHUser.h"
#import "SCHLookup.h"

@interface SCHMeeting : PFObject <PFSubclassing>
+ (NSString *)parseClassName;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) SCHUser *organizer;
@property (nonatomic, strong) SCHLookup *status;
@property (nonatomic, assign) BOOL expired;
@property (nonatomic, strong) NSArray *attendees;
@property (nonatomic, strong) NSArray *invites;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, strong) NSString *notes;
@property (nonatomic, strong) NSArray *changeRequests;


@end
