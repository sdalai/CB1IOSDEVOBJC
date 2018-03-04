//
//  SCHUserFevoriteService.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 12/6/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHUserFevoriteService.h"

@implementation SCHUserFevoriteService

@dynamic user;
@dynamic service;



+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHUserFevoriteServiceClass;
}

@end
