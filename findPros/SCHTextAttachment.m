//
//  SCHTextAttachment.m
//  CounterBean
//
//  Created by Sujit Dalai on 5/7/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHTextAttachment.h"

@implementation SCHTextAttachment

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex {
    CGFloat width = lineFrag.size.width;
    
    // Scale how you want
    float scalingFactor = 1.0;
    CGSize imageSize = [self.image size];
    if (width < imageSize.width)
        scalingFactor = width / imageSize.width;
    CGRect rect = CGRectMake(0, 0, imageSize.width * scalingFactor, imageSize.height * scalingFactor);
    
    return rect;
}

@end
