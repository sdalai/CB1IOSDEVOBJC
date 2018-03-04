//
//  SCHConstants.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 4/30/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCHLookup.h"

@interface SCHConstants : NSObject
+ (instancetype) sharedManager;
+(void)resetSharedManager;


//008373


#pragma mark - AppointmentStatus

@property (strong, nonatomic, readonly) SCHLookup  *SCHappointmentStatusConfirmed;
@property (strong, nonatomic, readonly) SCHLookup  *SCHappointmentStatusPending;
@property (strong, nonatomic, readonly) SCHLookup  *SCHappointmentStatusCancelled;
@property (strong, nonatomic, readonly) SCHLookup  *SCHappointmentStatusProcessing;


extern NSString const *myString;








#pragma mark - AppointmentActivityStatus

@property(nonatomic, strong, readonly) SCHLookup *SCHappointmentActivityStatusOpen;
@property(nonatomic, strong, readonly) SCHLookup *SCHappointmentActivityStatusComplete;


#pragma mark - AllocationType

@property(nonatomic, strong, readonly) SCHLookup  *SCHallocationTypeHard;
@property(nonatomic, strong, readonly) SCHLookup  *SCHallocationTypeSoft;


#pragma mark - Appointment Action
@property(nonatomic, strong, readonly) SCHLookup  *SCHAppointmentActionAppointmentRequest;
@property(nonatomic, strong, readonly) SCHLookup  *SCHAppointmentActionRespondToAppointmentRequest;
@property(nonatomic, strong, readonly) SCHLookup  *SCHAppointmentActionAppointmentCancellation;
@property(nonatomic, strong, readonly) SCHLookup  *SCHAppointmentActionAppointmentChangeRequest;
@property(nonatomic, strong, readonly) SCHLookup  *SCHAppointmentActionRespondToAppontmentChangeRequest;
@property(nonatomic, strong, readonly) SCHLookup  *SCHAppointmentActionAcceptance;
@property(nonatomic, strong, readonly) SCHLookup  *SCHAppointmentActionRejaction;
@property(nonatomic, strong, readonly) SCHLookup  *SCHAppointmentActionAppointmentCreation;
@property(nonatomic, strong, readonly) SCHLookup  *SCHAppointmentActionAppointmentChange;

#pragma mark - Notification Types
@property(nonatomic,strong, readonly) SCHLookup *SCHAppointmentResponseNotification;
@property(nonatomic, strong, readonly) SCHLookup *SCHAppointmentAcceptanceNotification;
@property(nonatomic, strong, readonly) SCHLookup *SCHAppointmentRejectionNotification;
@property(nonatomic, strong, readonly) SCHLookup *SCHAppointmentDeletionNotification;
@property(nonatomic, strong, readonly) SCHLookup *SCHNotificationForResponse;
@property(nonatomic, strong, readonly) SCHLookup *SCHNotificationForAcknowledgement;

#pragma mark - Subscription Type

@property(nonatomic, strong, readonly) SCHLookup *SCHSubscriptionTypeFreeUser;
@property(nonatomic, strong, readonly) SCHLookup *SCHSubscriptionTypePremiumUser;
@property(nonatomic, strong, readonly) SCHLookup *SCHSubscriptionTypeAllAccessFreeUser;

#pragma mark - privacyOptions
@property(nonatomic, strong, readonly) SCHLookup *SCHPrivacyOptionPublic;
@property(nonatomic, strong, readonly) SCHLookup *SCHPrivacyOptionClient;

#pragma mark - Auto Confirm Option
@property(nonatomic, strong, readonly) SCHLookup *SCHAutoConfirmOptionPublic;
@property(nonatomic, strong, readonly) SCHLookup *SCHAutoConfirmOptionClient;
@property(nonatomic, strong, readonly) SCHLookup *SCHAutoConfirmOptionNone;
@property(nonatomic, strong, readonly) SCHLookup *SCHAutoConfirmOptionSpecificClients;



#pragma mark - User feedback Option
@property(nonatomic, strong, readonly) SCHLookup *SCHUserFeedbackIssue;
@property(nonatomic, strong, readonly) SCHLookup *SCHUserFeedbackSuggestion;

#pragma mark - legal Document Type
@property(nonatomic, strong, readonly) SCHLookup *SCHLegalDocumentPrivacyPolicy;
@property(nonatomic, strong, readonly) SCHLookup *SCHLegalDocumentUserAgreement;

#pragma mark - SCHDeviceType
@property(nonatomic, strong,readonly) SCHLookup *SCHDeviceTypeiPhone;


#pragma mark - MeetupChangeRequestType

extern NSString *const SCHMeetupCRTypeAddInvitee;
extern NSString *const SCHMeetupCRTypeChangeLocationOrTime;


#pragma mark - MeetupChangeRequestType

extern NSString *const SCHMeetupCRAttrRequester;
extern NSString *const SCHMeetupCRAttrType;
extern NSString *const SCHMeetupCRAttrNewInvitee;
extern NSString *const SCHMeetupCRAttrProposedStartTime;
extern NSString *const SCHMeetupCRAttrProposedEndTime;
extern NSString *const SCHMeetupCRAttrProposedLocation;









#pragma mark - MeetupConfirmation
extern NSString *const SCHMeetupConfirmed;
extern NSString *const SCHMeetupNotConfirmed;
extern NSString *const SCHMeetupDeclined;

#pragma mark - MeetupStatus
extern NSString *const SCHMeetupStatusConfirmed;
extern NSString *const SCHMeetupStatusPending;
extern NSString *const SCHMeetupStatusCancelled;
extern NSString *const SCHMeetupStatusRespond;
extern NSString *const SCHMeetupStatusDeclined;




#pragma mark - MeetupInviteStructure
extern NSString *const SCHMeetupInviteeUser;
extern NSString *const SCHMeetupInviteeName;
extern NSString *const SCHMeetupInviteeConfirmation;
extern NSString *const SCHMeetupInviteePhoneNumber;
extern NSString *const SCHMeetupInviteeEmail;






#pragma mark - Server Action
extern NSString *const SCHAppName;
extern NSString *const SCHServerCommitSave;
extern NSString *const SCHServerCommitDelete;
extern NSString *const SCHServerCommitUpdate;
extern NSString *const SCHsyncFailure;
extern NSString *const SCHUserLogout;



#pragma mark - commitKeys
extern NSString *const SCHServerCommitAction;
extern NSString *const SCHServerCommitMode;
extern NSString *const SCHServerCommitModeSynchronous;
extern NSString *const SCHServerCommitModeAsynchronous;
extern NSString *const SCHserverCommitModeEventually;
extern NSString *const SCHserverCommitObject;


#pragma mark - time Block Properties

extern NSTimeInterval const SCHTimeBlockDuration;



#pragma mark - availability change reason code

extern NSString *const SCHACRCAvailabilityCreattion;



#pragma mark - Sreen Title

extern NSString *const SCHScreenTitleManageAvailability;
extern NSString *const SCHSCreenTitleNewAppointment;
extern NSString *const SCHSCreenTitleNewMeetup;
extern NSString *const SCHSCreenTitleSchedule;
extern NSString *const SCHSCreenTitlePendingAppointment;


#pragma mark - section Title

extern NSString *const SCHScreenSectionTitleService;
extern NSString *const SCHScreenSectionTitleTime;
extern NSString *const SCHScreenSectionTitleNote;
extern NSString *const SCHScreenSectionTitleRepeatation;


#pragma mark - ApplicationColor

extern NSString *const SCHApplicationNavagationBarColor;
extern NSString *const SCHLogoColor;
extern NSString *const SCHApplicationTintColor;


#pragma mark - Field Titles

extern NSString *const SCHFieldTitleAvailabilityAction;
extern NSString *const SCHFieldTitleService;
extern NSString *const SCHFieldTitleLocation;
extern NSString *const SCHFieldTitleFromTime;
extern NSString *const SCHFieldTitleToTime;
extern NSString *const SCHFieldTitleCancelExistingAppointments;
extern NSString *const SCHFieldTitleServiceType;
extern NSString *const SCHFieldTitleClient;
extern NSString *const SCHFieldTitleNote;
extern NSString *const SCHFieldTitleRepeat;
extern NSString *const SCHFieldTitleRepeatDays;
extern NSString *const SCHFieldTitleEndDate;
extern NSString *const SCHFieldTitleAppointmentTitle;
extern NSString *const SCHFieldTitleAppointmentSummary;
extern NSString *const SCHFieldTitleOfferingName;
extern NSString *const SCHFieldTitleOfferingStatus;
extern NSString *const SCHFieldTitleOfferingStanderdDuration;
extern NSString *const SCHFieldTitleOfferingDurationStatus;
extern NSString *const SCHFieldTitleOfferingDurationIncrement;
extern NSString *const SCHFieldTitleOfferingDescripition;
extern NSString *const SCHFieldTitleCustomerPhoneRequired;


#pragma mark - Edit Profile Field Titles

extern NSString *const SCHFieldTitleProfileFirstName;
extern NSString *const SCHFieldTitleProfileLastName;
extern NSString *const SCHFieldTitleProfilePhoneNumber;
extern NSString *const SCHFieldTitleProfileDisplayName;
extern NSString *const SCHFieldTitleProfileEmail;
extern NSString *const SCHFieldTitleProfileSubscriptionType;
extern NSString *const SCHFieldTitleProfilePaymentFrequency;
extern NSString *const SCHFieldTitleProfilePaymentAmount;
extern NSString *const SCHFieldTitleProfileStartDate;
extern NSString *const SCHFieldTitleProfileRenewalDate;
extern NSString *const SCHFieldTitleProfileExpirationDate;





#pragma mark - selector title

extern NSString *const SCHselectorTitleManageAvailabilityActionList;
extern NSString *const SCHSelectorTitleServiceList;
extern NSString *const SCHSelectorTitleServiceTypeList;
extern NSString *const SCHSelectorTitleClentList;
extern NSString *const SCHSelectorTitleRepeat;
extern NSString *const SCHSelectorTitleRepeatDay;



#pragma mark - Availability action selectors

extern NSString *const SCHSelectorAvailabilityActionOptionAvailable;
extern NSString *const SCHSelectorAvailabilityActionOptionUnavailable;
extern NSString *const SCHSelectorAvailabilityActionOptionChange;

#pragma mark - Availability Repeat selectors
extern NSString *const SCHSelectorRepeatationOptionNever;
extern NSString *const SCHSelectorRepeatationOptionEveryDay;
extern NSString *const SCHSelectorRepeatationOptionEveryWeek;
extern NSString *const SCHSelectorRepeatationOptionEvery2Weeks;
extern NSString *const SCHSelectorRepeatationOptionEveryMonth;
extern NSString *const SCHSelectorRepeatationOptionSpectficDaysOftheWeek;

#pragma mark - Availability Repeat Day selectors
extern NSString *const SCHSelectorRepeatationOptionMonday;
extern NSString *const SCHSelectorRepeatationOptionTuesday;
extern NSString *const SCHSelectorRepeatationOptionWednesday;
extern NSString *const SCHSelectorRepeatationOptionThursday;
extern NSString *const SCHSelectorRepeatationOptionFriday;
extern NSString *const SCHSelectorRepeatationOptionSaturday;
extern NSString *const SCHSelectorRepeatationOptionSunday;

#pragma mark - Parse object Names


extern NSString *const SCHAvailableTimeBlockClass;
extern NSString *const SCHServiceClass;
extern NSString *const SCHServiceClassificationClass;
extern NSString *const SCHServiceOfferingClass;
extern NSString *const SCHAppointmentClass;
extern NSString *const SCHAppointmentActivityClass;
//extern NSString *const SCHLookupClass;
extern NSString *const SCHAvailabilityClass;
extern NSString *const SCHAvailabilityForAppointmentClass;
extern NSString *const SCHNotificationClass;
extern NSString *const SCHAppointmentSeriesClass;
extern NSString *const SCHDefaultServiceOfferingClass;
extern NSString *const SCHUserLocationClass;
extern NSString *const SCHServiceProviderClientListClass;
extern NSString *const SCHNonUserClientClass;
extern NSString *const SCHPaymentFrequencyClass;
extern NSString *const SCHScheduleScreenFilterClass;
extern NSString *const SCHServiceMajorClassificationClass;
extern NSString *const SCHUserFeedbackClass;
extern NSString *const SCHUserFevoriteServiceClass;
extern NSString *const SCHLegalDocumentClass;
extern NSString *const SCHAppReleaseClass;
extern NSString *const SCHControlClass;
extern NSString *const SCHUserFriendClass;
extern NSString *const SCHUserClass;
extern NSString *const SCHMeetingClass;




extern NSString *const SCHFieldTitleMajorServiceClassification;
extern NSString *const SCHFieldTitleMinorServiceClassification;
extern NSString *const SCHFieldTitleBusinessName;
extern NSString *const SCHFieldTitlePrice;
extern NSString *const SCHFieldTitleBusinessProfileVisibility;
extern NSString *const SCHFieldTitleScheduleVisibility;
extern NSString *const SCHFieldTitleAutoConfirm;
extern NSString *const SCHFieldTitleBusinessServices;
extern NSString *const SCHFieldTitleViewOffering;
extern NSString * const SCHFieldBusinesPhone;
extern NSString * const SCHFieldBusinessEmail;




#pragma mark - Event Type

extern NSString *const SCHEventTypeAvailability;
extern NSString *const SCHEventTypeAppointment;

#pragma mark - Table Reusable Cell identifier
extern NSString *const SCHFromCell;
extern NSString *const SCHToCell;
extern NSString *const SCHDatePickerCell;
extern NSString *const SCHDateCell;
extern NSString *const SCHSelectorCell;
extern NSString *const SCHTextInputCell;
extern NSString *const SCHTextViewInputCell;

#pragma mark - Color constant
extern NSString *const SCHColorConformed;
extern NSString *const SCHColorPending;
extern NSString *const SCHColorCancled;
extern NSString *const SCHColorAvaliblity;
extern NSString *const SCHScheduleSectionHeaderColor;

#pragma mark - Progress Message
extern NSString *const SCHProgressMessageCreateAppointment;
extern NSString *const SCHProgressMessageCreateAvability;
extern NSString *const SCHProgressMessageCreateUnavailability;
extern NSString *const SCHProgressMessageChangingAvability;
extern NSString *const SCHProgressMessageAcceptAppointment;
extern NSString *const SCHProgressMessageDeclineAppointment;
extern NSString *const SCHProgressMessageCreateMeetup;
extern NSString *const SCHProgressMessageRemoveInvitee;
extern NSString *const SCHProgressMessageGeneric;


#pragma mark - Back Button Text
extern NSString *const SCHBackkButtonTitle;

extern NSString *const SCHScheduleListView;
extern NSString *const SCHScheduleCalenderWeekView;
extern NSString *const SCHScheduleCalenderMonthView;

@end
