//
//  SCHServiceProviderClientList.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 9/22/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "PFObject.h"
#import "SCHConstants.h"
#import "SCHNonUserClient.h"
#import "SCHService.h"
#import "SCHUser.h"

@interface SCHServiceProviderClientList : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property (nonatomic, strong) SCHUser *serviceProvider;
@property(nonatomic, strong)  SCHUser *client;
@property(nonatomic, strong)  SCHNonUserClient *nonUserClient;
@property (nonatomic, strong) NSString *name;
@property(nonatomic, assign) BOOL autoConfirmAppointment;
@property(nonatomic, strong) SCHService *service;


@end
