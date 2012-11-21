#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import "HKMLead.h"

#define SDKVERSION @"IOS/1.2"
#define MAX_ADDRESSBOOK_UPLOAD_SIZE 2000

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

// other notifications
#define NOTIF_HOOK_DOWNLOAD_SHARE_TEMPLATE_COMPLETE @"HookDownloadShareTemplatesComplete"
#define NOTIF_HOOK_ADDRESSBOOK_CACHE_EXPIRED @"HookAddressbookCacheExpired"
#define NOTIF_HOOK_NETWORK_ERROR @"HookNetworkError"

@interface HKMDiscoverer : NSObject <MFMessageComposeViewControllerDelegate> {
    
    NSString *_server;
    NSString *_SMSDest;
    NSString *_appKey;
    NSString *_installCode;
    BOOL _queryStatus;
    NSMutableArray *_leads;
    NSString *_errorMessage;
    NSMutableArray *_installs;
    NSMutableArray *_referrals;
    NSString *_fbTemplate;
    NSString *_emailTemplate;
    NSString *_smsTemplate;
    NSString *_twitterTemplate;
    NSString *_referralMessage;
    BOOL _skipVerificationSms;  // Skip the verification SMS box altogether
    
   	NSOperationQueue *queue;
    NSMutableData *discoverData;
    NSURLConnection *discoverConnection;
    NSString *addressbook;
    NSDate *lastDiscoverDate;
    
    NSMutableData *queryOrderData;
    NSURLConnection *queryOrderConnection;
    
    NSMutableData *verifyDeviceData;
    NSURLConnection *verifyDeviceConnection;
    UIViewController *viewController;
    BOOL forceVerificationSms; // The verification SMS box cannot be dismissed
    NSString *verifyMessage;
    
    NSMutableData *verificationData;
    NSURLConnection *verificationConnection;
    
    NSMutableData *shareTemplateData;
    NSURLConnection *shareTemplateConnection;
    
    NSMutableData *newReferralData;
    NSURLConnection *newReferralConnection;
    int referralId;
    NSString *invitationUrl;
    
    NSMutableData *updateReferralData;
    NSURLConnection *updateReferralConnection;
    
    NSMutableData *queryInstallsData;
    NSURLConnection *queryInstallsConnection;
    
    NSMutableData *queryReferralData;
    NSURLConnection *queryReferralConnection;
    
    NSMutableData *newInstallData;
    NSURLConnection *newInstallConnection;
    
    NSMutableData *claimRewardData;
    NSURLConnection *claimRewardConnection;
    
    // Need to restore full screen after the SMS verification screen is displayed
    BOOL fullScreen;
    
    NSMutableDictionary *contactsDictionary;
    
}

@property (nonatomic, retain) NSString *installCode;

@property (nonatomic, retain) NSString *server;
@property (nonatomic, retain) NSString *SMSDest;
@property (nonatomic, retain) NSString *appKey;
@property (nonatomic) BOOL queryStatus;
@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic, retain) NSMutableArray *leads;
@property (nonatomic, retain) NSMutableArray *installs;
@property (nonatomic, retain) NSMutableArray *referrals;

@property (nonatomic, retain) NSString *fbTemplate;
@property (nonatomic, retain) NSString *emailTemplate;
@property (nonatomic, retain) NSString *smsTemplate;
@property (nonatomic, retain) NSString *twitterTemplate;

@property (nonatomic, retain) NSString *referralMessage;

// Not commonly used
@property (nonatomic) BOOL skipVerificationSms;

+ (HKMDiscoverer *) agent;
+ (void) activate:(NSString *)ak;
+ (void) retire;

- (BOOL) newInstall;
- (BOOL) isRegistered;
- (BOOL) verifyDevice:(UIViewController *)vc forceSms:(BOOL) force userName:(NSString *) userName;
- (BOOL) queryVerifiedStatus;
- (NSDate *) lastDiscoverDate;
- (BOOL) discover:(int) limit;
- (BOOL) discoverWithoutVzw;
- (BOOL) discoverSelected:(NSMutableArray *)phones;
- (BOOL) queryLeads;
- (BOOL) downloadShareTemplates;
- (BOOL) newReferral:(NSArray *)phones withName:(NSString *)name useVirtualNumber:(BOOL) sendNow;
- (BOOL) updateReferral:(BOOL) sent;
- (BOOL) queryInstalls:(NSString *)direction;
- (BOOL) queryReferral;
- (BOOL) claimReward: (UIViewController *)vc;

- (NSString *) getAddressbook:(int) limit;
- (NSString *) getAddressbookHash:(int) limit;
- (void) createVerificationSms;
- (void) buildAddressBookDictionaryAsync;
- (void) buildAddressBookDictionary;
- (void) updateContactDetails:(HKMLead *)intoLead;
//- (NSString *) lookupNameFromPhone:(NSString *)p;
- (NSString *) formatPhone:(NSString *)p;

- (BOOL) checkNewAddresses:(NSString *)ab;
- (NSString *) cachedAddresses;

- (NSString *) getMacAddress;
- (int) murmurHash:(NSString *)s;

unsigned int MurmurHash2 ( const void * key, int len, unsigned int seed );

@end