   //
//  SCHUtility.m
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 4/5/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHUtility.h"
#import "SCHConstants.h"
#import "SCHLookup.h"
#import "SCHAppointment.h"
#import "SCHAppointmentActivity.h"
#import "SCHService.h"
#import "SCHServiceClassification.h"
#import "SCHServiceOffering.h"
#import "SCHAvailableTimeBlock.h"
#import "SCHAvailability.h"
#import <XLForm/XLForm.h>
#import "SCHBackgroundManager.h"
#import "SCHScheduledEventManager.h"
#import "SCHAvailabilityForAppointment.h"
#import "SCHNotification.h"
#import "SCHAvailabilityManager.h"
#import "SCHAvailabilityManager.h"
#import <CoreLocation/CoreLocation.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <AddressBookUI/AddressBookUI.h>
#import "AppDelegate.h"
#import "SCHUserLocation.h"
#import "SCHServiceProviderClientList.h"
#import "SCHNonUserClient.h"
#import "SCHPaymentFrequency.h"
#import "SCHScheduleScreenFilter.h"
#import "SCHScheduledEventManager.h"
#import "SCHServiceMajorClassification.h"
#import "SCHUserFevoriteService.h"
#import "SCHSyncManager.h"
#import "SCHAppRelease.h"
#import "SCHControl.h"
#import "SCHUserFriend.h"
#import "SlideMenuViewController.h"
#import "MFSideMenu.h"
#import "SCHActiveViewControllers.h"
#import "SCHTextAttachment.h"
#import "SCHMeeting.h"
#import "SCHMeetingManager.h"
#import <KVNProgress/KVNProgress.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
#import <libPhoneNumber-iOS/NBNumberFormat.h>
#import <libPhoneNumber-iOS/NBMetadataCore.h>
#import <libPhoneNumber-iOS/NBPhoneMetaData.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>




static BOOL debug = NO;



@implementation SCHUtility

#pragma mark - List of Value APIs

+(NSArray *) servicelist {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *serviceList = [[NSMutableArray alloc] init];
    
    
    
    PFQuery *query =[PFQuery queryWithClassName:@"SCHService"];
    [query fromLocalDatastore];
    [query whereKey:@"active" equalTo:@YES];
    [query whereKey:@"suspended" notEqualTo:@YES];
    [query whereKey:@"user" equalTo:appDelegate.user];
    
    for (SCHService *service in [query findObjects]){
        XLFormOptionsObject *optionobject = [XLFormOptionsObject formOptionsObjectWithValue:service displayText:service.serviceTitle];
        [serviceList addObject:optionobject];
    }
    return serviceList;
}

+(NSArray *) serviceOfferingList:(SCHService *) service {
    NSMutableArray *serviceOfferingList = [[NSMutableArray alloc] init];
    
  //  NSLog(@"Processing Service Offering");
 //   NSLog(@"service: %@", service);
    PFQuery *serviceOfferingQuery = [PFQuery queryWithClassName:SCHServiceOfferingClass];
    //[serviceOfferingQuery fromLocalDatastore];
    [serviceOfferingQuery whereKey:@"service" equalTo:service];
    
    NSArray *offerings = [serviceOfferingQuery findObjects];
    
    for (SCHServiceOffering *offering in offerings){
        XLFormOptionsObject *optionobject = [XLFormOptionsObject formOptionsObjectWithValue:offering displayText:offering.serviceOfferingName];
        [serviceOfferingList addObject:optionobject];
    }
    
    return serviceOfferingList;
}


+(NSArray *)initlizeContactList
{
    
    
    NSMutableArray *newContactArray = [[NSMutableArray alloc] init];
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    NSArray *arrayOfAllPeople1 = (__bridge NSArray *) ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSUInteger peopleCounter = 0;
    for (peopleCounter = 0;peopleCounter < [arrayOfAllPeople1 count]; peopleCounter++)
    {
        ABRecordRef thisPerson = (__bridge ABRecordRef) [arrayOfAllPeople1 objectAtIndex:peopleCounter];
        NSString *name = (__bridge NSString *) ABRecordCopyCompositeName(thisPerson);
        ABMultiValueRef number = ABRecordCopyValue(thisPerson, kABPersonPhoneProperty);
        for (NSUInteger emailCounter = 0; emailCounter < ABMultiValueGetCount(number); emailCounter++)
        {
            NSString *email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(number, emailCounter);
            if ([email length]!=0)
            {
                NSString* removed1=[email stringByReplacingOccurrencesOfString:@"-" withString:@""];
                NSString* removed2=[removed1 stringByReplacingOccurrencesOfString:@")" withString:@""];
                NSString* removed3=[removed2 stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSString* removed4=[removed3 stringByReplacingOccurrencesOfString:@"(" withString:@""];
                NSString* removed5=[removed4 stringByReplacingOccurrencesOfString:@"+" withString:@""];
                // NSMutableDictionary * contantDic = [[NSMutableDictionary alloc] init];
                NSString *contactName;
                if ([name length]==0)
                {
                    contactName = [NSString stringWithFormat:@"No name (%@)",removed5];
                }
                else
                {
                    contactName= name;
                }
                [newContactArray addObject:contactName];
            }
        }
    }
    CFRelease(addressBook);
    return newContactArray;
    
}

+(NSArray *) privacyPrefrences{
    NSMutableArray *privacyPreferences = [[NSMutableArray alloc] init];
    SCHConstants *constants = [SCHConstants sharedManager];
    
    XLFormOptionsObject *optionobject1 = [XLFormOptionsObject formOptionsObjectWithValue:constants.SCHPrivacyOptionPublic displayText:constants.SCHPrivacyOptionPublic.lookupText];
    [privacyPreferences addObject:optionobject1];
    
    XLFormOptionsObject *optionobject2 = [XLFormOptionsObject formOptionsObjectWithValue:constants.SCHPrivacyOptionClient displayText:constants.SCHPrivacyOptionClient.lookupText];
    [privacyPreferences addObject:optionobject2];
    
    return privacyPreferences;
    
}

+(NSArray *)autoConfirmOptions{
    NSMutableArray *options = [[NSMutableArray alloc] init];
    SCHConstants *constants = [SCHConstants sharedManager];
    
    XLFormOptionsObject *optionobject1 = [XLFormOptionsObject formOptionsObjectWithValue:constants.SCHAutoConfirmOptionNone displayText:constants.SCHAutoConfirmOptionNone.lookupText];
    [options addObject:optionobject1];
    
    XLFormOptionsObject *optionobject2 = [XLFormOptionsObject formOptionsObjectWithValue:constants.SCHAutoConfirmOptionClient displayText:constants.SCHAutoConfirmOptionClient.lookupText];
    [options addObject:optionobject2];
    
    XLFormOptionsObject *optionobject3 = [XLFormOptionsObject formOptionsObjectWithValue:constants.SCHAutoConfirmOptionPublic displayText:constants.SCHAutoConfirmOptionPublic.lookupText];
    [options addObject:optionobject3];
    
    XLFormOptionsObject *optionobject4 = [XLFormOptionsObject formOptionsObjectWithValue:constants.SCHAutoConfirmOptionSpecificClients displayText:constants.SCHAutoConfirmOptionSpecificClients.lookupText];
    [options addObject:optionobject4];
    
    
    
    
    return options;
}


+(NSArray *)userFeedbackType{
    NSMutableArray *options = [[NSMutableArray alloc] init];
    SCHConstants *constants = [SCHConstants sharedManager];
    
    XLFormOptionsObject *optionobject1 = [XLFormOptionsObject formOptionsObjectWithValue:constants.SCHUserFeedbackIssue displayText:constants.SCHUserFeedbackIssue.lookupText];
    [options addObject:optionobject1];
    
    XLFormOptionsObject *optionobject2 = [XLFormOptionsObject formOptionsObjectWithValue:constants.SCHUserFeedbackSuggestion displayText:constants.SCHUserFeedbackSuggestion.lookupText];
    [options addObject:optionobject2];
    
    return options;
    
}

+(NSArray *)getMajorServiceClassification:(BOOL) local{
    
    NSError *error = nil;
    PFQuery *majorServiceClassificationQuery = [SCHServiceMajorClassification query];
    if (local){
       [majorServiceClassificationQuery fromLocalDatastore];
    }
    [majorServiceClassificationQuery whereKey:@"visible" equalTo:@YES];
    [majorServiceClassificationQuery orderByAscending:@"majorClassification"];
    NSArray *majorServiceClassifications = [majorServiceClassificationQuery findObjects:&error];
    if (error){
        return @[];
    }
    return majorServiceClassifications;
}

+(NSArray *)getServiceClassification:(SCHServiceMajorClassification *) majorClassification{
    NSError *error = nil;
    PFQuery *serviceClassificationQuery = [SCHServiceClassification query];
    [serviceClassificationQuery whereKey:@"majorClassification" equalTo:majorClassification];
    [serviceClassificationQuery whereKey:@"visible" equalTo:@YES];
    [serviceClassificationQuery orderByAscending:@"serviceTypeName"];
    NSArray *serviceClassifications = [serviceClassificationQuery findObjects:&error];
    if (error){
        return @[];
    }
    return serviceClassifications;
    
}

+(NSArray *) getMajorServiceClassificationList {
    
    NSMutableArray *majorServiceClassificationList = [[NSMutableArray alloc] init];
    NSError *error = nil;
    PFQuery *majorServiceClassificationQuery = [SCHServiceMajorClassification query];
    [majorServiceClassificationQuery orderByAscending:@"majorClassification"];
    NSArray *majorServiceClassifications = [majorServiceClassificationQuery findObjects:&error];
    if (error){
        return @[];
    }
    for (SCHServiceMajorClassification *obj in majorServiceClassifications){
        XLFormOptionsObject *optionobject = [XLFormOptionsObject formOptionsObjectWithValue:obj displayText:obj.majorClassification];
        [majorServiceClassificationList addObject:optionobject];
    }
    return majorServiceClassificationList;
}


+(NSArray *)getServiceClassificationList:(SCHServiceMajorClassification *) majorClassification{
    NSMutableArray *minorServiceClassificationList = [[NSMutableArray alloc] init];
    NSError *error = nil;
    PFQuery *serviceClassificationQuery = [SCHServiceClassification query];
    [serviceClassificationQuery whereKey:@"majorClassification" equalTo:majorClassification];
    [serviceClassificationQuery orderByAscending:@"serviceTypeName"];
    NSArray *serviceClassifications = [serviceClassificationQuery findObjects:&error];
    if (error){
        return @[];
    }
    
    for (SCHServiceClassification *obj in serviceClassifications){
        XLFormOptionsObject *optionobject = [XLFormOptionsObject formOptionsObjectWithValue:obj displayText:obj.serviceTypeName];
        [minorServiceClassificationList addObject:optionobject];
    }
    
    return minorServiceClassificationList;
}



+(NSArray *)ServiceProviderListForService:(SCHServiceClassification *) serviceType {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
    NSError *error = nil;
    NSMutableArray *serviceProviderList = [[NSMutableArray alloc] init];
    
    
    NSPredicate *serviceProvidersPredicate = [NSPredicate predicateWithFormat:@"active = TRUE AND suspended != TRUE AND serviceClassification = %@ AND user != %@", serviceType, appDelegate.user];
    
    PFQuery *serviceProvidersQuery = [PFQuery queryWithClassName:SCHServiceClass predicate:serviceProvidersPredicate];
    [serviceProvidersQuery includeKey:@"user"];
    
    NSArray *serviceProviders = [serviceProvidersQuery findObjects:&error];
    if (error){
        return serviceProviderList;
    }
    
    
    for (SCHService *service in serviceProviders){
        if ([service.profileVisibilityControl isEqual:constants.SCHPrivacyOptionPublic] || !(service.profileVisibilityControl)){
            [serviceProviderList addObject:service];
            
        } else if ([service.profileVisibilityControl isEqual:constants.SCHPrivacyOptionClient]){
            PFQuery *ClientListsQuery = [SCHServiceProviderClientList query];
            [ClientListsQuery whereKey:@"serviceProvider" equalTo:service.user];
            [ClientListsQuery whereKey:@"client" equalTo:appDelegate.user];
            
            int clientlistCount = (int)[ClientListsQuery countObjects];
            
            if (clientlistCount> 0){
                [serviceProviderList addObject:service];
            }
            
            
        } else{
            [serviceProviderList addObject:service];
        }
        
        
    }
    // Add locations and earliest Availability
    
    return serviceProviderList;
}


+(NSArray *)userFevotiteServices:(SCHUser *) user{
    NSError *error = nil;
    NSMutableArray *fevoriteServices = [[NSMutableArray alloc] init];
    PFQuery *fevoriteQuery = [SCHUserFevoriteService query];
    [fevoriteQuery whereKey:@"user" equalTo:user];
    [fevoriteQuery includeKey:@"service"];
    [fevoriteQuery includeKey:@"service.user"];
    [fevoriteQuery includeKey:@"service.serviceClassification"];
    
    NSSet *fevoriteSet = [[NSSet alloc] initWithArray:[fevoriteQuery findObjects:&error]];
    
    if (error){
        return fevoriteServices;
    } else{
        for (SCHUserFevoriteService *fevService in fevoriteSet){
            [fevoriteServices addObject:fevService.service];
        }
        return fevoriteServices;
    }
    
}









#pragma mark - Date Related APIs

+(NSString *)getCurrentDate: (NSDate *) date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSLocale *preferredLocal = [NSLocale currentLocale];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setLocale:preferredLocal];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterNoStyle];
    
    return  [formatter stringFromDate:date];
}

+(NSDate *)getDate:(NSDate *) date{
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSCalendarUnit units =  NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *components =[preferredCalendar components:units fromDate:date];
    return [preferredCalendar dateFromComponents:components];
    
}

+(NSDateFormatter *)dateFormatterForShortDate{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *preferredLocale = [NSLocale currentLocale];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setLocale:preferredLocale];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    
    return formatter;
    
}
+(NSDateFormatter *)dateFormatterForMediumDate{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *preferredLocale = [NSLocale currentLocale];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setLocale:preferredLocale];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    return formatter;
    
}
+(NSDateFormatter *)dateFormatterForLongDate{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *preferredLocale = [NSLocale currentLocale];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setLocale:preferredLocale];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    
    return formatter;
    
}

+(NSDateFormatter *)dateFormatterForFullDate{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *preferredLocale = [NSLocale currentLocale];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setLocale:preferredLocale];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setDateStyle:NSDateFormatterFullStyle];
    
    return formatter;
    
}



+(NSDateFormatter *)dateFormatterForShortTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *preferredLocale = [NSLocale currentLocale];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setLocale:preferredLocale];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    return formatter;
    
}
+(NSDateFormatter *)dateFormatterForMediumTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *preferredLocale = [NSLocale currentLocale];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setLocale:preferredLocale];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    
    return formatter;
    
}
+(NSDateFormatter *)dateFormatterForLongTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *preferredLocale = [NSLocale currentLocale];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setLocale:preferredLocale];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setTimeStyle:NSDateFormatterLongStyle];
    
    return formatter;
    
}


+(NSDateFormatter *)dateFormatterForShortDateAndTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *preferredLocale = [NSLocale currentLocale];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setLocale:preferredLocale];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    return formatter;
    
}
+(NSDateFormatter *)dateFormatterForMediumDateAndTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *preferredLocale = [NSLocale currentLocale];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setLocale:preferredLocale];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    
    return formatter;
    
}
+(NSDateFormatter *)dateFormatterForLongDateAndTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *preferredLocale = [NSLocale currentLocale];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setLocale:preferredLocale];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    [formatter setTimeStyle:NSDateFormatterLongStyle];
    
    return formatter;
    
}
/*

+(NSDateFormatter *)dateFormaterForScheduleSectionHeader{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE MMM d, yy"];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSLocale *preferredLocal = [NSLocale currentLocale];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setLocale:preferredLocal];
    return formatter;
}
 */

+(NSDateFormatter *)dateFormatterForShortMonAndDate{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSLocale *preferredLocal = [NSLocale currentLocale];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setLocale:preferredLocal];
    [formatter setDateFormat:@"MMM d"];
    
    
    return  formatter;
    
}



+(NSDateFormatter *)dateFormatterForFromTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSLocale *preferredLocal = [NSLocale currentLocale];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setLocale:preferredLocal];
    [formatter setDateStyle:NSDateFormatterFullStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    return formatter;
    
}
+(NSDateFormatter *)dateFormatterForToTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSLocale *preferredLocal = [NSLocale currentLocale];
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    
    [formatter setCalendar:preferredCalendar];
    [formatter setTimeZone:currentTimeZone];
    [formatter setLocale:preferredLocal];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    return formatter;
    
}

+(NSDate *)startOrEndTime:(NSDate *) date{
    NSCalendar *preferredCalender = [NSCalendar currentCalendar];
    NSCalendarUnit units = NSCalendarUnitTimeZone | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour |NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *components = [preferredCalender components:units fromDate:date];
    components.minute = (components.minute%15 == 0)? (components.minute/15)*15 : (components.minute/15)*15 +15;
    components.second = 0;
    
    return [preferredCalender dateFromComponents:components];
}


#pragma  mark - Create color from Color code


+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (UIColor *)colorFromHexStringhalfAlpha:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:0.5];
}

+(BOOL)hasActiveService{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PFQuery *activeService = [SCHService query];
    [activeService whereKey:@"user" equalTo:appDelegate.user];
    [activeService whereKey:@"active" equalTo:@YES];
    [activeService whereKey:@"suspended" notEqualTo:@YES];
    
   // NSPredicate *activeServicePredicate = [NSPredicate predicateWithFormat:@"user = %@ AND active = YES", appDelegate.user];
  //  PFQuery *activeService = [PFQuery queryWithClassName:SCHServiceClass predicate:activeServicePredicate];
    [activeService fromLocalDatastore];
    
    
    
    return  ([activeService countObjects] > 0) ? YES : NO;
    
    
}

+(UIFont *)getPreferredBodyFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

+(UIFont *)getPreferredTitleFont{
    return [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
}
+(UIFont *)getPreferredSubtitleFont{
    return [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}

+(UIColor *)deepGrayColor{
    UIColor *color = [UIColor colorWithRed:88/255 green:88/255 blue:88/255 alpha:0.7];
    
    return color;
}

+(UIColor *)greenColor{
    return  [UIColor colorWithRed:28.0/255.0
                            green:159.0/255.0
                             blue:81.0/255.0
                            alpha:1];
}

+(UIColor *)brightOrangeColor{
    return  [UIColor colorWithRed:255/255.0 green:86/255 blue:33/255 alpha:1.0];
}

+(UIColor *)seaBlueColor{
    return  [UIColor colorWithRed:1/255 green:187/255 blue:211/255 alpha:1.0];
    
    
}





+(UIColor *)lightBlueColor{
    return  [UIColor colorWithRed:223/255.0 green:246/255 blue:249/255 alpha:1.0];

}

+(UIColor *)mercuryColor{
    return  [UIColor colorWithRed:230/255.0 green:230/255 blue:230/255 alpha:1.0];
    
}






+(NSDictionary *)preferredTextDispalyFontAttr{
    NSMutableDictionary *preferredattr = [[NSMutableDictionary alloc] init];
    [preferredattr setObject:[self getPreferredBodyFont] forKey:NSFontAttributeName];
    [preferredattr setObject:[UIColor grayColor] forKey:NSForegroundColorAttributeName];
    
    return preferredattr;
}


/*****************************************/
#pragma mark - ACL
/*****************************************/

+(void)setPublicAllRWACL:(PFACL *) acl{
    [acl setPublicReadAccess:YES];
    [acl setPublicWriteAccess:YES];
    [acl setShouldGroupAccessibilityChildren:YES];
    
    
}
+(void)setPublicAllROACL:(PFACL *) acl{
    
    [acl setPublicReadAccess:YES];
    [acl setPublicWriteAccess:NO];
    [acl setShouldGroupAccessibilityChildren:YES];
    
}
+(void) setNoPublicAccessACL:(PFACL *) acl{
    [acl setPublicReadAccess:NO];
    [acl setPublicWriteAccess:NO];
    [acl setShouldGroupAccessibilityChildren:YES];
    
}

+(PFACL *)publicAdultOnlyRWACL{
    PFACL *acl = [PFACL ACL];
    [acl setPublicReadAccess:YES];
    [acl setPublicWriteAccess:YES];
    [acl setShouldGroupAccessibilityChildren:NO];
    
    return acl;
    
    
}
+(PFACL *)publicAdultOnlyROACL{
    PFACL *acl = [PFACL ACL];
    [acl setPublicReadAccess:YES];
    [acl setPublicWriteAccess:NO];
    [acl setShouldGroupAccessibilityChildren:NO];
    
    return acl;
    
    
}

+(PFACL *)noPublicAccessACL{
    PFACL *acl = [PFACL ACL];
    [acl setPublicReadAccess:NO];
    [acl setPublicWriteAccess:NO];
    [acl setShouldGroupAccessibilityChildren:NO];
    
    return acl;
    
    
}
/*
+(PFACL *)privateRWACL:(PFUser *) user{
    PFACL *acl = [PFACL ACL];
    [acl setReadAccess:YES forUser:user];
    [acl setWriteAccess:YES forUser:user];
    
    return acl;
}

*/




+(NSArray *)getDaysforschedulingwithStartTime:(NSDate *) startTime endTime:(NSDate *) endTime endDate:(NSDate *) endDate repeatOption:(NSString *) repeatOption repeatDays:(NSArray *) repeatDays{
    
  //  NSLog(@"Processing getDaysForScheduling");
    
    if (debug){
        NSLog(@"StartTime: %@ - EndTime: %@", startTime, endTime);
    }
    
    
    NSMutableArray *schedulingDays = [[NSMutableArray alloc] init];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *day = [[NSDateComponents alloc] init];
    
    [day setDay:1];
    
    NSDateComponents *week = [[NSDateComponents alloc] init];
    
    [week setDay:7];
    
    NSDateComponents *twoWeeks = [[NSDateComponents alloc] init];
    
    [twoWeeks setDay:14];
    
    NSDateComponents *month = [[NSDateComponents alloc] init];
    [month setMonth:1];
    
    
  //  NSCalendarUnit units = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute|NSCalendarUnitWeekday | NSCalendarUnitTimeZone;
    

   // NSDateComponents *endTimeComponents = [calendar components:units fromDate:endTime];
    
    NSTimeInterval duration = [endTime timeIntervalSinceDate:startTime];
    
    
    
    
    if (repeatOption != SCHSelectorRepeatationOptionSpectficDaysOftheWeek) {
        
        
        NSDate *scheduleStartTime = startTime;
        NSDate *scheduleEndTime = nil;
        
        if(debug){
            NSLog(@"Start Time: %@", startTime);
        }

        
        while ([scheduleStartTime compare:endDate] == NSOrderedAscending || [scheduleStartTime compare:endDate] == NSOrderedSame){
            
            /*
            
            NSDateComponents *scheduleStartTimeComponents = [calendar components:units fromDate:scheduleStartTime];
            if (debug){
                NSLog(@"SCheduleStartTimeComponents:%@", scheduleStartTimeComponents);
            }
            
            
            NSDateComponents *scheduleEndTimeComponents = [[NSDateComponents alloc] init];
            
            [scheduleEndTimeComponents setYear:[scheduleStartTimeComponents year]];
            [scheduleEndTimeComponents setMonth:[scheduleStartTimeComponents month]];
            [scheduleEndTimeComponents setDay:[scheduleStartTimeComponents day]];
            [scheduleEndTimeComponents setHour:[endTimeComponents hour]];
            [scheduleStartTimeComponents setMinute:[endTimeComponents minute]];
            
            
            scheduleEndTime = [calendar dateFromComponents:scheduleEndTimeComponents];
             
             */
            scheduleEndTime = [NSDate dateWithTimeInterval:duration sinceDate:scheduleStartTime];
            
            NSDictionary *startAndEndTime = @{@"startTime" : scheduleStartTime, @"endTime" : scheduleEndTime};
            
            if (debug){
                NSLog(@"StartTime: %@ - EndTime: %@", [startAndEndTime valueForKey:@"startTime"], [startAndEndTime valueForKey:@"endTime"]);
            }
            
            
            
            [schedulingDays addObject:startAndEndTime];
            
            // determine next scheduling  start time
            if (repeatOption == SCHSelectorRepeatationOptionEveryDay){
                
                scheduleStartTime = [calendar dateByAddingComponents:day toDate:scheduleStartTime options:NSCalendarMatchFirst];
                
            } else if ([repeatOption isEqualToString:SCHSelectorRepeatationOptionEveryWeek]){
                
                scheduleStartTime = [calendar dateByAddingComponents:week toDate:scheduleStartTime options:NSCalendarMatchFirst];
                
            } else if ([repeatOption isEqualToString:SCHSelectorRepeatationOptionEvery2Weeks]){
                scheduleStartTime = [calendar dateByAddingComponents:twoWeeks toDate:scheduleStartTime options:NSCalendarMatchFirst];
            } else if ([repeatOption isEqualToString:SCHSelectorRepeatationOptionEveryMonth]){
                scheduleStartTime = [calendar dateByAddingComponents:month toDate:scheduleStartTime options:NSCalendarMatchFirst];
            }
            
        }
    } else if (repeatOption == SCHSelectorRepeatationOptionSpectficDaysOftheWeek) {
        
        
        for (int i = 0; i < [repeatDays count]; i++) {
            int dayOfWeekCode = ([repeatDays[i] isEqualToString:SCHSelectorRepeatationOptionSunday]) ? 1 : ([repeatDays[i] isEqualToString:SCHSelectorRepeatationOptionMonday]) ? 2 : ([repeatDays[i] isEqualToString:SCHSelectorRepeatationOptionTuesday]) ? 3 : ([repeatDays[i] isEqualToString:SCHSelectorRepeatationOptionWednesday]) ? 4: ([repeatDays[i] isEqualToString:SCHSelectorRepeatationOptionThursday]) ? 5 : ([repeatDays[i] isEqualToString:SCHSelectorRepeatationOptionFriday]) ? 6 : ([repeatDays[i] isEqualToString:SCHSelectorRepeatationOptionSaturday]) ? 7 : 0;
            
            
            NSDateComponents *weekDay = [[NSDateComponents alloc] init];
            [weekDay setWeekday:dayOfWeekCode];
                                 
            NSDate *scheduleStartTime = startTime;
            NSDate *scheduleEndTime = [[NSDate alloc] init];
            
        
            while ([scheduleStartTime compare:endDate] == NSOrderedAscending || [scheduleStartTime compare:endDate] == NSOrderedSame){
                
                
                if ([calendar date:scheduleStartTime matchesComponents:weekDay]) {
                    
                    /*
                    
                    NSDateComponents *scheduleStartTimeComponents = [calendar components:units fromDate:scheduleStartTime];
                    
                    NSDateComponents *scheduleEndTimeComponents = [[NSDateComponents alloc] init];
                    
                    [scheduleEndTimeComponents setYear:[scheduleStartTimeComponents year]];
                    [scheduleEndTimeComponents setMonth:[scheduleStartTimeComponents month]];
                    [scheduleEndTimeComponents setDay:[scheduleStartTimeComponents day]];
                    [scheduleEndTimeComponents setHour:[endTimeComponents hour]];
                    [scheduleStartTimeComponents setMinute:[endTimeComponents minute]];
                    
                    
                    scheduleEndTime = [calendar dateFromComponents:scheduleEndTimeComponents];
                     
                     */
                    scheduleEndTime = [NSDate dateWithTimeInterval:duration sinceDate:scheduleStartTime];
                    
                    NSDictionary *startAndEndTime = @{@"startTime" : scheduleStartTime, @"endTime" : scheduleEndTime};
                    
                    [schedulingDays addObject:startAndEndTime];
                    
                }
                
                scheduleStartTime = [calendar dateByAddingComponents:day toDate:scheduleStartTime options:NSCalendarMatchFirst];
            }
            
        }
        
        
    }
    
  
    
    
    return schedulingDays;
}

/*****************************************/
#pragma mark - logout
/*****************************************/

+(void) logout{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
   // if (appDelegate.serverReachable){
    
    
   
        
        
        [SCHUtility showProgressWithMessage:@"logging out ..."];
        [PFUser logOut];
        if (![PFUser currentUser]){
            appDelegate.dataSyncFailure = NO;
            [SCHUtility userToDeviceDelink];
            [PFObject unpinAllObjects];
            SCHScheduledEventManager *eventManager = [SCHScheduledEventManager sharedManager];
            [eventManager reset];
            [SCHConstants resetSharedManager];
            [FBSDKAccessToken setCurrentAccessToken:nil];
            [FBSDKProfile setCurrentProfile:nil];
            FBSDKLoginManager *loginmanager= [[FBSDKLoginManager alloc]init];
            [loginmanager logOut];
            if(appDelegate.syncTimer!=nil)
            [appDelegate.syncTimer invalidate];
            
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
            
            [appDelegate.objectsForProcessing reset];
            // [appDelegate.scheduledManager reset];
            [appDelegate setApplicationbadgeCount:0];
            SCHActiveViewControllers *vcs =[SCHActiveViewControllers sharedManager];
            [vcs.viewControllers removeAllObjects];
            appDelegate.user = nil;
            
        }

        
        [SCHUtility completeProgress];
    
    /*
    } else{
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                           message:[NSString stringWithFormat:@"Internet connection required for logging out."]
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        
        return;
    }
     */




}




/*****************************************/
#pragma mark - CreateNitification
/*****************************************/

+(SCHNotification *)createNotificationForUser:(SCHUser *) user notificationType:(SCHLookup *)notificationType notificationTitle:(NSString *) notificationTitle message:(NSString *) message referenceObject:(NSString *) referenceObject referenceObjectType:(NSString *) referenceObjectType{
    SCHNotification *notification = [SCHNotification object];
    
    notification.user = user;
    notification.notificationType = notificationType;
    notification.notificationTitle = notificationTitle;
    notification.message = message;
    notification.referenceObject = referenceObject;
    notification.referenceObjectType = referenceObjectType;
    notification.seen = NO;
    [self setPublicAllRWACL:notification.ACL];
    
    
    return notification;
    
}

+(void)sendNotification:(SCHNotification *) notification{
    NSString *user = notification.user.objectId;
    NSString *notificationTitle = notification.notificationTitle;
    
    
    
    
    [PFCloud callFunctionInBackground:@"sendNotification" withParameters:@{@"notificationTitle" : notificationTitle, @"user": user} block:^(id  _Nullable object, NSError * _Nullable error) {
        
        
        
        if (!error){
           // NSLog(@"Notification Sent");
        } else{
            NSLog(@"%@", error);
        }
    }];
    
}

+(BOOL) removeOldNotifications:(NSString *)refreenceObjectId{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSError *error = nil;
    NSPredicate *notificationPredicate = [NSPredicate predicateWithFormat:@"referenceObject = %@", refreenceObjectId];
    PFQuery *existingNotificationQuery = [PFQuery queryWithClassName:SCHNotificationClass predicate:notificationPredicate];
    NSArray *existingNotifications = [existingNotificationQuery findObjects:&error];
    
    if (!error){
        if (existingNotifications.count > 0){
            [appDelegate.backgroundCommit.objectsStagedForDelete addObjectsFromArray:existingNotifications];
            [appDelegate.backgroundCommit.objectsStagedForUnpin addObjectsFromArray:existingNotifications];
        }
        
    } else return NO;
    
    return YES;
    
}




+(NSArray *) clientlist {
    __block  NSMutableArray *clientList = [[NSMutableArray alloc] init];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHUser *currentUser = appDelegate.user;
    PFQuery *query =[SCHUser query];
    [query whereKey:@"objectId" notEqualTo:currentUser.objectId];
    
    
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error ) {
            //   NSLog(@"There are clients and client count is %lu", (unsigned long)objects.count);
            for (int i; i < objects.count; i++){
                SCHUser *user = objects[i];
                
                XLFormOptionsObject *optionobject = [XLFormOptionsObject formOptionsObjectWithValue:user displayText:user.preferredName];
                [clientList addObject:optionobject];
                
                
            }
        } //else NSLog(@"objects could not be retrieved");
    }];
    return clientList;
}




+(NSArray *)notificationsForUser{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHUser *user = appDelegate.user;
    NSMutableArray *notificationObjects = [[NSMutableArray alloc] init];
    NSPredicate *notificationPredicate = [NSPredicate predicateWithFormat:@"user = %@", user];
    PFQuery *notificationQuery = [PFQuery queryWithClassName:SCHNotificationClass predicate:notificationPredicate];
    for (SCHNotification *notification in[notificationQuery findObjects]) {
        if ([notification.referenceObjectType isEqualToString:SCHAppointmentClass]){
            PFQuery *notificationObjectQuery = [SCHAppointment query];
            [notificationQuery includeKey:@"service"];
            [notificationQuery includeKey:@"serviceOffering"];
            SCHAppointment *appointment = (SCHAppointment *)[notificationObjectQuery getObjectWithId:notification.referenceObject];
            NSDictionary *notificationObject = @{@"notification" : notification, @"referenceObject": appointment};
            [notificationObjects addObject:notificationObject];
            
        } else if ([notification.referenceObjectType isEqualToString:SCHAppointmentSeriesClass]){
            PFQuery *notificationObjectQuery  = [SCHAppointmentSeries query];
            [notificationObjectQuery includeKey:@"service"];
            [notificationQuery includeKey:@"serviceOffering"];
            SCHAppointmentSeries *appointmentSeries = (SCHAppointmentSeries *)[notificationObjectQuery getObjectWithId:notification.referenceObject];
            NSDictionary *notificationObject = @{@"notification" : notification, @"referenceObject": appointmentSeries};
            [notificationObjects addObject:notificationObject];
        } else if (!notification.referenceObjectType){
            NSDictionary *notificationObject = @{@"notification" : notification, @"referenceObject": [NSNull null]};
            [notificationObjects addObject:notificationObject];
        }
        
    }
    return notificationObjects;
}


/**************************************************/

#pragma  mark - Push

/*************************************************/

+(BOOL)userToDevicelink{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation[@"user"] = appDelegate.user;
    installation[@"syncDate"] = [NSNull null];
     return [installation save];
}

+(void)userToDeviceDelink {
    
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation[@"user"] = [NSNull null];
    
    installation[@"syncDate"] = [NSNull null];
    
    installation.badge = 0;
    [installation saveEventually];
}





/***************************************************/

#pragma  mark - Find Service Provider

/****************************************************/



+(NSDictionary *)availabilityForAppointment:(SCHUser *) serviceProvider service:(SCHService *) service {
    
    NSMutableDictionary *availabilities = [[NSMutableDictionary alloc] init];
    
    
    NSMutableSet *availabilitiesForAppointment = [[NSMutableSet alloc] init];
    
    NSPredicate *availabilitiesPredicate = [NSPredicate predicateWithFormat:@"user = %@ AND service = %@ AND endTime > %@", serviceProvider, service, [NSDate date]];
    PFQuery *availabilityQuery = [PFQuery queryWithClassName:SCHAvailabilityForAppointmentClass predicate:availabilitiesPredicate];
    [availabilityQuery includeKey:@"user"];
    [availabilityQuery includeKey:@"service"];
    
    [availabilitiesForAppointment addObjectsFromArray:[availabilityQuery findObjects]];
    
    NSMutableSet *availabilityDaysSet = [[NSMutableSet alloc] init];
    
    for (SCHAvailabilityForAppointment *availability in availabilitiesForAppointment){
        [availabilityDaysSet addObject:[self getDate:availability.startTime]];
    }
    
    NSSortDescriptor *availabilityDaysAsc = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    
    NSArray *availabilityDays = [availabilityDaysSet sortedArrayUsingDescriptors:@[availabilityDaysAsc]];
    
    for (NSDate *availabilityDay in availabilityDays){
        NSPredicate *dayAvailabilityPredicate = [NSPredicate predicateWithBlock:^BOOL(SCHAvailabilityForAppointment *availability, NSDictionary *bindings) {
            if ([[self getDate:availability.startTime] isEqualToDate:availabilityDay]){
                return YES;
            } else return NO;
        }];
        
        NSSortDescriptor *sortAvailabilitiesStartTime = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
        NSSortDescriptor *sortAvailabilitiesEndTime = [NSSortDescriptor sortDescriptorWithKey:@"endTime" ascending:YES];
        
        NSArray *availabilitiesOfDay = [[availabilitiesForAppointment filteredSetUsingPredicate:dayAvailabilityPredicate] sortedArrayUsingDescriptors:@[sortAvailabilitiesStartTime, sortAvailabilitiesEndTime]];
        
        NSDateFormatter *formatter = [self dateFormatterForFullDate];
        NSString *dayKey = [formatter stringFromDate:availabilityDay];
        
        [availabilities setObject:availabilitiesOfDay forKey:dayKey];
        
    }
    
    NSDictionary *availabilitiesForAppointmentDictonary = @{@"availabilityDays" : availabilityDays,
                                                            @"availabilities" : availabilities};
    
    
    
    return availabilitiesForAppointmentDictonary;
    
}

+(NSAttributedString*) getAvailabilityForAppointmentTitle:(SCHAvailabilityForAppointment*) availability
{
    UIFont *font = [self getPreferredTitleFont];
    NSDictionary *attrsDictionary =
    [NSDictionary dictionaryWithObject:font
                                forKey:NSFontAttributeName];
    
    
    NSString* locationString =availability.location;
    
    
    NSDateFormatter *scheduleTimeFormatter = [SCHUtility dateFormatterForToTime];
    NSString *startTimeString = [scheduleTimeFormatter stringFromDate:availability.startTime];
    NSString *endTimeString = [scheduleTimeFormatter stringFromDate:availability.endTime];
    
    NSString *appointmentHeader = [NSString stringWithFormat:@"From %@ to %@ at %@", startTimeString, endTimeString, locationString];
    
    NSAttributedString *header = [[NSAttributedString alloc] initWithString:appointmentHeader attributes:attrsDictionary];
    return header;
}


+(NSAttributedString *)getAvailabilityForAppointmentSubTitle:(SCHAvailabilityForAppointment*) availability {
    
    UIFont *font = [self getPreferredSubtitleFont];
    
    NSDictionary *attrsDictionary = @{NSFontAttributeName : font};
    
    NSString *minorTitle = [NSString stringWithFormat:@"%@", availability.service.serviceTitle];
    
    NSAttributedString *minorTitleString = [[NSAttributedString alloc] initWithString:minorTitle attributes:attrsDictionary];
    
    return minorTitleString;
}
/**************************************************/

#pragma  mark - Location Services

/*************************************************/

+(NSString *)createLocationAddress:(CLLocation *)location{
    NSMutableString *locationAddress = [[NSMutableString alloc] init];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
       // NSLog(@"Finding address");
        if (error) {
          //  NSLog(@"Error %@", error.description);
        } else {
            CLPlacemark *placemark = [placemarks lastObject];
            
            [locationAddress stringByAppendingString:[NSString stringWithFormat:@"%@", ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO)]];
           
        }
    }];
    
    return locationAddress;
    
}

+(CLPlacemark *)generateCLLocationfromAddress:(NSString *)address{
    
    __block CLPlacemark *placeMark = [[CLPlacemark alloc] init];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
           // NSLog(@"%@", error);
        } else {
            placeMark = [placemarks lastObject];

        }
    }];
    
    return placeMark;
}


/**************************************************/

#pragma  mark - User and Synchronization

/*************************************************/



+(BOOL)initializeSCheduleScreenFilter:(SCHUser *) user{
    
    BOOL success = YES;
    NSError *error = nil;
    
    PFQuery *scheduleScreenFilterQuery = [SCHScheduleScreenFilter query];
    [scheduleScreenFilterQuery whereKey:@"user" equalTo:user];
    
    NSArray *scheduleScreenFilterArray = [scheduleScreenFilterQuery findObjects:&error];
    
    if (error){
        return NO;
    }
    
    
    
    if (scheduleScreenFilterArray.count == 0){
        SCHScheduleScreenFilter *filter = [SCHScheduleScreenFilter object];
        filter.user = user;
        filter.availabilities = YES;
        filter.cancelledAppointments = NO;
        filter.expiredAppointments = NO;
        filter.confirmedAppointmentsIHaveBooked = YES;
        filter.confirmedAppointmentsForMyServices = YES;
        filter.pendingAppointmentsForMyServicesAwaitingMyResponse = YES;
        filter.pendingAppointmentsForMyServicesNotAwaitingMyResponse = YES;
        filter.pendingAppointmentsIHaveBookedAwaitingMyResponse = YES;
        filter.pendingAppointmentsIHaveBookedNotAwaitingMyResponse = YES;
        [self setPublicAllRWACL:filter.ACL];
        
        if (![filter save]){
            return NO;
        }
        
        [filter pin];
        
    

        
    }  else if (scheduleScreenFilterArray.count == 1){
               [scheduleScreenFilterArray[0] pin];
        
        
    } else {
        
        NSMutableArray *filterForDelete = [[NSMutableArray alloc] initWithArray:scheduleScreenFilterArray];
        [scheduleScreenFilterArray[0] pin];
        [filterForDelete removeObject:scheduleScreenFilterArray[0]];
        
        [PFObject unpinAll:filterForDelete];
        [PFObject deleteAll:filterForDelete];
    
    }
    
    return success;
}



#pragma mark -  Send Notification to schedule screen

+(void) reloadScheduleTableView{
 //   dispatch_queue_t backgroundQueue = [SCHBackgroundManager sharedManager].SCHSerialQueue;
     //   dispatch_barrier_async(backgroundQueue, ^{
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadScheduleTable" object:nil];
            });
      //  });
}
+(void) reloadNotificationTableView{
  //  dispatch_queue_t backgroundQueue = [SCHBackgroundManager sharedManager].SCHSerialQueue;
    //    dispatch_barrier_async(backgroundQueue, ^{
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadNotificationTable" object:nil];
            });
     //   });
}


#pragma mark - Add Progress bar
+(void)showProgressWithMessage:(NSString*) message onView:(UIView *)view
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        //Run UI Updates
    
    [KVNProgress showWithStatus:message onView:view];
    });
}
+(void)showProgressWithMessage:(NSString*) message
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        [KVNProgress showWithStatus:message];
    });
}
+(void)completeProgressWithStatus:(NSString *)status
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        [KVNProgress showSuccessWithStatus:status];
   });
}
+(void)completeProgress{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
    [KVNProgress dismiss];
    });
}
/******************************************************/
#pragma mark - table view cell content of Schedule Screen
/******************************************************/


+(NSString *) getEndDate:(NSDate *) endDate comparingStartDate:(NSDate *) startDate{
    
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
    NSString *startDay = [dayformatter stringFromDate:startDate];
    NSString *endDay = [dayformatter stringFromDate:endDate];
    
    if ([startDay isEqualToString:endDay]){
        return @"";
    } else{
        NSDateFormatter *shortDayFormatter = [self dateFormatterForShortMonAndDate];
        return [NSString stringWithFormat:@"on %@", [shortDayFormatter stringFromDate:endDate]];
    }
    
}



+(NSDictionary *)availabilityInfoForScheduleScreen:(SCHEvent *) event{
    
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSMutableAttributedString *availabilityCellContent = [[NSMutableAttributedString alloc] init];
    NSDateFormatter *scheduleTimeFormatter = [SCHUtility dateFormatterForToTime];
    NSMutableString *startTimeString = [[NSMutableString alloc] init];
    NSMutableString *endTimeString = [[NSMutableString alloc] init];
    NSMutableString *endDateString = [[NSMutableString alloc] init];
    NSMutableString *locationString = [[NSMutableString alloc] init];
    NSMutableString *title = [[NSMutableString alloc] init];
    
    
    if ([event.eventObject isKindOfClass:[SCHAvailability class]]){
        SCHAvailability *availability = event.eventObject;
        [startTimeString setString:[scheduleTimeFormatter stringFromDate:availability.startTime]];
        [endTimeString setString:[scheduleTimeFormatter stringFromDate:availability.endTime]];
        [endDateString  setString:[self getEndDate:availability.endTime comparingStartDate:availability.startTime]];
        
        [locationString setString:[NSString stringWithFormat:@"At %@",availability.location]];
        
        
        for (NSDictionary *serviceDict in availability.services){
            
            PFQuery *serviceQuery =[SCHService query];
            [serviceQuery fromLocalDatastore];
            
            SCHService *service = (SCHService *)[serviceDict valueForKey:@"service"];
            if (service.serviceTitle.length == 0){
                service = [serviceQuery getObjectWithId:service.objectId];
            }
            if (service.serviceTitle.length > 0){
                if(title.length >0)
                    [title appendFormat:@"\n"];
                
                [title appendString:service[@"serviceTitle"]];
            }
            
            
        }
        if (title.length == 0){
            [title appendString:@"Available"];
        }
        
    } else if ([event.eventObject isKindOfClass:[SCHAvailabilityForAppointment class]]){
        
        SCHAvailabilityForAppointment *availabilityForAppointment = event.eventObject;
        [startTimeString setString:[scheduleTimeFormatter stringFromDate:availabilityForAppointment.startTime]];
        [endTimeString setString:[scheduleTimeFormatter stringFromDate:availabilityForAppointment.endTime]];
        [endDateString  setString:[self getEndDate:availabilityForAppointment.endTime comparingStartDate:availabilityForAppointment.startTime]];
        
        
        [locationString setString:[NSString stringWithFormat:@"At %@",availabilityForAppointment.location]];
        [title setString:availabilityForAppointment.service.serviceTitle];
        
        
    }
    
    // Set time string
    
    //build string attributes for time
    NSDictionary *timeAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                               NSForegroundColorAttributeName : [self deepGrayColor]};
    NSDictionary *endTimeAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                               NSForegroundColorAttributeName : [UIColor lightGrayColor]};
    
    NSDictionary *endDateAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                  NSForegroundColorAttributeName : [UIColor redColor]};
    
    NSString *timeString = [NSString stringWithFormat:@"%@\n", startTimeString];
    
    
    
    
    NSMutableAttributedString *timeAttributedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttr];
    [timeAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:endTimeString attributes:endTimeAttr] ];
    
    if (endDateString.length > 0){
        [timeAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", endDateString] attributes:endDateAttr] ];
    }
    
    // Body content
    NSDictionary *titleAttr = @{NSFontAttributeName : [self getPreferredTitleFont],
                                NSForegroundColorAttributeName : [self deepGrayColor]};
    NSDictionary *subTitleAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                   NSForegroundColorAttributeName : [self deepGrayColor]};
    
    UIFontDescriptor *subtitleFontDescriptor = [[self getPreferredSubtitleFont] fontDescriptor];
    UIFontDescriptorSymbolicTraits traits = subtitleFontDescriptor.symbolicTraits;
    traits |= UIFontDescriptorTraitItalic;
    
    UIFontDescriptor *statusFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:traits];
    
    UIFont *statusFont = [UIFont fontWithDescriptor:statusFontDescriptor size:0];
    
    NSMutableParagraphStyle *statusStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [statusStyle setAlignment:NSTextAlignmentRight];
    
    NSDictionary *statusAttr = @{NSFontAttributeName : statusFont,
                                 NSForegroundColorAttributeName : [UIColor blueColor],
                                 NSParagraphStyleAttributeName: statusStyle};
    NSString *subTitle  = locationString;
    
    NSString *status = [NSString stringWithFormat:@"Available"];
    
    [availabilityCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
    [availabilityCellContent appendAttributedString:newline];
    [availabilityCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:subTitle attributes:subTitleAttr]];
    [availabilityCellContent appendAttributedString:newline];
    [availabilityCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:status attributes:statusAttr] ];
    
    
    NSDictionary *availabilityContent = @{@"time" :timeAttributedString,
                                         @"content": availabilityCellContent};
    
    
    return availabilityContent;
    
    
}


+(NSDictionary *)meetupInfoForScheduleScreen:(SCHEvent *) event{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSMutableAttributedString *meetingCellContent = [[NSMutableAttributedString alloc] init];
    NSDateFormatter *scheduleTimeFormatter = [SCHUtility dateFormatterForToTime];
    NSMutableString *startTimeString = [[NSMutableString alloc] init];
    NSMutableString *endTimeString = [[NSMutableString alloc] init];
    NSMutableString *locationString = [[NSMutableString alloc] init];
    NSMutableString *title = [[NSMutableString alloc] init];
    SCHMeeting *meeting = event.eventObject;
    
    //********************************
    //Build Time String
    //**********************************

    [startTimeString setString:[scheduleTimeFormatter stringFromDate:meeting.startTime]];
    [endTimeString setString:[scheduleTimeFormatter stringFromDate:meeting.endTime]];
    [locationString setString:[NSString stringWithFormat:@"At %@",meeting.location]];
    //********************************
    //Build content String
    //**********************************
    
    if ([meeting.organizer isEqual:appDelegate.user]){
        [title appendString:meeting.subject];
    } else{
        [title appendString:meeting.subject];
    }
    
    NSString *subtitle = [NSString localizedStringWithFormat:@"Organizer: %@\n %@", meeting.organizer.preferredName, locationString];
    
    NSString *status = [self getmeetupStatus:event];
    
    
    //build string attributes for time
    NSDictionary *timeAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                               NSForegroundColorAttributeName : [self deepGrayColor]};
    NSDictionary *endTimeAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                  NSForegroundColorAttributeName : [UIColor lightGrayColor]};
    
    NSDictionary *endDateAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                  NSForegroundColorAttributeName : [UIColor redColor]};
    
    NSString *timeString = [NSString stringWithFormat:@"%@\n", startTimeString];
    
    
    NSMutableAttributedString *timeAttributedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttr];
    [timeAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:endTimeString attributes:endTimeAttr] ];
    
    NSString *endDateString = [self getEndDate:meeting.endTime comparingStartDate:meeting.startTime];
    
    if (endDateString.length > 0){
        [timeAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",endDateString ] attributes:endDateAttr] ];
    }
    
    // Body content
    NSDictionary *titleAttr = @{NSFontAttributeName : [self getPreferredTitleFont],
                                NSForegroundColorAttributeName : [self deepGrayColor]};
    NSDictionary *subTitleAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                   NSForegroundColorAttributeName : [self deepGrayColor]};
    
    UIFontDescriptor *subtitleFontDescriptor = [[self getPreferredSubtitleFont] fontDescriptor];
    UIFontDescriptorSymbolicTraits traits = subtitleFontDescriptor.symbolicTraits;
    traits |= UIFontDescriptorTraitItalic;
    
    UIFontDescriptor *statusFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:traits];
    
    
    UIFont *statusFont = [UIFont fontWithDescriptor:statusFontDescriptor size:0];
    
    NSMutableParagraphStyle *statusStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [statusStyle setAlignment:NSTextAlignmentRight];
    
    //Confirmed status font
    
    NSDictionary *confirmedSstatusAttr = @{NSFontAttributeName : statusFont,
                                 NSForegroundColorAttributeName : [SCHUtility greenColor],
                                 NSParagraphStyleAttributeName: statusStyle};
    
    //Pending status font
    
    NSDictionary *pendingSstatusAttr = @{NSFontAttributeName : statusFont,
                                           NSForegroundColorAttributeName : [SCHUtility brightOrangeColor],
                                           NSParagraphStyleAttributeName: statusStyle};
    
    
    [meetingCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
    [meetingCellContent appendAttributedString:newline];
    [meetingCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:subtitle attributes:subTitleAttr]];
    [meetingCellContent appendAttributedString:newline];
    if ([status isEqualToString:@"Confirmed"]){
        [meetingCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:status attributes:confirmedSstatusAttr] ];
    } else{
        [meetingCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:status attributes:pendingSstatusAttr] ];
    }
    
    NSDictionary *meetingContent = @{@"time" :timeAttributedString,
                                          @"content": meetingCellContent};
    
    
    return meetingContent;
    

    
}

+(NSDictionary *)appointmentInfoForScheduleScreen:(SCHEvent *) event{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSMutableAttributedString *appointmentCellContent = [[NSMutableAttributedString alloc] init];
    SCHAppointment *appointment = event.eventObject;
    
    //********************************
    //Build Time String
    //**********************************
    
    NSDate *startTime = (!appointment.proposedStartTime || [appointment.proposedStartTime isEqual:[NSNull null]]) ? appointment.startTime :appointment.proposedStartTime;
    
    NSDate *endTime = (!appointment.proposedEndTime || [appointment.proposedEndTime isEqual:[NSNull null]]) ? appointment.endTime : appointment.proposedEndTime;
    
    NSString *endDateString = [self getEndDate:endTime comparingStartDate:startTime];
    NSDateFormatter *scheduleTimeFormatter = [SCHUtility dateFormatterForToTime];
    NSString *startTimeString = [scheduleTimeFormatter stringFromDate:startTime];
    NSString *endTimeString = [scheduleTimeFormatter stringFromDate:endTime];
    
    //build string attributes for time
    NSDictionary *timeAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                NSForegroundColorAttributeName : [self deepGrayColor]};
    NSDictionary *endTimeAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                  NSForegroundColorAttributeName : [UIColor lightGrayColor]};
    
    NSDictionary *endDateAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                  NSForegroundColorAttributeName : [UIColor redColor]};
    NSString *timeString = [NSString stringWithFormat:@"%@\n", startTimeString];
    
    NSMutableAttributedString *timeAttributedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttr];
    [timeAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:endTimeString attributes:endTimeAttr]];
    
    if (endDateString.length > 0){
        [timeAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", endDateString] attributes:endDateAttr]];
    }
    
    //********************************
    //Build content String
    //**********************************
    
    NSString *title = appointment.service.serviceTitle;
    UIFont *titleFont = [SCHUtility getPreferredSubtitleFont];
    UIImage *recurringIcon = [self imageWithImage:[UIImage imageNamed:@"Recurring.png"] scaledToSize:CGSizeMake(titleFont.pointSize+1, titleFont.pointSize+1)];
    SCHTextAttachment *recurringAttachment = [SCHTextAttachment new];
    recurringAttachment.image = recurringIcon;
    
    //NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:recurringAttachment];
    
    NSString *subTitle = nil;
    if ([[self getAppointmentClient:event] length] >0){
        
        if(appointment.appointmentSeries){
            subTitle =  [NSString stringWithFormat:@"Recurring %@ %@", appointment.serviceOffering.serviceOfferingName, [self getAppointmentClient:event]];
        } else{
            subTitle =  [NSString stringWithFormat:@"%@ %@", appointment.serviceOffering.serviceOfferingName, [self getAppointmentClient:event]];
        }
        
    } else {
        if (appointment.appointmentSeries){
            subTitle =  [NSString stringWithFormat:@"Recurring %@", appointment.serviceOffering.serviceOfferingName];
        } else{
            subTitle =  [NSString stringWithFormat:@"%@", appointment.serviceOffering.serviceOfferingName];
        }

        
        
    }
    
    SCHObjectsForProcessing *objectsForProcessing = [SCHObjectsForProcessing sharedManager];
    
    SCHLookup *appointmentStatus =([objectsForProcessing.objectsForProcessing containsObject:appointment]) ? constants.SCHappointmentStatusProcessing : appointment.status;
    

    
    if ([appointmentStatus isEqual:constants.SCHappointmentStatusConfirmed] && !appointment.expired){
        
        
        
        NSDictionary *titleAttr = @{NSFontAttributeName : [self getPreferredTitleFont],
                                    NSForegroundColorAttributeName : [self deepGrayColor]};
        NSDictionary *subTitleAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                       NSForegroundColorAttributeName : [self deepGrayColor]};
        
        UIFontDescriptor *subtitleFontDescriptor = [[self getPreferredSubtitleFont] fontDescriptor];
        UIFontDescriptorSymbolicTraits traits = subtitleFontDescriptor.symbolicTraits;
        traits |= UIFontDescriptorTraitItalic;
        
        UIFontDescriptor *statusFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:traits];
        
        UIFont *statusFont = [UIFont fontWithDescriptor:statusFontDescriptor size:0];
        
        NSMutableParagraphStyle *statusStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [statusStyle setAlignment:NSTextAlignmentRight];
        
        NSDictionary *statusAttr = @{NSFontAttributeName : statusFont,
                                     NSForegroundColorAttributeName : [self greenColor],
                                     NSParagraphStyleAttributeName: statusStyle};
        
        NSString *status = [NSString stringWithFormat:@"Confirmed"];
        
        
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
        if (appointment.appointmentSeries){
            [appointmentCellContent appendAttributedString:[NSAttributedString attributedStringWithAttachment:recurringAttachment]];
        }
        [appointmentCellContent appendAttributedString:newline];
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:subTitle attributes:subTitleAttr]];
        [appointmentCellContent appendAttributedString:newline];
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:status attributes:statusAttr] ];
        
        
        
    } else if([appointmentStatus isEqual:constants.SCHappointmentStatusPending] && !appointment.expired){
        
        NSString *waitTime = [self responseWaitTime:appointment.updatedAt];
        
        NSDictionary *titleAttr = @{NSFontAttributeName : [self getPreferredTitleFont],
                                    NSForegroundColorAttributeName : [self deepGrayColor]};
        NSDictionary *subTitleAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                       NSForegroundColorAttributeName : [self deepGrayColor]};
        
        UIFontDescriptor *subtitleFontDescriptor = [[self getPreferredSubtitleFont] fontDescriptor];
        UIFontDescriptorSymbolicTraits traits = subtitleFontDescriptor.symbolicTraits;
        traits |= UIFontDescriptorTraitItalic;
        
        UIFontDescriptor *statusFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:traits];
        
        UIFont *statusFont = [UIFont fontWithDescriptor:statusFontDescriptor size:0];
        
        NSMutableParagraphStyle *statusStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [statusStyle setAlignment:NSTextAlignmentRight];
        
        NSDictionary *statusAttr = @{NSFontAttributeName : statusFont,
                                     NSForegroundColorAttributeName : [self brightOrangeColor],
                                     NSParagraphStyleAttributeName: statusStyle};
        
        
        SCHAppointmentActivity *openactivity = event.openActivity;
        
        NSString *currentUserString = nil;
        NSString *nonCurrentUserString = nil;
        
        if (waitTime.length >0){
            currentUserString = [NSString stringWithFormat:@"Respond (waiting for %@)", waitTime];
            nonCurrentUserString = [NSString stringWithFormat:@"Awaiting response for %@", waitTime];
            
        } else{
            currentUserString = [NSString stringWithFormat:@"Respond"];
            nonCurrentUserString = [NSString stringWithFormat:@"Awaiting response"];
            
        }
        
        
        NSString *status = (openactivity.actionAssignedTo == appDelegate.user) ? currentUserString : nonCurrentUserString ;
        
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
        if (appointment.appointmentSeries){
            [appointmentCellContent appendAttributedString:[NSAttributedString attributedStringWithAttachment:recurringAttachment]];
        }
        [appointmentCellContent appendAttributedString:newline];
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:subTitle attributes:subTitleAttr]];
        [appointmentCellContent appendAttributedString:newline];
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:status attributes:statusAttr] ];
        
        
        
        
    } else if ([appointmentStatus isEqual:constants.SCHappointmentStatusProcessing]){
        NSDictionary *titleAttr = @{NSFontAttributeName : [self getPreferredTitleFont],
                                    NSForegroundColorAttributeName : [self deepGrayColor]};
        NSDictionary *subTitleAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                       NSForegroundColorAttributeName : [self deepGrayColor]};
        
        UIFontDescriptor *subtitleFontDescriptor = [[self getPreferredSubtitleFont] fontDescriptor];
        UIFontDescriptorSymbolicTraits traits = subtitleFontDescriptor.symbolicTraits;
        traits |= UIFontDescriptorTraitItalic;
        
        UIFontDescriptor *statusFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:traits];
        
        UIFont *statusFont = [UIFont fontWithDescriptor:statusFontDescriptor size:0];
        
        NSMutableParagraphStyle *statusStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [statusStyle setAlignment:NSTextAlignmentRight];
        
        NSDictionary *statusAttr = @{NSFontAttributeName : statusFont,
                                     NSForegroundColorAttributeName : [self deepGrayColor],
                                     NSParagraphStyleAttributeName: statusStyle};
        
        
        NSString *status = [NSString stringWithFormat:@"Processing"];
        
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
        if (appointment.appointmentSeries){
            [appointmentCellContent appendAttributedString:[NSAttributedString attributedStringWithAttachment:recurringAttachment]];
        }
        [appointmentCellContent appendAttributedString:newline];
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:subTitle attributes:subTitleAttr]];
        [appointmentCellContent appendAttributedString:newline];
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:status attributes:statusAttr] ];

        
        
        
    } else if ([appointmentStatus isEqual:constants.SCHappointmentStatusCancelled] && !appointment.expired){
        
        
        NSDictionary *titleAttr = @{NSFontAttributeName : [self getPreferredTitleFont],
                                    NSForegroundColorAttributeName : [self deepGrayColor]};
        NSDictionary *subTitleAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                       NSForegroundColorAttributeName : [self deepGrayColor]};
        
        UIFontDescriptor *subtitleFontDescriptor = [[self getPreferredSubtitleFont] fontDescriptor];
        UIFontDescriptorSymbolicTraits traits = subtitleFontDescriptor.symbolicTraits;
        traits |= UIFontDescriptorTraitItalic;
        
        UIFontDescriptor *statusFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:traits];
        
        UIFont *statusFont = [UIFont fontWithDescriptor:statusFontDescriptor size:0];
        
        NSMutableParagraphStyle *statusStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [statusStyle setAlignment:NSTextAlignmentRight];
        
        NSDictionary *statusAttr = @{NSFontAttributeName : statusFont,
                                     NSForegroundColorAttributeName : [self deepGrayColor],
                                     NSParagraphStyleAttributeName: statusStyle};
        
        
        NSString *status = [NSString stringWithFormat:@"Cancelled"];
        
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
        if (appointment.appointmentSeries){
            [appointmentCellContent appendAttributedString:[NSAttributedString attributedStringWithAttachment:recurringAttachment]];
        }
        [appointmentCellContent appendAttributedString:newline];
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:subTitle attributes:subTitleAttr]];
        [appointmentCellContent appendAttributedString:newline];
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:status attributes:statusAttr] ];
        
    } else if (appointment.expired){
        
        
        
        NSDictionary *titleAttr = @{NSFontAttributeName : [self getPreferredTitleFont],
                                    NSForegroundColorAttributeName : [self deepGrayColor]};
        NSDictionary *subTitleAttr = @{NSFontAttributeName : [self getPreferredSubtitleFont],
                                       NSForegroundColorAttributeName : [self deepGrayColor]};
        
        UIFontDescriptor *subtitleFontDescriptor = [[self getPreferredSubtitleFont] fontDescriptor];
        UIFontDescriptorSymbolicTraits traits = subtitleFontDescriptor.symbolicTraits;
        traits |= UIFontDescriptorTraitItalic;
        
        UIFontDescriptor *statusFontDescriptor = [subtitleFontDescriptor fontDescriptorWithSymbolicTraits:traits];
        
        UIFont *statusFont = [UIFont fontWithDescriptor:statusFontDescriptor size:0];
        
        NSMutableParagraphStyle *statusStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [statusStyle setAlignment:NSTextAlignmentRight];
        
        NSDictionary *statusAttr = @{NSFontAttributeName : statusFont,
                                     NSForegroundColorAttributeName : [self deepGrayColor],
                                     NSParagraphStyleAttributeName: statusStyle};
        
        
        NSString *status = [NSString stringWithFormat:@"Expired"];
        
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
        if (appointment.appointmentSeries){
            [appointmentCellContent appendAttributedString:[NSAttributedString attributedStringWithAttachment:recurringAttachment]];
        }
        [appointmentCellContent appendAttributedString:newline];
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:subTitle attributes:subTitleAttr]];
        [appointmentCellContent appendAttributedString:newline];
        [appointmentCellContent appendAttributedString:[[NSAttributedString alloc] initWithString:status attributes:statusAttr] ];
        
        
    }
    
    
     NSDictionary *appointmentContent = @{@"time" :timeAttributedString,
                           @"content": appointmentCellContent,
                           @"status": appointmentStatus};
    
    
    return appointmentContent;
}


+(NSString *)getAppointmentClient:(SCHEvent *) event
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHAppointment *appointment = (SCHAppointment *)event.eventObject;
    NSString *clientName = (appointment.client) ? appointment.client.preferredName : appointment.clientName;

    NSString *withWhom =(appDelegate.user == appointment.serviceProvider) ? clientName : appointment.serviceProvider.preferredName;
    
    if (withWhom.length == 0){
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([appDelegate.user isEqual:appointment.serviceProvider]){
            //get client
            if (appointment.client){
                if (appDelegate.serverReachable){
                    PFQuery *clientQuery = [SCHUser query];
                    SCHUser *client = [clientQuery getObjectWithId:appointment.client.objectId];
                    if (client){
                        [client unpin];
                        [client pin];
                    }
                }
            }
        
        } else{
            //get serviceProvider
            if (appDelegate.serverReachable){
                PFQuery *SPQuery = [SCHUser query];
                SCHUser *SP = [SPQuery getObjectWithId:appointment.serviceProvider.objectId];
                if (SP){
                    [SP unpin];
                    [SP pin];
                }
            }
            
            
        }
        
    }
    
    
    NSString *minorTitle = nil;
    if (withWhom.length > 0){
       minorTitle = [NSString stringWithFormat:@"with %@", withWhom];
    } else {
        minorTitle = [NSString stringWithFormat:@""];
    }
    
    
    
    return minorTitle;
}
 
 
+(NSAttributedString *)getAppointmentStatus: (SCHEvent *) event {
    SCHAppointmentActivity *openactivity = event.openActivity;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
   // NSLog(@"open activity: %@", openactivity);
    UIFont *font = [self getPreferredSubtitleFont];
    
    
    NSDictionary *attrsDictionary = @{NSFontAttributeName : font, NSForegroundColorAttributeName : [UIColor redColor] };

    
    NSString *status = (openactivity.actionAssignedTo == appDelegate.user) ? [NSString stringWithFormat:@"Awaiting your response"] : [NSString stringWithFormat:@"Awaiting %@'s response", openactivity.actionAssignedTo.preferredName];
    
    NSAttributedString *statusString = [[NSAttributedString alloc] initWithString:status attributes:attrsDictionary];
    return statusString;
}



+(NSString *) getlocation:(NSString *) location{
    NSMutableDictionary *addressComponents = [[NSMutableDictionary alloc] init];
    NSDataDetector* detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeAddress error:nil];
    NSString* addressString = location;
    NSArray* matches = [detector matchesInString:addressString options:0 range:NSMakeRange(0, addressString.length)];
    for(NSTextCheckingResult* match in matches)
    {
        if(match.resultType == NSTextCheckingTypeAddress)
        {
           // [addressComponents  = [match addressComponents];
            [addressComponents setDictionary:[match addressComponents]];
            ;
        }
    }
    NSString *locationString = [NSString stringWithFormat:@"%@, %@", [addressComponents valueForKey:@"City"], [addressComponents valueForKey:@"State"]];
    
    if (![addressComponents valueForKey:@"City"] || ![addressComponents valueForKey:@"State"]){
        locationString = location;
    }
    
    
    return locationString;
}

+(UITextView *)resizeTextView:(UITextView *) textView{
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fixedWidth, newSize.height);
    textView.frame = newFrame;
    return textView;
}

+(CGFloat)tableViewCellHeight:(UITextView *) textView width:(CGFloat) width{
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
//    CGFloat stdwidth = 310.00;

    
    CGFloat fixedWidth = screenWidth-92;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    
    return newSize.height;
}

+(SCHAppointmentActivity *)getOpenActivity:(SCHAppointment *) appointment{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
    
    SCHAppointmentActivity *openActivity = [SCHAppointmentActivity object];
    
    if ([appointment.status isEqual:constants.SCHappointmentStatusPending]){
        NSPredicate *openActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointment = %@ AND status = %@", appDelegate.user, appDelegate.user, appointment, constants.SCHappointmentActivityStatusOpen];
        PFQuery *openActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openActivityPredicate];
        [openActivityQuery includeKey:@"actionAssignedTo"];
        [openActivityQuery includeKey:@"actionInitiator"];
        [openActivityQuery includeKey:@"status"];
        [openActivityQuery includeKey:@"action"];
        [openActivityQuery fromLocalDatastore];
        NSArray *appointmentOpenActivity = [openActivityQuery findObjects];
        
        if (appointmentOpenActivity.count == 0){
            // check series
            if (appointment.appointmentSeries){
                // Get appointment Series  Open Activity
                NSPredicate *openSeriesActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointmentSeries = %@ AND status = %@", appDelegate.user, appDelegate.user, appointment.appointmentSeries, constants.SCHappointmentActivityStatusOpen];
                PFQuery *openSeriesActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openSeriesActivityPredicate];
                [openSeriesActivityQuery includeKey:@"actionAssignedTo"];
                [openSeriesActivityQuery includeKey:@"actionInitiator"];
                [openSeriesActivityQuery includeKey:@"status"];
                [openSeriesActivityQuery includeKey:@"action"];
                [openSeriesActivityQuery fromLocalDatastore];
                NSArray *appointmentSeriesOpenActivity = [openSeriesActivityQuery findObjects];
                
                if(appointmentSeriesOpenActivity.count > 0){
                    openActivity = appointmentSeriesOpenActivity.firstObject;
                } else {
                    //NSLog(@"couldn't retrieve apoen activity");
                    openActivity = NULL;
                }
            } else{
               // NSLog(@"couldn't retrieve apoen activity");
                openActivity = NULL;
            }

        }  else openActivity = appointmentOpenActivity.firstObject;
        
    }
    
    return openActivity;
}

+(SCHAppointmentActivity *)getOpenSeriesActivity:(SCHAppointmentSeries *) appointmentSeries{
    SCHConstants *constants = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHAppointmentActivity *openActivity = [SCHAppointmentActivity object];
    
    if ([appointmentSeries.status isEqual:constants.SCHappointmentStatusPending]){
        // Get appointment Series  Open Activity
        NSPredicate *openSeriesActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointmentSeries = %@ AND status = %@", appDelegate.user, appDelegate.user, appointmentSeries, constants.SCHappointmentActivityStatusOpen];
        PFQuery *openSeriesActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openSeriesActivityPredicate];
        [openSeriesActivityQuery includeKey:@"actionAssignedTo"];
        [openSeriesActivityQuery includeKey:@"actionInitiator"];
        [openSeriesActivityQuery includeKey:@"status"];
        [openSeriesActivityQuery includeKey:@"action"];
        [openSeriesActivityQuery fromLocalDatastore];
        NSArray *appointmentSeriesOpenActivity = [openSeriesActivityQuery findObjects];
        
        if(appointmentSeriesOpenActivity.count > 0){
            openActivity = appointmentSeriesOpenActivity.firstObject;
        } else {
           // NSLog(@"couldn't retrieve apoen activity");
            openActivity = NULL;
        }
        
    } else {
       // NSLog(@"couldn't retrieve apoen activity");
        openActivity = NULL;
    }
    
    return openActivity;
    
}


+(NSArray *)appointmentDetailContents:(id)object{
    

    SCHConstants *constants = [SCHConstants sharedManager];

    NSMutableString *objectType = [[NSMutableString alloc] init];
    
    //Appointment info
    
    SCHAppointment *appointment = [SCHAppointment object];
    SCHAppointmentActivity *openActivity = [SCHAppointmentActivity object];
    
    //Appointment Series info
    
    SCHAppointmentSeries *appointmentSeries = [SCHAppointmentSeries object];
    
    //Meetup Info
    SCHMeeting *meeting = [SCHMeeting object];

    
    
    
    
    if ([object isKindOfClass:[SCHAppointment class]]){
        appointment = (SCHAppointment *)object;
        [objectType setString:SCHAppointmentClass];
        // Get appointment status and open Activity
        if ([appointment.status isEqual:constants.SCHappointmentStatusPending]){
            openActivity = [self getOpenActivity:appointment];
            
        }
    } else if ([object isKindOfClass:[SCHAppointmentSeries class]]){
        //get appointment series info
        appointmentSeries = (SCHAppointmentSeries *)object;
        [objectType setString:SCHAppointmentSeriesClass];
        if ([appointmentSeries.status isEqual:constants.SCHappointmentStatusPending]){
            openActivity = [self getOpenSeriesActivity:appointmentSeries];
        }
        
        
    }else if ([object isKindOfClass:[SCHMeeting class]]){
        meeting = (SCHMeeting *) object;
        [objectType setString:SCHMeetingClass];
        
    }else if([object isKindOfClass:[SCHEvent class]]){
        // get appointment info
        SCHEvent *event = (SCHEvent *)object;
        if ([event.eventType isEqualToString:SCHAppointmentClass]){
            [objectType setString:SCHAppointmentClass];
            appointment = event.eventObject;
            if ([appointment.status isEqual:constants.SCHappointmentStatusPending]){
                openActivity = event.openActivity;
            }

        } else if ([event.eventType isEqualToString:SCHMeetingClass]){
            meeting = (SCHMeeting *) event.eventObject;
            [objectType setString:SCHMeetingClass];
        }
    }
    
    if ([objectType isEqualToString:SCHAppointmentClass]){
        
        return [self DetailContentOfAppointment:appointment openActivity:openActivity];
        
    } else if ([objectType isEqualToString:SCHAppointmentSeriesClass]){
        
        
        return [self detailContentOfAppointmentSeries:appointmentSeries openActivity:openActivity];
    } else if ([objectType isEqualToString:SCHMeetingClass]){
        
        return [self detailContentForMeetup:meeting];
        
    }else return @[];
    
    

}


+(NSArray *)detailContentOfAppointmentSeries:(SCHAppointmentSeries *) appointmentSeries openActivity:(SCHAppointmentActivity *) openActivity{
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
    NSMutableArray *seriesDetailContent = [[NSMutableArray alloc] init];
    NSDictionary *withWhom = nil;
    
    
    // Build Cells
    
    
    //withWhom
    SCHUser *user = nil;
    SCHNonUserClient *nonUser = nil;
    NSString *name = nil;
    
    if ([appDelegate.user isEqual:appointmentSeries.serviceProvider]){
        if (appointmentSeries.client){
            user = appointmentSeries.client;
            withWhom = @{@"user" : user};
        } else {
            nonUser = appointmentSeries.nonUserClient;
            name = appointmentSeries.clientName;
            withWhom = @{@"nonUser" : nonUser, @"name" : name};
        }
    }  else {
    withWhom = @{@"user" : appointmentSeries.serviceProvider};
    }



    
    
    //title
    NSString *title = [NSString stringWithFormat:@"%@ - %@", appointmentSeries.service.serviceTitle, appointmentSeries.serviceOffering.serviceOfferingName];
   // NSLog(@"TITLE: %@", title);
    
    // status
    NSMutableString *status = [[NSMutableString alloc] init];
    
    if ([appointmentSeries.status isEqual:constants.SCHappointmentStatusConfirmed]){
        [status setString:[NSString stringWithFormat:@"Confirmed"]];
    } else if ([appointmentSeries.status isEqual:constants.SCHappointmentStatusPending]){
        if ([openActivity.actionAssignedTo isEqual:appDelegate.user]){
            [status setString:[NSString stringWithFormat:@"Awaiting your response"]];
        } else{
            [status setString:[NSString stringWithFormat:@"Awaiting %@ response", openActivity.actionAssignedTo.preferredName]];
        }
    }
    
   // NSLog(@"Status: %@", status);
    
    // Get Date and Time
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
   // NSString *appointmentDay = [dayformatter stringFromDate:appointment.startTime];
    NSDateFormatter *fromTimeFormatter = [SCHUtility dateFormatterForFromTime];
    NSDateFormatter *toTimeFormatter = [SCHUtility dateFormatterForToTime];
    NSString *appointmentTime = [NSString stringWithFormat:@"from %@ to %@", [toTimeFormatter stringFromDate:appointmentSeries.startTime], [toTimeFormatter stringFromDate:appointmentSeries.endTime]];
    
   // NSLog(@"Appointment Time: %@", appointmentTime);
    
   //NSMutableString *proposedDay = [[NSMutableString alloc] init];
    NSMutableString *proposedTime = [[NSMutableString alloc] init];
    
    if (appointmentSeries.status == constants.SCHappointmentStatusPending && (appointmentSeries.proposedStartTime || appointmentSeries.proposedEndTime)){
        
        [proposedTime setString:[NSString stringWithFormat:@"%@ to %@", [fromTimeFormatter stringFromDate:appointmentSeries.proposedStartTime], [toTimeFormatter stringFromDate:appointmentSeries.proposedEndTime]]];
        
    } else {
        [proposedTime setString:@""];
    }
    
  //  NSLog(@"Proposed Time: %@", proposedTime);
    
    // repeatation optionrepeat options
    
    NSMutableString *repeatOptions = [[NSMutableString alloc] init];
    
    if ([appointmentSeries.repeatOption isEqualToString:SCHSelectorRepeatationOptionSpectficDaysOftheWeek]){
        
        NSMutableString *repeatDays = [[NSMutableString alloc] init];
        for (NSString *repeatDayString in appointmentSeries.repeatDays){
            [repeatDays appendString:[NSString stringWithFormat:@"%@, ", repeatDayString]];
        }
        
        NSString *repeatString = nil;
        if ([repeatDays length] > 0) {
            repeatString = [repeatDays substringToIndex:[repeatDays length] - 1];
        }
        
        [repeatOptions setString:[NSString stringWithFormat:@"occurs every %@ from %@ till %@", repeatString, [dayformatter stringFromDate:appointmentSeries.startTime], [dayformatter stringFromDate:appointmentSeries.endDate]]];
    

    } else {
        
        [repeatOptions setString:[NSString stringWithFormat:@"Occurs %@\nfrom %@ till %@", appointmentSeries.repeatOption, [[self dateFormatterForMediumDate] stringFromDate:appointmentSeries.startTime], [[self dateFormatterForMediumDate] stringFromDate:appointmentSeries.endDate]]];
    }

    
    
    
    // Add AppointmentSeries Summary to  detail content Array
    
    NSAttributedString *appointmentSummary = [self seriesSummaryCellContent:title
                                                                     status:status
                                                                 seriesTime:appointmentTime
                                                         proposedSeriesTime:proposedTime
                                                               repeatOption:repeatOptions];
    
    NSLog(@"appointment Summary: %@", appointmentSummary);
    
    
    [seriesDetailContent addObject:@{@"appointmentSummary" : @{@"content": appointmentSummary}}];
    
    //Add with Whom
    NSAttributedString *withWhomTitle = [[NSAttributedString alloc] initWithString:@"with" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ];
    
    [seriesDetailContent addObject:@{@"withWhom" : @{@"title": withWhomTitle,
                                                      @"content" : withWhom}}];
    
    //Get Location
    NSAttributedString *locationTitle = [[NSAttributedString alloc] initWithString:@"location" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ];
    
    if (appointmentSeries.proposedLocation){
        NSDictionary *locationContentAttr = @{NSFontAttributeName : [self getPreferredBodyFont],
                                              NSStrikethroughStyleAttributeName:[NSNumber numberWithBool:YES]};
        [seriesDetailContent addObject:@{@"appointmentLocation" : @{@"title": locationTitle,
                                                                     @"content" : [[NSAttributedString alloc] initWithString:appointmentSeries.location attributes:locationContentAttr]}}];
        
        
        // Add proposed location
        [seriesDetailContent addObject:@{@"appointmentLocation" : @{@"title": [[NSAttributedString alloc] initWithString:@"new location proposed" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]}], @"content" : [[NSAttributedString alloc] initWithString:appointmentSeries.proposedLocation attributes:@{NSFontAttributeName : [self getPreferredBodyFont]}]}}];
        
        
    } else {
        [seriesDetailContent addObject:@{@"appointmentLocation" : @{@"title": locationTitle,
                                                                     @"content" : [[NSAttributedString alloc] initWithString:appointmentSeries.location attributes:[self preferredTextDispalyFontAttr]]}}];
    }
    
    // Add Notes
    NSAttributedString *notesTitle = [[NSAttributedString alloc] initWithString:@"notes" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ];
    NSAttributedString *noteDetail = [[NSAttributedString alloc] initWithString:(appointmentSeries.note)?appointmentSeries.note:@"  " attributes:@{NSFontAttributeName : [self getPreferredBodyFont]}];
    
    [seriesDetailContent addObject:@{@"notes" : @{@"title": notesTitle,
                                                   @"content" : noteDetail}}];
     
     
     
    
    
    
    
    return seriesDetailContent;
}


+(NSAttributedString *)seriesSummaryCellContent:(NSString *) title status:(NSString *) status  seriesTime:(NSString *)seriesTime proposedSeriesTime:(NSString *)proposedSeriesTime repeatOption:(NSString *) repeatOption{
    
   // NSLog(@"title: %@",title);
   // NSLog(@"status: %@", status);
  //  NSLog(@"series Time: %@", seriesTime);
   // NSLog(@"proposed Series Time: %@", proposedSeriesTime);
   // NSLog(@"repeat Option: %@", repeatOption);
    
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    
    //Get string Attributes
    UIFont *titlefont = [self getPreferredTitleFont];
    NSDictionary *titleAttr =
    [NSDictionary dictionaryWithObject:titlefont
                                forKey:NSFontAttributeName];
    
    UIColor *greenColorForConfirmedAppointment = [UIColor colorWithRed:28.0/255.0
                                                                 green:159.0/255.0
                                                                  blue:81.0/255.0
                                                                 alpha:1];
    
    NSMutableDictionary *statusAttr = [[NSMutableDictionary alloc] init];
    if ([status isEqualToString:@"Confirmed"]){
        
        [statusAttr setValue:[self getPreferredSubtitleFont] forKey:NSFontAttributeName];
        [statusAttr setValue:greenColorForConfirmedAppointment forKey:NSForegroundColorAttributeName];
        
    } else {
        [statusAttr setValue:[self getPreferredSubtitleFont] forKey:NSFontAttributeName];
        [statusAttr setValue:[UIColor redColor] forKey:NSForegroundColorAttributeName];
    }
    
    NSMutableDictionary *timeAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *proposedtimeAttr = [[NSMutableDictionary alloc] init];
    
    if ([proposedSeriesTime isEqualToString:@""]){
        
        [timeAttr setObject:[self getPreferredBodyFont] forKey:NSFontAttributeName];
        [timeAttr setObject:[UIColor grayColor] forKey:NSForegroundColorAttributeName];
        
    } else{
        [timeAttr setObject:[self getPreferredBodyFont] forKey:NSFontAttributeName];
        [timeAttr setObject:[UIColor grayColor] forKey:NSForegroundColorAttributeName];
        [timeAttr setObject:[NSNumber numberWithBool:YES] forKey:NSStrikethroughStyleAttributeName];
        
        [proposedtimeAttr setObject:[self getPreferredBodyFont] forKey:NSFontAttributeName];
        [proposedtimeAttr setObject:[UIColor blueColor] forKey:NSForegroundColorAttributeName];
    }
    
    NSDictionary *repeatAttr = @{ NSFontAttributeName : [self getPreferredBodyFont],
                                  NSForegroundColorAttributeName :[UIColor grayColor]};
    
    NSMutableAttributedString *titleContent = [[NSMutableAttributedString alloc] init];
    
    
    
    [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:title attributes:titleAttr]];
    
    UIFont *titleFont = [SCHUtility getPreferredSubtitleFont];
    UIImage *recurringIcon = [self imageWithImage:[UIImage imageNamed:@"Recurring.png"] scaledToSize:CGSizeMake(titleFont.pointSize+1, titleFont.pointSize+1)];
    SCHTextAttachment *recurringAttachment = [SCHTextAttachment new];
    recurringAttachment.image = recurringIcon;
    [titleContent appendAttributedString:[NSAttributedString attributedStringWithAttachment:recurringAttachment]];
    
   // NSLog(@"title Content: %@", titleContent);
    
    // Add line
    [titleContent appendAttributedString:newline];
    
   // NSLog(@"title Content: %@", titleContent);
    
    
    
    //Add status
    [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:status attributes:statusAttr]];
    
   // NSLog(@"title Content: %@", titleContent);
    
    
    
    // Add two line
    [titleContent appendAttributedString:newline];
    [titleContent appendAttributedString:newline];
    
   // NSLog(@"title Content: %@", titleContent);
    
    //Add time
    [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:seriesTime attributes:timeAttr]];
    
   // NSLog(@"title Content: %@", titleContent);
    
    if (![proposedSeriesTime isEqualToString:@""]){
        // Proposed time has to be added
        // Add two new lines
        [titleContent appendAttributedString:newline];
        [titleContent appendAttributedString:newline];
        
        // Add subtitle for proposed time
        [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:@"new time proposed"
                                                                            attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]}]];
        
        // Add line
        [titleContent appendAttributedString:newline];
        
        //Add Proposed time
        [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:proposedSeriesTime attributes:proposedtimeAttr]];
        
    }
    
  //  NSLog(@"title Content: %@", titleContent);

    
    // Add line
    [titleContent appendAttributedString:newline];
    
  //  NSLog(@"title Content: %@", titleContent);
    
    
    
    // Add Time
    [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:repeatOption attributes:repeatAttr]];
    
   // NSLog(@"title Content: %@", titleContent);
    
    
    
    return  titleContent;
}






+(NSArray *)DetailContentOfAppointment:(SCHAppointment *) appointment openActivity:(SCHAppointmentActivity *) openActivity{
    SCHConstants *constants = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *appointDetailContent = [[NSMutableArray alloc] init];
    NSDictionary *withWhom = nil;
    
    BOOL sendReminder = NO;
    
    // Build Cells
    //withWhom
    SCHUser *user = nil;
    SCHNonUserClient *nonUser = nil;
    NSString *name = nil;
    
    if ([appDelegate.user isEqual:appointment.serviceProvider]){
        if (appointment.client){
            user = appointment.client;
            withWhom = @{@"user" : user};
        } else {
            nonUser = appointment.nonUserClient;
            name = appointment.clientName;
            withWhom = @{@"nonUser" : nonUser, @"name" : name};
        }
    } else {
        withWhom = @{@"user" : appointment.serviceProvider};
    }
        
    //title
    NSString *title = [NSString stringWithFormat:@"%@ - %@", appointment.service.serviceTitle, appointment.serviceOffering.serviceOfferingName];
    // status
    NSMutableString *status = [[NSMutableString alloc] init];
    if ([appointment.status isEqual:constants.SCHappointmentStatusConfirmed]){
        (appointment.expired) ?  [status setString:[NSString stringWithFormat:@"Confirmed (expired)"]] : [status setString:[NSString stringWithFormat:@"Confirmed"]];
        if (!appointment.expired){
            sendReminder = YES;
        }
        
        
    } else if ([appointment.status isEqual:constants.SCHappointmentStatusPending]){
        NSString *waitTime =[self responseWaitTime:appointment.updatedAt];
        if ([openActivity.actionAssignedTo isEqual:appDelegate.user]){
            
            if (waitTime.length > 0){
                (appointment.expired) ? [status setString:[NSString stringWithFormat:@"Awaiting your response (Expired)"]]: [status setString:[NSString stringWithFormat:@"Awaiting your response for %@", waitTime]];
            } else{
                (appointment.expired) ? [status setString:[NSString stringWithFormat:@"Awaiting your response (Expired)"]]: [status setString:[NSString stringWithFormat:@"Awaiting your response"]];
            }
            
            
        } else{
            if (!appointment.expired){
                sendReminder = YES;
            }
            if (waitTime.length > 0){
                (appointment.expired) ?   [status setString:[NSString stringWithFormat:@"Awaiting %@'s response (Expired)", openActivity.actionAssignedTo.preferredName]] :  [status setString:[NSString stringWithFormat:@"Awaiting %@'s response for %@", openActivity.actionAssignedTo.preferredName, waitTime]];
            }else{
                (appointment.expired) ?   [status setString:[NSString stringWithFormat:@"Awaiting %@'s response (Expired)", openActivity.actionAssignedTo.preferredName]] :  [status setString:[NSString stringWithFormat:@"Awaiting %@'s response", openActivity.actionAssignedTo.preferredName]];
                
            }
            
           
        }
    } else if ([appointment.status isEqual:constants.SCHappointmentStatusCancelled]){
        [status setString:@"Cancelled"];
    }
    
    // Get Date and Time
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
    NSString *appointmentDay = [dayformatter stringFromDate:appointment.startTime];
    NSDateFormatter *toTimeFormatter = [SCHUtility dateFormatterForShortTime];
    
    NSString *appointmentTime = nil;
    
    NSString *endTimeDateString = [self getEndDate:appointment.endTime comparingStartDate:appointment.startTime];
    if (endTimeDateString.length > 0){
        appointmentTime = [NSString stringWithFormat:@"from %@ to %@ %@", [toTimeFormatter stringFromDate:appointment.startTime], [toTimeFormatter stringFromDate:appointment.endTime], endTimeDateString];
    } else{
        appointmentTime = [NSString stringWithFormat:@"from %@ to %@", [toTimeFormatter stringFromDate:appointment.startTime], [toTimeFormatter stringFromDate:appointment.endTime]];
    }
    
    
    
    
    
    
    NSMutableString *proposedDay = [[NSMutableString alloc] init];
    NSMutableString *proposedTime = [[NSMutableString alloc] init];
    
    if (appointment.status == constants.SCHappointmentStatusPending && (appointment.proposedStartTime || appointment.proposedEndTime)){
        [proposedDay setString:[NSString stringWithFormat:@"%@",[dayformatter stringFromDate:appointment.proposedStartTime]]];
        NSString *proposedEndTimeDateString = [self getEndDate:appointment.proposedEndTime comparingStartDate:appointment.proposedStartTime];
        
        
        if (proposedEndTimeDateString.length > 0){
            [proposedTime setString:[NSString stringWithFormat:@"%@ to %@ %@", [toTimeFormatter stringFromDate:appointment.proposedStartTime], [toTimeFormatter stringFromDate:appointment.proposedEndTime], proposedEndTimeDateString]];
            
        }else{
            [proposedTime setString:[NSString stringWithFormat:@"%@ to %@", [toTimeFormatter stringFromDate:appointment.proposedStartTime], [toTimeFormatter stringFromDate:appointment.proposedEndTime]]];
        }
        
    } else {
        [proposedDay setString:@""];
        [proposedTime setString:@""];
    }
    
    NSString *recurringInfo = nil;
    if (appointment.appointmentSeries){
        recurringInfo = [NSString stringWithFormat:@"Recurs till %@",[dayformatter stringFromDate:appointment.appointmentSeries.endDate]];
    }
    
    // Add Appointment Summary to  detail content Array
    
    [appointDetailContent addObject:@{@"appointmentSummary" : @{@"content": [self appointSummaryCellContent:title
                                                                                                     status:status
                                                                                             appointmentDay:appointmentDay
                                                                                            appointmentTime:appointmentTime
                                                                                            recurrinInfo:recurringInfo
                                                                                                proposedDay:proposedDay
                                                                                               proposedTime:proposedTime
                                                                                                     series:appointment.appointmentSeries ? YES : NO]}}];
    
    
    
    
    //Get Location
    NSAttributedString *locationTitle = [[NSAttributedString alloc] initWithString:@"location" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ];
    
    if (appointment.proposedLocation){
        // Add proposed location
        [appointDetailContent addObject:@{@"appointmentLocation" : @{@"title": [[NSAttributedString alloc] initWithString:@"Proposed Location" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont], NSForegroundColorAttributeName : [UIColor blueColor]}], @"content" : [[NSAttributedString alloc] initWithString:appointment.proposedLocation attributes:@{NSFontAttributeName : [self getPreferredBodyFont], NSForegroundColorAttributeName: [UIColor blueColor]}]}}];
        
        NSDictionary *locationContentAttr = @{NSFontAttributeName : [self getPreferredBodyFont],
                                              NSStrikethroughStyleAttributeName:[NSNumber numberWithBool:YES]};
        [appointDetailContent addObject:@{@"appointmentLocation" : @{@"title": locationTitle,
                                                                     @"content" : [[NSAttributedString alloc] initWithString:appointment.location attributes:locationContentAttr]}}];
        
        
        
        
        
    } else {
        [appointDetailContent addObject:@{@"appointmentLocation" : @{@"title": locationTitle,
                                                                     @"content" : [[NSAttributedString alloc] initWithString:appointment.location attributes:[self preferredTextDispalyFontAttr]]}}];
    }
    
    //Add with Whom
    NSAttributedString *withWhomTitle = [[NSAttributedString alloc] initWithString:@"with" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ];
    
    [appointDetailContent addObject:@{@"withWhom" : @{@"title": withWhomTitle,
                                                      @"content" : withWhom}}];
    
    //Add reminder
    if (sendReminder){
        
        NSDictionary *attr = @{NSFontAttributeName: [SCHUtility getPreferredBodyFont],
                                    NSForegroundColorAttributeName: [UIColor blueColor]};
        
        NSAttributedString *sendReminder = [[NSAttributedString alloc] initWithString:@"Send Reminder" attributes:attr];
        
        
        [appointDetailContent addObject:@{@"sendReminder" : @{@"content" : sendReminder}}];
        
    
    }
    
    

    // Add Notes
    NSAttributedString *notesTitle = [[NSAttributedString alloc] initWithString:@"notes" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ];
    NSAttributedString *noteDetail = [[NSAttributedString alloc] initWithString:(appointment.note)?appointment.note:@"  " attributes:@{NSFontAttributeName : [self getPreferredBodyFont]}];
    
    [appointDetailContent addObject:@{@"notes" : @{@"title": notesTitle,
                                                   @"content" : noteDetail}}];
    
    
    return appointDetailContent;
}




+(NSAttributedString *)appointSummaryCellContent:(NSString *) title status:(NSString *) status appointmentDay:(NSString *)appointmentDay appointmentTime:(NSString *)appointmentTime recurrinInfo:(NSString *) recurringInfo proposedDay:(NSString *)proposedDay proposedTime:(NSString *)proposedTime series:(BOOL) series{
    
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    UIFont *titleFont = [SCHUtility getPreferredSubtitleFont];
    UIImage *recurringIcon = [self imageWithImage:[UIImage imageNamed:@"Recurring.png"] scaledToSize:CGSizeMake(titleFont.pointSize+1, titleFont.pointSize+1)];
    SCHTextAttachment *recurringAttachment = [SCHTextAttachment new];
    recurringAttachment.image = recurringIcon;
    
    
    //Get string Attributes
    UIFont *titlefont = [self getPreferredTitleFont];
    NSDictionary *titleAttr =
    [NSDictionary dictionaryWithObject:titlefont
                                forKey:NSFontAttributeName];
    UIColor *greenColorForConfirmedAppointment = [UIColor colorWithRed:28.0/255.0
                                                                 green:159.0/255.0
                                                                  blue:81.0/255.0
                                                                 alpha:1];
    
    NSMutableDictionary *statusAttr = [[NSMutableDictionary alloc] init];
    if ([status isEqualToString:@"Confirmed"]){
        
        [statusAttr setValue:[self getPreferredSubtitleFont] forKey:NSFontAttributeName];
        [statusAttr setValue:greenColorForConfirmedAppointment forKey:NSForegroundColorAttributeName];
        
    } else {
        [statusAttr setValue:[self getPreferredSubtitleFont] forKey:NSFontAttributeName];
        [statusAttr setValue:[SCHUtility brightOrangeColor] forKey:NSForegroundColorAttributeName];
    }
    
    NSMutableDictionary *dayAndTimeAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *proposedDayAndTimeAttr = [[NSMutableDictionary alloc] init];
    
    if ([proposedDay isEqualToString:@""] && [proposedTime isEqualToString:@""]){
        
        [dayAndTimeAttr setObject:[self getPreferredBodyFont] forKey:NSFontAttributeName];
        [dayAndTimeAttr setObject:[UIColor grayColor] forKey:NSForegroundColorAttributeName];
        
    } else{
        [dayAndTimeAttr setObject:[self getPreferredBodyFont] forKey:NSFontAttributeName];
        [dayAndTimeAttr setObject:[UIColor grayColor] forKey:NSForegroundColorAttributeName];
        [dayAndTimeAttr setObject:[NSNumber numberWithBool:YES] forKey:NSStrikethroughStyleAttributeName];
        
        [proposedDayAndTimeAttr setObject:[self getPreferredSubtitleFont] forKey:NSFontAttributeName];
        [proposedDayAndTimeAttr setObject:[UIColor blueColor] forKey:NSForegroundColorAttributeName];
    }
    
   // NSString *appointmentDayAndTime = [NSString stringWithFormat:@"%@ %@", appointmentDay,appointmentTime];
    
    NSMutableAttributedString *titleContent = [[NSMutableAttributedString alloc] init];
    
    [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:title attributes:titleAttr]];
    
    if(series){
        [titleContent appendAttributedString:[NSAttributedString attributedStringWithAttachment:recurringAttachment]];
    }
    
    // Add line
    [titleContent appendAttributedString:newline];
    
    //Add status
    [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:status attributes:statusAttr]];
    
    // Add two line
    [titleContent appendAttributedString:newline];
    [titleContent appendAttributedString:newline];
    // Add day and Time
   // [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:appointmentDayAndTime attributes:dayAndTimeAttr]];
    

    
    //Add Day
    [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:appointmentDay attributes:dayAndTimeAttr]];
    
    // Add line
    [titleContent appendAttributedString:newline];
    
    // Add Time
    [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:appointmentTime attributes:dayAndTimeAttr]];
    
    if (recurringInfo.length > 0 ){
        [titleContent appendAttributedString:newline];
         [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:recurringInfo attributes:dayAndTimeAttr]];
    }
     
    
    
    if (![proposedDay isEqualToString:@""] && ![proposedTime isEqualToString:@""]){
        // Proposed time has to be added
        // Add two new lines
        [titleContent appendAttributedString:newline];
        [titleContent appendAttributedString:newline];
        
        // Add subtitle for proposed time
        [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:@"Proposed Time"
                                                                            attributes:proposedDayAndTimeAttr]];
        
        // Add line
        [titleContent appendAttributedString:newline];
        
       // NSString *proposedDayAndTime = [NSString stringWithFormat:@"%@ from %@", proposedDay, proposedTime ];
        
       // [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:proposedDayAndTime attributes:proposedDayAndTimeAttr]];
        
        
        
        //Add Proposed date
        [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:proposedDay attributes:proposedDayAndTimeAttr]];
        
        // Add line
        [titleContent appendAttributedString:newline];
        
        // Add Time
        [titleContent appendAttributedString:[[NSAttributedString alloc]initWithString:proposedTime attributes:proposedDayAndTimeAttr]];
        
        
    }
    
    
    
    
    return  titleContent;
}


+(NSArray *)detailContentForMeetup:(SCHMeeting *) meeting{
    SCHConstants *constants = [SCHConstants sharedManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *meetupDetailContent = [[NSMutableArray alloc] init];
    NSDictionary *organizer = @{@"user" : meeting.organizer};

    
    NSString *title = meeting.subject;
    
    NSString *status = [SCHUtility getmeetupStatus:meeting];
    // Get Date and Time
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
    NSString *appointmentDay = [dayformatter stringFromDate:meeting.startTime];
    NSDateFormatter *toTimeFormatter = [SCHUtility dateFormatterForShortTime];
    NSString *endTimeDateString = [self getEndDate:meeting.endTime comparingStartDate:meeting.startTime];
    
    NSString *appointmentTime = nil;
    
    if (endTimeDateString.length > 0){
        appointmentTime = [NSString stringWithFormat:@"from %@ to %@ %@", [toTimeFormatter stringFromDate:meeting.startTime], [toTimeFormatter stringFromDate:meeting.endTime], endTimeDateString];
    } else{
       appointmentTime = [NSString stringWithFormat:@"from %@ to %@", [toTimeFormatter stringFromDate:meeting.startTime], [toTimeFormatter stringFromDate:meeting.endTime]];
    }
    
    NSMutableString *proposedDay = [[NSMutableString alloc] init];
    NSMutableString *proposedTime = [[NSMutableString alloc] init];
    

        [proposedDay setString:@""];
        [proposedTime setString:@""];
    
    
    NSString *recurringInfo = nil;
    // Add Summary to  detail content Array
    
    [meetupDetailContent addObject:@{@"appointmentSummary" : @{@"content": [self appointSummaryCellContent:title
                                                                                                     status:status
                                                                                             appointmentDay:appointmentDay
                                                                                            appointmentTime:appointmentTime
                                                                                               recurrinInfo:recurringInfo
                                                                                                proposedDay:proposedDay
                                                                                               proposedTime:proposedTime
                                                                                                     series:NO]}}];
    
    
    //Get Location
    NSAttributedString *locationTitle = [[NSAttributedString alloc] initWithString:@"location" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ];
    

        [meetupDetailContent addObject:@{@"appointmentLocation" : @{@"title": locationTitle,
                                                                     @"content" : [[NSAttributedString alloc] initWithString:meeting.location attributes:[self preferredTextDispalyFontAttr]]}}];
    
    
    //Change Requests
    if (meeting.changeRequests.count > 0 && [meeting.organizer isEqual:appDelegate.user]){
        NSDictionary *attr = @{NSFontAttributeName: [SCHUtility getPreferredSubtitleFont],
                               NSForegroundColorAttributeName: [SCHUtility brightOrangeColor]};
        
        NSAttributedString *changeRequests;
        
        if (meeting.changeRequests.count == 1){
            changeRequests = [[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Change Request"] attributes:attr];
        } else{
            changeRequests = [[NSAttributedString alloc] initWithString:[NSString localizedStringWithFormat:@"Change Requests"] attributes:attr];
        }
        
        
        
        
        [meetupDetailContent addObject:@{@"changeRequest" : @{@"title": changeRequests,
                                                              @"content" : meeting}}];
        
        
    }

    
    //Add with Whom
    
    if ([meeting.status isEqual:constants.SCHappointmentStatusCancelled] && ![meeting.organizer isEqual:appDelegate.user]){
        NSAttributedString *withWhomTitle = [[NSAttributedString alloc] initWithString:@"organizer" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ];
        
        [meetupDetailContent addObject:@{@"withWhom" : @{@"title": withWhomTitle,
                                                         @"content" : organizer}}];
        
    }
    
    
    
 
    
   // Add invites
    if ([meeting.organizer isEqual:appDelegate.user] || ![meeting.status isEqual:constants.SCHappointmentStatusCancelled]){
        NSDictionary *attr =@{NSFontAttributeName : [self getPreferredSubtitleFont]};
        
        NSAttributedString *invitesTitle = [[NSAttributedString alloc] initWithString:@"Attendees" attributes:attr];
        
        
        [meetupDetailContent addObject:@{@"invities" : @{@"title": invitesTitle,
                                                         @"content" : meeting.invites}}];

        
    }
    
    
    
    // Add Notes
    NSAttributedString *notesTitle = [[NSAttributedString alloc] initWithString:@"notes" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ];
    NSAttributedString *noteDetail = [[NSAttributedString alloc] initWithString:(meeting.notes)?meeting.notes:@"  " attributes:@{NSFontAttributeName : [self getPreferredBodyFont]}];
    
    [meetupDetailContent addObject:@{@"notes" : @{@"title": notesTitle,
                                                   @"content" : noteDetail}}];

    
    
    return meetupDetailContent;
}



/*

+(NSAttributedString *)meetupSummaryCellContent:(NSString *)title status:(NSString *) status meetupDay:(NSString *) meetupDay meetupTime:(NSString *)meetupTime proposedDay:(NSString *)proposedDay proposedTime:(NSString *)proposedTime{
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    //Get string Attributes
    UIFont *titlefont = [self getPreferredTitleFont];
    NSDictionary *titleAttr =
    [NSDictionary dictionaryWithObject:titlefont
                                forKey:NSFontAttributeName];
    UIColor *greenColorForConfirmedAppointment = [UIColor colorWithRed:28.0/255.0
                                                                 green:159.0/255.0
                                                                  blue:81.0/255.0
                                                                 alpha:1];
    
    NSMutableDictionary *statusAttr = [[NSMutableDictionary alloc] init];
    if ([status isEqualToString:@"Confirmed"]){
        
        [statusAttr setValue:[self getPreferredSubtitleFont] forKey:NSFontAttributeName];
        [statusAttr setValue:greenColorForConfirmedAppointment forKey:NSForegroundColorAttributeName];
        
    } else {
        [statusAttr setValue:[self getPreferredSubtitleFont] forKey:NSFontAttributeName];
        [statusAttr setValue:[SCHUtility brightOrangeColor] forKey:NSForegroundColorAttributeName];
    }

    
    
    
    
    
    return nil;
}

*/


+(NSArray *)availabilityDetailContents:(SCHAvailability *)availability{

    NSMutableArray *availabilityDetailContent = [[NSMutableArray alloc] init];
    
    UIFont *font = [self getPreferredTitleFont];
    NSDictionary *attrsDictionary =
    [NSDictionary dictionaryWithObject:font
                                forKey:NSFontAttributeName];
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    // Get Date and Time
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
    NSString *availabilityDay = [dayformatter stringFromDate:availability.startTime];
   
    NSDateFormatter *toTimeFormatter = [SCHUtility dateFormatterForToTime];
    NSString *endTimeDateString = [self getEndDate:availability.endTime comparingStartDate:availability.startTime];
    NSString *availabilityTime = nil;
    
    if (endTimeDateString.length > 0){
        availabilityTime = [NSString stringWithFormat:@"%@ to %@ %@", [toTimeFormatter stringFromDate:availability.startTime], [toTimeFormatter stringFromDate:availability.endTime], endTimeDateString];
    }else{
        availabilityTime = [NSString stringWithFormat:@"%@ to %@", [toTimeFormatter stringFromDate:availability.startTime], [toTimeFormatter stringFromDate:availability.endTime]];
    }
    
    //Title
    NSMutableAttributedString *titlestring = [[NSMutableAttributedString alloc] initWithString:availabilityDay attributes:attrsDictionary];
    
    [titlestring appendAttributedString:newline];
    
    [titlestring appendAttributedString:[[NSAttributedString alloc] initWithString:availabilityTime attributes:attrsDictionary ] ];
    
    [availabilityDetailContent addObject:@{@"availabilityTitle": titlestring}];
    
    // Add location
    [availabilityDetailContent addObject:@{@"appointmentLocation" : @{@"title": [[NSAttributedString alloc] initWithString:@"at" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ], @"content" : [[NSAttributedString alloc] initWithString:availability.location attributes:[self preferredTextDispalyFontAttr]]}}];
    
    
    // add service header
    
    if (availability.services.count == 1){
        [availabilityDetailContent addObject:@{@"serviceListHeader" : [[NSAttributedString alloc] initWithString:@"for service" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ]}];
        
    } else if (availability.services.count > 1){
        [availabilityDetailContent addObject:@{@"serviceListHeader" : [[NSAttributedString alloc] initWithString:@"for services" attributes:@{NSFontAttributeName : [self getPreferredSubtitleFont]} ]}];
    }
    
    //Add list of services
    NSMutableArray *serviceList = [[NSMutableArray alloc] init];
    
    for (NSDictionary *service in availability.services) {
        NSString *serviceTitle = [(SCHService *)[service valueForKey:@"service"] serviceTitle];
        NSString *serviceTime = [NSString stringWithFormat:@"%@ to %@", [toTimeFormatter stringFromDate:(NSDate *)[service valueForKey:@"startTime"]], [toTimeFormatter stringFromDate:(NSDate *)[service valueForKey:@"endTime"]]];
        
        NSDictionary *availabilityService = @{ @"service": [[NSAttributedString alloc] initWithString:serviceTitle attributes:[self preferredTextDispalyFontAttr]],
                                               @"serviceTime" : [[NSAttributedString alloc] initWithString:serviceTime attributes:[self preferredTextDispalyFontAttr]]};
        
        [serviceList addObject:availabilityService];
    }
    
    if (serviceList.count > 0){
        [availabilityDetailContent addObject:@{@"service" : serviceList}];
    }
    
    
    
    
    return availabilityDetailContent;
}

+(NSAttributedString *)summaryForAppointmentedit:(SCHAppointment *) appointment{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
    NSDateFormatter *toTimeFormatter = [SCHUtility dateFormatterForToTime];
    NSMutableAttributedString *bodyContent = [[NSMutableAttributedString alloc] init];

    
    NSString *withWhom = nil;
    
    // Build Cells
    //withWhom
    if ([appDelegate.user isEqual:appointment.serviceProvider]){
        if (appointment.client){
            withWhom = appointment.client.preferredName;
        
        } else{
            withWhom = appointment.clientName;
        }
    } else {
        withWhom = appointment.serviceProvider.preferredName;
    }
    //title
    NSString *title = [NSString stringWithFormat:@"%@ - %@ with %@", appointment.service.serviceTitle, appointment.serviceOffering.serviceOfferingName, withWhom];
    UIFont *titlefont = [self getPreferredTitleFont];
    NSDictionary *titleAttr =
    [NSDictionary dictionaryWithObject:titlefont
                                forKey:NSFontAttributeName];
    
    
    [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
    [bodyContent appendAttributedString:newline];
    [bodyContent appendAttributedString:newline];
    
    NSMutableDictionary *currentBodyAttr = [[NSMutableDictionary alloc] init];
    [currentBodyAttr setObject:[self getPreferredBodyFont] forKey:NSFontAttributeName];
    [currentBodyAttr setObject:[UIColor grayColor] forKey:NSForegroundColorAttributeName];
    
    [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:[dayformatter stringFromDate:appointment.startTime] attributes:currentBodyAttr]];
    [bodyContent appendAttributedString:newline];
    [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ to %@", [toTimeFormatter stringFromDate:appointment.startTime], [toTimeFormatter stringFromDate:appointment.endTime]] attributes:currentBodyAttr]];
    

    [bodyContent appendAttributedString:newline];
    [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"at %@", appointment.location] attributes:currentBodyAttr]];
    
    
    if ([appointment.status isEqual:constants.SCHappointmentStatusPending] && (appointment.proposedStartTime || appointment.proposedStartTime|| appointment.proposedLocation )){
        
        NSDictionary *proposedBodyAttr = @{NSFontAttributeName : [self getPreferredBodyFont], NSForegroundColorAttributeName:[UIColor blueColor]};
        
        [bodyContent appendAttributedString:newline];
        [bodyContent appendAttributedString:newline];
        [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:@"Proposed" attributes:proposedBodyAttr]];
        [bodyContent appendAttributedString:newline];
        if (appointment.proposedStartTime && appointment.proposedEndTime){
            [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:[dayformatter stringFromDate:appointment.proposedStartTime] attributes:proposedBodyAttr]];
            [bodyContent appendAttributedString:newline];
            [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ to %@", [toTimeFormatter stringFromDate:appointment.proposedStartTime], [toTimeFormatter stringFromDate:appointment.proposedEndTime]] attributes:proposedBodyAttr]];
        }
        if(appointment.proposedLocation){
            
            [bodyContent appendAttributedString:newline];
            [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"at %@", appointment.proposedLocation] attributes:proposedBodyAttr]];
        }
        
    }
    
    
    return bodyContent;
}

+(NSAttributedString *)summaryForMeetingEdit:(SCHMeeting *) meeting{
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSDateFormatter *dayformatter = [SCHUtility dateFormatterForFullDate];
    NSDateFormatter *toTimeFormatter = [SCHUtility dateFormatterForToTime];
    NSString *endTimeDateString = [self getEndDate:meeting.endTime comparingStartDate:meeting.startTime];
    NSMutableAttributedString *bodyContent = [[NSMutableAttributedString alloc] init];
    
    
    //title
    NSString *title = meeting.subject;
    UIFont *titlefont = [SCHUtility getPreferredTitleFont];
    NSDictionary *titleAttr = @{NSFontAttributeName: titlefont,
                                NSForegroundColorAttributeName: [SCHUtility deepGrayColor]};
    NSMutableDictionary *currentBodyAttr = [[NSMutableDictionary alloc] init];
    [currentBodyAttr setObject:[SCHUtility getPreferredBodyFont] forKey:NSFontAttributeName];
    [currentBodyAttr setObject:[SCHUtility deepGrayColor] forKey:NSForegroundColorAttributeName];
    
    [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
    [bodyContent appendAttributedString:newline];
    [bodyContent appendAttributedString:newline];
    
    [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:[dayformatter stringFromDate:meeting.startTime] attributes:currentBodyAttr]];
    [bodyContent appendAttributedString:newline];
    
    
    if (endTimeDateString.length > 0){
        [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ to %@ %@", [toTimeFormatter stringFromDate:meeting.startTime], [toTimeFormatter stringFromDate:meeting.endTime], endTimeDateString] attributes:currentBodyAttr]];
        
    } else{
        [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ to %@", [toTimeFormatter stringFromDate:meeting.startTime], [toTimeFormatter stringFromDate:meeting.endTime]] attributes:currentBodyAttr]];
    }
    
    
    
    
    [bodyContent appendAttributedString:newline];
    [bodyContent appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"at %@", meeting.location] attributes:currentBodyAttr]];
    
    
    
    return bodyContent;
}


+(NSString *)getmeetupStatus:(id) object{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
    SCHMeeting *meeting = nil;
    if ([object isKindOfClass:[SCHEvent class]]){
        SCHEvent *event = (SCHEvent *)object;
        meeting = event.eventObject;
    } else{
        meeting = (SCHMeeting *) object;
        
    }
    NSString *status = nil;
    
    if ([appDelegate.user isEqual:meeting.organizer]){
        if ([meeting.status isEqual:constants.SCHappointmentStatusConfirmed]){
            status = SCHMeetupStatusConfirmed;
        } else if ([meeting.status isEqual:constants.SCHappointmentStatusPending]){
            int pendingresponses = [self pendingMeetupStatus:meeting.invites];
            int pendingChangeRequests = 0;
            if (meeting.changeRequests.count > 0){
                pendingChangeRequests = (int)meeting.changeRequests.count;
            }
            NSString *pendingResponseString = nil;
            if (pendingresponses == 1){
                pendingResponseString =[NSString localizedStringWithFormat:@"Awaiting %d response", pendingresponses ];
            } else if (pendingresponses > 1){
                pendingResponseString = [NSString localizedStringWithFormat:@"Awaiting %d responses", pendingresponses ];
            }
            
            NSString *changeRequestString = nil;
            if (pendingChangeRequests == 1){
                changeRequestString =[NSString localizedStringWithFormat:@"%d Change request", pendingChangeRequests ];
            } else if (pendingChangeRequests > 1){
                changeRequestString = [NSString localizedStringWithFormat:@"%d Change requests", pendingChangeRequests ];
            }
            
            
            if (!pendingResponseString && !changeRequestString){
                status = SCHMeetupStatusPending;
            } else if (!changeRequestString && pendingResponseString){
                status = pendingResponseString;
            } else if (changeRequestString && !pendingResponseString){
                status = changeRequestString;
            } else if (changeRequestString && pendingResponseString){
                status = [NSString localizedStringWithFormat:@"%@ and %@",pendingResponseString, changeRequestString];
            }
            
        }else{
           status = SCHMeetupStatusCancelled;
        }
        
    }else{
        NSPredicate *inviteePredicate = [NSPredicate predicateWithFormat:@" user = %@", appDelegate.user];
        NSArray *inviteies = [meeting.invites filteredArrayUsingPredicate:inviteePredicate];
        NSDictionary *invitee = nil;
        
        if (inviteies.count >0){
            invitee = inviteies[0];
        }
        if (invitee){
            
            if ([meeting.status isEqual:constants.SCHappointmentStatusCancelled]){
                 status = SCHMeetupStatusCancelled;
            } else{
                if ([[invitee valueForKey: @"confirmation"] isEqualToString:SCHMeetupConfirmed]){
                    status = SCHMeetupStatusConfirmed;
                } else{
                    status = SCHMeetupStatusRespond;
                }

                
            }

                    } else{
            status = SCHMeetupStatusDeclined;
        }
        
    }
    return status;
    
    
}

+(int)pendingMeetupStatus:(NSArray *)invites{
    int PendingInvites = 0;
    for (NSDictionary *invitee in invites){
        if ([[invitee valueForKey:SCHMeetupInviteeConfirmation] isEqualToString:SCHMeetupNotConfirmed]){
            PendingInvites = PendingInvites+1;
        }
    }
    
    
    
    return PendingInvites;
}

+(int)nonDeclinedMeetupStatus:(NSArray *)invites{
    int nonDeclinedInvites = 0;
    for (NSDictionary *invitee in invites){
        if (![[invitee valueForKey:SCHMeetupInviteeConfirmation] isEqualToString:SCHMeetupDeclined]){
            nonDeclinedInvites = nonDeclinedInvites+1;
        }
    }
    
    
    
    return nonDeclinedInvites;
}



+(NSDictionary *)serviceProviderProfileContentForService:(SCHService *) service{
    NSDictionary *serviceProfile = nil;
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    
    //Title Content
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] init];;
    UIFont *titlefont = [self getPreferredTitleFont];
    NSDictionary *titleAttr = @{NSFontAttributeName: titlefont,
                                NSForegroundColorAttributeName: [self deepGrayColor]};
    
    [titleString appendAttributedString:[[NSAttributedString alloc] initWithString:service.serviceTitle attributes:titleAttr]];
    [titleString appendAttributedString:newline];
    [titleString appendAttributedString:newline];
    
    //Add dollar
    
    NSDictionary *dollarAttr = @{NSFontAttributeName: [self getPreferredTitleFont],
                                 NSForegroundColorAttributeName : [self brightOrangeColor]};
    if (service.standardCharge > 0){
        [titleString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"$%d", service.standardCharge] attributes:dollarAttr]];
    } else{
        [titleString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Free"] attributes:dollarAttr]];
    }
    
    
    if (service.website){
        [titleString appendAttributedString:newline];
        [titleString appendAttributedString:newline];
        
        NSDictionary *websiteAttr = @{NSFontAttributeName: [self getPreferredSubtitleFont],
                                      NSForegroundColorAttributeName : [UIColor blueColor]};
        
        
        [titleString appendAttributedString:[[NSAttributedString alloc] initWithString:service.website attributes:websiteAttr]];
        
        
    }
    NSString *descriptionString = @"";
    if(service.serviceDescription)
        descriptionString = service.serviceDescription;
    // Get Service Description
    NSDictionary *descriptionAttr = @{NSForegroundColorAttributeName: [self getPreferredBodyFont],
                                  NSForegroundColorAttributeName : [self deepGrayColor]};
    NSAttributedString *description = [[NSAttributedString alloc] initWithString:descriptionString attributes:descriptionAttr];

    
    
    //Construct Dictonary
    
    
    
    serviceProfile = @{@"title": titleString,
                       @"email": service.user.email,
                       @"phone": service.user.phoneNumber,
                       @"description": description};
    
    return serviceProfile;
}


/*****************************************/
#pragma mark - User Location and  client
/*****************************************/

+(void)createUserLocation:(NSString *) location{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (location.length> 0){
        NSSet *userLocationSet = [NSSet setWithArray:[self getUserLocations:appDelegate.user]];
        
        NSPredicate *locationPredate = [NSPredicate predicateWithFormat:@"location = %@", location];
        
        
        
        if ([[userLocationSet filteredSetUsingPredicate:locationPredate] count] == 0){
            SCHUserLocation *newlocation = [SCHUserLocation object];
            newlocation.user = appDelegate.user;
            newlocation.location = location;
            [self setPublicAllROACL:newlocation.ACL];
            [newlocation pin];
            CLGeocoder *geocoder = [[CLGeocoder alloc] init];
            [geocoder geocodeAddressString:location completionHandler:^(NSArray *placemarks, NSError *error) {
                CLPlacemark *placeMark = nil;
                if (!error) {
                    placeMark = [placemarks firstObject];
                }
                PFGeoPoint *locationPoint = [PFGeoPoint geoPoint];
                
                if (placeMark){
                    locationPoint = [PFGeoPoint geoPointWithLocation:placeMark.location];
                    newlocation.locationPoint = locationPoint;
                    [newlocation save];
                }
            }];
            
            
        }

    }

    
    
}

+(NSArray *)getUserLocations:(SCHUser *) user{
    PFQuery *userLocationQuery = [SCHUserLocation query];
    [userLocationQuery whereKey:@"user" equalTo:user];
    [userLocationQuery fromLocalDatastore];
    
    
    return [userLocationQuery findObjects];

}

+(NSArray *)getClientWithName:(NSString *) name email:(NSString *) email phoneNumber:(NSString *)phoneNumber{
    NSMutableArray *userArray = [[NSMutableArray alloc] init];
    NSError *error = nil;
    if ((phoneNumber || email)&& !name){
        return @[];
    }

    
    // search user table
    
    NSPredicate *userQueryPredicate = nil;
    if (email && phoneNumber){
        userQueryPredicate= [NSPredicate predicateWithFormat:@"phoneNumber = %@ OR email = %@", phoneNumber, email];
    } else if (!email && phoneNumber){
        userQueryPredicate= [NSPredicate predicateWithFormat:@"phoneNumber = %@", phoneNumber];
    }else{
        userQueryPredicate= [NSPredicate predicateWithFormat:@"email = %@", email];
    }
    
    
    PFQuery *userQuery = [PFQuery queryWithClassName:SCHUserClass predicate:userQueryPredicate];
    
    
    [userArray addObjectsFromArray:[userQuery findObjects:&error]];
    
    if (error){
        return @[];
    }

    

    
    // search Non User Table
    
    if (userArray.count == 0){
        
        NSPredicate *nonUserPredicate = nil;
        if (email && phoneNumber){
            nonUserPredicate= [NSPredicate predicateWithFormat:@"phoneNumber = %@ AND email = %@", phoneNumber, email];
        } else if (!email && phoneNumber){
            nonUserPredicate= [NSPredicate predicateWithFormat:@"phoneNumber = %@", phoneNumber];
        }else{
            nonUserPredicate= [NSPredicate predicateWithFormat:@"email = %@", email];
        }
        
        PFQuery *nonUserQuery = [PFQuery queryWithClassName:SCHNonUserClientClass predicate:nonUserPredicate];
        
        
        [userArray addObjectsFromArray:[nonUserQuery findObjects:&error]];
        if (error){
            return @[];
        }
        
        if (userArray.count > 0){
            if (email){
                for (SCHNonUserClient *nonUserClient in userArray){
                    nonUserClient.email = email;
                }
                
                [PFObject saveAllInBackground:userArray];
                
            }
            
            
        }

        
        
    }
    
    
    // If not create Non user
    if (userArray.count == 0){
        SCHNonUserClient *newClient = [SCHNonUserClient object];
        if (email){
            newClient.email = email;
        }
        
        if (phoneNumber){
            newClient.phoneNumber = phoneNumber;
        }
        
        [self setPublicAllRWACL:newClient.ACL];
        [newClient save];
        [userArray addObject:newClient];
        
    }
    
    
    return userArray;

    
}



+(NSArray *)getClientWithName:(NSString *) name email:(NSString *) email phoneNumber:(NSString *)phoneNumber forServiceProvider:(SCHUser *) serviceProvider{
    
    NSMutableArray *userArray = [[NSMutableArray alloc] init];
    NSError *error = nil;
    if ((!phoneNumber || !email)&& !name){
        return @[];
    }
    
    //search serviceProviders Clientlist
    NSArray *clientLists = [self GetServiceProviderClientList:serviceProvider];
    
    if (clientLists.count > 0){
        NSPredicate *clientListPredicate = nil;
        
        [NSPredicate predicateWithFormat:@"client.phoneNumber = @ OR "];
        if (email && phoneNumber){
            clientListPredicate= [NSPredicate predicateWithFormat:@"(client.phoneNumber = %@ OR client.email = %@) OR (nonUserClient.phoneNumber = %@ AND nonUserClient.email = %@", phoneNumber, email, phoneNumber, email];
        } else if (!email && phoneNumber){
            clientListPredicate= [NSPredicate predicateWithFormat:@"client.phoneNumber = %@ OR nonUserClient.phoneNumber = %@", phoneNumber, phoneNumber];
        }else{
            clientListPredicate= [NSPredicate predicateWithFormat:@"client.email = %@ OR nonUserClient.email = %@ ", email, email];
        }
        
        NSArray *filteredClientList = [clientLists filteredArrayUsingPredicate:clientListPredicate];
        
        if (filteredClientList.count > 0){
            for (SCHServiceProviderClientList *clientList in filteredClientList){
                
                if (clientList.client){
                    [userArray addObject:clientList.client];
                } else{
                    [userArray addObject:clientList.nonUserClient];
                }
                
            }
        }
        
    }
    
    
    
     // search user table
    
    if (userArray == 0){
        NSPredicate *userQueryPredicate = nil;
        if (email && phoneNumber){
            userQueryPredicate= [NSPredicate predicateWithFormat:@"phoneNumber = %@ OR email = %@", phoneNumber, email];
        } else if (!email && phoneNumber){
            userQueryPredicate= [NSPredicate predicateWithFormat:@"phoneNumber = %@", phoneNumber];
        }else{
            userQueryPredicate= [NSPredicate predicateWithFormat:@"email = %@", email];
        }
        
        
        PFQuery *userQuery = [PFQuery queryWithClassName:SCHUserClass predicate:userQueryPredicate];
        
        
        [userArray addObjectsFromArray:[userQuery findObjects:&error]];
        
        if (error){
            return @[];
        }

        
    }
    
    
    // search Non User Table
    
    if (userArray.count == 0){
        
        NSPredicate *nonUserPredicate = nil;
        if (email && phoneNumber){
            nonUserPredicate= [NSPredicate predicateWithFormat:@"phoneNumber = %@ AND email = %@", phoneNumber, email];
        } else if (!email && phoneNumber){
            nonUserPredicate= [NSPredicate predicateWithFormat:@"phoneNumber = %@", phoneNumber];
        }else{
            nonUserPredicate= [NSPredicate predicateWithFormat:@"email = %@", email];
        }
        
        PFQuery *nonUserQuery = [PFQuery queryWithClassName:SCHNonUserClientClass predicate:nonUserPredicate];
        
    
        [userArray addObjectsFromArray:[nonUserQuery findObjects:&error]];
        if (error){
            return @[];
        }
        
           if (userArray.count > 0){
               if (email){
                   for (SCHNonUserClient *nonUserClient in userArray){
                       nonUserClient.email = email;
                   }
                
                [PFObject saveAllInBackground:userArray];
            
            }
        
        
        }
        
        

    }
    
    
    // If not create Non user
    if (userArray.count == 0){
        SCHNonUserClient *newClient = [SCHNonUserClient object];
        if (email){
            newClient.email = email;
        }
        newClient.phoneNumber = phoneNumber;
        [self setPublicAllRWACL:newClient.ACL];
        [newClient save];
        [userArray addObject:newClient];
        
    }
    
    
    return userArray;
}

+(SCHServiceProviderClientList *)addClientToServiceProvider:(SCHUser *)serviceProvider client:(SCHUser *) client name:(NSString *) name nonUserClient:(SCHNonUserClient *) nonUserClient autoConfirm:(BOOL) autoConfirm{
    
    
    BOOL success = YES;
    NSError *error = nil;
    
    
    
    
    
    
    
    PFQuery *clientListQuery = [SCHServiceProviderClientList query];
    [clientListQuery whereKey:@"serviceProvider" equalTo:serviceProvider];
   // [clientListQuery fromLocalDatastore];
    if (client){
        [clientListQuery whereKey:@"client" equalTo:client];
    }
    if (nonUserClient){
        [clientListQuery whereKey:@"nonUserClient" equalTo:nonUserClient];
    }
    
    NSArray *userArray = [clientListQuery findObjects:&error];
    
    if (error){
        return nil;
    }
    if (userArray.count > 1){
        return nil;
    } else if (userArray.count == 1){
        return userArray[0];
    } else if (userArray.count == 0){
        
        SCHServiceProviderClientList *newClistList;
        newClistList = [SCHServiceProviderClientList object];
        newClistList.serviceProvider = serviceProvider;
        newClistList.client = client;
        newClistList.nonUserClient = nonUserClient;
        if (nonUserClient){
            newClistList.name = name;
        }
        newClistList.autoConfirmAppointment = autoConfirm;
        [self setPublicAllRWACL:newClistList.ACL];
        [newClistList pin];
        success = [newClistList save];
        return newClistList;
        
    } else {
        return nil;
    }

    
    
    
}

+(NSArray *) GetServiceProviderClientList:(SCHUser *)serviceProvider{
    
    
    PFQuery *clientListQuery = [SCHServiceProviderClientList query];
    [clientListQuery whereKey:@"serviceProvider" equalTo:serviceProvider];
    [clientListQuery includeKey:@"client"];
    [clientListQuery includeKey:@"nonUserClient"];
    [clientListQuery fromLocalDatastore];
    
   // NSArray *clientList = [clientListQuery findObjects];
    NSMutableArray *clientList = [[NSMutableArray alloc] initWithArray:[clientListQuery findObjects]];
    
    
    
    NSMutableArray *clientListWithName = [[NSMutableArray alloc] init];
    
    
    for (SCHServiceProviderClientList *client in clientList){
        if (client.client){
            client.name = client.client.preferredName;
        }
        [clientListWithName addObject:client];
        
    }
    
    NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    
    NSArray *sortedClientList = [clientListWithName sortedArrayUsingDescriptors:@[nameSort]];
    
    
    return sortedClientList;
}



+(BOOL)saveServieAndOffering:(SCHService *) service serviceOffering:(SCHServiceOffering *)serviceOffering{
    
    BOOL success = YES;
    if ([self setFreeBusinessTrial:service.user]) {
        [service pin];
        success =  [service save];
        
        [serviceOffering pin];
        success = [serviceOffering save];
        
        if (success){
            SCHServiceClassification *classification = service.serviceClassification;
            SCHServiceMajorClassification *majorClassification = service.serviceClassification.majorClassification;
            
            [self setServiceCategoryVisibility:majorClassification serviceClassification:classification];
        }
        
    } else {
        success = NO;
    }
    [self setServiceProviderStatus];
    
 
    
    
    
    
    return YES;
}


+ (NSString *)phoneNumberFormate:(NSString *)str {
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    
  //  NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    NBAsYouTypeFormatter *phoneFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:countryCode];
    
   // NSString *c1 = [NSString stringWithFormat:@"(%@) ",[str substringToIndex:3]];NSString *c2 = [NSString stringWithFormat:@"%@-%@",[str substringWithRange:NSMakeRange(3, 3)],[str substringWithRange:NSMakeRange(6, 4)]];
    return [phoneFormatter inputString:str];
}

+(NSAttributedString *)userSubscriptionInfo{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *subscriptionContentDict = @{NSFontAttributeName : [self getPreferredBodyFont],
                                              NSForegroundColorAttributeName : [self deepGrayColor]};
    SCHUser *user = appDelegate.user;
    
    NSString *paymentFrequency = user.paymentFrequency.paymentFrequency;
    float amount = user.paymentFrequency.amount;
    NSDateFormatter *dateFormat = [self dateFormatterForFullDate];
    
    
   // NSDate *startDate = subscription.premiumStartDate;
    NSString *startDate = [dateFormat stringFromDate:user.premiumStartDate];
    NSString *renewalDate = [dateFormat stringFromDate:user.premiumRenewalDate];
    NSString *expirationDate = nil;
    if (user.premiumExpirationDate){
        expirationDate = [dateFormat stringFromDate:user.premiumExpirationDate];
    }
    NSMutableString *content = [[NSMutableString alloc] init];
    [content appendString:[NSString stringWithFormat:@"%@ ($%f)", paymentFrequency, amount]];
    [content appendString:@"\n"];
    [content appendString:[NSString stringWithFormat:@"Premium Start Date: %@", startDate]];
    [content appendString:@"\n"];
    if (user.premiumExpirationDate){
        [content appendString:[NSString stringWithFormat:@"Expiration Date: %@", expirationDate]];
    } else {
        [content appendString:[NSString stringWithFormat:@"Renewal Date: %@", renewalDate]];
    }
    NSMutableAttributedString *subscriptionInfo = [[NSMutableAttributedString alloc] initWithString:content attributes:subscriptionContentDict];

    return subscriptionInfo;
}

+(void)deleteUserLocation:(SCHUserLocation *) location{
    [location unpinInBackground];
    [location deleteInBackground];
}

+(void)deleteServiceProviderClient:(SCHServiceProviderClientList *)client{
    
    [client unpin];
    [client delete];
}
+(void)addLocation:(NSString *) location forUser:(SCHUser *)user{
    SCHUserLocation *userLocation = [SCHUserLocation object];
    userLocation.user = user;
    userLocation.location = location;
    [self setPublicAllRWACL:userLocation.ACL];
    [userLocation pin];
    [userLocation save];
}

+(BOOL)commit{
    
    BOOL success = YES;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit addObjectsToCommitQueue:appDelegate.backgroundCommit.objectsStagedForDelete
                                             commitAction:SCHServerCommitDelete
                                               commitMode:SCHServerCommitModeSynchronous];
    
    success = [appDelegate.backgroundCommit serverCommit];
    
    if (success){
        [appDelegate.backgroundCommit addObjectsoUnpinningQueue:appDelegate.backgroundCommit.objectsStagedForUnpin];
        [appDelegate.backgroundCommit unPinObjects];
        [appDelegate.backgroundCommit addObjectsToCommitQueue:appDelegate.backgroundCommit.objectsStagedForSave
                                                 commitAction:SCHServerCommitSave
                                                   commitMode:SCHServerCommitModeSynchronous];
        
        success =[appDelegate.backgroundCommit serverCommit];
        
    }
    if (success){
        [appDelegate.backgroundCommit addObjectsoPinningQueue:appDelegate.backgroundCommit.objectsStagedForPinning];
        [appDelegate.backgroundCommit pinObjects];
    }
    
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    
    
    return success;

}
+(BOOL)commitEventually{
    
    BOOL success = YES;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit addObjectsToCommitQueue:appDelegate.backgroundCommit.objectsStagedForDelete
                                             commitAction:SCHServerCommitDelete
                                               commitMode:SCHserverCommitModeEventually];
    
    success = [appDelegate.backgroundCommit serverCommit];
    
    if (success){
        [appDelegate.backgroundCommit addObjectsoUnpinningQueue:appDelegate.backgroundCommit.objectsStagedForUnpin];
        [appDelegate.backgroundCommit unPinObjects];
        [appDelegate.backgroundCommit addObjectsToCommitQueue:appDelegate.backgroundCommit.objectsStagedForSave
                                                 commitAction:SCHServerCommitSave
                                                   commitMode:SCHserverCommitModeEventually];
        
        success =[appDelegate.backgroundCommit serverCommit];
        
    }
    if (success){
        [appDelegate.backgroundCommit addObjectsoPinningQueue:appDelegate.backgroundCommit.objectsStagedForPinning];
        [appDelegate.backgroundCommit pinObjects];
    }
    
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    
    
    return success;
}


+(NSAttributedString *) termsOfUse{
    NSAttributedString *termsOfUse = [[NSAttributedString alloc] initWithString:@"Terms of Use content"];
    return termsOfUse;
}

+(NSAttributedString *) privacyPolicy{
    NSAttributedString *privacyPolicy = [[NSAttributedString alloc] initWithString:@"Privacy Policy content"];
    return privacyPolicy;
}

+(BOOL)phoneNumberExists:(NSString *) phoneNumber{
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL exists = NO;
    PFQuery *phoneExistsQuery = [SCHUser query];
    [phoneExistsQuery whereKey:@"phoneNumber" equalTo:phoneNumber];
    [phoneExistsQuery whereKey:@"objectId" notEqualTo:appDelegate.user.objectId];
    
    if ([phoneExistsQuery countObjects:&error] == 0){
        exists = NO;
    } else {
        exists = YES;
    }
    
    if (error){
        exists = YES;
    }
    
    return exists;
}

+(BOOL) syncPriorNonUserActivities:(NSString *)phoneNumber email:(NSString *) email User:(SCHUser *)user{
    
    BOOL success = YES;
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.backgroundCommit refreshQueues];
    [appDelegate.backgroundCommit refrshStagedQueue];
    
    
    NSPredicate *nonUserPredicate = [NSPredicate predicateWithFormat:@"phoneNumber = %@ OR email = %@", phoneNumber, email];
    PFQuery *nonUserQuery = [PFQuery queryWithClassName:SCHNonUserClientClass predicate:nonUserPredicate];

    NSArray *nonUserClients = [nonUserQuery findObjects];
    
    if (nonUserClients.count > 0){
        for (SCHNonUserClient *nonUserClient in nonUserClients ){
            //Get all appointment Series
            PFQuery *seriesQuery = [SCHAppointmentSeries query];
            [seriesQuery whereKey:@"nonUserClient" equalTo:nonUserClient];
            NSArray *seriesAppts = [seriesQuery findObjects:&error];
            if (error){
                return NO;
            }
            if(seriesAppts.count > 0){
                for (SCHAppointmentSeries *series in seriesAppts){
                    series.nonUserClient = nil;
                    series.clientName = nil;
                    series.client = user;
                    series.isClientUser = YES;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:series];
                }
            }
            
            
            
            //Get all appointments
            PFQuery *appointmentQuery = [SCHAppointment query];
            [appointmentQuery whereKey:@"nonUserClient" equalTo:nonUserClient];
            
            NSArray *appointments = [appointmentQuery findObjects:&error];
            if (error){
                return NO;
            }
            if (appointments.count > 0){
                for (SCHAppointment *appointment in appointments){
                    appointment.nonUserClient = nil;
                    appointment.clientName = nil;
                    appointment.client = user;
                    appointment.isClientUser = YES;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:appointment];
                    
                }
            }
            
            //get meetups
            NSUInteger limit = 500;
            NSUInteger skip = 0;
            NSUInteger lastObjectCount = 0;
            NSUInteger CurrentObjectCount = 0;
            // Unpin all meetups
            
            PFQuery *meetingQuery = [SCHMeeting  query];
            [meetingQuery whereKey:@"attendees" containsAllObjectsInArray:@[nonUserClient]];
            NSMutableArray *meetupArray = [[NSMutableArray alloc] init];
            
            [meetingQuery setLimit:limit];
            
            while (CurrentObjectCount == skip){
                lastObjectCount = CurrentObjectCount;
                [meetingQuery setSkip:skip];
                if (appDelegate.serverReachable && appDelegate.user){
                    [meetupArray addObjectsFromArray:[meetingQuery findObjects:&error]];
                } else{
                    [meetupArray removeAllObjects];
                    success = NO;
                    break;
                }
                
                if (error){
                    [meetupArray removeAllObjects];
                    success = NO;
                    break;
                    
                }
                
                CurrentObjectCount = [meetupArray count];
                if (lastObjectCount == CurrentObjectCount){
                    break;
                } else {
                    skip = skip + limit;
                }
                
            }
            
            // if nor reachable then end here
            if (!appDelegate.serverReachable || !appDelegate.user){
                success = NO;
            }
            if (!success){
                return success;
            }
            
            if (meetupArray.count > 0){
                for (SCHMeeting *meeting in meetupArray){
                    NSMutableArray *meetingAttendees = [[NSMutableArray alloc] initWithArray:meeting.attendees];
                    NSMutableArray *meetingInvites = [[NSMutableArray alloc] initWithArray:meeting.invites];
                    [meetingAttendees removeObject:nonUserClient];
                    [meetingAttendees addObject:appDelegate.user];
                    
                    NSPredicate *inviteePredicate = [NSPredicate predicateWithFormat:@" user = %@", nonUserClient];
                    NSArray *selfDicts = [meeting.invites filteredArrayUsingPredicate:inviteePredicate];
                    
                    if (selfDicts.count > 0){
                        [meetingInvites removeObjectsInArray:selfDicts];
                    }
                    [meetingInvites addObject:[SCHMeetingManager createInvitesWith:appDelegate.user
                                                                              name:appDelegate.user.preferredName
                                                                         accepance:SCHMeetupConfirmed]];
                    
                    meeting.invites = meetingInvites;
                    meeting.attendees = meetingAttendees;
                    
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:meeting];
                    
                }
                
            }
            
            //get User Client list
            PFQuery *clientListQuery = [SCHServiceProviderClientList query];
            [clientListQuery whereKey:@"nonUserClient" equalTo:nonUserClient];
            NSArray *clientLists = [clientListQuery findObjects:&error];
            if (error){
                return NO;
            }
            
            if (clientLists.count > 0){
                for (SCHServiceProviderClientList *clientList in clientLists){
                    clientList.client = user;
                    clientList.nonUserClient = nil;
                    clientList.name = nil;
                    [appDelegate.backgroundCommit.objectsStagedForSave addObject:clientList];
                    
                }
            }
            
            success = [self commit];
            if (success){
                success = [nonUserClient delete];
            }

            
        }
    }
    
    if (success){
        user.dataSyncRequired = NO;
       success = [user save];
    }
    
    
    return success;
    
    
}

+(NSString *) responseWaitTime:(NSDate *) responseRequestTime{
    
    NSString *waitTime = nil;
    
    NSCalendar *preferredCalendar = [NSCalendar currentCalendar];
    NSCalendarUnit calendarUnits = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute;
    NSDateComponents *components = [preferredCalendar components:calendarUnits
                                                        fromDate:responseRequestTime
                                                          toDate:[NSDate date]
                                                         options:0];
    int year = (int)[components year];
    int month = (int)[components month];
    int day = (int)[components day];
    int hour = (int)[components hour];
    int min = (int)[components minute];
    
    
    if (year > 0){
        if (year == 1){
            waitTime = [NSString stringWithFormat:@"%d year", year];
            return waitTime;
        } else{
            waitTime = [NSString stringWithFormat:@"%d years", year];
            return waitTime;
        }
       
    }
    if (month > 0){
        if (month == 1){
            waitTime = [NSString stringWithFormat:@"%d month", month];
            return waitTime;
        } else{
            waitTime = [NSString stringWithFormat:@"%d months", month];
            return waitTime;
        }
    }
    if (day > 0){
        if (day == 1){
            waitTime = [NSString stringWithFormat:@"%d day", day];
            return waitTime;
        } else{
            waitTime = [NSString stringWithFormat:@"%d days", day];
            return waitTime;
        }
    }
    if (hour > 0){
        if (hour == 1){
            waitTime = [NSString stringWithFormat:@"%d hour", hour];
            return waitTime;
        } else{
            waitTime = [NSString stringWithFormat:@"%d hours", hour];
            return waitTime;
        }
    }
    if (min > 0){
        if (min < 30){
            waitTime = @"";
            return waitTime;
        } else{
            waitTime = [NSString stringWithFormat:@"%d minutes", min];
            return waitTime;
        }
        
    }
    
    
    return @"";
}


+(BOOL)IsMandatoryUpgradeRequired{
    
    
    BOOL manadatoryUpgradeRequired = NO;
    SCHConstants *constants = [SCHConstants sharedManager];
    //Get Device Type
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *model = [currentDevice model];
    SCHLookup *deviceType = nil;
    if ([model isEqualToString:constants.SCHDeviceTypeiPhone.lookupText]){
        deviceType = constants.SCHDeviceTypeiPhone;
        //Get Latest Mandatory Release
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.serverReachable){
            PFQuery *appReleaseQuery = [SCHAppRelease query];
            [appReleaseQuery whereKey:@"deviceType" equalTo:deviceType];
            [appReleaseQuery whereKey:@"mandatoryRelease" equalTo:@YES];
            [appReleaseQuery whereKey:@"releaseDate" lessThanOrEqualTo:[NSDate date]];
            [appReleaseQuery orderByDescending:@"releaseDate"];
            
            SCHAppRelease *appRelease = nil;
            
            if ([appReleaseQuery countObjects] > 0){
                appRelease = [appReleaseQuery getFirstObject];
            }
            
            if (appRelease){
                
                
                //get current release from plist
                NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
                int installedVersion = truncf([[infoDict objectForKey:@"CFBundleShortVersionString"] floatValue]*100000);
                int currentMandatoryVersion =truncf([appRelease.releaseNumber floatValue]*100000);
                
                if (currentMandatoryVersion > installedVersion){
                    manadatoryUpgradeRequired = YES;
                }
                
                
                
            }
        }

    }
    

    
    
    return manadatoryUpgradeRequired;
}

+(BOOL)BusinessUserAccess{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL BusinessUserAccess = NO;
    SCHUser *currentUser = appDelegate.user;
    SCHConstants *constants = [SCHConstants sharedManager];
    if ([currentUser.subscriptionType isEqual:constants.SCHSubscriptionTypeFreeUser]){
        if (currentUser.freeTrialExpirationDate){
                if ([currentUser.freeTrialExpirationDate compare:[NSDate date]] == NSOrderedDescending){
                    BusinessUserAccess = YES;
                }
            }
    }else if ([currentUser.subscriptionType isEqual:constants.SCHSubscriptionTypePremiumUser]){
            if ([currentUser.premiumExpirationDate compare:[NSDate date]] == NSOrderedDescending){
                BusinessUserAccess = YES;
            }
    }else if ([currentUser.subscriptionType isEqual:constants.SCHSubscriptionTypeAllAccessFreeUser]){
        BusinessUserAccess = YES;
    }
    
    
    return BusinessUserAccess;
    
}

+(BOOL) setFreeBusinessTrial:(SCHUser *)user{
    NSError *error = nil;
    SCHConstants *constants = [SCHConstants sharedManager];
    NSDateComponents *daysCompontnt = [[NSDateComponents alloc] init];
    if (!user.freeTrialExpirationDate && [user.subscriptionType isEqual:constants.SCHSubscriptionTypeFreeUser]){
        PFQuery *schControlQuery = [SCHControl query];
        SCHControl *control = [schControlQuery getFirstObject:&error];
        if (!error){
            [daysCompontnt setDay:control.freeTrialDays];
        } else {
            return NO;
                
         }
       NSDate *trialExpirationDate = [[NSCalendar currentCalendar] dateByAddingComponents:daysCompontnt toDate:[NSDate date] options:NSCalendarMatchFirst];
        user.freeTrialExpirationDate = trialExpirationDate;
        return  [user save];
    } else return YES;
        
    
}



+(NSArray *)conflictingAppointmentsForService:(SCHService *) service location:(NSString *) location timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo{
    

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    SCHConstants *constants = [SCHConstants sharedManager];
 
    
    //find all appointments that falls in unavailability fime frame
    
    NSTimeInterval oneMin = 60;
    NSMutableSet *existingAppointmentSet = [[NSMutableSet alloc] init];
    
    
    NSDate *timeFromForCheck = [NSDate dateWithTimeInterval:oneMin sinceDate:timeFrom];
    NSDate *timeToForCheck = [NSDate dateWithTimeInterval:-oneMin sinceDate:timeTo];
    
    NSPredicate *existingAppointmentWithCurrentTimePred1 = [NSPredicate predicateWithFormat:@"serviceProvider = %@ AND status IN {%@, %@}  AND (startTime BETWEEN %@ OR endTime BETWEEN %@)", appDelegate.user, constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, @[timeFromForCheck, timeToForCheck], @[timeFromForCheck, timeToForCheck]];
    
    PFQuery *existingAppointmentQuery1 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred1];
    
    [existingAppointmentQuery1 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery1 findObjects]];
    
    NSPredicate *existingAppointmentWithCurrentTimePred2 = [NSPredicate predicateWithFormat:@"serviceProvider = %@ AND status IN {%@, %@}  AND (proposedStartTime BETWEEN %@ OR proposedEndTime BETWEEN %@)", appDelegate.user, constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, @[timeFromForCheck, timeToForCheck], @[timeFromForCheck, timeToForCheck]];
    
    PFQuery *existingAppointmentQuery2 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred2];
    
    [existingAppointmentQuery2 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery2 findObjects]];
    
    
    NSPredicate *existingAppointmentWithCurrentTimePred3 = [NSPredicate predicateWithFormat:@"serviceProvider = %@ AND status IN {%@, %@}  AND (startTime <= %@ AND endTime => %@)", appDelegate.user, constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, timeFromForCheck, timeToForCheck];
    
    PFQuery *existingAppointmentQuery3 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred3];
    
    [existingAppointmentQuery3 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery3 findObjects]];
    
    NSPredicate *existingAppointmentWithCurrentTimePred4 = [NSPredicate predicateWithFormat:@"status IN {%@, %@}  AND (proposedStartTime <= %@ AND proposedEndTime => %@)", constants.SCHappointmentStatusConfirmed, constants.SCHappointmentStatusPending, timeFromForCheck, timeToForCheck];
    
    PFQuery *existingAppointmentQuery4 = [PFQuery queryWithClassName:SCHAppointmentClass predicate:existingAppointmentWithCurrentTimePred4];
    
    [existingAppointmentQuery3 fromLocalDatastore];
    
    [existingAppointmentSet addObjectsFromArray:[existingAppointmentQuery4 findObjects]];
    
    //remove all expired and canceled then filter them out
    
    NSPredicate *appointmentFilter = [NSPredicate predicateWithBlock:^BOOL(SCHAppointment *appointment, NSDictionary<NSString *,id> * _Nullable bindings) {
        if ([appointment.status isEqual:constants.SCHappointmentStatusCancelled]){
            return NO;
        }
        if (appointment.expired){
            return NO;
        }
        return YES;
    }];
    
    [existingAppointmentSet filterUsingPredicate:appointmentFilter];
    
    
    
    //if there is service then discard the appointments that does not match to service
    
    if (service){
        NSPredicate *serviceFilterPredicate = [NSPredicate predicateWithFormat:@"service = %@", service];
        
        [existingAppointmentSet filterUsingPredicate:serviceFilterPredicate];
    }
    
    //if there is location then  discard the appointments that does not match to location
    if (location){
        NSPredicate *locationFilterPredicate = [NSPredicate predicateWithFormat:@"location = %@ OR proposedLocation = %@", location, location];
        [existingAppointmentSet filterUsingPredicate:locationFilterPredicate];
    }
    
    
    
    return [existingAppointmentSet allObjects];
}

+(void) setServiceCategoryVisibility:(SCHServiceMajorClassification *) majorCategory serviceClassification:(SCHServiceClassification *) serviceCategory{
    PFQuery *serviceQuery = [SCHService query];
    [serviceQuery whereKey:@"active" equalTo:@YES];
    [serviceQuery whereKey:@"serviceClassification" equalTo:serviceCategory];
    SCHService *service = [serviceQuery getFirstObject];
    if (service){
        serviceCategory.visible = YES;
        [serviceCategory save];
    }else{
        serviceCategory.visible = NO;
        [serviceCategory save];
    }
    
    PFQuery *serviceCategoryQuery  = [SCHServiceClassification query];
    [serviceCategoryQuery whereKey:@"visible" equalTo:@YES];
    [serviceCategoryQuery whereKey:@"majorClassification" equalTo:majorCategory];
    
    SCHServiceClassification *classification = [serviceCategoryQuery getFirstObject];
    if (classification){
        majorCategory.visible = YES;
        [majorCategory save];
    } else{
        majorCategory.visible = NO;
        [majorCategory save];
    }
    
    
    
    
}
/*
+(NSString *) randomStringWithLength: (int) len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform(letters.length)]];
    }
    
    return randomString;
}
 */

+(NSString *)referMessage:(SCHService *) service{
    NSMutableString *messageBody = [[NSMutableString alloc] init];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [messageBody appendString:[NSString stringWithFormat:@"%@ referred you %@", appDelegate.user.preferredName, service.user.preferredName]];
    
    [messageBody appendString:@"\n"];
    [messageBody appendString:@"\n"];
    
    [messageBody appendString:[NSString stringWithFormat:@"%@", service.serviceTitle]];
    [messageBody appendString:@"\n"];
    [messageBody appendString:[NSString stringWithFormat:@"%@", service.serviceClassification.serviceTypeName]];
    [messageBody appendString:@"\n"];
    [messageBody appendString:[NSString stringWithFormat:@"%@", service.user.email]];
    [messageBody appendString:@"\n"];
    [messageBody appendString:[NSString stringWithFormat:@"%@", [SCHUtility phoneNumberFormate:service.user.phoneNumber]]];
    [messageBody appendString:@"\n"];
    
    if (service.website){
        [messageBody appendString:[NSString stringWithFormat:@"%@", service.website]];
        [messageBody appendString:@"\n"];
    }
    
    [messageBody appendString:@"\n"];
    [messageBody appendString:@"\n"];
    [messageBody appendString:[NSString stringWithFormat:@"View %@'s profile in CounterBean.", service.user.preferredName]];
    [messageBody appendString:@"\n"];
    [messageBody appendString:[NSString stringWithFormat:@"Download CounterBean App from Apple App Store to manage  and book  your appointments."]];
    [messageBody appendString:@"\n"];
    [messageBody appendString:@"It's free."];
    
    
    return  messageBody;
}


+(void) syncFacebookFriends:(NSArray *) FBFriends{

    
    PFQuery *friendsQuery = [SCHUserFriend query];
    [friendsQuery fromLocalDatastore];
    [friendsQuery whereKey:@"facebookId" notEqualTo:@""];
    
    NSArray *existingFBFriends = [friendsQuery findObjects];
    
    NSMutableSet *existingFriendsSet = [[NSMutableSet alloc] init];
    
    if (existingFBFriends.count >0){
        for (SCHUserFriend *existingFBFriend in existingFBFriends){
            if (existingFBFriend.facebookId){
                [existingFriendsSet addObject:existingFBFriend.facebookId];
            }
            
        }
    }
    
    NSMutableSet *retrievedFBFriendsSet = [[NSMutableSet alloc] init];
    
    if (FBFriends.count >0){
        for (NSDictionary *friend in FBFriends){
            [retrievedFBFriendsSet addObject:[friend valueForKey:@"id"]];
        }
    }
    
    if (retrievedFBFriendsSet.count == 0){
        return;
    } else{
        if (existingFriendsSet.count > 0){
            //Identify objects to be removed
            [existingFriendsSet minusSet:retrievedFBFriendsSet];
            if (existingFriendsSet.count >0){
                [self removeFBFriendsFromList:[existingFriendsSet allObjects]];
            }
            
            // add new friends
            [existingFriendsSet removeAllObjects];
            for (SCHUserFriend *existingFBFriend in existingFBFriends){
                [existingFriendsSet addObject:existingFBFriend.facebookId];
            }
            [retrievedFBFriendsSet minusSet:existingFriendsSet];
            if (retrievedFBFriendsSet.count > 0){
                [self addFBFriendsToList:[retrievedFBFriendsSet allObjects]];
            }
            
        } else{
            [self addFBFriendsToList:[retrievedFBFriendsSet allObjects]];
        }
    }
    
    
}
+(void) addFBFriendsToList:(NSArray *) friends{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PFQuery *userFriendsQuery = [SCHUser query];
    [userFriendsQuery whereKey:@"facebookId" containedIn:friends];
    
    NSArray *userfriends = [userFriendsQuery findObjects];
    
    if (userfriends.count > 0){
        for (SCHUser *userFriend in userfriends){
            SCHUserFriend *CBFriend = [SCHUserFriend new];
            CBFriend.user = appDelegate.user;
            CBFriend.CBFriend = userFriend;
            CBFriend.facebookId = appDelegate.user.facebookId;
            [CBFriend saveEventually];
            [CBFriend pin];
            
        }
    }

}
+(void)removeFBFriendsFromList:(NSArray *)friends{
    PFQuery *friendsForRemovalQuery = [SCHUserFriend query];
    [friendsForRemovalQuery whereKey:@"facebookId" containedIn:friends];
    
    NSArray *friendsForRemoval = [friendsForRemovalQuery findObjects];
    
    if (friendsForRemoval.count > 0){
        [PFObject unpinAll:friendsForRemoval];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.serverReachable){
            [PFObject deleteAllInBackground:friendsForRemoval];
        }
        
    }
    
    
}

+(void) setServiceProviderStatus{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PFQuery *serviceQuery = [SCHService query];
    [serviceQuery fromLocalDatastore];
    [serviceQuery whereKey:@"user" equalTo:appDelegate.user];
   // SCHService *userService = (SCHService *)[serviceQuery getFirstObject:&error];
    int serviceCount = (int)[serviceQuery countObjects];
    if (serviceCount > 0){
        appDelegate.serviceProvider = YES;
    } else {
        appDelegate.serviceProvider = NO;
    }
    
    [serviceQuery whereKey:@"active" equalTo:@YES];
    [serviceQuery whereKey:@"suspended" notEqualTo:@YES];
    
    //SCHService *serActiveService = (SCHService *)[serviceQuery getFirstObject:&error];
    int activeServiceCount =  (int)[serviceQuery countObjects];
    if (activeServiceCount > 0){
        appDelegate.serviceProviderWithActiveService = YES;
    } else{
        appDelegate.serviceProviderWithActiveService = NO;
    }
    
}

+(void)setSideMenu{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIStoryboard  *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    if (!appDelegate.tabBarController){
        UITabBarController * tabController = [storyboard instantiateViewControllerWithIdentifier:@"SCHMainTBC"];
        appDelegate.tabBarController = tabController;
    }
    
    SlideMenuViewController *leftMenu = [storyboard instantiateViewControllerWithIdentifier:@"SlideMenuViewController"];
    appDelegate.slideMenu = leftMenu;
    
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                        containerWithCenterViewController:appDelegate.tabBarController
                                                        leftMenuViewController:leftMenu
                                                        rightMenuViewController:nil];


    
    window.rootViewController = container;
    [window makeKeyAndVisible];
}

+(void)getFacebookUserFriends:(PFUser *) user{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.serverReachable){
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {

            
            FBSDKGraphRequest *friendRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/friends" parameters:@{@"fields": @"id, name, picture"} tokenString:[FBSDKAccessToken currentAccessToken].tokenString version:nil HTTPMethod:nil];

            [friendRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                if (!error){
                    
                    NSArray *friends = [result valueForKey:@"data"] ;
                    if (friends.count > 0){
                        SCHBackgroundManager *backgroundManager = [SCHBackgroundManager sharedManager];
                        
                        dispatch_async(backgroundManager.SCHSerialQueue, ^{
                            [SCHUtility syncFacebookFriends:friends];
                        });
                        
                    }
                    
                }
                
            }];
            
            
        }

    }
}

+(NSArray *)bookSearch:(NSString *)searchString{
    NSMutableArray *result = [[NSMutableArray alloc] init];

    PFQuery *availabilityQuery = [SCHAvailabilityForAppointment query];
    [availabilityQuery includeKey:@"service"];
    [availabilityQuery includeKey:@"user"];
   [availabilityQuery whereKey:@"object" matchesRegex:searchString];
    [availabilityQuery selectKeys:@[@"service"]];
    
    
    [result addObjectsFromArray:[availabilityQuery findObjects]];

    
    return result;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}



+(NSDictionary *)getAppointmentHistoryForUser:(SCHUser *) user serviceProvider:(SCHUser *) serviceProvider service:(SCHService *) service{
    
    NSError *error = nil;
    SCHConstants *constants = [SCHConstants sharedManager];
    NSMutableDictionary *appointmentHistory = [[NSMutableDictionary alloc]init];
    NSPredicate *historyQueryPredicate = [NSPredicate predicateWithFormat:@"(serviceProvider = %@ OR client = %@) AND status != %@ AND expired = YES ", serviceProvider, user, constants.SCHappointmentStatusCancelled ];
    
    PFQuery *priorAppointmentQuery = [PFQuery queryWithClassName:SCHAppointmentClass predicate:historyQueryPredicate];
    //[priorAppointmentQuery whereKey:@"expired" equalTo:@YES];
   // [priorAppointmentQuery whereKey:@"status" notEqualTo:constants.SCHappointmentStatusCancelled];
    [priorAppointmentQuery includeKey:@"status"];
    [priorAppointmentQuery includeKey:@"serviceProvider"];
    [priorAppointmentQuery includeKey:@"service"];
    [priorAppointmentQuery includeKey:@"serviceOffering"];
    [priorAppointmentQuery includeKey:@"client"];
    [priorAppointmentQuery includeKey:@"nonUserClient"];
    [priorAppointmentQuery includeKey:@"appointmentSeries"];
    
    /*
    
    if (serviceProvider){
        [priorAppointmentQuery whereKey:@"serviceProvider" equalTo:serviceProvider];
    } else if (service){
        [priorAppointmentQuery whereKey:@"service" equalTo:service];
    } else{
        [priorAppointmentQuery whereKey:@"client" equalTo:appDelegate.user];
    }
     
     */
    
    NSArray *appointments = [priorAppointmentQuery findObjects:&error];
    
    
    if (appointments.count > 0){
        NSMutableSet *appointmentDaysSet = [[NSMutableSet alloc] init];
        for(SCHAppointment *appointment in appointments){
            if (appointment.proposedStartTime){
                [appointmentDaysSet addObject:[self getDate:appointment.proposedStartTime]];
            }else{
                [appointmentDaysSet addObject:[self getDate:appointment.startTime]];
            }
        }
        
        NSSet *appointmentSet = [[NSSet alloc] initWithArray:appointments];
        NSSortDescriptor *appointmentDaysAsc = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        NSArray *appointmentDays = [appointmentDaysSet sortedArrayUsingDescriptors:@[appointmentDaysAsc]];
        [appointmentHistory setObject:appointmentDays forKey:@"eventDays"];
        NSMutableDictionary *appointmentDictonary = [[NSMutableDictionary alloc] init];
        for (NSDate *appointmentDay in appointmentDays ){
            NSPredicate *daySchedulePredicate = [NSPredicate predicateWithBlock:^BOOL(SCHAppointment *appointment, NSDictionary<NSString *,id> * _Nullable bindings) {
                
                if (appointment.proposedStartTime){
                    if ([[self getDate:appointment.proposedStartTime] isEqualToDate:appointmentDay]){
                        return YES;
                    } else{
                        return NO;
                    }
                    
                } else if ([[self getDate:appointment.startTime] isEqualToDate:appointmentDay]){
                    return YES;
                } else{
                    return NO;
                }
            }];
            
            
            //Get appointments for the day
            NSSet *scheduleDaysEventSet = [appointmentSet filteredSetUsingPredicate:daySchedulePredicate];
            NSMutableArray *scheduleDaysEvent = [[NSMutableArray alloc] init];
            for (SCHAppointment *appointment in scheduleDaysEventSet){
                SCHEvent *event = [self createEventWithEventDay:appointmentDay
                                                      eventType:SCHAppointmentClass
                                                    eventObject:appointment
                                                      startTime:(appointment.proposedStartTime)? appointment.proposedStartTime : appointment.startTime
                                                        endTime:(appointment.proposedEndTime)? appointment.proposedEndTime : appointment.endTime
                                                       Location:(appointment.proposedLocation)? appointment.proposedLocation: appointment.location];
                
                [scheduleDaysEvent addObject:event];
                
            }
            
            
            if (scheduleDaysEvent.count > 0){
                //sort day's schedule event array with start time, end time
                NSSortDescriptor *sortscheduleDaysEventSetStartTime = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
                NSSortDescriptor *sortscheduleDaysEventSetEndTime = [NSSortDescriptor sortDescriptorWithKey:@"endTime" ascending:YES];
                
                NSArray *sortArray = @[sortscheduleDaysEventSetStartTime, sortscheduleDaysEventSetEndTime];
                
                [scheduleDaysEvent sortUsingDescriptors:sortArray];
                
                // NSString *dayKey = [SCHUtility getCurrentDate:scheduleDay];
                NSDateFormatter *formatter = [SCHUtility dateFormatterForFullDate];
                NSString *dayKey = [formatter stringFromDate:appointmentDay];
                
                [appointmentDictonary setObject:scheduleDaysEvent forKey:dayKey];
                
            }
        }
        [appointmentHistory setObject:appointmentDictonary forKey:@"appointments"];
    }
    return  appointmentHistory;
}

+(SCHEvent *)createEventWithEventDay:(NSDate *)eventDay eventType:(NSString *) eventType eventObject:(id)eventObject startTime:(NSDate *) startTime endTime:(NSDate *) endTime Location:(NSString *) location {
    SCHEvent *event = [[SCHEvent alloc] init];
    SCHConstants *constants = [SCHConstants sharedManager];
    if ([eventType isEqualToString:SCHAppointmentClass]){
        SCHAppointment *appointment = (SCHAppointment *)eventObject;
        
        
        if (appointment.status == constants.SCHappointmentStatusPending){
            NSPredicate *openActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointment = %@ AND status = %@", [PFUser currentUser][@"CBUser"], [PFUser currentUser][@"CBUser"], appointment, constants.SCHappointmentActivityStatusOpen];
            PFQuery *openActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openActivityPredicate];
            [openActivityQuery includeKey:@"actionAssignedTo"];
            [openActivityQuery includeKey:@"actionInitiator"];
            [openActivityQuery includeKey:@"status"];
            [openActivityQuery includeKey:@"action"];
            NSArray *appointmentOpenActivity = [openActivityQuery findObjects];
            
            if (appointmentOpenActivity.count == 0){
                // check series
                if (appointment.appointmentSeries){
                    // Get appointment Series  Open Activity
                    
                    NSPredicate *openSeriesActivityPredicate = [NSPredicate predicateWithFormat:@"(actionAssignedTo = %@  OR actionInitiator = %@) AND appointmentSeries = %@ AND status = %@", [PFUser currentUser][@"CBUser"], [PFUser currentUser][@"CBUser"], appointment.appointmentSeries, constants.SCHappointmentActivityStatusOpen];
                    
                    
                    PFQuery *openSeriesActivityQuery = [PFQuery queryWithClassName:SCHAppointmentActivityClass predicate:openSeriesActivityPredicate];
                    [openSeriesActivityQuery includeKey:@"actionAssignedTo"];
                    [openSeriesActivityQuery includeKey:@"actionInitiator"];
                    [openSeriesActivityQuery includeKey:@"status"];
                    [openSeriesActivityQuery includeKey:@"action"];
                    NSArray *appointmentSeriesOpenActivity = [openSeriesActivityQuery findObjects];
                    
                    if(appointmentSeriesOpenActivity.count > 0){
                        event.openActivity = appointmentSeriesOpenActivity.firstObject;
                    } //else NSLog(@"couldn't retrieve apoen activity");
                } // else NSLog(@"couldn't retrieve apoen activity");
            }  else event.openActivity = appointmentOpenActivity.firstObject;
            
        }
    }
    event.eventDay = eventDay;
    event.eventType = eventType;
    event.eventObject = eventObject;
    event.startTime = startTime;
    event.endTime = endTime;
    event.location = location;
    
    
    
    
    return event;
    
}

+(BOOL)suspendAccountDueOTPLimt{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.serverReachable){
        [appDelegate.user fetch];
         appDelegate.user.suspended = YES;
         appDelegate.user.OTP = NULL;
        appDelegate.user.verificationSMSCount = 0;
         if (!appDelegate.user.suspensionExpirationTime){
             NSTimeInterval fourHours = 60*5;
             appDelegate.user.suspensionExpirationTime = [NSDate dateWithTimeIntervalSinceNow:fourHours];
                
        }
        return [appDelegate.user save];
    } else{
        return NO;
    }
    
}

+(BOOL)removeAccountSuspensionWithExpirationDate{
    AppDelegate * appdeligate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appdeligate.serverReachable){
        [appdeligate.user fetch];
        if (appdeligate.user.suspensionExpirationTime){
            if ([appdeligate.user.suspensionExpirationTime compare:[NSDate date]] == NSOrderedAscending){
                appdeligate.user.suspensionExpirationTime= nil;
                appdeligate.user.suspended = NO;
                return [appdeligate.user save];
            }
        }
        
    }
    return YES;
    
}

+(NSArray *)getAllContacts{
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSError *error = nil;
    
    NSString *phoneTypeHome = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABHomeLabel);
    NSString *phoneTypeMobile = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABPersonPhoneMobileLabel);
    NSString *phoneTypeiPhone = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABPersonPhoneIPhoneLabel);
    NSString *phoneTypeWork  = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABWorkLabel);
    NSString *phoneTypeMain = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABPersonPhoneMainLabel);
    NSString *phoneTypeOther = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABOtherLabel);
    
    NSArray *validPhoneTypes = @[phoneTypeHome, phoneTypeMobile, phoneTypeiPhone, phoneTypeWork, phoneTypeMain, phoneTypeOther];
    
    NSMutableSet *LinkedPersons = [[NSMutableSet alloc] init];
    NSMutableArray *contactArray = [[NSMutableArray alloc]init];
    ABAddressBookRef allPeople = ABAddressBookCreate();
    CFArrayRef allContacts = ABAddressBookCopyArrayOfAllPeople(allPeople);
    CFIndex numberOfContacts  = ABAddressBookGetPersonCount(allPeople);
    
    for(int i = 0; i < numberOfContacts; i++){
        ABRecordRef contactRecordRef = CFArrayGetValueAtIndex(allContacts, i);
        
        if ([LinkedPersons containsObject:(__bridge id _Nonnull)(contactRecordRef)]){
            continue;
        }
        
        //Get linked records
        NSMutableSet *linkedContacts = [[NSMutableSet alloc] initWithArray:(__bridge NSArray *)(ABPersonCopyArrayOfAllLinkedPeople(contactRecordRef))];
        CFArrayRef linkedContactArray = (__bridge CFArrayRef)([linkedContacts allObjects]);
        [LinkedPersons addObjectsFromArray:[linkedContacts allObjects]];
        
        
        
        
        //Get Names
        NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(contactRecordRef, kABPersonFirstNameProperty));
        NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(contactRecordRef, kABPersonLastNameProperty));
        NSString *name =@"";
        if (firstName != nil) {
            name = [NSString localizedStringWithFormat:@"%@", firstName];
        }
        if (lastName != nil) {
            name = [name stringByAppendingString:[NSString localizedStringWithFormat:@" %@", lastName]];
        }
        
        NSMutableArray *phones = [[NSMutableArray alloc] init];
        NSMutableArray *phoneArray = [[NSMutableArray alloc] init];
        NSMutableArray *emails = [[NSMutableArray alloc] init];
        NSMutableArray *emailArray = [[NSMutableArray alloc] init];
        
        for (int m = 0; m < linkedContacts.count; m++){
            ABRecordRef contactRecord = CFArrayGetValueAtIndex(linkedContactArray, m);
            
            //Get phones
            ABMultiValueRef phoneProperty = ABRecordCopyValue(contactRecord, kABPersonPhoneProperty);
            
            int phoneCount = (int)ABMultiValueGetCount(phoneProperty);
            
            if (phoneCount > 0){
                for (int n = 0; n < phoneCount; n++){
                    error = nil;
                    NBPhoneNumber *NBNumber = [phoneUtil parse:(__bridge NSString*)ABMultiValueCopyValueAtIndex(phoneProperty, n)
                                                 defaultRegion:countryCode
                                                         error:&error];
                    if (!error){
                        if ([phoneUtil isValidNumber:NBNumber]){
                            CFStringRef labelStingRef = ABMultiValueCopyLabelAtIndex(phoneProperty, n);
                            NSString *phoneLabel = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(labelStingRef);
 
                            
                            
                            if (phoneLabel.length == 0){
                                phoneLabel = phoneTypeOther;
                            }
                            error = nil;
                            if ([validPhoneTypes containsObject:phoneLabel]){
                                NSString *phoneNumber = [phoneUtil format:NBNumber
                                                             numberFormat:NBEPhoneNumberFormatE164
                                                                    error:&error];
                                if (!error){
                                    if ([phoneArray containsObject:phoneNumber]){
                                        
                                         NSPredicate *findPhone = [NSPredicate predicateWithFormat:@"phoneNumber CONTAINS[cd] %@", [phoneNumber stringByReplacingOccurrencesOfString:@"+" withString:@""]];
                                         NSArray *foundPhones = [phones filteredArrayUsingPredicate:findPhone];
                                         
                                         if (foundPhones.count > 0){
                                         NSMutableDictionary *phone = [[NSMutableDictionary alloc] initWithDictionary:(NSMutableDictionary *)[foundPhones objectAtIndex:0]];
                                         if (![[phone objectForKey:@"phoneType"] isEqualToString:phoneLabel] && [phoneLabel isEqualToString:phoneTypeOther]){
                                         [phones removeObjectsInArray:foundPhones];
                                         NSDictionary *phoneDict = @{@"phoneType": phoneLabel,
                                         @"phoneNumber": phoneNumber};
                                         if ([phoneLabel isEqualToString:phoneTypeMobile]){
                                         [phones insertObject:phoneDict atIndex:0];
                                         } else if ([phoneLabel isEqualToString:phoneTypeiPhone]){
                                         [phones insertObject:phoneDict atIndex:0];
                                         } else{
                                         [phones addObject:phoneDict];
                                         }
                                         
                                         
                                         }
                                         
                                         
                                         }
                                         
                                    } else{
                                        NSDictionary *phoneDict = @{@"phoneType": phoneLabel,
                                                                    @"phoneNumber": phoneNumber};
                                        [phoneArray addObject:phoneNumber];
                                        if ([phoneLabel isEqualToString:phoneTypeMobile]){
                                            [phones insertObject:phoneDict atIndex:0];
                                        } else if ([phoneLabel isEqualToString:phoneTypeiPhone]){
                                            [phones insertObject:phoneDict atIndex:0];
                                        } else{
                                            [phones addObject:phoneDict];
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                }
                
            }
            // Phone Capture ends
            
            //Get Email
            
            ABMultiValueRef emailProperty = ABRecordCopyValue(contactRecord, kABPersonEmailProperty);
            int emailCount = (int)ABMultiValueGetCount(emailProperty);
            if (emailCount> 0){
                for (int n= 0; n< emailCount; n++){
                    NSString *email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(emailProperty, n);
                    if ([self isValidEmail:email]){
                        CFStringRef labelStingRef = ABMultiValueCopyLabelAtIndex(emailProperty, n);
                        NSString *emailLabel = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(labelStingRef);
                        
                        if (![emailArray containsObject:email]){
                            NSDictionary *emailDict = @{@"emailType": emailLabel,
                                                        @"email": email};
                            [emails addObject:emailDict];
                            [emailArray addObject:email];
                            
                        }
                    }
                    
                }
            }
            
        }
        

        
        
        
        if (name.length > 0){
            
            if (![self NSStringIsValidEmail:name]){
                if ((phones.count > 0 || emails.count > 0)){

                    
                    CFDataRef imageData = ABPersonCopyImageData(contactRecordRef);
                    UIImage *image = [UIImage imageWithData:(__bridge NSData *)imageData];
                    
                    NSMutableDictionary *contact = [[NSMutableDictionary alloc] init];
                    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@" 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"] invertedSet];
                    
                    [contact setObject:[self stringByTrimLeadingWhiteSpace:[[name componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""]] forKey:@"name"];
                    if(image != nil && image != NULL){
                        [contact setObject:image forKey:@"image"];
                        CFRelease(imageData);
                    }
                    
                    if (phones.count > 0){
                        [contact setObject:phones forKey:@"phones"];
                    }
                    if (emails.count > 0){
                        [contact setObject:emails forKey:@"emails"];
                    }
                    
                    [contactArray addObject:contact];
                    
                }
                
            }
        }

    }
    return [self sortedContact:contactArray];
}

+(NSArray *)getAllContactsold{
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    NSString *phoneTypeHome = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABHomeLabel);
    NSString *phoneTypeMobile = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABPersonPhoneMobileLabel);
    NSString *phoneTypeiPhone = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABPersonPhoneIPhoneLabel);
    NSString *phoneTypeWork  = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABWorkLabel);
    NSString *phoneTypeMain = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABPersonPhoneMainLabel);
    NSString *phoneTypeOther = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABOtherLabel);

    
    
    
    
    NSMutableArray *contactArray = [[NSMutableArray alloc]init];
    ABAddressBookRef allPeople = ABAddressBookCreate();
    CFArrayRef allContacts = ABAddressBookCopyArrayOfAllPeople(allPeople);
    CFIndex numberOfContacts  = ABAddressBookGetPersonCount(allPeople);
    
    
    
    
    
    for(int i = 0; i < numberOfContacts; i++){
        NSString* name = @"";
        NSMutableArray *phones = [[NSMutableArray alloc] init];
        NSMutableArray *emails = [[NSMutableArray alloc] init];
        
        ABRecordRef aPerson = CFArrayGetValueAtIndex(allContacts, i);
        ABMultiValueRef fnameProperty = ABRecordCopyValue(aPerson, kABPersonFirstNameProperty);
        ABMultiValueRef lnameProperty = ABRecordCopyValue(aPerson, kABPersonLastNameProperty);
        
        ABMultiValueRef phoneProperty = ABRecordCopyValue(aPerson, kABPersonPhoneProperty);
        
        int phoneCount = (int)ABMultiValueGetCount(phoneProperty);
        if (phoneCount > 0){
            NSError *error = nil;
            for (int i= 0; i < phoneCount; i++){
                NBPhoneNumber *NBNumber = [phoneUtil parse:(__bridge NSString*)ABMultiValueCopyValueAtIndex(phoneProperty, i)
                                                  defaultRegion:countryCode
                                                          error:&error];
                if (!error){
                    if ([phoneUtil isValidNumber:NBNumber]){
                        CFStringRef labelStingRef = ABMultiValueCopyLabelAtIndex(phoneProperty, i);
                        
                        NSString *phoneLabel = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(labelStingRef);
                        
                        if ([phoneLabel isEqualToString:phoneTypeHome]||[phoneLabel isEqualToString:phoneTypeWork]|| [phoneLabel isEqualToString:phoneTypeOther]||[phoneLabel isEqualToString:phoneTypeiPhone] ||[phoneLabel isEqualToString:phoneTypeMobile]||[phoneLabel isEqualToString:phoneTypeMain]){
                            

                            
                           
                            NSString *phoneNumber = [phoneUtil format:NBNumber
                                                         numberFormat:NBEPhoneNumberFormatE164
                                                                error:&error];
                            
                            if (!error){
                                
                                NSDictionary *phoneDict = @{@"phoneType": phoneLabel,
                                                            @"phoneNumber": phoneNumber};
                                if ([phoneLabel isEqualToString:phoneTypeMobile]){
                                    [phones insertObject:phoneDict atIndex:0];
                                } else if ([phoneLabel isEqualToString:phoneTypeiPhone]){
                                    [phones insertObject:phoneDict atIndex:0];
                                } else{
                                    [phones addObject:phoneDict];
                                }
                                
                                
                            }
                        }
                        
                    }
                }
                
            }
        }
        
        // Get Emails
        ABMultiValueRef emailProperty = ABRecordCopyValue(aPerson, kABPersonEmailProperty);
        int emailCount = (int)ABMultiValueGetCount(emailProperty);
        if (emailCount> 0){
            for (int i = 0; i < emailCount; i++){
                NSString *email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(emailProperty, i);
                if ([self isValidEmail:email]){
                    CFStringRef labelStingRef = ABMultiValueCopyLabelAtIndex(emailProperty, i);
                    NSString *emailLabel = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(labelStingRef);
                    NSDictionary *emailDict = @{@"emailType": emailLabel,
                                                @"email": email};
                    [emails addObject:emailDict];
                }
            }
        }
        
        if (fnameProperty != nil) {
            name = [NSString localizedStringWithFormat:@"%@", fnameProperty];
        }
        if (lnameProperty != nil) {
            name = [name stringByAppendingString:[NSString localizedStringWithFormat:@" %@", lnameProperty]];
        }
        
        if (name.length > 0){
            if (![self NSStringIsValidEmail:name]){
                if ((phones.count > 0 || emails.count > 0)){
                    
                    
                    CFDataRef imageData = ABPersonCopyImageData(aPerson);
                    UIImage *image = [UIImage imageWithData:(__bridge NSData *)imageData];
                    
                    NSMutableDictionary *contact = [[NSMutableDictionary alloc] init];
                    [contact setObject:name forKey:@"name"];
                    if(image != nil && image != NULL){
                        [contact setObject:image forKey:@"image"];
                        CFRelease(imageData);
                    }
                    
                    if (phones.count > 0){
                        [contact setObject:phones forKey:@"phones"];
                    }
                    if (emails.count > 0){
                        [contact setObject:emails forKey:@"emails"];
                    }
                    
                    [contactArray addObject:contact];
                    
                }
                
            }
        }
        
    }
    return [self sortedContact:contactArray];
}



+(NSArray *)sortedContact:(NSArray *) contacts{
    NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    
    NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:@[nameSort]];
    
    return sortedContacts;
}




+(NSArray *) searchContact:(NSString *) searchText contects:(NSArray *) contactArray{
    NSMutableArray *filteredContacts = [[NSMutableArray alloc] init];

    
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    NSPredicate *searchPredicate =  [NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] %@", searchText];
    
    
    
    for (NSDictionary *contact in contactArray){
        NSString *name = [contact objectForKey:@"name"];
        NSArray *phones = [contact objectForKey:@"phones"];
        NSArray *emails = [contact objectForKey:@"emails"];
        BOOL Match = NO;
        NSString *show = @"phone";
        NSString *phone = nil;
        NSString *email = nil;
        NSMutableDictionary *filteredContact = [[NSMutableDictionary alloc] init];
        

        
        if (name){
            
            if ([searchPredicate evaluateWithObject:name]){
                Match = YES;
            }
            
        }
        if (phones.count > 0){
            for (NSDictionary *phoneElement in phones){
                NSString *phoneNumber = [phoneElement valueForKey:@"phoneNumber"];
                NSNumber *countryCode = [phoneUtil extractCountryCode:phoneNumber nationalNumber:nil];
                NSString *trimmingString = [NSString stringWithFormat:@"+%@", countryCode];
                phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:trimmingString withString:@""];
                if ([searchPredicate evaluateWithObject:phoneNumber]){
                    Match = YES;
                    phone = [phoneElement valueForKey:@"phoneNumber"];
                    break;
                    
                }
            }
            if (Match && phone.length == 0){
                phone = [(NSDictionary *)phones[0] objectForKey:@"phoneNumber"];
            }
        }
        if (emails.count > 0){
            for (NSDictionary *emailElement in emails){
                
                if ([searchPredicate evaluateWithObject:[emailElement valueForKey:@"email"]]){
                    Match = YES;
                    email = [emailElement valueForKey:@"email"];
                    show = @"email";
                    break;
                    
                }
            }
            if (Match && email.length == 0){
                email = [(NSDictionary *)emails[0] objectForKey:@"email"];
            }
            
        }
        if (phone.length > 0){
            show = @"phone";
        }
        
        
        if (Match && name.length > 0 && (phone.length > 0 || email.length)){
            [filteredContact setObject:name forKey:@"name"];
            if (phone.length){
                [filteredContact setObject:phone forKey:@"phone"];
            }
            if (email.length > 0){
                [filteredContact setObject:email forKey:@"email"];
            }
            [filteredContact setObject:show forKey:@"show"];
            
            if([contact objectForKey:@"image"] != nil && [contact objectForKey:@"image"] != NULL){
                [filteredContact setObject:[contact objectForKey:@"image"] forKey:@"image"];
            }
            
            [filteredContacts addObject:filteredContact];
        }
    }
    
    return filteredContacts;
}

+ (BOOL)isValidEmail:(NSString *)email
{
    NSString *regex1 = @"\\A[a-z0-9]+([-._][a-z0-9]+)*@([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,6}\\z";
    NSString *regex2 = @"^(?=.{1,64}@.{4,64}$)(?=.{6,100}$).*";
    NSPredicate *test1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex1];
    NSPredicate *test2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex2];
    return [test1 evaluateWithObject:email] && [test2 evaluateWithObject:email];
}
+(BOOL) NSStringIsValidEmail:(NSString *)checkString{
    
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}
+(NSString*)stringByTrimLeadingWhiteSpace:(NSString *) inputString {
    NSInteger i = 0;
    
    while ((i < [inputString length])
           && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[inputString characterAtIndex:i]]) {
        i++;
    }
    return [inputString substringFromIndex:i];
}






@end
