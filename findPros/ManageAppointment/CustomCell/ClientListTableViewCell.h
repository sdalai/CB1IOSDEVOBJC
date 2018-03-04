//
//  ClientListTableViewCell.h
//   CounterBean Inc.
//
//  Created by Pratap Yadav on 10/5/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClientListTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *txtName;
@property (strong, nonatomic) IBOutlet UILabel *txtPhone;
@property (strong, nonatomic) IBOutlet UILabel *txtEmail;

/**
 *  The UIDatePicker displayed in the cell.
 */

@end
