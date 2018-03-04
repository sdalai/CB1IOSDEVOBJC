//
//  SCHLookup.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 4/2/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>


@interface SCHLookup : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property (nonatomic, strong) NSString *lookupType;
@property (nonatomic, strong) NSString *lookupCode;
@property (nonatomic, strong) NSString *lookupText;

@end
