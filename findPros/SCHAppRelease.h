//
//  SCHAppRelease.h
//  CounterBean
//
//  Created by Sujit Dalai on 1/9/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"
#import "SCHLookup.h"
@interface SCHAppRelease : PFObject <PFSubclassing>

+ (NSString *)parseClassName;


@property(nonatomic, strong) NSString *releaseNumber;
@property(nonatomic,strong) SCHLookup *deviceType;
@property(nonatomic, assign) BOOL  mandatoryRelease;
@property(nonatomic, strong) NSDate *releaseDate;
@property(nonatomic,strong) NSString *releaseNote;



@end
