//
//  SCHConfirmGroupAppointment.h
//  CounterBean
//
//  Created by Pratap Yadav on 17/06/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLTokenInputView.h"
#import "SCHMeeting.h"

static NSString * const kaddInvites = @"addInvites";
static NSString * const kcreateMeetup = @"createMeetup";



@interface SCHConfirmMeetup :UIViewController <CLTokenInputViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) NSArray *names;
@property (strong, nonatomic) NSArray *filteredNames;

@property (strong, nonatomic) NSMutableArray *selectedNames;
@property (strong, nonatomic) NSArray *contactArray;
@property (strong, nonatomic) NSDictionary *meetupInfo;
@property (strong, nonatomic) SCHMeeting *meeting;
@property (strong, nonatomic) NSString *saveAction;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tokenInputTopSpace;
@property (strong, nonatomic) IBOutlet CLTokenInputView *tokenInputView;
//@property (strong, nonatomic) IBOutlet CLTokenInputView *secondTokenInputView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *TokenInputViewHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewTopLayoutContraint;
@property (weak, nonatomic) IBOutlet UITextView *textView;



@end
