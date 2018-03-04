//
//  SCHNonUserClient.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 10/2/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "PFObject.h"
#import "SCHConstants.h"

@interface SCHNonUserClient : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property(nonatomic, strong) NSString *email;
@property(nonatomic, strong) NSString *phoneNumber;


@end
