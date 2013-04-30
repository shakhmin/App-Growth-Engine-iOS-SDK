#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import "HKMLead.h"

#define SDKVERSION @"IOS/1.4"

#define MAX_ADDRESSBOOK_UPLOAD_SIZE 1000
#define AGE_SERVER @"https://age.hookmobile.com"
#define DEFAULT_VIRTUAL_NUMBER @"3025175040"

// SMS Verification notification
#define NOTIF_HOOK_NOT_SMS_DEVICE @"HookNotSMSDevice"
#define NOTIF_HOOK_DEVICE_VERIFIED @"HookDeviceVerified"
#define NOTIF_HOOK_DEVICE_NOT_VERIFIED @"HookDeviceNotVerified"
#define NOTIF_HOOK_VERIFY_DEVICE_COMPLETE @"HookVerifyDeviceComplete"
#define NOTIF_HOOK_VERIFICATION_SMS_SENT @"HookVerificationSMSSent"
#define NOTIF_HOOK_VERIFICATION_SMS_NOT_SENT @"HookVerificationSMSNotSent"

// Addressbook discovery notification
#define NOTIF_HOOK_DISCOVER_COMPLETE @"HookDiscoverComplete"
#define NOTIF_HOOK_DISCOVER_NO_CHANGE @"HookDiscoverNoChange"
#define NOTIF_HOOK_DISCOVER_FAILED @"HookDiscoverFailed"

// Query invitation leads notification
#define NOTIF_HOOK_QUERY_ORDER_COMPLETE @"HookQueryOrderComplete"
#define NOTIF_HOOK_QUERY_ORDER_FAILED @"HookQueryOrderFailed"

// Referral notification
#define NOTIF_HOOK_NEW_REFERRAL_COMPLETE @"HookNewReferralComplete"
#define NOTIF_HOOK_NEW_REFERRAL_FAILED @"HookNewReferralFailed"
#define NOTIF_HOOK_UPDATE_REFERRAL_COMPLETE @"HookUpdateReferralComplete"
#define NOTIF_HOOK_UPDATE_REFERRAL_FAILED @"HookUpdateReferralFailed"
#define NOTIF_HOOK_QUERY_REFERRAL_COMPLETE @"HookQueryReferralComplete"
#define NOTIF_HOOK_QUERY_REFERRAL_FAILED @"HookQueryReferralFailed"

// Query friends with installs notification
#define NOTIF_HOOK_QUERY_INSTALLS_COMPLETE @"HookQueryInstallsComplete"
#define NOTIF_HOOK_QUERY_INSTALLS_FAILED @"HookQueryInstallsFailed"

// Claim reward notification
#define NOTIF_HOOK_CLAIM_REWARD_COMPLETE @"HookClaimRewardComplete"
#define NOTIF_HOOK_CLAIM_REWARD_PENDING_SMS_VERIFICATION @"HookClaimRewardPendingSmsVerification"
#define NOTIF_HOOK_CLAIM_REWARD_FAILED @"HookClaimRewardFailed"

// Query phone number type notification
#define NOTIF_HOOK_QUERY_PHONE_NUMBER_TYPE_COMPLETE @"HookQueryPhoneNumberTypeComplete"
#define NOTIF_HOOK_QUERY_PHONE_NUMBER_TYPE_FAILED @"HookQueryPhoneNumberTypeFailed"

// other notifications
#define NOTIF_HOOK_DOWNLOAD_SHARE_TEMPLATE_COMPLETE @"HookDownloadShareTemplatesComplete"
#define NOTIF_HOOK_ADDRESSBOOK_CACHE_EXPIRED @"HookAddressbookCacheExpired"
#define NOTIF_HOOK_NETWORK_ERROR @"HookNetworkError"


@interface HKMDiscoverer : NSObject

@property (nonatomic, strong) NSString *installCode;
@property (nonatomic, strong) NSMutableArray *leads;
@property (nonatomic, strong) NSString *errorMessage;
@property (nonatomic, strong) NSMutableArray *installs;
@property (nonatomic, strong) NSMutableArray *referrals;
@property (nonatomic, strong) NSString *referralMessage;
@property (nonatomic, retain) NSString *customParam;
@property (nonatomic) BOOL contactsLoaded;
@property (nonatomic, retain) NSMutableArray *phoneNumberTypes;
@property (nonatomic) int queryPhoneNumberTypeListIndex;

+ (HKMDiscoverer *) agent;
+ (void) activate:(NSString *)ak;
+ (void) activateKey:(NSString *)ak customParam:(NSString *) customParam;
+ (void) retire;
+ (BOOL) deviceSmsSupport;
+ (NSString *) deviceOwnerName;

- (BOOL) newInstall;
- (BOOL) isRegistered;
- (BOOL) verifyDevice:(UIViewController *)vc forceSms:(BOOL) force userName:(NSString *) userName;
- (BOOL) queryVerifiedStatus;
- (NSDate *) lastDiscoverDate;
- (BOOL) discover:(int) limit;
- (BOOL) queryLeads;
- (BOOL) newReferral:(NSArray *)phones useVirtualNumber:(BOOL) sendNow;
- (BOOL) newReferral:(NSArray *)phones withName:(NSString *)name useVirtualNumber:(BOOL) sendNow;
- (BOOL) updateReferral:(BOOL) sent;
- (BOOL) queryInstalls:(NSString *)direction;
- (BOOL) queryReferral;
- (BOOL) claimReward: (UIViewController *)vc;
- (BOOL) trackEventName: (NSString *)name Value: (NSString *)value;
- (BOOL) loadAddressBooktoIntoLeads;
- (BOOL) queryPhoneNumberTypeAtLeadsIndex: (int)index;
- (BOOL) queryPhoneNumberType: (NSArray *)phones;


@end