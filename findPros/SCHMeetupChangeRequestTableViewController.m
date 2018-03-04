//
//  SCHMeetupChangeRequestTableViewController.m
//  CounterBean
//
//  Created by Sujit Dalai on 7/4/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHMeetupChangeRequestTableViewController.h"
#import "SCHUser.h"
#import "SCHAlert.h"
#import <KVNProgress/KVNProgress.h>

@interface SCHMeetupChangeRequestTableViewController ()

@property (nonatomic, strong) NSMutableArray *changeRequests;

@end

@implementation SCHMeetupChangeRequestTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.changeRequests = [[NSMutableArray alloc] init];
    self.constants = [SCHConstants sharedManager];
    self.objectsForProcessing  = [SCHObjectsForProcessing sharedManager];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    double delayInSeconds = 0.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appdeligate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });


}

-(void)locadChangeRequests{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        [self.meeting fetch];
    }
    
    self.changeRequests = [[NSMutableArray alloc] initWithArray:self.meeting.changeRequests];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
    
    
}


-(void)internetConnectionChanged{
    
    
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appdeligate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });
    
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Change Requests";
    [self locadChangeRequests];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return self.rowheight;
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.changeRequests.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"changeRequest" forIndexPath:indexPath];
    
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"changeRequest"];
    }
    
    UILabel *requesterLabel = (UILabel *)[cell.contentView viewWithTag:1];
    UITextView *CRContentView = (UITextView *)[cell.contentView viewWithTag:2];
   // UIView *responseView = (UIView *)[cell.contentView viewWithTag:3];
    UIButton *acceptButton = (UIButton *)[cell.contentView viewWithTag:4];
    UIButton *ignoreButton = (UIButton *)[cell.contentView viewWithTag:5];
    [acceptButton addTarget:self action:@selector(acceptButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [ignoreButton addTarget:self action:@selector(ignoreButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    NSDictionary *changeRequest = self.changeRequests[indexPath.row];
    
    NSDictionary *cellContent = [self changeRequestCellContent:changeRequest];
    
    NSDictionary *requester = [cellContent valueForKey:@"requester"];
    
    [requesterLabel setAttributedText:[requester valueForKey:@"name"]];
    

    
    [CRContentView setAttributedText:[cellContent valueForKey:@"content"]];
    
    
    self.rowheight = [SCHUtility tableViewCellHeight:CRContentView width:CRContentView.bounds.size.width] + 80;
    
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
}

-(NSIndexPath *) indexPathForsender:(id)sender{
    
    
    UITableViewCell *cell = (UITableViewCell *)[[[sender superview] superview] superview];
    
    return [self.tableView indexPathForCell:cell];
    
}

#pragma mark - accept decline clicked
-(void)acceptButtonClicked:(id)sender{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.serverReachable){

        [self.meeting fetch];
         NSIndexPath *indexPath = [self indexPathForsender:sender];
         NSDictionary *changeRequest = self.changeRequests[indexPath.row];
        NSString *changeRequestType = [changeRequest valueForKey:SCHMeetupCRAttrType];
        SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
        
        
        [self.objectsForProcessing addObjectsToProcessingQueue:self.meeting];
        self.eventManager.notificationChanged = YES;
        self.eventManager.scheduleEventsChanged = YES;
        [SCHUtility showProgressWithMessage:SCHProgressMessageAcceptAppointment];
        dispatch_async(backgroundManager.SCHSerialQueue, ^{
            [backgroundManager beginBackgroundTask];
            NSDictionary *output = [SCHMeetingManager  acceptChangeProposal:self.meeting
                                                                   proposal:changeRequest ];
            

            [self.objectsForProcessing removeObjectsFromProcessingQueue:self.meeting];
            
            if (output){
                self.meeting = [output valueForKey:@"meeting"];
                NSArray *textList = [output valueForKey:@"nonUsetTextList"];
                
                [SCHSyncManager syncUserData:self.meeting.startTime];
                
                
                
                
                NSArray *emailList = [output valueForKey:@"nonUserEmailList"];
                
                if ([changeRequestType isEqualToString:SCHMeetupCRTypeAddInvitee]){
                    
                    if (textList.count > 0 && emailList.count > 0){
                        [SCHMeetingManager sendEmailAndText:self.meeting emailList:emailList textList:textList messageType:kNewMeetingNotification];
                    } else if (textList.count > 0 && emailList.count == 0){
                        [SCHMeetingManager sendTextMessage:self.meeting textList:textList messageType:kNewMeetingNotification];
                    } else if (textList.count == 0 && emailList.count > 0){
                        [SCHMeetingManager sendEmail:self.meeting emailList:emailList messageType:kNewMeetingNotification];
                    }

                } else{

                    if (textList.count > 0 && emailList.count > 0){
                        [SCHMeetingManager sendEmailAndText:self.meeting emailList:emailList textList:textList messageType:kMeetingChangeNotification];
                    } else if (textList.count > 0 && emailList.count == 0){
                        [SCHMeetingManager sendTextMessage:self.meeting textList:textList messageType:kMeetingChangeNotification];
                    } else if (textList.count == 0 && emailList.count > 0){
                        [SCHMeetingManager sendEmail:self.meeting emailList:emailList messageType:kMeetingChangeNotification];
                    }

                }
                
                
                
            } else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([changeRequestType isEqualToString:SCHMeetupCRTypeAddInvitee]){
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                            message:@"Invites couldn't be added. Try again."
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                        
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertView *nvavigationAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                          message:@"Change request couldn't be processed. Try again."
                                                                         delegate:nil
                                                                cancelButtonTitle:@"Ok"
                                                                otherButtonTitles:nil];
                            [nvavigationAlert show];
                        });

                        
                    }
                    
                    
                    
                    
                });
            }
            
            
            
            [self.meeting fetch];
            
            
            [KVNProgress dismissWithCompletion:^{
                
                if (_meeting.changeRequests.count == 0){
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        
                        
                        NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithObjects:self.navigationController.viewControllers[0], nil];
                        
                        UIViewController *firstVC;
                        
                        
                        if (navigationArray.count >0){
                            firstVC = navigationArray[0];
                            
                        }else{
                            firstVC = self;
                        }
                        
                        
                        self.navigationController.viewControllers = navigationArray;
                        
                        
                        UITabBarController *tabBar =  self.navigationController.tabBarController;
                        [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
                        
                        
                    });

                }
                
            }];
            [backgroundManager endBackgroundTask];
        

        });
        
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self.changeRequests removeObject:changeRequest];
            [self.tableView reloadData];
            
            
        }];
        
    } else{
        [SCHAlert internetOutageAlert];
       
    }
    
}

-(void)ignoreButtonClicked:(id)sender{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    if (appDelegate.serverReachable){
        [SCHUtility showProgressWithMessage:SCHProgressMessageGeneric];
            [self.meeting fetch];
        NSIndexPath *indexPath = [self indexPathForsender:sender];
        NSDictionary *changeRequest = self.changeRequests[indexPath.row];
        NSString *changeRequestType = [changeRequest valueForKey:SCHMeetupCRAttrType];
        SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
        
        
        [self.objectsForProcessing addObjectsToProcessingQueue:self.meeting];
        self.eventManager.notificationChanged = YES;
        self.eventManager.scheduleEventsChanged = YES;
        [SCHUtility showProgressWithMessage:SCHProgressMessageDeclineAppointment];
        dispatch_async(backgroundManager.SCHSerialQueue, ^{
            [backgroundManager beginBackgroundTask];
            if (![SCHMeetingManager  declineChangerequest:self.meeting proposal:changeRequest]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([changeRequestType isEqualToString:SCHMeetupCRTypeAddInvitee]){
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                            message:@"Invites couldn't be added. Try again."
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                        
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertView *nvavigationAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                                       message:@"Change request couldn't be processed. Try again."
                                                                                      delegate:nil
                                                                             cancelButtonTitle:@"Ok"
                                                                             otherButtonTitles:nil];
                            [nvavigationAlert show];
                        });
                        
                        
                    }
                    
                    
                    
                    
                });

                
            }
            
            
            [self.objectsForProcessing removeObjectsFromProcessingQueue:self.meeting];
            [self.meeting fetch];
            
            
            [KVNProgress dismissWithCompletion:^{
                
                if (_meeting.changeRequests.count == 0){
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        
                        
                        NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithObjects:self.navigationController.viewControllers[0], nil];
                        
                        UIViewController *firstVC;
                        
                        
                        if (navigationArray.count >0){
                            firstVC = navigationArray[0];
                            
                        }else{
                            firstVC = self;
                        }
                        
                        
                        self.navigationController.viewControllers = navigationArray;
                        
                        
                        UITabBarController *tabBar =  self.navigationController.tabBarController;
                        [tabBar setSelectedViewController:(UIViewController *)[tabBar.viewControllers objectAtIndex: 1]];
                        
                        
                    });
                    
                }
                
            }];

            [backgroundManager endBackgroundTask];
            
            
        });
        
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self.changeRequests removeObject:changeRequest];
            [self.tableView reloadData];
            
            
        }];
        
    } else{
        [SCHAlert internetOutageAlert];
        
    }
    
}

-(NSDictionary *)changeRequestCellContent:(NSDictionary *) changeRequest{
    
    SCHUser *requester = [changeRequest valueForKey:SCHMeetupCRAttrRequester];
    NSString *CRType = [changeRequest valueForKey:SCHMeetupCRAttrType];
    NSDictionary *newInvitee = nil;
    NSDate *proposedStartTime = nil;
    NSDate *proposedEndTime = nil;
    NSString *proposedLocation = nil;
    if ([CRType isEqualToString:SCHMeetupCRTypeAddInvitee]){
        newInvitee = [changeRequest valueForKey:SCHMeetupCRAttrNewInvitee];
    }else{
        proposedStartTime = [changeRequest valueForKey:SCHMeetupCRAttrProposedStartTime];
        proposedEndTime = [changeRequest valueForKey:SCHMeetupCRAttrProposedEndTime];
        proposedLocation = [changeRequest valueForKey:SCHMeetupCRAttrProposedLocation];
    }
    
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
    NSDateFormatter *toTimeFormatter = [SCHUtility dateFormatterForToTime];
    


    
    NSDictionary *subtitleAttr = @{NSFontAttributeName: [SCHUtility getPreferredSubtitleFont],
                                   NSForegroundColorAttributeName: [UIColor blackColor]};
    
    UIFontDescriptor *subtitleFontDescriptor = [[SCHUtility getPreferredSubtitleFont] fontDescriptor];
    UIFontDescriptorSymbolicTraits boldTraits = subtitleFontDescriptor.symbolicTraits;
    boldTraits |= UIFontDescriptorTraitBold;
    UIFontDescriptor *boldFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:boldTraits];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldFontDescriptor size:0];
    
    NSDictionary *boldSubtitleAttr = @{NSFontAttributeName: boldFont,
                                   NSForegroundColorAttributeName: [UIColor blackColor]};
    
    
    
    
    
    
    NSMutableDictionary *bodyAttr = [[NSMutableDictionary alloc] init];
    [bodyAttr setObject:[SCHUtility getPreferredBodyFont] forKey:NSFontAttributeName];
    [bodyAttr setObject:[SCHUtility deepGrayColor] forKey:NSForegroundColorAttributeName];
    
    
    // Requester
    
    NSDictionary *reuqestorDict = @{@"name": [[NSAttributedString alloc] initWithString:requester.preferredName attributes:subtitleAttr],
                                @"user": requester};
    
    
    //Content
    NSMutableAttributedString *CRContent = [[NSMutableAttributedString alloc] init];
    if ([CRType isEqualToString:SCHMeetupCRTypeAddInvitee]){
        [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Requested to invite"] attributes:boldSubtitleAttr]];
        [CRContent appendAttributedString:newline];
         [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"%@", [newInvitee valueForKey:@"name"]] attributes:bodyAttr]];
        [CRContent appendAttributedString:newline];
        [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"%@", [SCHUtility phoneNumberFormate:[newInvitee valueForKey:@"phone"] ]] attributes:bodyAttr]];

    } else{
        if (proposedStartTime && proposedLocation){
            [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Proposed new location and time"] attributes:boldSubtitleAttr]];
            [CRContent appendAttributedString:newline];
            
            [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[dayformatter stringFromDate:proposedStartTime] attributes:bodyAttr]];
            [CRContent appendAttributedString:newline];
            [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ to %@", [toTimeFormatter stringFromDate:proposedStartTime], [toTimeFormatter stringFromDate:proposedEndTime]] attributes:bodyAttr]];
            [CRContent appendAttributedString:newline];
            
            [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"at %@", proposedLocation] attributes:bodyAttr]];
            
            
        } else if (proposedLocation && !proposedStartTime){
            [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Proposed new location"] attributes:subtitleAttr]];
            [CRContent appendAttributedString:newline];
            [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"at %@", proposedLocation] attributes:bodyAttr]];
            
        } else if (proposedStartTime && !proposedLocation){
            [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Proposed new time"] attributes:subtitleAttr]];
            [CRContent appendAttributedString:newline];
            
            [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[dayformatter stringFromDate:proposedStartTime] attributes:bodyAttr]];
            [CRContent appendAttributedString:newline];
            [CRContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ to %@", [toTimeFormatter stringFromDate:proposedStartTime], [toTimeFormatter stringFromDate:proposedEndTime]] attributes:bodyAttr]];
            
            
        }
    }
    
    
    
    

    
    return @{@"requester": reuqestorDict,
             @"content": CRContent};
}


@end
