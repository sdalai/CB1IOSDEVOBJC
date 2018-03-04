//
//  SCHservicePictureTableViewCell.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/22/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHservicePictureTableViewCell.h"

NSString * const XLFormRowDescriptorTypeProfielPicture = @"XLFormRowDescriptorTypeProfielPicture";

@implementation SCHservicePictureTableViewCell

@synthesize rowDescriptor;

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
+(void) load {
    
        [XLFormViewController.cellClassesForRowDescriptorTypes setObject:NSStringFromClass([SCHservicePictureTableViewCell class]) forKey:XLFormRowDescriptorTypeProfielPicture];
}

-(void) configure {
    [super configure];
    
    
    
    
}
-(void) update {
    [super update];
    
}


@end
