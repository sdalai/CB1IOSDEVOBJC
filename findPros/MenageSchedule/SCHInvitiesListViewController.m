//
//  SCHInvitiesListViewController.m
//  CounterBean
//
//  Created by Pratap Yadav on 24/06/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHInvitiesListViewController.h"
#import "SCHUtility.h"
#import "SCHUser.h"
#import "SCHNonUserClient.h"
#import "SCHConstants.h"
#import "SCHScheduleClientDetailViewController.h"
#import "AppDelegate.h"
#import "SCHSyncManager.h"
#import "SCHConfirmMeetup.h"
#import <KVNProgress/KVNProgress.h>

@implementation SCHInvitiesListViewController
bool isUserOrganizer;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    double delayInSeconds = 0.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appDelegate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });

    
    self.tableView.tableFooterView = [[UIView alloc]init];
    
//    NSLog([NSString stringWithFormat:@"invitied %d",self.invitiesArray.count]);
    isUserOrganizer = true;
    
    SCHConstants *constants = [SCHConstants sharedManager];
    
    
    if(![self.meeting.status isEqual:constants.SCHappointmentStatusCancelled]&& appDelegate.serverReachable)
    {
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                  initWithTitle:@"Add Invities" style:UIBarButtonItemStyleDone target:self action:@selector(addInvites)];
    self.navigationItem.rightBarButtonItem = addButton;
    }
    
    
}

-(void)internetConnectionChanged{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appDelegate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            self.navigationItem.rightBarButtonItem = nil;
            
        } else {
            [self.navigationItem setPrompt:nil];
            SCHConstants *constants = [SCHConstants sharedManager];
            if(![self.meeting.status isEqual:constants.SCHappointmentStatusCancelled])
            {
                UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Add Invities" style:UIBarButtonItemStyleDone target:self action:@selector(addInvites)];
                self.navigationItem.rightBarButtonItem = addButton;
            }

            
        }
    });
    
    
    
    
}



- (UIBarButtonItem *)backBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(backButtonPressed:)];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Attendees";
    [self.menuContainerViewController setPanMode:MFSideMenuPanModeNone];
    
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self buildAttendeeList];
    
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.menuContainerViewController setPanMode:MFSideMenuPanModeDefault];
}



-(void)addInvites{
    
    SCHConfirmMeetup *tokenVC = [[SCHConfirmMeetup alloc] initWithNibName:@"SCHConfirmMeetup" bundle:nil];
    tokenVC.meeting = self.meeting;
    tokenVC.saveAction =kaddInvites;
    [self.navigationController pushViewController:tokenVC animated:YES];
    
}
#pragma mark - Table view data source

/*
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  30;
}
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        return self.invitiesArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    static NSString *CellIdentifier = @"clientCell";
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    /*
    
    UIImageView *profilePic = (UIImageView*)[cell.contentView viewWithTag:1];
    profilePic.layer.masksToBounds = YES;
    profilePic.contentMode = UIViewContentModeScaleAspectFill;
    profilePic.layer.cornerRadius = 6.0;
    profilePic.layer.borderColor = [[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] CGColor];
    profilePic.layer.borderWidth = 3.0;
    UITextView *txtMessage = (UITextView*)[cell.contentView viewWithTag:2];
    txtMessage.userInteractionEnabled = false;
     
     */
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    
    UIFontDescriptor *subtitleFontDescriptor = [[SCHUtility getPreferredSubtitleFont] fontDescriptor];
    UIFontDescriptorSymbolicTraits traits = subtitleFontDescriptor.symbolicTraits;
    traits |= UIFontDescriptorTraitItalic;
    
    UIFontDescriptor *statusFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:traits];
    
    UIFont *statusFont = [UIFont fontWithDescriptor:statusFontDescriptor size:0];
    
    
    NSDictionary *subtittleAttrGray = @{NSFontAttributeName : statusFont,
                                    NSForegroundColorAttributeName : [SCHUtility deepGrayColor]};
    NSDictionary *subtittleAttrGreen = @{NSFontAttributeName : statusFont,
                                    NSForegroundColorAttributeName : [SCHUtility greenColor]};
    
    NSDictionary *subtittleAttrRed = @{NSFontAttributeName : statusFont,
                                    NSForegroundColorAttributeName : [SCHUtility brightOrangeColor]};
    
    NSDictionary *subTitleAttrBlueColor = @{NSFontAttributeName : statusFont,
                                         NSForegroundColorAttributeName : [UIColor blueColor]};
    

   // [txtMessage setEditable:false];
   // [txtMessage setSelectable:false];
     

    
    NSString *name=@"";
    NSString *email=@"";
    NSString *phone=@"";
    UIImage *image;
    
    NSDictionary *contact = [self.invitiesArray objectAtIndex:indexPath.row];
    
    
    
    
    if ([[contact valueForKey:SCHMeetupInviteeUser] isKindOfClass:[SCHNonUserClient class]]){
        SCHNonUserClient *nonUser = (SCHNonUserClient *)[contact valueForKey:SCHMeetupInviteeUser];
        name =[contact valueForKey:SCHMeetupInviteeName];
        phone = nonUser.phoneNumber;
        email = nonUser.email;
        image= [UIImage imageNamed:@"dummy_img"];
       // profilePic.image  = image;
    } else{
        SCHUser *user = (SCHUser *)[contact valueForKey:SCHMeetupInviteeUser];
        if ([user isEqual:appDelegate.user]){
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.backgroundColor = [UIColor lightTextColor];
        }

        name = user.preferredName;
        phone = user.phoneNumber;
        email = user.email;
        
        
        /*
        PFFile *imageFile = user.profilePicture;
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(!error){
                UIImage *profileImage = [UIImage imageWithData:data];
                if(profileImage!=nil)
                    profilePic.image  = profileImage;
                else{
                    profileImage= [UIImage imageNamed:@"dummy_img"];
                    profilePic.image  = profileImage;
                }
            }
        }];
         
         */
 
        
    }
    
    NSString *status=@"";
    if ([self.meeting.organizer isEqual:[contact valueForKey:SCHMeetupInviteeUser]]){
        status = @"Organizer";
    }else{
        if([[contact valueForKey:SCHMeetupInviteeConfirmation] isEqualToString:SCHMeetupConfirmed] )
        {
            status = @"Confirmed";
        } else if([[contact valueForKey:SCHMeetupInviteeConfirmation] isEqualToString:SCHMeetupDeclined] ){
             status = @"Declined";
            
        }else{
            status = @"Pending";
        }
        
    }
    
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:1];
    [title setAttributedText:[[NSMutableAttributedString alloc] initWithString:name attributes:titleAttr]];
    if ([status isEqualToString:@"Organizer"]){
        [cell.detailTextLabel setAttributedText:[[NSAttributedString alloc] initWithString:status attributes:subTitleAttrBlueColor]];
    } else if ([status isEqualToString:@"Confirmed"]){
        [cell.detailTextLabel setAttributedText:[[NSAttributedString alloc] initWithString:status attributes:subtittleAttrGreen]];
        
    } else if ([status isEqualToString:@"Pending"]){
        [cell.detailTextLabel setAttributedText:[[NSAttributedString alloc] initWithString:status attributes:subtittleAttrRed]];
    } else if ([status isEqualToString:@"Declined"]){
        [cell.detailTextLabel setAttributedText:[[NSAttributedString alloc] initWithString:status attributes:subtittleAttrGray]];
    }
    

    
    
   // NSMutableAttributedString *detailSubstring = [[NSMutableAttributedString alloc] initWithString:name attributes:titleAttr];
   // [detailSubstring appendAttributedString:newline];
   // [detailSubstring appendAttributedString:[[NSAttributedString alloc] initWithString:status attributes:subtittleAttr]];
    
//   if(email.length > 0){
//       [detailSubstring appendAttributedString:newline];
//       [detailSubstring appendAttributedString:[[NSAttributedString alloc] initWithString:email attributes:subtittleAttr]];
//       
//   }
//    if (phone.length >0){
//       if (phone.length == 10){
//          [detailSubstring appendAttributedString:newline];
//           [detailSubstring appendAttributedString:[[NSAttributedString alloc] initWithString:[SCHUtility phoneNumberFormate:phone] attributes:subtittleAttr]];
//       } else{
//            [detailSubstring appendAttributedString:newline];
//            [detailSubstring appendAttributedString:[[NSAttributedString alloc] initWithString:phone attributes:subtittleAttr]];
//        }
//        
//   }
    
    
    //[txtMessage setAttributedText:detailSubstring];

    //txtMessage.frame = CGRectMake(8, 0, cell.frame.size.width, self.rowheight );
    //  [cell addSubview:txtMessage];
    
    
    return cell;
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *contact = [self.invitiesArray objectAtIndex:indexPath.row];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([[contact valueForKey:@"user"] isKindOfClass:[SCHUser class]]){
        SCHUser *user = (SCHUser *) [contact valueForKey:@"user"];
        if ([user isEqual:appDelegate.user]){
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else{
            [self performSegueWithIdentifier:@"goToClientDetailSegue" sender:contact];
        }
    } else{
        [self performSegueWithIdentifier:@"goToClientDetailSegue" sender:contact];
    }
    
    
    
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCHConstants *constants = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if([self.meeting.organizer isEqual:appDelegate.user] && ![self.meeting.status isEqual:constants.SCHappointmentStatusCancelled]&& appDelegate.serverReachable){
        return YES;
    } else{
        return NO;
    }
    
        
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (editingStyle == UITableViewCellEditingStyleDelete && appDelegate.serverReachable) {
        [SCHUtility showProgressWithMessage:SCHProgressMessageGeneric];
        // Delete the row from the data source
       
        
        SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
        dispatch_async(backgroundManager.SCHSerialQueue, ^{
            [backgroundManager beginBackgroundTask];
            NSDictionary *contact = [self.invitiesArray objectAtIndex:indexPath.row];
            NSDictionary *output = [SCHMeetingManager removeInvities:@[contact] fromMeeting:self.meeting];
            if (output){

                self.meeting = [output valueForKey:@"meeting"];
                NSArray *textList = [output valueForKey:@"nonUsetTextList"];
                NSArray *emailList = [output valueForKey:@"nonUserEmailList"];
                
                [SCHSyncManager syncUserData:self.meeting.startTime];
                

                if (textList.count > 0 && emailList.count > 0){
                    [SCHMeetingManager sendEmailAndText:self.meeting emailList:emailList textList:textList messageType:kMeetingRemoveInviteeNotification];
                } else if (textList.count > 0 && emailList.count == 0){
                    [SCHMeetingManager sendTextMessage:self.meeting textList:textList messageType:kMeetingRemoveInviteeNotification];
                } else if (textList.count == 0 && emailList.count > 0){
                    [SCHMeetingManager sendEmail:self.meeting emailList:emailList messageType:kMeetingRemoveInviteeNotification];
                }

                
            } else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                        message:@"Meet-up was not created. Try again."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles:nil];
                    [alertView show];
                });
                
                
            }
            
            [self.meeting fetch];

            
            [KVNProgress dismissWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    
                    if ([SCHUtility nonDeclinedMeetupStatus:self.meeting.invites] == 0){
                        NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithObjects:self.navigationController.viewControllers[0], nil];
                        
                        UIViewController *firstVC = navigationArray[0];
                        
                        self.navigationController.viewControllers = navigationArray;
                        
                        
                        UITabBarController *tabBar =  firstVC.navigationController.tabBarController;
                        [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
                        
                    }
                    
                    
                    
                });

                
            }];
            [backgroundManager endBackgroundTask];
        });
        

        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.invitiesArray removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        });
 
 
 



    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{//appointmentDetailNew
    if([segue.identifier isEqualToString:@"goToClientDetailSegue"])
    {
        SCHScheduleClientDetailViewController *vcToPushTo = segue.destinationViewController;
        
        vcToPushTo.clientInfo = @{@"content": sender};
    }
}
-(void)buildAttendeeList{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.invitiesArray = [[NSMutableArray alloc] init];
    NSMutableArray *remainingInvites =[[NSMutableArray alloc] initWithArray:self.meeting.invites];
    NSArray *selfDicts = [[NSArray alloc] init];
    if (![self.meeting.organizer isEqual:appDelegate.user]){
        SCHUser *user = appDelegate.user;
        NSPredicate *inviteePredicate = [NSPredicate predicateWithFormat:@" user = %@", user];
        selfDicts = [self.meeting.invites filteredArrayUsingPredicate:inviteePredicate];
    }
    
    if (selfDicts.count > 0){
        [self.invitiesArray addObjectsFromArray:selfDicts];
    }
    

    
    //create organizer dict
    NSDictionary *organizerDict =  [SCHMeetingManager createInvitesWith:_meeting.organizer name:_meeting.organizer.preferredName accepance:SCHMeetupConfirmed];
    [self.invitiesArray addObject:organizerDict];
    

    
    
    if (selfDicts.count > 0){
        [remainingInvites removeObjectsInArray:selfDicts];
    }
    
    [self.invitiesArray addObjectsFromArray:remainingInvites];
    [self.tableView reloadData];
    
}


@end
