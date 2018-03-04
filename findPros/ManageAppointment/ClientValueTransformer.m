//
//  ClientValueTransformer.m
//   CounterBean Inc.
//
//  Created by Pratap Yadav on 10/6/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "ClientValueTransformer.h"

@implementation ClientValueTransformer
+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if (!value) return nil;
    NSDictionary * locationDict = (NSDictionary *)value;
    return [NSString stringWithFormat:@"%@",(NSString*)[locationDict valueForKey:@"name"]];
}

@end
