//
//  SCHServiceClassification.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/20/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHConstants.h"
#import "SCHServiceMajorClassification.h"

@interface SCHServiceClassification : PFObject <PFSubclassing>
+ (NSString *)parseClassName;

@property (strong, nonatomic) SCHServiceMajorClassification *majorClassification;
@property (nonatomic, strong) NSString *serviceTypeName;
@property (nonatomic, strong) PFFile *backgroundPicture;
@property (nonatomic, assign) BOOL visible;

@end
