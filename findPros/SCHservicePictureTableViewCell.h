//
//  SCHservicePictureTableViewCell.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 3/22/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import"XLFormBaseCell.h"

extern NSString * const XLFormRowDescriptorTypeProfielPicture;

@interface SCHservicePictureTableViewCell :  XLFormBaseCell
@property (weak, nonatomic) IBOutlet UIImageView *ImageView;
@property (weak, nonatomic) IBOutlet UILabel *displayName;

@end
