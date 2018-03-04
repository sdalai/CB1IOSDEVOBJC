//
//  SCHAddServiceDescription.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/22/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHAddServiceDescription.h"

NSString * const XLFormRowDescriptorTypeServiceDescription = @"XLFormRowDescriptorTypeServiceDescription";

@implementation SCHAddServiceDescription

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+(void)load {
    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:[SCHAddServiceDescription class] forKey:XLFormRowDescriptorTypeServiceDescription];
}

+(CGFloat)formDescriptorCellHeightForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor {
    return 180.0f;
}

@end
