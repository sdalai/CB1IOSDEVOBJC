//
//  SCHBookAppointmentViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 7/7/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHBookViewController.h"
#import "AppDelegate.h"
#import "SCHMinorClassificationTableViewController.h"
#import "SCHAlert.h"
#import "MFSideMenu.h"
#import "SCHActiveViewControllers.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
#import "SCHUserAppointmentHistory.h"

@interface SCHBookViewController () <CNPPopupControllerDelegate>
@property (nonatomic, strong) CNPPopupController *popupController;


@end



@implementation SCHBookViewController
AppDelegate * appDelegate;
bool isSearshBarActive = false;
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    SCHActiveViewControllers *activeVC = [SCHActiveViewControllers sharedManager];
    [activeVC.viewControllers setObject:self forKey:@"bookVC"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCHUserLogout object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLogout)
                                                 name:SCHUserLogout
                                               object:nil];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(openPopover)];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appDelegate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });
    
    
    [self setupMenuBarButtonItems];
}

-(void)userLogout{
    SCHActiveViewControllers *activeVC = [SCHActiveViewControllers sharedManager];
    [activeVC.viewControllers removeObjectForKey:@"bookVC"];
    [self dismissViewControllerAnimated:NO completion:NULL];
}



-(void)openPopover
{
    [self showPopupWithStyle:CNPPopupStyleCentered];
    
}
- (void)setupMenuBarButtonItems {
    if(self.menuContainerViewController.menuState == MFSideMenuStateClosed &&
       ![[self.navigationController.viewControllers objectAtIndex:0] isEqual:self]) {
        self.navigationItem.leftBarButtonItem = [self backBarButtonItem];
    } else {
        self.navigationItem.leftBarButtonItem = [self leftMenuBarButtonItem];
    }
}

- (UIBarButtonItem *)leftMenuBarButtonItem {
    return [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStylePlain
            target:self
            action:@selector(leftSideMenuButtonPressed:)];
}
- (void)leftSideMenuButtonPressed:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
        [self setupMenuBarButtonItems];
    }];
}

- (UIBarButtonItem *)backBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(backButtonPressed:)];
}

-(void)internetConnectionChanged{
    
    [self loadData];
    
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!appDelegate.serverReachable) {
            [self.navigationItem setPrompt:@"Please connect to Internet."];
            
        } else {
            [self.navigationItem setPrompt:nil];
            
        }
    });
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"Book Appointment";
    
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.activeServiceProvider = NO;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self loadData];
}


-(void)loadData{
    
    self.activeServiceProvider = (appDelegate.serviceProviderWithActiveService && [SCHUtility BusinessUserAccess] && appDelegate.serverReachable);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (appDelegate.serverReachable){
            self.tableData = [SCHUtility getMajorServiceClassification:NO];
        } else{
            self.tableData = @[];
        }
        self.searchResult = [NSMutableArray arrayWithArray:self.tableData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
    });
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section==0 && !isSearshBarActive)
    {
        return 80;
    }else{
        return 44;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(!isSearshBarActive){
        return 2;    }
    return 1;
    
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(self.tableData.count == self.searchResult.count){
        if(section == 0)
        {
            return @"";
        }else{
            return @"";
        }
    }
    return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!isSearshBarActive){
        if(section==0)
            return 1;
    }
    return [self.searchResult count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell;
    
    if(!isSearshBarActive){
        
        
        if(indexPath.section == 0)
        {
            UIView *newAppointment=nil,*newMeetUp=nil,*favoriteServices=nil,*appointmentHistory=nil;
        
            if(appDelegate.serverReachable)
            {
                if (self.activeServiceProvider){
                    cell = [tableView dequeueReusableCellWithIdentifier:@"serviceProviderCell"];
                    
                    newAppointment= (UIView*)[cell viewWithTag:1];
                    newMeetUp= (UIView*)[cell viewWithTag:2];
                    favoriteServices= (UIView*)[cell viewWithTag:3];
                    appointmentHistory= (UIView*)[cell viewWithTag:4];
                    
                    
                }else{
                    cell = [tableView dequeueReusableCellWithIdentifier:@"normalUserCell"];
                    newMeetUp= (UIView*)[cell viewWithTag:1];
                    favoriteServices= (UIView*)[cell viewWithTag:2];
                    appointmentHistory= (UIView*)[cell viewWithTag:3];
                }
                
            }else{
                cell = [tableView dequeueReusableCellWithIdentifier:@"allUserNoInternetCell"];
                favoriteServices= (UIView*)[cell viewWithTag:1];
            }
            
            if(newAppointment!=nil)
            {
                UITapGestureRecognizer *newTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goToNewAppointment)];
                [newAppointment setUserInteractionEnabled:YES];
                [newAppointment addGestureRecognizer:newTap];
            }
            
            if(newMeetUp!=nil)
            {
                UITapGestureRecognizer *newTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goToNewMeetup)];
                [newMeetUp setUserInteractionEnabled:YES];
                [newMeetUp addGestureRecognizer:newTap];
            }
            
            if(favoriteServices!=nil)
            {
                UITapGestureRecognizer *newTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goTofavorite)];
                [favoriteServices setUserInteractionEnabled:YES];
                [favoriteServices addGestureRecognizer:newTap];
            }
        
            if(appointmentHistory!=nil)
            {
                UITapGestureRecognizer *newTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goToAppointmentHistory)];
                [appointmentHistory setUserInteractionEnabled:YES];
                [appointmentHistory addGestureRecognizer:newTap];

            }
            
            
            
        }else{
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            SCHServiceMajorClassification *majorClassificationObject =  (SCHServiceMajorClassification *)[self.searchResult objectAtIndex:indexPath.row];
            cell.textLabel.text = majorClassificationObject.majorClassification;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            //Set selection background color
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
            [cell setSelectedBackgroundView:bgColorView];
        }
        
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        SCHServiceMajorClassification *majorClassificationObject =  (SCHServiceMajorClassification *)[self.searchResult objectAtIndex:indexPath.row];
        cell.textLabel.text = majorClassificationObject.majorClassification;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        //Set selection background color
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
        [cell setSelectedBackgroundView:bgColorView];
        
    }
    
    
    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
}

#pragma mark - tableView Deligate method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        
        if(!isSearshBarActive && indexPath.section==0 )
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

        }else{
        SCHServiceMajorClassification *selectedObj = [self.searchResult objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"serviceClassfiationSegue" sender:selectedObj];
        }
        
        
    } else{
        [SCHAlert internetOutageAlert];
    }
    
    
    //toAppointmentHistory
    
    
}


-(void)goToNewAppointment{
    [self performSegueWithIdentifier:@"bookAppointmentToNewAppointmentBySP" sender:nil];
}
-(void)goToNewMeetup{
    [self performSegueWithIdentifier:@"goToMeetupSegue" sender:nil];
}
-(void)goTofavorite{
    [self performSegueWithIdentifier:@"favServiceProviderSegue" sender:nil];
}
-(void)goToAppointmentHistory{
    [self performSegueWithIdentifier:@"toAppointmentHistory" sender:nil];
}
#pragma overriding segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"serviceClassfiationSegue"]){
        SCHMinorClassificationTableViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.majorClassification_obj  = (SCHServiceMajorClassification *)sender;
    } else if ([segue.identifier isEqualToString:@"toAppointmentHistory"]){
        SCHUserAppointmentHistory *historyVC = segue.destinationViewController;
        AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        historyVC.user = appdeligate.user;
        historyVC.serviceProvider = appdeligate.user;
        
        
    }
}




#pragma mark - search bar deligate method
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [self.searchResult removeAllObjects];
    if(searchText.length>0){
        // NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"serviceTypeName contains[c] %@", searchText];
        NSPredicate *resultPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            NSString *evaluatedString = [NSString stringWithFormat:@"%@", evaluatedObject ];
            if ([evaluatedString localizedCaseInsensitiveContainsString:searchText]){
                return YES;
            } else{
                return NO;
            }
            
        }];
        
        
        self.searchResult = [NSMutableArray arrayWithArray: [self.tableData filteredArrayUsingPredicate:resultPredicate]];
    }else{
        self.searchResult = [NSMutableArray arrayWithArray:self.tableData];
    }
    
}


-(BOOL)searchDisplayController:(UISearchController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:[[controller.searchBar scopeButtonTitles] objectAtIndex:[controller.searchBar selectedScopeButtonIndex]]];
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    NSLog(@"searchBarBegain Editing");
    isSearshBarActive = true;
}
// called when text starts editing
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    NSLog(@"searchBarEnd Editing");
    isSearshBarActive = false;
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchResult = [NSMutableArray arrayWithArray:self.tableData];
}

- (void)showPopupWithStyle:(CNPPopupStyle)popupStyle {
    
    //Define Button
    CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [button setTitle:@"OK" forState:UIControlStateNormal];
    button.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    button.layer.cornerRadius = 4;
    button.selectionHandler = ^(CNPPopupButton *button){
        [self.popupController dismissPopupControllerAnimated:YES];
        NSLog(@"Block for button: %@", button.titleLabel.text);
    };
    // Define View
    
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 200)];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 280, 200)];
    
    
    /*
     NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
     paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
     paragraphStyle.alignment = NSTextAlignmentCenter;
     
     NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"It's A Popup!" attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:24], NSParagraphStyleAttributeName : paragraphStyle}];
     NSAttributedString *lineOne = [[NSAttributedString alloc] initWithString:@"You can add text and images" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSParagraphStyleAttributeName : paragraphStyle}];
     NSAttributedString *lineTwo = [[NSAttributedString alloc] initWithString:@"With style, using NSAttributedString" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSForegroundColorAttributeName : [UIColor colorWithRed:0.46 green:0.8 blue:1.0 alpha:1.0], NSParagraphStyleAttributeName : paragraphStyle}];
     
     */
    
    
    
    
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = [self helpTitle];
    
    
    // UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"info"]];
    
    
    
    // customView.backgroundColor = [UIColor lightGrayColor];
    
    
    
    [textView setEditable:NO];
    [textView setSelectable:NO];
    [textView setAttributedText:[self helpContent]];
    [customView addSubview:textView];
    
    self.popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, customView, button]];
    self.popupController.theme = [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle = popupStyle;
    self.popupController.theme.cornerRadius = 20;
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];
}

-(NSAttributedString *) helpContent{
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] init];
    NSString *nextLine = @"\n";
    
    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    NSDictionary *blueBodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                                   NSForegroundColorAttributeName :[UIColor blueColor]};
    
    if (self.activeServiceProvider){
        //
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Setup Appointment with Client"] attributes:blueBodyAttr]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" to book appointment."] attributes:bodyAttr]];
        
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select a professional from "] attributes:bodyAttr]];
        
        //
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"My Favorite"] attributes:blueBodyAttr]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" list to book appointment."] attributes:bodyAttr]];
        
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"If no favorite select a business category to find the professionals and book appointment."] attributes:bodyAttr]];
        
    }else{
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select a professional from "] attributes:bodyAttr]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"My Favorite"] attributes:blueBodyAttr]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" list to book appointment."] attributes:bodyAttr]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"If no favorite select a business category to find the professionals and book appointment."] attributes:bodyAttr]];
        
    }
    
    
    return content;
    
    
}




-(NSAttributedString *) helpTitle{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Book Appointment"]  attributes:titleAttr]];
    return title;
}





@end
