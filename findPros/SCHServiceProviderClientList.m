//
//  SCHServiceProviderClientList.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 9/22/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHServiceProviderClientList.h"

@implementation SCHServiceProviderClientList

@dynamic serviceProvider;
@dynamic client;
@dynamic nonUserClient;
@dynamic name;
@dynamic autoConfirmAppointment;
@dynamic service;



+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHServiceProviderClientListClass;
}


@end
