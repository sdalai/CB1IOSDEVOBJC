//
//  SCHConstants.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 4/30/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHConstants.h"
#import <Parse/Parse.h>
#import "SCHBackgroundManager.h"
#import "AppDelegate.h"


#pragma mark - MeetupChangeRequestType

NSString *const SCHMeetupCRTypeAddInvitee = @"addInvitee";
NSString *const SCHMeetupCRTypeChangeLocationOrTime = @"changeLocationOrTime";


#pragma mark - MeetupChangeRequestType

NSString *const SCHMeetupCRAttrRequester = @"changeRequester";
NSString *const SCHMeetupCRAttrType = @"CRType";
NSString *const SCHMeetupCRAttrNewInvitee = @"newInvite";
NSString *const SCHMeetupCRAttrProposedStartTime = @"proposedStartTime";
NSString *const SCHMeetupCRAttrProposedEndTime = @"proposedEndTime";
NSString *const SCHMeetupCRAttrProposedLocation = @"proposedLocation";

#pragma mark - MeetupConfirmation
NSString *const SCHMeetupConfirmed = @"Confirmed";
NSString *const SCHMeetupNotConfirmed = @"notConfirmed";
NSString *const SCHMeetupDeclined = @"Declined";

#pragma mark - MeetupStatus
NSString *const SCHMeetupStatusConfirmed = @"Confirmed";
NSString *const SCHMeetupStatusPending = @"Pending";
NSString *const SCHMeetupStatusCancelled = @"Cancelled";
NSString *const SCHMeetupStatusRespond = @"Respond";
NSString *const SCHMeetupStatusDeclined = @"Declined";

#pragma mark - MeetupInviteStructure
NSString *const SCHMeetupInviteeUser = @"user";
NSString *const SCHMeetupInviteeName = @"name";
NSString *const SCHMeetupInviteeConfirmation = @"confirmation";
NSString *const SCHMeetupInviteePhoneNumber = @"phoneNumber";
NSString *const SCHMeetupInviteeEmail = @"email";


NSString *const SCHAppName = @"CounterBean";
NSString *const SCHsyncFailure = @"syncFailure";
NSString *const SCHUserLogout = @"SCHUserLogout";

#pragma mark - time Block Properties

NSTimeInterval const SCHTimeBlockDuration = 60*15;

#pragma mark - Event Type

NSString *const SCHEventTypeAvailability = @"Availability";
NSString *const SCHEventTypeAppointment = @"Appointment";

#pragma mark - Parse object Names

NSString *const SCHAvailableTimeBlockClass = @"SCHAvailableTimeBlock";
NSString *const SCHServiceClass = @"SCHService";
NSString *const SCHServiceClassificationClass = @"SCHServiceClassification";
NSString *const SCHServiceOfferingClass = @"SCHServiceOffering";
NSString *const SCHAppointmentClass = @"SCHAppointment";
NSString *const SCHAppointmentActivityClass = @"SCHAppointmentActivity";
//NSString *const SCHLookupClass = @"SCHLookup";
NSString *const SCHAvailabilityClass = @"SCHAvailability";
NSString *const SCHAvailabilityForAppointmentClass = @"SCHAvailabilityForAppointment";
NSString *const SCHNotificationClass = @"SCHNotification";
NSString *const SCHAppointmentSeriesClass = @"SCHAppointmentSeries";
NSString *const SCHDefaultServiceOfferingClass = @"SCHDefaultServiceOffering";
NSString *const SCHUserLocationClass = @"SCHUserLocation";
NSString *const SCHServiceProviderClientListClass = @"SCHServiceProviderClientList";
NSString *const SCHNonUserClientClass = @"SCHNonUserClient";
NSString *const SCHPaymentFrequencyClass = @"SCHPaymentFrequency";
NSString *const SCHScheduleScreenFilterClass = @"SCHScheduleScreenFilter";
NSString *const SCHServiceMajorClassificationClass = @"SCHServiceMajorClassification";
NSString *const SCHUserFeedbackClass = @"SCHUserFeedback";
NSString *const SCHUserFevoriteServiceClass = @"SCHUserFevoriteService";
NSString *const SCHLegalDocumentClass = @"SCHLegalDocument";
NSString *const SCHAppReleaseClass = @"SCHAppRelease";
NSString *const SCHControlClass = @"SCHControl";
NSString *const SCHUserFriendClass = @"SCHUserFriend";
NSString *const SCHUserClass = @"SCHUser";
NSString *const SCHMeetingClass = @"SCHMeeting";







NSString *const SCHFieldTitleMajorServiceClassification = @"Category";
NSString *const SCHFieldTitleMinorServiceClassification = @"Sub Category";
NSString *const SCHFieldTitleBusinessName = @"Name";
NSString *const SCHFieldTitlePrice = @"Price($)";
NSString *const SCHFieldTitleBusinessProfileVisibility = @"Business Profile Visibility";
NSString *const SCHFieldTitleScheduleVisibility = @"Schedule Visibility";
NSString *const SCHFieldTitleAutoConfirm = @"Appt. Auto Confirm";
NSString *const SCHFieldTitleBusinessServices=@"Offering";
NSString *const SCHFieldTitleViewOffering=@"View Offerings";
NSString * const SCHFieldBusinesPhone = @"Phone";
NSString * const SCHFieldBusinessEmail = @"Email";
NSString *const SCHFieldTitleCustomerPhoneRequired = @"Phone Reqd for Booking";



#pragma mark - ServerActions
NSString *const SCHServerCommitSave = @"save";
NSString *const SCHServerCommitDelete = @"delete";
NSString *const SCHServerCommitUpdate = @"update";
NSString *const SCHServerCommitAction = @"action";
NSString *const SCHServerCommitMode = @"commmitMode";
NSString *const SCHServerCommitModeSynchronous = @"synchronous";
NSString *const SCHServerCommitModeAsynchronous = @"asynchronous";
NSString *const SCHserverCommitModeEventually = @"eventually";
NSString *const SCHserverCommitObject = @"commitObject";




#pragma mark - availability change reason code

NSString *const SCHACRCAvailabilityCreattion = @"AvailabilityCreation";

#pragma mark - Sreen Title

NSString *const SCHScreenTitleManageAvailability = @"Availability";
NSString *const SCHSCreenTitleNewAppointment = @"Appointment";
NSString *const SCHSCreenTitleNewMeetup = @"Meet-up";
NSString *const SCHSCreenTitleSchedule = @"Schedule";
NSString *const SCHSCreenTitlePendingAppointment = @"Pending Appointment";
#pragma mark - section Title

NSString *const SCHScreenSectionTitleService = @"Service";
NSString *const SCHScreenSectionTitleTime = @"Time";
NSString *const SCHScreenSectionTitleNote = @"Note";
NSString *const SCHScreenSectionTitleRepeatation = @"";


#pragma mark - Field Titles

NSString *const SCHFieldTitleAvailabilityAction = @"Action";
NSString *const SCHFieldTitleService = @"Business";
NSString *const SCHFieldTitleLocation = @"Location";
NSString *const SCHFieldTitleFromTime = @"From";
NSString *const SCHFieldTitleToTime = @"To";
NSString *const SCHFieldTitleCancelExistingAppointments = @"Cancel Existing Appointments";
NSString *const SCHFieldTitleServiceType = @"For";
NSString *const SCHFieldTitleClient = @"Client";
NSString *const SCHFieldTitleNote = @"Notes";
NSString *const SCHFieldTitleRepeat = @"Repeat";
NSString *const SCHFieldTitleRepeatDays = @"Repeat Days";
NSString *const SCHFieldTitleEndDate = @"End Date";
NSString *const SCHFieldTitleAppointmentTitle = @"AppointmentTitle";
NSString *const SCHFieldTitleAppointmentSummary = @"AppointmentSummary";

NSString *const SCHFieldTitleOfferingName = @"Offering Name";
NSString *const SCHFieldTitleOfferingStatus = @"Status";
NSString *const SCHFieldTitleOfferingStanderdDuration = @"Service Duration";
NSString *const SCHFieldTitleOfferingDurationStatus = @"Is Duration Fixed?";
NSString *const SCHFieldTitleOfferingDurationIncrement = @"Minimum Increment";
NSString *const SCHFieldTitleOfferingDescripition = @"Description";


#pragma mark - Edit Profile Field Titles

NSString *const SCHFieldTitleProfileFirstName = @"First Name";
NSString *const SCHFieldTitleProfileLastName = @"Last Name";
NSString *const SCHFieldTitleProfilePhoneNumber = @"Phone Number";
NSString *const SCHFieldTitleProfileDisplayName = @"Preferred Name";
NSString *const SCHFieldTitleProfileEmail = @"Email";
NSString *const SCHFieldTitleProfileSubscriptionType = @"Subscription Type";
NSString *const SCHFieldTitleProfilePaymentFrequency = @"Payment Frequency";
NSString *const SCHFieldTitleProfilePaymentAmount = @"Amount";
NSString *const SCHFieldTitleProfileStartDate = @"Start Date";
NSString *const SCHFieldTitleProfileRenewalDate = @"Renewal Date";
NSString *const SCHFieldTitleProfileExpirationDate = @"Expiration Date";

#pragma mark - ApplicationColor

NSString *const SCHApplicationNavagationBarColor = @"00BBD3";
NSString *const SCHApplicationTintColor = @"00BBD3";
NSString *const SCHLogoColor  = @"008373";

#pragma mark - selector title

NSString *const SCHselectorTitleManageAvailabilityActionList = @"Action";
NSString *const SCHSelectorTitleServiceList = @"Service";
NSString *const SCHSelectorTitleServiceTypeList = @"Service Type";
NSString *const SCHSelectorTitleClentList = @"Client";
NSString *const SCHSelectorTitleRepeat = @"Repeat";
NSString *const SCHSelectorTitleRepeatDay = @"Day";


#pragma mark - Availability action selectors

NSString *const SCHSelectorAvailabilityActionOptionAvailable = @"Add";
NSString *const SCHSelectorAvailabilityActionOptionUnavailable = @"Remove";
NSString *const SCHSelectorAvailabilityActionOptionChange = @"Change";

#pragma mark - Availability repeat selectors
NSString *const SCHSelectorRepeatationOptionNever = @"Never";
NSString *const SCHSelectorRepeatationOptionEveryDay = @"Every Day";
NSString *const SCHSelectorRepeatationOptionEveryWeek = @"Every Week";
NSString *const SCHSelectorRepeatationOptionEvery2Weeks = @"Every 2 Weeks";
NSString *const SCHSelectorRepeatationOptionEveryMonth = @"Every Month";
NSString *const SCHSelectorRepeatationOptionSpectficDaysOftheWeek = @"Specific Days of Week";

#pragma mark - Availability Repeat Day selectors
NSString *const SCHSelectorRepeatationOptionMonday = @"Monday";
NSString *const SCHSelectorRepeatationOptionTuesday = @"Tuesday";
NSString *const SCHSelectorRepeatationOptionWednesday = @"Wednesday";
NSString *const SCHSelectorRepeatationOptionThursday = @"Thursday";
NSString *const SCHSelectorRepeatationOptionFriday =@"Friday";
NSString *const SCHSelectorRepeatationOptionSaturday = @"Saturday";
NSString *const SCHSelectorRepeatationOptionSunday= @"Sunday";





#pragma mark - Table Reusable Cell identifier
NSString *const SCHFromCell = @"FromPicker";
NSString *const SCHToCell = @"ToPicker";
NSString *const SCHDatePickerCell = @"datePicker";
NSString *const SCHDateCell = @"dateCell";
NSString *const SCHSelectorCell = @"selecterCell";
NSString *const SCHTextInputCell = @"textInputCell";
NSString *const SCHTextViewInputCell = @"textViewInputCell";

#pragma mark - Color constant
NSString *const SCHColorConformed = @"#666666";
NSString *const SCHColorPending = @"#FFFFFA";
NSString *const SCHColorCancled = @"#778899";
NSString *const SCHColorAvaliblity = @"#99CCFF"; //48D1CC";
NSString *const SCHScheduleSectionHeaderColor = @"#333333";

#pragma mark - Progress Message
NSString *const SCHProgressMessageCreateAppointment = @"Requesting Appointment";
NSString *const SCHProgressMessageCreateAvability = @"Creating Availability";
NSString *const SCHProgressMessageCreateUnavailability = @"Removing Availability";
NSString *const SCHProgressMessageChangingAvability = @"Changing Availability";
NSString *const SCHProgressMessageAcceptAppointment = @"Accepting Request";
NSString *const SCHProgressMessageDeclineAppointment = @"Declining Request";
NSString *const SCHProgressMessageCreateMeetup = @"Creating Meet-up";
NSString *const SCHProgressMessageRemoveInvitee = @"Removing";
NSString *const SCHProgressMessageGeneric = @"Processing";


#pragma mark - Back Button
NSString *const SCHBackkButtonTitle = @"Back";

NSString *const SCHScheduleListView = @"list_view";
NSString *const SCHScheduleCalenderWeekView = @"calender_week";
NSString *const SCHScheduleCalenderMonthView = @"calender_month";


@interface SCHConstants ()
#pragma mark - AppointmentStatus

@property (strong, nonatomic, readwrite) SCHLookup  *SCHappointmentStatusConfirmed;
@property (strong, nonatomic, readwrite) SCHLookup  *SCHappointmentStatusPending;
@property (strong, nonatomic, readwrite) SCHLookup  *SCHappointmentStatusCancelled;
@property (strong, nonatomic, readwrite) SCHLookup  *SCHappointmentStatusProcessing;



#pragma mark - AppointmentActivityStatus

@property(nonatomic, strong, readwrite) SCHLookup *SCHappointmentActivityStatusOpen;
@property(nonatomic, strong, readwrite) SCHLookup *SCHappointmentActivityStatusComplete;


#pragma mark - AllocationType

@property(nonatomic, strong, readwrite) SCHLookup  *SCHallocationTypeHard;
@property(nonatomic, strong, readwrite) SCHLookup  *SCHallocationTypeSoft;

#pragma mark - Appointment Action
@property(nonatomic, strong, readwrite) SCHLookup  *SCHAppointmentActionAppointmentRequest;
@property(nonatomic, strong, readwrite) SCHLookup  *SCHAppointmentActionRespondToAppointmentRequest;
@property(nonatomic, strong, readwrite) SCHLookup  *SCHAppointmentActionAppointmentCancellation;
@property(nonatomic, strong, readwrite) SCHLookup  *SCHAppointmentActionAppointmentChangeRequest;
@property(nonatomic, strong, readwrite) SCHLookup  *SCHAppointmentActionRespondToAppontmentChangeRequest;
@property(nonatomic, strong, readwrite) SCHLookup  *SCHAppointmentActionAcceptance;
@property(nonatomic, strong, readwrite) SCHLookup  *SCHAppointmentActionRejaction;
@property(nonatomic, strong, readwrite) SCHLookup  *SCHAppointmentActionAppointmentCreation;
@property(nonatomic, strong, readwrite) SCHLookup  *SCHAppointmentActionAppointmentChange;

#pragma mark - Notification Types
@property(nonatomic,strong, readwrite) SCHLookup *SCHAppointmentResponseNotification;
@property(nonatomic, strong, readwrite) SCHLookup *SCHAppointmentAcceptanceNotification;
@property(nonatomic, strong, readwrite) SCHLookup *SCHAppointmentRejectionNotification;
@property(nonatomic, strong, readwrite) SCHLookup *SCHAppointmentDeletionNotification;
@property(nonatomic, strong, readwrite) SCHLookup *SCHNotificationForResponse;
@property(nonatomic, strong, readwrite) SCHLookup *SCHNotificationForAcknowledgement;

#pragma mark - Subscription Type

@property(nonatomic, strong, readwrite) SCHLookup *SCHSubscriptionTypeFreeUser;
@property(nonatomic, strong, readwrite) SCHLookup *SCHSubscriptionTypePremiumUser;
@property(nonatomic, strong, readwrite) SCHLookup *SCHSubscriptionTypeAllAccessFreeUser;

#pragma mark - privacyOptions
@property(nonatomic, strong, readwrite) SCHLookup *SCHPrivacyOptionPublic;
@property(nonatomic, strong, readwrite) SCHLookup *SCHPrivacyOptionClient;

#pragma mark - Auto Confirm Option
@property(nonatomic, strong, readwrite) SCHLookup *SCHAutoConfirmOptionPublic;
@property(nonatomic, strong, readwrite) SCHLookup *SCHAutoConfirmOptionClient;
@property(nonatomic, strong, readwrite) SCHLookup *SCHAutoConfirmOptionNone;
@property(nonatomic, strong, readwrite) SCHLookup *SCHAutoConfirmOptionSpecificClients;


#pragma mark - User feedback Option
@property(nonatomic, strong, readwrite) SCHLookup *SCHUserFeedbackIssue;
@property(nonatomic, strong, readwrite) SCHLookup *SCHUserFeedbackSuggestion;

#pragma mark - legal Document Type
@property(nonatomic, strong, readwrite) SCHLookup *SCHLegalDocumentPrivacyPolicy;
@property(nonatomic, strong, readwrite) SCHLookup *SCHLegalDocumentUserAgreement;

#pragma mark - SCHDeviceType
@property(nonatomic, strong,readwrite) SCHLookup *SCHDeviceTypeiPhone;


@end


@implementation SCHConstants

static int numberOfLookup = 38;

static SCHConstants *ConstantManager = nil;


+ (instancetype) sharedManager {

    @synchronized(self) {
        if (ConstantManager == nil){
            ConstantManager = [[[self class] alloc] init];
            if (![ConstantManager initializeConstants]){
                [SCHConstants resetSharedManager];
            }
        }
       return ConstantManager;
    }
    
}

+(void)resetSharedManager{
    @synchronized(self) {
        ConstantManager = nil;

    }
    
    
}





-(BOOL)initializeConstants{
    

    BOOL initialized = YES;
    NSSet *lookupSet = [NSSet setWithArray:[self getlookupcodes]];
    
    if (lookupSet.count < numberOfLookup){
        initialized = NO;
        return initialized;
    }

    NSSortDescriptor *lookupCode = [NSSortDescriptor sortDescriptorWithKey:@"lookupCode" ascending:YES];

        
       // NSLog(@"counts lookups: %lu", (unsigned long)[lookupSet count]);
        
        // Appointmentstatus
        
        NSPredicate *appointmentStatusPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            SCHLookup *lookup = (SCHLookup *)evaluatedObject;
            if ([lookup.lookupType isEqualToString:@"appointmentStatus"]){
                return YES;
            } else return  NO;
        }];
        
        NSArray *appointmentStatuses = [[lookupSet filteredSetUsingPredicate:appointmentStatusPredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    if (appointmentStatuses.count < 4){
        
        initialized = NO;
        return initialized;
        


        
    } else{
        if (appointmentStatuses[0]){
            self.SCHappointmentStatusConfirmed = appointmentStatuses[0];
        }
        
        if (appointmentStatuses[1]){
            self.SCHappointmentStatusPending = appointmentStatuses[1];
        }
        if (appointmentStatuses[2]){
            self.SCHappointmentStatusCancelled =appointmentStatuses[2];
        }
        
        if (appointmentStatuses[3]){
            self.SCHappointmentStatusProcessing =appointmentStatuses[3];
        }

        
    }
        
        //appointmentActivityStatus
        
        NSPredicate *appointmentActivityStatusPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            SCHLookup *lookup = (SCHLookup *)evaluatedObject;
            if ([lookup.lookupType isEqualToString:@"appointmentActivityStatus"]){
                return YES;
            } else return  NO;
        }];
        
        NSArray *appointmentActivityStatus = [[lookupSet filteredSetUsingPredicate:appointmentActivityStatusPredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    if (appointmentActivityStatus.count < 2){
        initialized = NO;
        return initialized;
    } else{
        if (appointmentActivityStatus[0]){
            self.SCHappointmentActivityStatusComplete = appointmentActivityStatus[0];
        }
        
        if (appointmentActivityStatus[1]){
            self.SCHappointmentActivityStatusOpen = appointmentActivityStatus[1];
        }
    }
        
        //AllocationType
        
        NSPredicate *allocationTypePredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            SCHLookup *lookup = (SCHLookup *)evaluatedObject;
            if ([lookup.lookupType isEqualToString:@"appointmentActivityStatus"]){
                return YES;
            } else return  NO;
        }];
        
        NSArray *allocationTypes = [[lookupSet filteredSetUsingPredicate:allocationTypePredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    if (allocationTypes.count < 2){
        initialized = NO;
        return initialized;

    } else{
        self.SCHallocationTypeHard = allocationTypes[0];
        self.SCHallocationTypeSoft = allocationTypes[1];
    }
    
        
        NSPredicate *appointmentActionPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            SCHLookup *lookup = (SCHLookup *)evaluatedObject;
            if ([lookup.lookupType isEqualToString:@"appointmentAction"]){
                return YES;
            } else return  NO;
        }];
        NSArray *appointmentActions = [[lookupSet filteredSetUsingPredicate:appointmentActionPredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    
    if (appointmentActions.count < 9){
        initialized = NO;
        return initialized;
    } else{
        if (appointmentActions[0]){
            self.SCHAppointmentActionAppointmentRequest = appointmentActions[0];
        }
        if (appointmentActions[1]){
            self.SCHAppointmentActionRespondToAppointmentRequest = appointmentActions[1];
        }
        if (appointmentActions[2]){
            self.SCHAppointmentActionAppointmentCancellation = appointmentActions[2];
        }
        if (appointmentActions[3]){
            self.SCHAppointmentActionAppointmentChangeRequest = appointmentActions[3];
        }
        
        if (appointmentActions[4]){
            self.SCHAppointmentActionRespondToAppontmentChangeRequest= appointmentActions[4];
        }
        if (appointmentActions[5]){
            self.SCHAppointmentActionAcceptance = appointmentActions[5];
        }
        if (appointmentActions[6]){
            self.SCHAppointmentActionRejaction = appointmentActions[6];
        }
        if (appointmentActions[7]){
            self.SCHAppointmentActionAppointmentCreation = appointmentActions[7];
        }
        if (appointmentActions[8]){
            self.SCHAppointmentActionAppointmentChange = appointmentActions[8];
        }

    }
    
    
    
        NSPredicate *notificationPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
           SCHLookup *lookup = (SCHLookup *)evaluatedObject;
           if ([lookup.lookupType isEqualToString:@"SCHNotification"]){
              return YES;
           } else return  NO;
        }];
    
        NSArray *notifications = [[lookupSet filteredSetUsingPredicate:notificationPredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    if (notifications.count < 6){
        initialized = NO;
        return initialized;

    } else {
        if (notifications[0]){
            self.SCHAppointmentResponseNotification = notifications[0];
        }
        if (notifications[1]){
            self.SCHAppointmentAcceptanceNotification = notifications[1];
        }
        if (notifications[2]){
            self.SCHAppointmentRejectionNotification = notifications[2];
        }
        if (notifications[3]){
            self.SCHAppointmentDeletionNotification = notifications[3];
        }
        if (notifications[4]){
            self.SCHNotificationForResponse = notifications[4];
        }
        if (notifications[5]){
            self.SCHNotificationForAcknowledgement = notifications[5];
        }

    }
    
    
    
    
    NSPredicate *subscriptionPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        SCHLookup *lookup = (SCHLookup *)evaluatedObject;
        if ([lookup.lookupType isEqualToString:@"SCHSubscriptionType"]){
            return YES;
        } else return  NO;
    }];
    
    NSArray *subscriptions = [[lookupSet filteredSetUsingPredicate:subscriptionPredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    if (subscriptions.count < 3){
        initialized = NO;
        return initialized;
    } else{
        if (subscriptions[0]){
            self.SCHSubscriptionTypeFreeUser = subscriptions[0];
        }
        if (subscriptions[1]){
            self.SCHSubscriptionTypePremiumUser = subscriptions[1];
        }
        if (subscriptions[2]){
            self.SCHSubscriptionTypeAllAccessFreeUser = subscriptions[2];
        }

    }
    
    
    
    
    NSPredicate *privacyOptionPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        SCHLookup *lookup = (SCHLookup *)evaluatedObject;
        if ([lookup.lookupType isEqualToString:@"SCHPrivacyControl"]){
            return YES;
        } else return  NO;
    }];
    
    NSArray *privacyOptions = [[lookupSet filteredSetUsingPredicate:privacyOptionPredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    if (privacyOptions.count < 2){
        initialized = NO;
        return initialized;
    } else {
        if (privacyOptions[0]){
            self.SCHPrivacyOptionPublic = privacyOptions[0];
        }
        if (privacyOptions[1]){
            self.SCHPrivacyOptionClient = privacyOptions[1];
        }
    }


    //SCHAutoConfirmOption
    
    NSPredicate *autoConfirmOptionPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        SCHLookup *lookup = (SCHLookup *)evaluatedObject;
        if ([lookup.lookupType isEqualToString:@"SCHAutoConfirmOption"]){
            return YES;
        } else return  NO;
    }];
    
    NSArray *autoConfirmOptions = [[lookupSet filteredSetUsingPredicate:autoConfirmOptionPredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    if (autoConfirmOptions.count < 4){
        initialized = NO;
        return initialized;
    } else {
        if (autoConfirmOptions[0]){
            self.SCHAutoConfirmOptionPublic = autoConfirmOptions[0];
        }
        if (autoConfirmOptions[1]){
            self.SCHAutoConfirmOptionClient = autoConfirmOptions [1];
        }
        if (autoConfirmOptions[2]){
            self.SCHAutoConfirmOptionNone = autoConfirmOptions[2];
        }
        if (autoConfirmOptions[3]){
            self.SCHAutoConfirmOptionSpecificClients = autoConfirmOptions[3];
        }

    }
    
    //SCHUserFeedback
    
    NSPredicate *userFeedbackPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        SCHLookup *lookup = (SCHLookup *)evaluatedObject;
        if ([lookup.lookupType isEqualToString:@"SCHUserFeedback"]){
            return YES;
        } else return  NO;
    }];
    
    NSArray *userFeedbacks = [[lookupSet filteredSetUsingPredicate:userFeedbackPredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    if (userFeedbacks.count < 2){
        initialized = NO;
        return initialized;
    } else{
        if (userFeedbacks[0]){
            self.SCHUserFeedbackIssue = userFeedbacks[0];
        }
        if (userFeedbacks[1]){
            self.SCHUserFeedbackSuggestion = userFeedbacks[1];
        }
        
    }
    
    //SCH Legal Document Types
    NSPredicate *legalDocumentPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        SCHLookup *lookup = (SCHLookup *)evaluatedObject;
        if ([lookup.lookupType isEqualToString:@"SCHLegalDocument"]){
            return YES;
        } else return  NO;
    }];

    NSArray *legalDocuments = [[lookupSet filteredSetUsingPredicate:legalDocumentPredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    if (legalDocuments.count < 2){
        initialized = NO;
        return initialized;
    } else{
        if (legalDocuments[0]){
            self.SCHLegalDocumentPrivacyPolicy = legalDocuments[0];
        }
        if (legalDocuments[0]){
            self.SCHLegalDocumentUserAgreement = legalDocuments[1];
        }
    }
    
    

    
    
    
    
    
    //SCHDeviceType - SCHDeviceType
    NSPredicate *deviceTypePredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        SCHLookup *lookup = (SCHLookup *)evaluatedObject;
        if ([lookup.lookupType isEqualToString:@"SCHDeviceType"]){
            return YES;
        } else return  NO;
    }];
    NSArray *deviceTypes = [[lookupSet filteredSetUsingPredicate:deviceTypePredicate] sortedArrayUsingDescriptors:@[lookupCode]];
    
    if (deviceTypes.count < 1){
        initialized = NO;
        return initialized;
    } else{
        if (deviceTypes[0]){
            self.SCHDeviceTypeiPhone = deviceTypes[0];
        }
    }
    
    return initialized;
    
    
}

-(NSArray *)getlookupcodes{
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PFQuery *lookupQuery = [SCHLookup query];
    [lookupQuery fromLocalDatastore];
    if (lookupQuery.countObjects >= numberOfLookup){
        NSArray *lookups = [lookupQuery findObjects];
        return lookups;

    } else {
        // refresh localdata for lookup
        PFQuery *lookupWueryFromServer = [SCHLookup query];
        if (appDelegate.serverReachable){
            NSArray *sLookups = [lookupWueryFromServer findObjects:&error];
            if (!error){
                NSArray *LDLookups = [lookupQuery findObjects];
                if (LDLookups && LDLookups.count >0){
                    [PFObject unpinAll:LDLookups];
                }
                [PFObject pinAll:sLookups];
                return sLookups;
                
            } else return @[];
        }else return @[];
    
    }
}


@end
