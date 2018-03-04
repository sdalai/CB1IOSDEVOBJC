//
//  SCHClientListViewController.m
//  CounterBean Inc.
//
//  Created by Pratap Yadav on 10/2/15.
//  Copyright © 2015 SujitDalai. All rights reserved.
//

#import "SCHClientListViewController.h"
#import <AddressBook/AddressBook.h>
#import "SCHUtility.h"
#import "ClientListTableViewCell.h"
#import "SCHAddClientViewController.h"
#import "SCHUser.h"
#import "AppDelegate.h"
@interface SCHClientListViewController ()

@property (strong, nonatomic) NSArray *indexArray;
@property (strong, nonatomic) NSDictionary *indexedObjects;


@end

@implementation SCHClientListViewController
@synthesize rowDescriptor = _rowDescriptor;
AppDelegate *appDelegate;
int selectedSource=0;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//       
//    }
//    return self;
//}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc]init];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.clientList = [[NSMutableArray alloc]init];
    self.contactList = [[NSMutableArray alloc] init];
    self.clientList = [[NSMutableArray alloc] initWithArray:[SCHUtility GetServiceProviderClientList:appDelegate.user]];
    
    selectedSource =0;
    self.title = @"Client";
    self.view.tintColor =  [SCHUtility colorFromHexString:SCHLogoColor];
    self.OptionButton.tintColor = [SCHUtility colorFromHexString:SCHApplicationNavagationBarColor];
    self.contactList = [self getContactAuthorizationFromUser];
    [self.OptionButton addTarget:self action:@selector(segmentControlBtnAction:) forControlEvents:UIControlEventValueChanged];
    self.indexedObjects = [self generateIndexArray:self.clientList];
    
    self.tableView.delegate = self;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIBarButtonItem *addClntButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewClient)];
    self.navigationItem.rightBarButtonItem = addClntButton;

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.title = @"Client";
    [self.tableView reloadData];
}

-(void)addNewClient{
    self.title = @"";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SCHAddClientViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"addNewClientView"];
    vc.XLFormdelegate = self;
    [self.navigationController pushViewController:vc animated:YES];
    
}
- (IBAction) segmentControlBtnAction:(id)sender
{
    UISegmentedControl* segmentControl = (UISegmentedControl *)sender;
    int index = (int)[segmentControl selectedSegmentIndex];
    
    switch(index)
    {
        case 0: // Perform action on first button of segment controller
          //  NSLog(@"0 index");
            selectedSource=0;
            self.indexedObjects = [self generateIndexArray:self.clientList];
            [self.tableView reloadData];
            break;
        case 1: // Perform action on second button of segment controller
           // NSLog(@"1 index");
            selectedSource=1;
            self.indexedObjects = [self generateIndexArray:self.contactList];
            [self.tableView reloadData];
            break;
    }
}

#pragma mark - Search bar deligate
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
 self.searchBar.showsCancelButton = YES;
    return true;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.showsCancelButton = NO;
    [self.searchBar resignFirstResponder];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
     [self.searchBar resignFirstResponder];
}

// called when text ends editing
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self applyFilterWithSerarchText:searchText];
   
   // NSLog(@"textDidChange");
   
}// called when text changes (including clear)


-(void)applyFilterWithSerarchText:(NSString*)searchText{
    
    if(searchText.length>0)
    {
       if(selectedSource ==0)
       {
           NSPredicate *predicateString = [NSPredicate predicateWithFormat:@"(firstName BEGINSWITH[c] %@)",searchText]; //keySelected is NSString itself
           //NSLog(@"predicate %@",predicateString);
           self.indexedObjects = [ self generateIndexArray:[NSMutableArray arrayWithArray:[self.clientList filteredArrayUsingPredicate:predicateString]]];
           
       }else if(selectedSource==1)
       {
        NSPredicate *predicateString = [NSPredicate predicateWithFormat:@"(%K BEGINSWITH[cd] %@) OR (%K BEGINSWITH[cd] %@) OR (%K BEGINSWITH[cd] %@)", @"name", searchText,@"email",searchText, @"phone",searchText]; //keySelected is NSString itself
       // NSLog(@"predicate %@",predicateString);
        self.indexedObjects= [self generateIndexArray:[NSMutableArray arrayWithArray:[self.contactList filteredArrayUsingPredicate:predicateString]]];
       }
    }else{
            if(selectedSource==0)
            {
                self.indexedObjects = [self generateIndexArray:self.clientList];
                
            }else if(selectedSource==1)
            {
                self.indexedObjects = [self generateIndexArray:self.contactList];
            }
    }
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
       return  100;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.indexArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *index = self.indexArray[section];
    NSArray *indexObjects = [self.indexedObjects valueForKey:index];

    return indexObjects.count;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{

    return self.indexArray;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    return self.indexArray[section];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    static NSString *CellIdentifier = @"clientCell";
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    UIImageView *profilePic = (UIImageView*)[cell.contentView viewWithTag:1];
    profilePic.layer.masksToBounds = YES;
    profilePic.contentMode = UIViewContentModeScaleAspectFill;
    profilePic.layer.cornerRadius = 6.0;
    profilePic.layer.borderColor = [[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor] CGColor];
    profilePic.layer.borderWidth = 3.0;
    UITextView *txtMessage = (UITextView*)[cell.contentView viewWithTag:2];
    txtMessage.userInteractionEnabled = false;
    NSDictionary *titleAttr = @{NSFontAttributeName : [SCHUtility getPreferredTitleFont],
                                NSForegroundColorAttributeName :[SCHUtility deepGrayColor]};
    
    
    NSDictionary *subtittleAttr = @{NSFontAttributeName : [SCHUtility getPreferredSubtitleFont],
                                    NSForegroundColorAttributeName : [SCHUtility deepGrayColor]};
    
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    [txtMessage setEditable:false];
    [txtMessage setSelectable:false];
    
    NSString *name=@"";
    NSString *email=@"";
    NSString *phone=@"";
    

    NSArray *DataArray = (NSArray *)[self.indexedObjects valueForKey:self.indexArray[indexPath.section]];

    
    if(selectedSource==0)
    {
        
        SCHServiceProviderClientList *client = DataArray[indexPath.row];
        
        if(client.client){
            SCHUser *user = client.client;
           // NSLog(@" %@", user);
            
            
            name = user.preferredName;
            email = user.email;
            phone =user.phoneNumber;
            
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

            
        }else if(client.nonUserClient){
            name = client.name;
            email = client.nonUserClient.email;
            phone = client.nonUserClient.phoneNumber;
        }
    
       
    }else if(selectedSource == 1)
    {
        NSDictionary *contact = DataArray[indexPath.row];
        NSArray *phones = [contact objectForKey:@"phones"];
        NSArray *emails = [contact objectForKey:@"emails"];
    
        name =[contact valueForKey:@"name"];
        if (emails.count > 0){
            email = [emails[0] valueForKey:@"email"];
        }
        if (phones.count > 0){
            phone = [SCHUtility phoneNumberFormate:[phones[0] valueForKey:@"phoneNumber"]];
        }
        
        UIImage *image= [contact objectForKey:@"image"];
        if(image!=nil)
        profilePic.image  = image;
        else{
            image= [UIImage imageNamed:@"dummy_img"];
            profilePic.image  = image;
        }
            
    }
    
    
    NSMutableAttributedString *detailSubstring = [[NSMutableAttributedString alloc] initWithString:name attributes:titleAttr];
    
    if(email.length > 0){
        [detailSubstring appendAttributedString:newline];
        [detailSubstring appendAttributedString:[[NSAttributedString alloc] initWithString:email attributes:subtittleAttr]];
        
    }
    if (phone.length >0){
        if (phone.length == 10){
            [detailSubstring appendAttributedString:newline];
            [detailSubstring appendAttributedString:[[NSAttributedString alloc] initWithString:[SCHUtility phoneNumberFormate:phone] attributes:subtittleAttr]];
        } else{
            [detailSubstring appendAttributedString:newline];
            [detailSubstring appendAttributedString:[[NSAttributedString alloc] initWithString:phone attributes:subtittleAttr]];
        }
        
    }
    
    
    [txtMessage setAttributedText:detailSubstring];
     self.rowheight = [self tableViewCellHeight:txtMessage];

    
    //txtMessage.frame = CGRectMake(8, 0, cell.frame.size.width, self.rowheight );
  //  [cell addSubview:txtMessage];
    
    
    return cell;
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *DataArray = (NSArray *)[self.indexedObjects valueForKey:self.indexArray[indexPath.section]];
   if(selectedSource==0)
   {
       SCHServiceProviderClientList *client = DataArray[indexPath.row];
       NSString *name;
       if(client.client){
           SCHUser *user = client.client;
           name = user.preferredName;
           
            }else if(client.nonUserClient){
                name = client.name;
        
            }
       [self.rowDescriptor setValue:@{@"name": name,@"client":client}];
       [self.navigationController popViewControllerAnimated:YES];

      }else{
          NSDictionary * contactData = DataArray[indexPath.row];
          NSString *contactName = [contactData valueForKey:@"name"];
          NSString *contactPhone =nil;
          NSString *contactEmail = nil;
          
          NSArray *phones = [contactData valueForKey:@"phones"];
          if (phones.count > 0){
              contactPhone = [phones[0] valueForKey:@"phoneNumber"];
          }
          NSArray *emails = [contactData valueForKey:@"emails"];
          if (emails.count > 0){
              contactEmail =  [emails[0] valueForKey:@"email"];
          }
          
          
          
          
          
          if (appDelegate.user.phoneNumber && contactPhone){
              if ([appDelegate.user.phoneNumber isEqualToString:contactPhone]){
                  //show Alert
                  UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Not a Client" message:[NSString localizedStringWithFormat:@"%@ is your phone Number!", [SCHUtility phoneNumberFormate:contactPhone]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                  [theAlert show];
                  
                  
                  return;
              }
              
              
              
          }
          if (contactEmail){
              if ([appDelegate.user.email isEqualToString:contactEmail]){
                  //show Alert
                  UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Not a Client" message:[NSString localizedStringWithFormat:@"%@ is your email!", contactEmail] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                  [theAlert show];
                  return;
              }
          }
          
          NSDictionary *cloudFunctionDict = nil;
          
          if (contactPhone.length > 0 && contactEmail.length > 0){
              cloudFunctionDict = @{@"email": contactEmail, @"phoneNumber" : contactPhone};
          } else if (contactEmail.length > 0 && contactPhone.length == 0){
              cloudFunctionDict = @{@"email": contactEmail, @"phoneNumber" : @""};
          } else if (contactEmail.length == 0 && contactPhone.length > 0){
              cloudFunctionDict = @{@"email": @"", @"phoneNumber" : contactPhone};
          }
          
      [PFCloud callFunctionInBackground:@"NonUserDetails" withParameters:cloudFunctionDict block:^(id  _Nullable object, NSError * _Nullable error) {
          if (!error){
              NSString *objectType = [object valueForKey:@"Type"];
              NSString *objectId = [object valueForKey:@"ObjectID"];
              PFQuery *objectQuery = nil;
              if ([objectType isEqualToString:@"User"]){
                  objectQuery = [SCHUser query];
              } else{
                  objectQuery = [SCHNonUserClient query];
              }
              
              id client = [objectQuery getObjectWithId:objectId];
              [client pin];
              if (client){
                  SCHUser *user = nil;
                  SCHNonUserClient *nonUser = nil;
                  if ([client isKindOfClass:[SCHUser class]]){
                      user = client;
                  } else{
                      nonUser = client;
                  }
                  SCHServiceProviderClientList *SPClient = [SCHUtility addClientToServiceProvider:appDelegate.user client:user name:contactName nonUserClient:nonUser autoConfirm:NO];
                  [self.rowDescriptor setValue:@{@"name": contactName,@"client":SPClient}];
                  
                  dispatch_async(dispatch_get_main_queue(), ^{
                      [self.navigationController popViewControllerAnimated:YES];
                  });
                  
                  
              } else{
                  
              }
              
              
          }else{
              return;
          }
          
              
        
      }];
      

   }
    
    
}


#pragma mark - Contact API
-(NSMutableArray *)getContactAuthorizationFromUser{
    
    NSMutableArray *finalContactList = [[NSMutableArray alloc] init];
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                [finalContactList addObjectsFromArray:[self getContactswithPhoneNumber:[SCHUtility getAllContacts]]];

            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        finalContactList = [[NSMutableArray alloc] initWithArray:[self getContactswithPhoneNumber:[SCHUtility getAllContacts]]];
        [self.tableView reloadData];
        // NSLog(@"Authorize");
    }
    else {
       // NSLog(@"UnAuthorize");
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
    }
    return finalContactList;
    
}


-(NSArray *)getContactswithPhoneNumber:(NSArray *) contacts{
    
    NSPredicate *phoneOnlyPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary  *contact, NSDictionary<NSString *,id> * _Nullable bindings) {
        if ([[contact allKeys] containsObject:@"phones"]){
            return YES;
        }else{
            return NO;
        }
    
    }];
    
    
    
    
    return [contacts filteredArrayUsingPredicate:phoneOnlyPredicate];
}



-(NSArray *)sortedContact:(NSArray *) contacts{
    NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    
    NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:@[nameSort]];
    
    return sortedContacts;
    
    
    
}

-(NSDictionary *) generateIndexArray:(NSArray *) inputArray{
    
    
    NSMutableSet *indexSet = [[NSMutableSet alloc] init];
    NSMutableSet *testSet = [[NSMutableSet alloc] init];
    if (selectedSource == 0){
        for (int i = 0; i<inputArray.count; i++){
            SCHServiceProviderClientList *client = (SCHServiceProviderClientList*)[inputArray objectAtIndex:i];
            if (client.client){
                SCHUser *user = client.client;
                [indexSet addObject:[[user.preferredName substringToIndex:1] localizedUppercaseString]];
                
            } else if(client.nonUserClient){
                [indexSet addObject:[[client.name substringToIndex:1] localizedUppercaseString]];
                
                
            }
            
        }
        
        
    }else if(selectedSource == 1){
        for (int i = 0; i<inputArray.count; i++){
            NSDictionary *contact = [inputArray objectAtIndex:i];
            [indexSet addObject:[[[contact valueForKey:@"name"] substringToIndex:1] localizedUppercaseString]];
            [testSet addObject:[[contact valueForKey:@"name"] substringToIndex:1]];
            
        }
        
    }
    
    NSArray *indexArray = [[indexSet allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableDictionary *indexedDictonary = [[NSMutableDictionary alloc] init];

    if (indexArray.count > 0){
        for (NSString *index in indexArray){
            if (selectedSource == 0){
                NSPredicate *indexpredicate = [NSPredicate predicateWithBlock:^BOOL(SCHServiceProviderClientList *client, NSDictionary<NSString *,id> * _Nullable bindings) {
                    if (client.client){
                        SCHUser *user = client.client;
                        if ([[[user.preferredName substringToIndex:1] localizedUppercaseString] isEqualToString:index]){
                            return YES;
                        } else{
                            return NO;
                        }
                    } else if (client.nonUserClient){
                        if ([[[client.name substringToIndex:1] localizedUppercaseString] isEqualToString:index]){
                            return YES;
                        }else{
                            return NO;
                        }
                    } else{
                        return NO;
                    }
                }];
            
                NSArray *objectsOfIndex = [inputArray filteredArrayUsingPredicate:indexpredicate];
                [indexedDictonary setObject:objectsOfIndex forKey:index];
            }else if(selectedSource == 1){
                NSPredicate *indexPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *contact, NSDictionary<NSString *,id> * _Nullable bindings) {

                    
                    NSString *firstCharacter = [[[contact valueForKey:@"name"] substringToIndex:1] localizedUppercaseString];

                    if (firstCharacter.length == 1){
                        if ([firstCharacter isEqualToString:index]){

                            return YES;
                            
                        } else{

                            return NO;
                        }

                    } else{

                        return NO;
                    }
                    
                }];

                NSArray *objectsOfIndex = [SCHUtility sortedContact:[inputArray filteredArrayUsingPredicate:indexPredicate]];
                
                [indexedDictonary setObject:objectsOfIndex forKey:index];
                
            }
            
        }
        
    }
    self.indexArray = indexArray;
    
    return  indexedDictonary;
}

-(CGFloat)tableViewCellHeight:(UITextView *) textView{
    
    CGFloat fixedWidth = textView.bounds.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    
    return newSize.height;
}


//
@end
