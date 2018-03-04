//
//  SCHUtility.h
//  BookingNinjaTest
//
//  Created by Sujit Dalai on 4/5/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "SCHService.h"
#import "SCHServiceOffering.h"
#import "SCHAppointment.h"
#import "SCHNotification.h"
#import <AddressBook/AddressBook.h>
#import "SCHAppointmentSeries.h"
#import <KVNProgress/KVNProgress.h>
#import "SCHEvent.h"
#import <UIKit/UIKit.h>
#import "SCHAvailabilityForAppointment.h"
#import "SCHServiceProviderClientList.h"
#import "SCHUserLocation.h"
#import "SCHServiceMajorClassification.h"
#import "SCHUser.h"
#import "SCHMeeting.h"

@interface SCHUtility : NSObject


+(void) logout;

+(NSArray *)getDaysforschedulingwithStartTime:(NSDate *) startTime endTime:(NSDate *) endTime endDate:(NSDate *) endDate repeatOption:(NSString *) repeatOption repeatDays:(NSArray *) repeatDays;



+(NSArray *)notificationsForUser;



#pragma mark - List of Value APIs

+(NSArray *) servicelist;
+(NSArray *) clientlist;
+(NSArray *) serviceOfferingList:(SCHService *) service;
+(NSArray *)initlizeContactList;
+(NSArray *) privacyPrefrences;
+(NSArray *)autoConfirmOptions;
+(NSArray *)userFeedbackType;
+(NSArray *)getMajorServiceClassification:(BOOL) local;
+(NSArray *)getServiceClassification:(SCHServiceMajorClassification *) majorClassification;
+(NSArray *)ServiceProviderListForService:(SCHServiceClassification *) serviceType;
+(NSArray *)userFevotiteServices:(SCHUser *) user;



#pragma mark - Date Related APIs

//+(NSString *)getCurrentDate: (NSDate *) date;
+(NSDate *)getDate:(NSDate *) date;
+(NSDateFormatter *)dateFormatterForShortDate;
+(NSDateFormatter *)dateFormatterForMediumDate;
+(NSDateFormatter *)dateFormatterForLongDate;
+(NSDateFormatter *)dateFormatterForFullDate;
+(NSDateFormatter *)dateFormatterForShortTime;
+(NSDateFormatter *)dateFormatterForMediumTime;
+(NSDateFormatter *)dateFormatterForLongTime;
+(NSDateFormatter *)dateFormatterForShortDateAndTime;
+(NSDateFormatter *)dateFormatterForMediumDateAndTime;
+(NSDateFormatter *)dateFormatterForLongDateAndTime;
//+(NSDateFormatter *)dateFormaterForScheduleSectionHeader;
+(NSDateFormatter *)dateFormatterForFromTime;
+(NSDateFormatter *)dateFormatterForToTime;
+(NSDate *)startOrEndTime:(NSDate *) date;

#pragma  mark - color  and font from Color code

+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (UIColor *)colorFromHexStringhalfAlpha:(NSString *)hexString;
+(UIColor *)deepGrayColor;
+(UIColor *)greenColor;
+(UIColor *)brightOrangeColor;
+(UIColor *)seaBlueColor;
+(UIColor *)lightBlueColor;
+(UIColor *)mercuryColor;
+(UIFont *)getPreferredTitleFont;
+(UIFont *)getPreferredBodyFont;
+(UIFont *)getPreferredSubtitleFont;

#pragma mark - ACL
+(void)setPublicAllRWACL:(PFACL *) acl;
+(void)setPublicAllROACL:(PFACL *) acl;
+(void) setNoPublicAccessACL:(PFACL *) acl;
+(PFACL *)publicAdultOnlyRWACL;
+(PFACL *)noPublicAccessACL;
//+(PFACL *)privateRWACL:(PFUser *) user;

#pragma mark - Initialization


+(BOOL)initializeSCheduleScreenFilter:(SCHUser *) user;



+(BOOL)hasActiveService;
#pragma mark - progress methoda
+(void)showProgressWithMessage:(NSString*) message onView:(UIView*)view;
+(void)showProgressWithMessage:(NSString*) message;
+(void)completeProgressWithStatus:(NSString *)status;
+(void)completeProgress;
+(BOOL)userToDevicelink;
+(void)userToDeviceDelink;




+(void) reloadScheduleTableView;
+(void) reloadNotificationTableView;



+(SCHNotification *)createNotificationForUser:(SCHUser *) user notificationType:(SCHLookup *)notificationType notificationTitle:(NSString *) notificationTitle message:(NSString *) message referenceObject:(NSString *) referenceObject referenceObjectType:(NSString *) referenceObjectType;

+(void)sendNotification:(SCHNotification *) notification;

+(BOOL) removeOldNotifications:(NSString *)refreenceObjectId;


/***************************************************/

#pragma  mark - Find Service Provider

/****************************************************/


+(NSDictionary *)availabilityForAppointment:(SCHUser *) serviceProvider service:(SCHService *) service;

/**************************************************/

#pragma  mark - Location Services

/*************************************************/
+(NSString *)createLocationAddress:(CLLocation *)location;
+(CLPlacemark *)generateCLLocationfromAddress:(NSString *)address;

/******************************************************/
#pragma mark - table view cell content of Schedule Screen
/******************************************************/

//+(NSAttributedString *)getAppointmentTitle:(SCHEvent *)event;
//+(NSAttributedString *)getAppointmentSubtitle:(SCHEvent *) event;

+(NSAttributedString *)getAppointmentStatus: (SCHEvent *) event;
+(NSString *)getAppointmentClient:(SCHEvent *) event;
+(UITextView *)resizeTextView:(UITextView *) textView;
+(CGFloat)tableViewCellHeight:(UITextView *) textView width:(CGFloat) width;
+(NSDictionary *)preferredTextDispalyFontAttr;

+(NSAttributedString*) getAvailabilityForAppointmentTitle:(SCHAvailabilityForAppointment*) availability;
+(NSAttributedString *)getAvailabilityForAppointmentSubTitle:(SCHAvailabilityForAppointment*) availability;

+(NSArray *)appointmentDetailContents:(id)object;
+(NSArray *) getMajorServiceClassificationList;
+(NSArray *)getServiceClassificationList:(SCHServiceMajorClassification *) majorClassification;

//+(NSAttributedString *)getAvailabilityTitle:(SCHAvailability *) availability;
//+(NSAttributedString *)getAvailabilitySubtile:(SCHEvent *) event;
+(NSArray *)availabilityDetailContents:(SCHAvailability *)availability;



+(NSAttributedString *)summaryForAppointmentedit:(SCHAppointment *) appointment;
+(NSAttributedString *)summaryForMeetingEdit:(SCHMeeting *) meeting;

+(NSString *)getmeetupStatus:(id) object;
+(int)pendingMeetupStatus:(NSArray *)invites;
+(int)nonDeclinedMeetupStatus:(NSArray *)invites;


//new ones
+(NSDictionary *)appointmentInfoForScheduleScreen:(SCHEvent *) event;
+(NSDictionary *)availabilityInfoForScheduleScreen:(SCHEvent *) event;
+(NSDictionary *)meetupInfoForScheduleScreen:(SCHEvent *) event;



+(NSDictionary *)serviceProviderProfileContentForService:(SCHService *) service;

+(void)createUserLocation:(NSString *) location;
+(NSArray *)getUserLocations:(SCHUser *) user;



+(NSArray *)getClientWithName:(NSString *) name email:(NSString *) email phoneNumber:(NSString *)phoneNumber;
+(NSArray *)getClientWithName:(NSString *) name email:(NSString *) email phoneNumber:(NSString *)phoneNumber forServiceProvider:(SCHUser *) serviceProvider;

+(SCHServiceProviderClientList *)addClientToServiceProvider:(SCHUser *)serviceProvider client:(SCHUser *) client name:(NSString *) name nonUserClient:(SCHNonUserClient *) nonUserClient autoConfirm:(BOOL) autoConfirm;
+(NSArray *) GetServiceProviderClientList:(SCHUser *)serviceProvider;

+(BOOL)saveServieAndOffering:(SCHService *) service serviceOffering:(SCHServiceOffering *)serviceOffering;
+ (NSString *)phoneNumberFormate:(NSString *)str;
+(NSAttributedString *)userSubscriptionInfo;



+(void)deleteUserLocation:(SCHUserLocation *) location;
+(void)deleteServiceProviderClient:(SCHServiceProviderClientList *)client;
//+(void)addLocation:(NSString *) location forUser:(SCHUser *)user;

+(BOOL)commit;
+(BOOL)commitEventually;

+(NSAttributedString *) termsOfUse;
+(NSAttributedString *) privacyPolicy;

+(BOOL)phoneNumberExists:(NSString *) phoneNumber;
+(BOOL) syncPriorNonUserActivities:(NSString *)phoneNumber email:(NSString *) email User:(SCHUser *)user;
+(BOOL)IsMandatoryUpgradeRequired;
+(BOOL)BusinessUserAccess;

+(NSArray *)conflictingAppointmentsForService:(SCHService *) service location:(NSString *) location timeFrom:(NSDate *) timeFrom timeTo:(NSDate *) timeTo;
+(void) setServiceCategoryVisibility:(SCHServiceMajorClassification *) majorCategory serviceClassification:(SCHServiceClassification *) serviceCategory;


+(NSString *)referMessage:(SCHService *) service;
+(void) syncFacebookFriends:(NSArray *) FBFriends;
+(void) setServiceProviderStatus;
+(void)setSideMenu;
+(void)getFacebookUserFriends:(SCHUser *) user;
+(NSArray *)bookSearch:(NSString *)searchString;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

+(NSDictionary *)getAppointmentHistoryForUser:(SCHUser *) user serviceProvider:(SCHUser *) serviceProvider service:(SCHService *) service;
+(NSString *) getEndDate:(NSDate *) endDate comparingStartDate:(NSDate *) startDate;
+(BOOL)suspendAccountDueOTPLimt;
+(BOOL)removeAccountSuspensionWithExpirationDate;
+(NSArray *)getAllContacts;
+(NSArray *) searchContact:(NSString *) searchText contects:(NSArray *) contactArray;
+(NSArray *)sortedContact:(NSArray *) contacts;
+(BOOL) NSStringIsValidEmail:(NSString *)checkString;


@end
