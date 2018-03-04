//
//  SCHInvitiesListViewController.h
//  CounterBean
//
//  Created by Pratap Yadav on 24/06/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFSideMenu.h"
#import "SCHMeeting.h"
#import "SCHMeetingManager.h"
@interface SCHInvitiesListViewController : UITableViewController
@property (nonatomic, strong) NSMutableArray *invitiesArray;
@property (nonatomic, strong) SCHMeeting *meeting;


@property CGFloat rowheight;

@end
