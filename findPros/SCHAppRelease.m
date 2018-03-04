//
//  SCHAppRelease.m
//  CounterBean
//
//  Created by Sujit Dalai on 1/9/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHAppRelease.h"


@implementation SCHAppRelease

@dynamic releaseNumber;
@dynamic deviceType;
@dynamic mandatoryRelease;
@dynamic releaseDate;
@dynamic releaseNote;


+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHAppReleaseClass;
}
@end
