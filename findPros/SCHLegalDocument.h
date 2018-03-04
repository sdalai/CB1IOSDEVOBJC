//
//  SCHLegalDocument.h
//  CounterBean
//
//  Created by Sujit Dalai on 1/5/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SCHLookup.h"
#import "SCHConstants.h"

@interface SCHLegalDocument : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property(nonatomic, strong) SCHLookup *documentType;
@property(nonatomic, strong) PFFile *document;
@property(nonatomic,assign) float documentVersion;
@property(nonatomic, assign) BOOL Active;
@property(nonatomic, strong) NSDate *EffectivityStartDate;
@property(nonatomic, strong) NSDate *EffectivityEndDate;




@end
