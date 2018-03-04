//
//  SCHManageBusinessViewController.h
//  CounterBean
//
//  Created by Sujit Dalai on 4/21/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCHManageBusinessViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *businessList;

-(void)loadData;


@end
