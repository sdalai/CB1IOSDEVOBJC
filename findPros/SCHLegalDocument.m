//
//  SCHLegalDocument.m
//  CounterBean
//
//  Created by Sujit Dalai on 1/5/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHLegalDocument.h"

@implementation SCHLegalDocument

@dynamic documentType;
@dynamic document;
@dynamic documentVersion;
@dynamic Active;
@dynamic EffectivityStartDate;
@dynamic EffectivityEndDate;


+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return SCHLegalDocumentClass;
}


@end
