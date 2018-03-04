//
//  AppDelegate.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 4/11/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/ParseFacebookUtilsV4.h>
#import "SCHSyncManager.h"
#import "SCHUtility.h"
#import "SCHActiveViewControllers.h"
#import "SCHNotificationViewController.h"
#import "SCHConstants.h"
#import "SCHLoginViewController.h"
#import "SCHKeychainWrapper.h"
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "SCHTimeBlock.h"


@interface AppDelegate ()

@property (nonatomic, strong) SCHKeychainWrapper *keychain;


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
   // Override point for customization after application launch.
    [Parse enableLocalDatastore];
    
/*

     //Rack Space dev
     [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
     configuration.localDatastoreEnabled = YES;
     configuration.applicationId = @"JpbaZeeosnz3HjX2m7EPEBQ31X0nCiusCktgU414";
     configuration.clientKey = @"taprfOHgnprHE05zB0Bit6zMPR9nCZ8HJlaCthmA";
     configuration.server = @"http://devserver.counterbean.com:1337/parse";
     }]];
 
 
 */
    
 
    //Rackspace Production
    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        configuration.localDatastoreEnabled = YES;
        configuration.applicationId = @"verzer7RWQzns4xNcZ3TZrSQIPEUTzw9wwo8gf8w";
        configuration.clientKey = @"t835B3x2oeF4XtT8fBWPIE5b9I9p33IjalY629lI";
        configuration.server = @"http://prodserver.counterbean.com/parse";

        
    }]];
    

   
    self.keychain = [[SCHKeychainWrapper alloc] initWithIdentifier:@"CBUUID" accessGroup:nil];
    
 
     
  /* [[FBSDKApplicationDelegate sharedInstance] application:application
                            didFinishLaunchingWithOptions:launchOptions]; */
    
    
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];

    // Set default ACLs
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicWriteAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    
    // Register for Push Notitications
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    
  
    
    

    // create a Reachability object for the internet
    
    self.serverConnectionReach =[Reachability reachabilityWithHostname:@"http://prodserver.counterbean.com/parse"];
    NetworkStatus hostStatus = [self.serverConnectionReach currentReachabilityStatus];
    if(hostStatus == NotReachable){
       // NSLog(@"Parse Not reachable");
        self.serverReachable = false;
    }else{
       // NSLog(@"Parse is reachable");
        self.serverReachable = true;
        if (hostStatus == ReachableViaWiFi){
            self.wifiReachable = YES;
        }
    }
   [self.serverConnectionReach stopNotifier];
    [self.serverConnectionReach startNotifier];
    
    //Added reachbility changed Observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
     
     
    
    //change navigation bar title color
    UIFontDescriptor *userHeadLineFont = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
    CGFloat userHeadLineFontSize = [userHeadLineFont pointSize];
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],NSFontAttributeName :[UIFont fontWithDescriptor:userHeadLineFont size:userHeadLineFontSize+2]}];
    
    [[UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil] setBarTintColor:[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor]];
    [[UINavigationBar appearance] setBarTintColor:[SCHUtility colorFromHexString:SCHApplicationNavagationBarColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    //Initialize service Provider Status
    self.serviceProvider = NO;
    self.serviceProviderWithActiveService = NO;
    

    
    return YES;
}

//Push Notification Rigistration
#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application   didRegisterUserNotificationSettings:   (UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString   *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}
#endif
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
 
    [self setCBUUID];
   /* NSString * deviceTokenString = [[[[deviceToken description]
                                      stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                     stringByReplacingOccurrencesOfString: @">" withString: @""]
                                    stringByReplacingOccurrencesOfString: @" " withString: @""];
    */
    //NSLog(@"The generated device token string is : %@",deviceTokenString);    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    currentInstallation.badge = 0;
    [currentInstallation saveEventually];
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
    
    
        int badgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber ? (int)[UIApplication sharedApplication].applicationIconBadgeNumber : 0;
        badgeNumber = badgeNumber +1;
       // [(AppDelegate *)[[UIApplication sharedApplication] delegate] setApplicationbadgeCount:badgeNumber];
    [self setApplicationbadgeCount:badgeNumber];
    
    
    
    
    if (self.serverReachable){
        
        
        if (self.user){
            dispatch_barrier_async(self.backgroundManager.SCHSerialQueue, ^{
                
                [SCHSyncManager syncUserData:nil];
                
            });
        }
    }else {
        if (self.user){
            dispatch_barrier_async(self.backgroundManager.SCHSerialQueue, ^{
                
                [SCHSyncManager syncUserDateNoInternetMode:nil];
                
            });
        }
        
    }
}



- (void)applicationWillResignActive:(UIApplication *)application {
    
    
    if (self.user){
        if(self.syncTimer!=nil)
            [self.syncTimer invalidate];
    }
    
 

    
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
   
    
    
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    

    
    
   [FBSDKAppEvents activateApp];
    
 
    
    if ([PFUser currentUser] ){
        //Get Initialize SCH User
        if (![self initializeSCHUser]){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.slideMenu){
                    [self.slideMenu dismissViewControllerAnimated:NO completion:NULL];
                    [self.slideMenu performSegueWithIdentifier:@"logoutSegue" sender:self];
                } else{
                    [SCHUtility logout];
                }
                
            });
        }
        
    }
    
   
    
    SCHConstants *constants = [SCHConstants sharedManager];

    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //Initialize all singletons
        
        //Initiliaze background queue
        self.backgroundManager = [SCHBackgroundManager sharedManager];
        
        //background Commit;
        self.backgroundCommit = [SCHBackendCommit sharedManager];
        
        //objects for Processing
        self.objectsForProcessing = [SCHObjectsForProcessing sharedManager];
        
        // Iniliatize availalability Refesh Queue
        self.refreshQueue = [SCHAvailabilityRefreshQueue sharedManager];

        
        
        
        // DATA PROCESSING 1
        dispatch_async(dispatch_get_main_queue(), ^{
            // UI UPDATION 1
            
            if (self.user && constants){
                
                
                
                
                if (self.serverReachable){

                    
                    [self.user fetch];
                    
                    //Handle suspension
 
                    if (![SCHUtility removeAccountSuspensionWithExpirationDate]){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (self.slideMenu){
                                [self.slideMenu dismissViewControllerAnimated:NO completion:NULL];
                                [self.slideMenu performSegueWithIdentifier:@"logoutSegue" sender:self];
                            } else{
                                [SCHUtility logout];
                            }
                            
                        });
                    }
                    
                                        
                    if (self.user.suspended){
                        
                        NSString *message = nil;
                        if (self.user.suspensionExpirationTime){
                            NSDateFormatter *formatter = [SCHUtility dateFormatterForLongDateAndTime];
                            NSString *expirationTime = [formatter stringFromDate:self.user.suspensionExpirationTime ];
                            message = [NSString localizedStringWithFormat:@"Your account is suspended till %@.", expirationTime];
                        } else{
                            
                            message = [NSString localizedStringWithFormat:@"Account is suspended. Please email contact@counterbean.com."];
                        }
                        
                        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                           message:message
                                                                          delegate:self
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil,nil];
                        [theAlert show];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (self.slideMenu){
                                [self.slideMenu dismissViewControllerAnimated:NO completion:NULL];
                                [self.slideMenu performSegueWithIdentifier:@"logoutSegue" sender:self];
                            } else{
                                [SCHUtility logout];
                            }
                            
                        });
                    } else{
                        
                        if ([SCHUtility IsMandatoryUpgradeRequired]){
                            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                                               message:@"Mandatory upgarde required."
                                                                              delegate:self
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil,nil];
                            [theAlert show];
                            
                            
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (self.slideMenu){
                                    [self.slideMenu dismissViewControllerAnimated:NO completion:NULL];
                                    [self.slideMenu performSegueWithIdentifier:@"logoutSegue" sender:self];
                                } else{
                                    [SCHUtility logout];
                                }
                                
                            });
                            
                            
                        } else {
                            dispatch_barrier_async(self.backgroundManager.SCHSerialQueue, ^{
                                
                                [SCHSyncManager syncUserData:nil];
                                
                                
                            });
                            
                            
                        }

                        
                    }

                    
                    
                    
                }else {
                    dispatch_barrier_async(self.backgroundManager.SCHSerialQueue, ^{
                        
                        [SCHSyncManager syncUserDateNoInternetMode:nil];
                        
                    });
                }
                if(self.syncTimer==nil){
                    self.syncTimer=[NSTimer scheduledTimerWithTimeInterval:SCHTimeBlockDuration
                                                                    target:self
                                                                  selector:@selector(callStartTimer)
                                                                  userInfo:nil
                                                                   repeats:YES];
                    
                }
                

                
                
             
         }
            
        

        });
    });
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.slideMenu){
            [self.slideMenu dismissViewControllerAnimated:NO completion:NULL];
            [self.slideMenu performSegueWithIdentifier:@"logoutSegue" sender:self];
        } else{
            [SCHUtility logout];
        }
        
    });
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    
    
}


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}


-(void)callStartTimer
{
    [SCHSyncManager callTimer];
}

#pragma mark -  Reachability Change
-(void)reachabilityChanged:(NSNotification*)note
{
   
    self.serverConnectionReach =[Reachability reachabilityWithHostname:@"http://devserver.counterbean.com:1337/parse"];
    if(self.serverConnectionReach.isReachable)
    {
        self.serverReachable = true;
        
    }
    else
    {
        self.serverReachable = false;
    }
}

#pragma mark -  bedag

-(void) setApplicationbadgeCount:(int)badge{
    if(badge>0){
        
    [UIApplication sharedApplication].applicationIconBadgeNumber = badge;
    if(self.tabBarController)
    [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:[NSString stringWithFormat:@"%lu",(unsigned long)badge]];
    }else{
        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
    }
    
}

-(void)setCBUUID
{
   
    NSString *currentTnstallationId = [PFInstallation currentInstallation].installationId;
    
  //  KeychainWrapper *MyKeychainWrapper = [KeychainWrapper new];
    
    NSString *SCHinstallationId = [self CBUUID:self.keychain];
    
    if (SCHinstallationId.length == 0) {
       // [MyKeychainWrapper mySetObSCHinstallationId	__NSCFString *	@"6e6d1ada-ac9e-49db-9218-bbf9cb57caae"	0x000000015ce6ad48ject:CBUUID forKey:@"CBUUID"];
       // [MyKeychainWrapper writeToKeychain];
        [self.keychain setObject:currentTnstallationId forKey:(__bridge id)(kSecAttrAccount)];

    } else if ((SCHinstallationId.length > 0) && ![currentTnstallationId isEqualToString:SCHinstallationId]){
        [PFCloud callFunctionInBackground:@"CleanInstallation" withParameters:@{@"installationId" : SCHinstallationId} block:^(id  _Nullable object, NSError * _Nullable error) {
            
            if (!error){
               // NSLog(@"Success");
            } else{
                //  NSLog(@"Failure");
            }
        }];
        
        [self.keychain setObject:currentTnstallationId forKey:(__bridge id)(kSecAttrAccount)];
       
    }
   
}

-(NSString*)CBUUID:(SCHKeychainWrapper *) keychain
{
    /*
    KeychainWrapper *MyKeychainWrapper = [KeychainWrapper new];
    return (NSString*)[MyKeychainWrapper myObjectForKey:@"CBUUID"];
     */
    return [keychain objectForKey:(__bridge id)(kSecAttrAccount)];
}

-(void)VerifyFBOAUthException{
    
    
    if (![PFUser currentUser].authenticated){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                               message:@"Please Login again."
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
            [theAlert show];
            
        });

    }
    
}

-(BOOL)initializeSCHUser{
    BOOL initialized = NO;
    NSError *error = nil;
    if (self.user){
        initialized = YES;
    }else{
        PFObject *object = [PFUser currentUser][@"CBUser"];
        PFQuery *userQuery = [SCHUser query];
        [userQuery fromLocalDatastore];
        self.user = [userQuery getObjectWithId:object.objectId error:&error];
        if (self.user){
            initialized = YES;
        } else{
            initialized = NO;
        }
        
    }

    return initialized;
}


@end
