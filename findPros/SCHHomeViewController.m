//
//  SCHHomeViewController.m
//  CounterBean
//
//  Created by Sujit Dalai on 4/21/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHHomeViewController.h"
#import "MFSideMenu.h"
#import "SCHNotificationViewController.h"
#import "SCHUtility.h"
#import <Parse/Parse.h>
#import "SCHAppointment.h"
#import "SCHConstants.h"
#import "SCHScheduledEventManager.h"
#import "SCHActiveViewControllers.h"
#import "SCHEvent.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
#import "SCHEvent.h"
#import "SCHMeeting.h"
@interface SCHHomeViewController ()<CNPPopupControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) CNPPopupController *popupController;
@property (nonatomic, strong) SCHEvent *upcomingEvent;

@property (weak, nonatomic) IBOutlet UITextView *textView;



@end

@implementation SCHHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    SCHActiveViewControllers *activeVC = [SCHActiveViewControllers sharedManager];
    [activeVC.viewControllers setObject:self forKey:@"homeVC"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCHUserLogout object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLogout)
                                                 name:SCHUserLogout
                                               object:nil];

    
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(openPopover)];
    
    
    //show Alert
    [self.textView setText:@""];
     [self setupMenuBarButtonItems];
    
    [self.textView setDelegate:self];

}

-(void)userLogout{
    SCHActiveViewControllers *activeVC = [SCHActiveViewControllers sharedManager];
    [activeVC.viewControllers removeObjectForKey:@"homeVC"];
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Home";
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
  //  UIBarButtonItem *infoButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"info"] style:UIBarButtonItemStylePlain target:self action:@selector(openPopover)];
   // [self.navigationItem setRightBarButtonItem:infoButton];
    
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.userJustLoggedIn){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
               
            }];
        });
        appDelegate.userJustLoggedIn = NO;
    }

    
    [self.textView setAttributedText:[self homeScreenMessage]];


}



-(NSAttributedString *)homeScreenMessage{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableAttributedString *message = [[NSMutableAttributedString alloc] init];
    NSString *nextLine = @"\n";
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    NSDictionary *subTitleAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
   
    
    
    UIFontDescriptor *subtitleFontDescriptor = [[SCHUtility getPreferredSubtitleFont] fontDescriptor];
    UIFontDescriptorSymbolicTraits traits = subtitleFontDescriptor.symbolicTraits;
    traits |= UIFontDescriptorTraitItalic;
    
    UIFontDescriptor *statusFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:traits];
    
    UIFont *statusFont = [UIFont fontWithDescriptor:statusFontDescriptor size:0];
    
    NSMutableParagraphStyle *statusStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [statusStyle setAlignment:NSTextAlignmentLeft];
    
    NSDictionary *itallicAttr = @{NSFontAttributeName : statusFont,
                                 NSForegroundColorAttributeName : [UIColor blueColor],
                                 NSParagraphStyleAttributeName: statusStyle};
    
    UIFontDescriptorSymbolicTraits boldTraits = subtitleFontDescriptor.symbolicTraits;
    boldTraits |= UIFontDescriptorTraitBold;
    UIFontDescriptor *boldFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:boldTraits];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldFontDescriptor size:0];
    
    NSDictionary *boldAttr = @{NSFontAttributeName : boldFont,
                                  NSForegroundColorAttributeName : [SCHUtility deepGrayColor],
                                  NSParagraphStyleAttributeName: statusStyle};
    
    
    
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Hi, %@", appDelegate.user.preferredName]  attributes:titleAttr]];
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    
    NSString *upcomingAppointment = [self getUpcomingAppointment];
    
    if ([upcomingAppointment length] > 0){
        //Enable text view gesture recognization
        
        [message appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Welcome to CounterBean."]  attributes:subTitleAttr]];
        [message appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [message appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
        [message appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Your upcoming schedule:"]  attributes:boldAttr]];
        

        [message appendAttributedString:[[NSAttributedString alloc] initWithString:upcomingAppointment  attributes:itallicAttr]];
        [message addAttribute:NSLinkAttributeName
                                 value:@"event://event"
                                 range:[[message string] rangeOfString:upcomingAppointment]];

        
    } else{
       [message appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Welcome to CounterBean. You can book appointment with a professional and set up your own Meet-up."]  attributes:subTitleAttr]];
    }
    
        return message;
}
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([[URL scheme] isEqualToString:@"event"]) {
        [self performSegueWithIdentifier:@"eventDetail" sender:nil];
        return NO;
    }
    return YES; // let the system open this URL
}

-(void)refreshHomeScreen{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView setAttributedText:[self homeScreenMessage]];
    });
    
    
}

-(NSString *)getUpcomingAppointment{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableString *appointmentString = [[NSMutableString alloc] init];
    NSDate *currentDate = [SCHUtility startOrEndTime:[NSDate date]];
    SCHConstants *constants = [SCHConstants sharedManager];
    SCHScheduledEventManager *eventManager = [SCHScheduledEventManager sharedManager];
    NSDictionary *dayEvents = eventManager.scheduledEvents;
    NSMutableArray *events = [[NSMutableArray alloc] init];
    
    for (NSArray *dayEvent in [dayEvents allValues]){
        [events addObjectsFromArray:dayEvent];
    }
    
    NSPredicate *eventFilter = [NSPredicate predicateWithBlock:^BOOL(SCHEvent *event, NSDictionary<NSString *,id> * _Nullable bindings) {
        if ([currentDate compare:event.endTime]== NSOrderedAscending && [event.eventType isEqualToString:SCHAppointmentClass]){
            if ([event.eventObject isKindOfClass:[SCHAppointment class]]){
                
                SCHAppointment *appointment = (SCHAppointment *)event.eventObject;
                if (!appointment.expired && ([appointment.status isEqual:constants.SCHappointmentStatusPending] || [appointment.status isEqual:constants.SCHappointmentStatusConfirmed])){
                    return YES;
                }else{
                    return NO;
                }

            } else{
               return NO;
            }
            
        } else if ([event.eventObject isKindOfClass:[SCHMeeting class]]){
            
            return YES;
        } else{
            return NO;
        }
    }];
    
    NSSortDescriptor *appointmentSort = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    
    NSArray *upcomingAppointmentArray = [[events filteredArrayUsingPredicate:eventFilter] sortedArrayUsingDescriptors:@[appointmentSort]];
    if (upcomingAppointmentArray.count > 0){
        SCHEvent *upcomingEvent = upcomingAppointmentArray[0];
        self.upcomingEvent = upcomingEvent;
        
        
        
        NSString *appointmentDate = [[SCHUtility dateFormatterForFullDate] stringFromDate:upcomingEvent.startTime];
        NSString *appointmentTime = [[SCHUtility dateFormatterForShortTime] stringFromDate:upcomingEvent.startTime];
        [appointmentString appendString:[NSString localizedStringWithFormat:@"\n%@ at %@",appointmentDate, appointmentTime]];
        
        
        if ([upcomingEvent.eventObject isKindOfClass:[SCHAppointment class]]){
            SCHAppointment *appointment = (SCHAppointment *)upcomingEvent.eventObject;
            if (appointment.service.serviceTitle &&appointment.serviceOffering.serviceOfferingName){
                [appointmentString appendString:[NSString localizedStringWithFormat:@"\n%@-%@",appointment.service.serviceTitle, appointment.serviceOffering.serviceOfferingName ] ];
                
                
            }
            [appointmentString appendString:[NSString localizedStringWithFormat:@"\n%@", appointment.location]];
            
        } else{
            SCHMeeting *meeting = (SCHMeeting *)upcomingEvent.eventObject;
            NSMutableString *title = [[NSMutableString alloc] init];
            
            if (meeting.subject){
                if ([meeting.organizer isEqual:appDelegate.user]){
                    [title appendString:[NSString localizedStringWithFormat:@"\n%@", meeting.subject]];
                } else{
                    [title appendString:[NSString localizedStringWithFormat:@"\n%@ - organized by %@", meeting.subject, meeting.organizer.preferredName]];
                }
            }
            if (title){
               [appointmentString appendString:title ];
            }
             [appointmentString appendString:[NSString localizedStringWithFormat:@"\n%@", meeting.location]];
        }
        
        
        
        
       
        
        
        
    }
    
    
    return appointmentString;
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
    
   UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
    
    
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

#pragma overriding segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{//appointmentDetailNew
    
    
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"eventDetail"]){
        
        SCHScheduleSummeryViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.recived_data  =(NSObject *)_upcomingEvent;
        
    }
}

-(NSAttributedString *) helpContent{
    UIFont *bodyFont = [SCHUtility getPreferredTitleFont];
    UIImage *calendarIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"calender"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *calendarAttachment = [SCHTextAttachment new];
    calendarAttachment.image = calendarIcon;
    
    UIImage *bookIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"book"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *bookAttachment = [SCHTextAttachment new];
    bookAttachment.image = bookIcon;
    
    UIImage *notificationIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"notification"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *notificationAttachment = [SCHTextAttachment new];
    notificationAttachment.image = notificationIcon;
    
    UIImage *businessIcon = [SCHUtility imageWithImage:[UIImage imageNamed:@"business"] scaledToSize:CGSizeMake(bodyFont.pointSize, bodyFont.pointSize)];
    SCHTextAttachment *businessAttachment = [SCHTextAttachment new];
    businessAttachment.image = businessIcon;
    
    
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] init];
    NSString *nextLine = @"\n";
    
    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                                   NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    
    
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:calendarAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" Event Calendar"] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:bookAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" Setup Appointment with Professional or client"] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:notificationAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" Your messages"] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[NSAttributedString attributedStringWithAttachment:businessAttachment]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" Register new business or manage existing business"] attributes:bodyAttr]];

    
    return content;
    
}




-(NSAttributedString *) helpTitle{
     NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"CounterBean"]  attributes:titleAttr]];
    return title;
}
@end
