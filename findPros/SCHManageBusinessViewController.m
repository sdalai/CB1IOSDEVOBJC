//
//  SCHManageBusinessViewController.m
//  CounterBean
//
//  Created by Sujit Dalai on 4/21/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHManageBusinessViewController.h"
#import "SCHloginViewController.h"
#import "MFSideMenu.h"
#import "AppDelegate.h"
#import "SCHUtility.h"
#import "SCHActiveViewControllers.h"
#import "SCHAlert.h"
#import "SCHUserServicesTableViewController.h"
#import "SCHUserLocationTableViewController.h"
#import "CNPPopupController.h"
#import "SCHTextAttachment.h"
#import "SCHUserAppointmentHistory.h"

static NSString * const kRegisterBusiness = @"Register Business";
static NSString * const kManageBusiness = @"Business Profiles";
static NSString * const kManageAvailability = @"Business Schedule";
static NSString * const kLocations = @"Locations";
static NSString * const kClients = @"Clients";
static NSString * const ksetupAppointment = @"Appointment with Client";
static NSString * const kappointmentHistory = @"Appointment History";




@interface SCHManageBusinessViewController () <UITableViewDelegate, UITableViewDataSource, CNPPopupControllerDelegate>

@property (nonatomic, strong) NSArray *tableData;
@property (nonatomic, assign) BOOL serviceProvider;
@property (nonatomic, assign) BOOL ActiveServiceProvider;
@property (nonatomic, strong) UITapGestureRecognizer *imageTap;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (nonatomic, strong) CNPPopupController *popupController;

@end

@implementation SCHManageBusinessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    SCHActiveViewControllers *activeVC = [SCHActiveViewControllers sharedManager];
    [activeVC.viewControllers setObject:self forKey:@"manageServiceVC"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCHUserLogout object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLogout)
                                                 name:SCHUserLogout
                                               object:nil];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(openPopover)];
    
    
    self.imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pictureTapped)];
    [self.image setUserInteractionEnabled:YES];
    [self.image addGestureRecognizer:self.imageTap];
    
    self.businessList.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    // Do any additional setup after loading the view.
    [self setupMenuBarButtonItems];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
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



-(void)userLogout{
    
    SCHActiveViewControllers *activeVC = [SCHActiveViewControllers sharedManager];
    [activeVC.viewControllers removeObjectForKey:@"manageServiceVC"];
    [self dismissViewControllerAnimated:NO completion:NULL];
}



-(void)openPopover
{
    [self showPopupWithStyle:CNPPopupStyleCentered];
    
}

-(void)internetConnectionChanged{
    
    // [self viewDidLoad];
    [self loadData];
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


-(void)loadData{
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.serviceProvider = appdeligate.serviceProvider;
    self.ActiveServiceProvider = (appdeligate.serviceProviderWithActiveService && [SCHUtility BusinessUserAccess]);
    
    
        if (self.serviceProvider){
            if (self.ActiveServiceProvider){
                // Acitve service Provider
                
                self.tableData = [[NSArray alloc]initWithObjects:kManageBusiness, kManageAvailability, ksetupAppointment,  kLocations, kClients, nil];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.navigationItem.rightBarButtonItem.title = @"Help";
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                });
                

                
            }else{
                self.tableData = [[NSArray alloc]initWithObjects:kManageBusiness,  kLocations, kClients, nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.navigationItem.rightBarButtonItem.title = @"Help";
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                });
            }
            
            
        } else{
            // Not a service Provider
            self.tableData = [[NSArray alloc]initWithObjects:kRegisterBusiness,nil];
            self.navigationItem.rightBarButtonItem.title = @"";
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.businessList reloadData];
    });
    
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"SCHTextViewCell" forIndexPath:indexPath];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SCHTextViewCell"];
    }
    NSString *cellData = self.tableData[indexPath.row];
    cell.textLabel.text = cellData;
    
    //Set selection background color
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    [cell setSelectedBackgroundView:bgColorView];
    
    return cell;
    
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:kManageBusiness]){
        [self performSegueWithIdentifier:@"manageBusinessToService" sender:self.tableData[indexPath.row]];
    } else if ([cell.textLabel.text isEqualToString:kRegisterBusiness]){
        if (appdeligate.serverReachable){
            [self performSegueWithIdentifier:@"addNewServiceSegue" sender:self.tableData[indexPath.row]];
        } else{
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [SCHAlert internetOutageAlert];
        }
        
    } else if([cell.textLabel.text isEqualToString:kManageAvailability]){
        if (appdeligate.serverReachable){
            [self performSegueWithIdentifier:@"manageBusinessToManageAvailability" sender:self.tableData[indexPath.row]];
        } else{
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [SCHAlert internetOutageAlert];
        }
    } else if ([cell.textLabel.text isEqualToString:kLocations]) {
        //manageBusinessToLocations
        [self performSegueWithIdentifier:@"manageBusinessToLocations" sender:nil];
        
    } else if ([cell.textLabel.text isEqualToString:kClients]) {
        //manageBusinessToClients
        [self performSegueWithIdentifier:@"manageBusinessToClients" sender:self.tableData[indexPath.row]];
     } else if ([cell.textLabel.text isEqualToString:ksetupAppointment]) {
         
         if (appdeligate.serverReachable){
             [self performSegueWithIdentifier:@"manageBusinessToBookAppointmentWithClient" sender:self.tableData[indexPath.row]];
         } else{
             [tableView deselectRowAtIndexPath:indexPath animated:YES];
             [SCHAlert internetOutageAlert];
         }
    
      } else{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
}




#pragma mark - Navigation

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = [NSString localizedStringWithFormat:@"My Business"];
    
    [self loadData];
    
}




// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.navigationItem.title = SCHBackkButtonTitle;
    if([segue.identifier isEqualToString:@"manageBusinessToService"]){
        
        SCHUserServicesTableViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.doNotnavigateToNewServiceScreen = self.serviceProvider;
        
    }


    
}

-(void)pictureTapped{
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([self.tableData[0] isEqualToString:kManageBusiness]){
        [self performSegueWithIdentifier:@"manageBusinessToService" sender:self.tableData[0]];
    } else if([self.tableData[0] isEqualToString:kRegisterBusiness]){
        
        if (appdeligate.serverReachable){
             [self performSegueWithIdentifier:@"addNewServiceSegue" sender:self.tableData[0]];
        } else{
            [SCHAlert internetOutageAlert];
        }
    }
    
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

-(NSAttributedString *) helpContent{
    
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] init];
    NSString *nextLine = @"\n";
    
    NSDictionary *bodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    
    NSDictionary *blueBodyAttr = @{NSFontAttributeName : [SCHUtility getPreferredBodyFont],
                               NSForegroundColorAttributeName :[UIColor blueColor]};
    
    
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Business Profiles"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" to view existing profile or register new business."] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Business Schedule"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" to manage your business availability."] attributes:bodyAttr]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Appointment with Client"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" to book appointment."] attributes:bodyAttr]];

    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Locations"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" to manage your business locations."] attributes:bodyAttr]];
    
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:nextLine]];
    
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Select "] attributes:bodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Clients"] attributes:blueBodyAttr]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@" to manage your client."] attributes:bodyAttr]];
    
    
    return content;
}




-(NSAttributedString *) helpTitle{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *titleStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [titleStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor],
                                NSParagraphStyleAttributeName : titleStyle};
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"My Business"]  attributes:titleAttr]];
    return title;
}




@end
