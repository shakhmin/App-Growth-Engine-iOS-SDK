#import "HKMDiscoverer.h"
#import "HKMLead.h"
#import "HKMJSON.h"
#import "HKMReferralRecord.h"
#import <AddressBook/AddressBook.h>
#import "UIDevice-HKMHardware.h"
#import "HKMOpenUDID.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

@interface HKMDiscoverer () <MFMessageComposeViewControllerDelegate>

@property (nonatomic, strong) NSString *server;
@property (nonatomic, strong) NSString *SMSDest;
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic) BOOL queryStatus;
// Not commonly used
@property (nonatomic) BOOL skipVerificationSms;

- (BOOL) discoverSelected:(NSMutableArray *)phones;

- (NSString *) getAddressbook:(int) limit;
- (NSString *) getAddressbookHash:(int) limit;
- (void) createVerificationSms;
- (void) buildAddressBookDictionaryAsync;
- (void) buildAddressBookDictionary;
//- (void) updateContactDetails:(HKMLead *)intoLead;
- (void) updateLeadFromAddressbook;
- (NSString *) formatPhone:(NSString *)p;

- (BOOL) checkNewAddresses:(NSString *)ab;
- (NSString *) cachedAddresses;

- (NSString *) getMacAddress;
- (int) murmurHash:(NSString *)s;

unsigned int MurmurHash2 ( const void * key, int len, unsigned int seed );

@end

@implementation HKMDiscoverer

static HKMDiscoverer *_agent;
static NSString *_deviceOwnerName;

NSString *_server;
NSString *_SMSDest;
NSString *_appKey;
NSString *_installCode;
BOOL _queryStatus;
NSMutableArray *_leads;
NSString *_errorMessage;
NSMutableArray *_installs;
NSMutableArray *_referrals;
NSString *_referralMessage;
BOOL _skipVerificationSms;  // Skip the verification SMS box altogether
NSString *_isoCountryCode;
NSString *_operatorCode;
BOOL _contactsLoaded;
int _queryPhoneNumberTypeListIndex;

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

NSMutableData *trackEventData;
NSURLConnection *trackEventConnection;

NSMutableData *queryPhoneNumberTypeData;
NSURLConnection *queryPhoneNumberTypeConnection;

// Need to restore full screen after the SMS verification screen is displayed
BOOL fullScreen;

NSMutableDictionary *contactsDictionary;

@synthesize server=_server, SMSDest=_SMSDest, appKey=_appKey, queryStatus=_queryStatus, errorMessage=_errorMessage, installs=_installs, referrals=_referrals, customParam=_customParam, contactsLoaded=_contactsLoaded;
@synthesize referralMessage=_referralMessage, phoneNumberTypes=_phoneNumberTypes, queryPhoneNumberTypeListIndex=_queryPhoneNumberTypeListIndex;
@synthesize installCode = _installCode;
@synthesize skipVerificationSms=_skipVerificationSms;
@synthesize leads = _leads;

- (id) init {
    self = [super init];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults) {
		self.installCode = [standardUserDefaults objectForKey:@"installCode"];
        self.customParam = [standardUserDefaults objectForKey:@"customParam"];
		lastDiscoverDate = [standardUserDefaults objectForKey:@"lastDiscoverDate"];
    }
    
    contactsDictionary = [NSMutableDictionary dictionary];
    
    queue = [[NSOperationQueue alloc] init];
    
    // default
    self.skipVerificationSms = NO;
    
    return self;
}

- (BOOL) isRegistered{
    if (self.installCode == nil || [self.installCode length] == 0) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL) verifyDevice:(UIViewController *)vc forceSms:(BOOL) force userName:(NSString *) userName {
    if (verifyDeviceConnection != nil) {
        return NO;
    }
    if (vc != nil) {
        viewController = vc;
        forceVerificationSms = force;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/newverify", self.server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [self.appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceInfo=%@", [self getDeviceInfoJson]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceModel=%@", [[UIDevice currentDevice] platformString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceOs=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&openUdid=%@", [[HKMOpenUDID value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installToken=%@", [[HKMOpenUDID value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&macAddress=%@", [[self getMacAddress] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&verifyMessageTemplate=%@", [@"Send text to confirm your device and see which friends has this app.  %installCode%" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    if (userName != nil) {
        [postBody appendData:[[NSString stringWithFormat:@"&name=%@", [userName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&operatorCode=%@", _operatorCode] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&isoCountryCode=%@", _isoCountryCode] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&name=%@", [HKMDiscoverer deviceOwnerName]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		verifyDeviceData = [NSMutableData data];
        verifyDeviceConnection = connection;
	}
    
    return YES;
}

- (BOOL) queryVerifiedStatus {
    if (verificationConnection != nil || self.installCode == nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryverify", self.server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [self.appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [[self installCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		verificationData = [NSMutableData data];
        verificationConnection = connection;
	}
    return YES;
}

- (NSDate *) lastDiscoverDate {
    return lastDiscoverDate;
}

- (BOOL) discover:(int) limit {
    if (discoverConnection != nil) {
        return NO;
    }
    
    //NSLog(@"installCode is %@", self.installCode);
    
    NSString *ab = [self getAddressbook:limit];
    if (ab == nil) {
        return NO;
    }
    
    if (![self checkNewAddresses:ab] && [self lastDiscoverDate] != nil) {
        if ([contactsDictionary count] == 0)
            [self buildAddressBookDictionary];
        
        NSLog(@"discover: No change to address book, request igorned, post Notification %@", NOTIF_HOOK_DISCOVER_NO_CHANGE);
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_DISCOVER_NO_CHANGE object:nil];
        return YES;
    }
    
    // build dictionary for quick lookup by phone
    [self buildAddressBookDictionaryAsync];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/discover", [self server]]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [self.appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    if (self.installCode != nil ) {
        [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [[self installCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSString *encodedJsonStr = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)ab, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
	[postBody appendData:[[NSString stringWithFormat:@"&addressBook=%@", encodedJsonStr] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceInfo=%@", [self getDeviceInfoJson]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceModel=%@", [[UIDevice currentDevice] platformString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceOs=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&openUdid=%@", [[HKMOpenUDID value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installToken=%@", [[HKMOpenUDID value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&macAddress=%@", [[self getMacAddress] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&operatorCode=%@", _operatorCode] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&isoCountryCode=%@", _isoCountryCode] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&name=%@", [HKMDiscoverer deviceOwnerName]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		discoverData = [NSMutableData data];
        discoverConnection = connection;
	}
    
    return YES;
}

// contacts must be an array of dictionaries
// Each dictionary has
//    phone
//    firstName
//    lastName
- (BOOL) discoverSelected:(NSMutableArray *)contacts {
    if (discoverConnection != nil) {
        return NO;
    }
    
    //NSLog(@"installCode is %@", self.installCode);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/selectupdate", [self server]]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [self.appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    if (self.installCode != nil ) {
        [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [[self installCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSError *error;
    NSData *aData = [NSJSONSerialization dataWithJSONObject:contacts
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    NSString* jsonStr = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
    //NSLog(@"JSON Object --> %@", jsonStr);
    NSString *encodedJsonStr = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)jsonStr, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
    
	[postBody appendData:[[NSString stringWithFormat:@"&addressBook=%@", encodedJsonStr] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceInfo=%@", [self getDeviceInfoJson]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceModel=%@", [[UIDevice currentDevice] platformString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceOs=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&openUdid=%@", [[HKMOpenUDID value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installToken=%@", [[HKMOpenUDID value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&macAddress=%@", [[self getMacAddress] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&name=%@", [HKMDiscoverer deviceOwnerName]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		discoverData = [NSMutableData data];
        discoverConnection = connection;
	}
    
    return YES;
}

- (BOOL) queryLeads {
    if (queryOrderConnection != nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryleads", [self server]]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [self.appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [self.installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		queryOrderData = [NSMutableData data];
        queryOrderConnection = connection;
	}
    
    return YES;
}

- (BOOL) newReferral:(NSArray *)phones useVirtualNumber:(BOOL) sendNow {
    return [self newReferral:phones withName:[HKMDiscoverer deviceOwnerName] useVirtualNumber:sendNow];
}

- (BOOL) newReferral:(NSArray *)phones withName:(NSString *)name useVirtualNumber:(BOOL) sendNow {
    
    if (newReferralConnection != nil) {
        return NO;
    }
    
    if (!sendNow && ![HKMDiscoverer deviceSmsSupport])
        sendNow = true;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/newreferral", [self server]]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [[self appKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [[self installCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    for (NSString *phone in phones) {
        NSString *encodedPhone = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)phone, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
        [postBody appendData:[[NSString stringWithFormat:@"&phone=%@", encodedPhone] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    if (name != nil) {
        [postBody appendData:[[NSString stringWithFormat:@"&name=%@", [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [postBody appendData:[@"&useShortUrl=true" dataUsingEncoding:NSUTF8StringEncoding]];
    if (sendNow) {
        [postBody appendData:[@"&sendNow=true" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&operatorCode=%@", _operatorCode] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&isoCountryCode=%@", _isoCountryCode] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		newReferralData = [NSMutableData data];
        newReferralConnection = connection;
	}
    
    return YES;
}

- (BOOL) updateReferral:(BOOL) sent {
    if (updateReferralConnection != nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/updatereferral", [self server]]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [self.appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [[self installCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&referralId=%d", referralId] dataUsingEncoding:NSUTF8StringEncoding]];
    if (sent) {
        [postBody appendData:[@"&action=sent" dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        [postBody appendData:[@"&action=cancel" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		updateReferralData = [NSMutableData data];
        updateReferralConnection = connection;
	}
    
    return YES;
}

- (BOOL) queryInstalls:(NSString *)direction {
    if (queryInstallsConnection != nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryinstalls", [self server]]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [[self appKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [[self installCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&reference=%@", [direction stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		queryInstallsData = [NSMutableData data];
        queryInstallsConnection = connection;
	}
    
    return YES;
}

- (BOOL) queryReferral {
    if (queryReferralConnection != nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryreferral", [self server]]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [[self appKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [[self installCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		queryReferralData = [NSMutableData data];
        queryReferralConnection = connection;
	}
    
    return YES;
}

- (BOOL) newInstall {
    [self readTelephonyInfo];
    
    if (newInstallConnection != nil) {
        return NO;
    }
    if (self.installCode != nil && ![@"" isEqualToString:self.installCode]) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/newinstall", [self server]]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [[self appKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    //    [postBody appendData:[[NSString stringWithFormat:@"&addrHash=%@", [self getAddressbookHash:10]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceInfo=%@", [self getDeviceInfoJson]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&openUdid=%@", [[HKMOpenUDID value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installToken=%@", [[HKMOpenUDID value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&macAddress=%@", [[self getMacAddress] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceModel=%@", [[UIDevice currentDevice] platformString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceOs=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&operatorCode=%@", _operatorCode] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&isoCountryCode=%@", _isoCountryCode] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&name=%@", [HKMDiscoverer deviceOwnerName]] dataUsingEncoding:NSUTF8StringEncoding]];
    if ([self customParam] != nil)
        [postBody appendData:[[NSString stringWithFormat:@"&customParam=%@", [self customParam]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		newInstallData = [NSMutableData data];
        newInstallConnection = connection;
	}
    
    return YES;
}

- (BOOL) claimReward: (UIViewController *)vc  {
    if (claimRewardConnection != nil)
        return NO;
    if (self.installCode == nil)
        return NO;
    
    if (vc != nil) {
        viewController = vc;
    }
    
    NSLog(@"claimReward is %@", self.installCode);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/newrewardclaim", self.server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [[self appKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [[self installCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installToken=%@", [[HKMOpenUDID value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceInfo=%@", [self getDeviceInfoJson]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&macAddress=%@", [[self getMacAddress] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceModel=%@", [[UIDevice currentDevice] platformString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceOs=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&openUdid=%@", [[HKMOpenUDID value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&name=%@", [HKMDiscoverer deviceOwnerName]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		claimRewardData = [NSMutableData data];
        claimRewardConnection = connection;
	}
    
    return YES;
}

- (BOOL) trackEventName: (NSString *)name Value: (NSString *)value {
    if (trackEventConnection != nil || [self installCode] == nil) {
        return NO;
    }
    
    NSLog(@"trackEvent name:%@, value:%@", name, value);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/trackevent", [self server]]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [[self appKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [[self installCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&sdkVersion=%@", [SDKVERSION stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&eventName=%@", [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&eventValue=%@", [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		trackEventData = [NSMutableData data];
        trackEventConnection = connection;
	}
    // [connection release];
    
    return YES;
    
}

- (BOOL)loadAddressBooktoIntoLeads {
    //NSLog(@"Loading addressbook contact..");
    ABAddressBookRef addressBook = ABAddressBookCreate();
    if (addressBook == nil)
        return NO;
    
    ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
    CFArrayRef addressBookRecords = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, kABPersonSortByFirstName);
    
    for (int i = 0 ; i < CFArrayGetCount(addressBookRecords) ; i++)
    {
        HKMLead *lead = [[HKMLead alloc] init];
        
        // get a single person as a record
        ABRecordRef person = CFArrayGetValueAtIndex(addressBookRecords, i) ;
        lead.recordId = ABRecordGetRecordID(person);
        lead.name = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName((ABRecordRef)person));
        lead.addressbookIndex = i;
        
        
        
        // Check for contact picture
        if (ABPersonHasImageData(person)) {
            if ( &ABPersonCopyImageDataWithFormat != nil ) // iOS >= 4.1
                lead.image = [UIImage imageWithData:(NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail))];
            else // iOS < 4.1
                lead.image = [UIImage imageWithData:(NSData *)CFBridgingRelease(ABPersonCopyImageData(person))];
        }
        [self.leads addObject:lead];
        self.contactsLoaded = true;
    }
    
    // release memory
    if (addressBook)
        CFRelease(addressBook) ;
    if (source)
        CFRelease(source);
    if (addressBookRecords)
        CFRelease(addressBookRecords) ;
    
    return YES;
}

- (BOOL) queryPhoneNumberTypeAtLeadsIndex: (int)index {
    if (index < 0 || index > [self leads].count)
        return NO;
    
    self.queryPhoneNumberTypeListIndex = index;
    // retrieve lead
    HKMLead *lead = [[self leads] objectAtIndex:index];
    // retrieve contact from address book
    //NSLog(@"Loading addressbook contact..");
    ABAddressBookRef addressBook = ABAddressBookCreate();
    ABRecordRef contact = ABAddressBookGetPersonWithRecordID(addressBook, lead.recordId);
    ABMultiValueRef ps = ABRecordCopyValue(contact, kABPersonPhoneProperty);
    CFIndex count = ABMultiValueGetCount (ps);
    
    if (count == 0) {
        NSLog(@"queryPhoneNumberTypeAtLeadsIndex: post notification %@", NOTIF_HOOK_QUERY_PHONE_NUMBER_TYPE_COMPLETE);
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_QUERY_PHONE_NUMBER_TYPE_COMPLETE object:nil];
        return YES;
    }
    
    NSMutableArray *phones = [[NSMutableArray alloc] initWithCapacity:10];
    for (int i = 0; i < count; i++) {
        CFStringRef phone = ABMultiValueCopyValueAtIndex (ps, i);
        [phones addObject:(NSString *) CFBridgingRelease(phone)];
    }
    
    [self queryPhoneNumberType:phones];
    
    // release memory
    if (addressBook)
        CFRelease(addressBook) ;
    if (ps)
        CFRelease(ps);
    
    return YES;
}

- (BOOL) queryPhoneNumberType: (NSArray *)phones {
    if (queryPhoneNumberTypeConnection != nil || self.installCode == nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryphonenumbertype", [self server]]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [self.appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    if (self.installCode != nil ) {
        [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [[self installCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [postBody appendData:[[NSString stringWithFormat:@"&operatorCode=%@", _operatorCode] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&isoCountryCode=%@", _isoCountryCode] dataUsingEncoding:NSUTF8StringEncoding]];
    
    for (NSString *phone in phones) {
        NSString *encodedPhone = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)phone, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
        [postBody appendData:[[NSString stringWithFormat:@"&phone=%@", encodedPhone] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		queryPhoneNumberTypeData = [NSMutableData data];
        queryPhoneNumberTypeConnection = connection;
	}
    // [connection release];
    
    return YES;
}


- (NSString *) getAddressbook:(int) limit {
    ABAddressBookRef ab = ABAddressBookCreate();
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(ab);
    CFIndex nPeople = ABAddressBookGetPersonCount(ab);
    if (limit > MAX_ADDRESSBOOK_UPLOAD_SIZE || limit <= 0)
        limit = MAX_ADDRESSBOOK_UPLOAD_SIZE;
    
    NSMutableArray *phones = [[NSMutableArray alloc] init];
    for (int i = 0; i < nPeople; i++) {
        if ([phones count] >= limit)
            break;
        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);
        CFStringRef firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
        CFStringRef lastName = ABRecordCopyValue(ref, kABPersonLastNameProperty);
        
        NSString *firstNameStr = (NSString *) CFBridgingRelease(firstName);
        if (firstNameStr == nil) {
            firstNameStr = @"";
        }
        NSString *lastNameStr = (NSString *) CFBridgingRelease(lastName);
        if (lastNameStr == nil) {
            lastNameStr = @"";
        }
        
        ABMultiValueRef ps = ABRecordCopyValue(ref, kABPersonPhoneProperty);
        CFIndex count = ABMultiValueGetCount (ps);
        for (int i = 0; i < count; i++) {
            if ([phones count] >= limit)
                break;
            CFStringRef phone = ABMultiValueCopyValueAtIndex (ps, i);
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:16];
            [dic setObject:((NSString *) CFBridgingRelease(phone)) forKey:@"phone"];
            [dic setObject:((NSString *) firstNameStr) forKey:@"firstName"];
            [dic setObject:((NSString *) lastNameStr) forKey:@"lastName"];
            [phones addObject:dic];
        }
        
        CFRelease(ps);
    }
    if (allPeople)
        CFRelease(allPeople);
    if (ab)
        CFRelease(ab);
    
    // create json for phone and name based on phones
    NSError *error;
    NSData *aData = [NSJSONSerialization dataWithJSONObject:phones
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    NSString* jsonStr = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
    NSLog(@"getAddressbook: request limit %d records, returning %d records", limit, [phones count]);
    
    return jsonStr;
}

- (NSString *) getAddressbookHash:(int) limit {
    ABAddressBookRef ab = ABAddressBookCreate();
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(ab);
    CFIndex nPeople = ABAddressBookGetPersonCount(ab);
    if (limit > 0 && nPeople > limit) {
        nPeople = limit;
    }
    
    NSMutableString *hashes = [NSMutableString stringWithCapacity:1024];
    for (int i = 0; i < nPeople; i++) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);
        
        ABMultiValueRef ps = ABRecordCopyValue(ref, kABPersonPhoneProperty);
        CFIndex count = ABMultiValueGetCount (ps);
        for (int i = 0; i < count; i++) {
            CFStringRef phone = ABMultiValueCopyValueAtIndex (ps, i);
            NSString *fphone = [self formatPhone:((NSString *) CFBridgingRelease(phone))];
            int hash = [self murmurHash:fphone];
            [hashes appendFormat:@"%d|", hash];
            //            NSLog(@"Murmur Hash of addresses %@ is %d", fphone, hash);
        }
        if (ps)
            CFRelease(ps);
    }
	if (allPeople) {
        CFRelease(allPeople);
    }
    
    NSString *res = @"";
    if ([hashes length] > 0) {
        res = [hashes substringToIndex:([hashes length]-1)];
    }
    //NSLog(@"Murmur Hash outcome is %@", res);
    if (ab)
        CFRelease(ab);
    
    return res;
}

- (void) createVerificationSms {
    fullScreen = [UIApplication sharedApplication].statusBarHidden;
    NSString *platform = [[UIDevice currentDevice] platformString];
    NSString *model = [[UIDevice currentDevice] model];
    if (viewController != nil) {
        if ([MFMessageComposeViewController canSendText] && [platform hasPrefix:@"iPhone"] && ![model isEqualToString:@"iPhone Simulator"] && ![self skipVerificationSms]) {
            [UIApplication sharedApplication].statusBarHidden = NO;
            MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
            controller.body = verifyMessage;
            controller.recipients = [NSArray arrayWithObjects:[self SMSDest], nil];
            controller.messageComposeDelegate = self;
            [viewController presentModalViewController:controller animated:YES];
        } else {
            //NSLog(@"Not a SMS device. Fail silently.");
            NSLog(@"createVerificationSms: post notification %@", NOTIF_HOOK_NOT_SMS_DEVICE);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_NOT_SMS_DEVICE object:nil];
        }
    }
}

- (NSString *) lookupNameFromPhone:(NSString *)p {
    //double start = [[NSDate date] timeIntervalSince1970];
    
    NSString *name;
    
    ABAddressBookRef ab = ABAddressBookCreate();
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(ab);
    CFIndex nPeople = ABAddressBookGetPersonCount(ab);
    
    for (int i = 0; i < nPeople; i++) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);
        
        ABMultiValueRef ps = ABRecordCopyValue(ref, kABPersonPhoneProperty);
        CFIndex count = ABMultiValueGetCount (ps);
        for (int i = 0; i < count; i++) {
            NSString *phone = CFBridgingRelease(ABMultiValueCopyValueAtIndex (ps, i));
            
            if ([p isEqualToString:[self formatPhone:(phone)]]) {
                name = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName((ABRecordRef)ref));
                break;
            }
        }
    }
	if (allPeople) {
        CFRelease(allPeople);
    }
    
    //NSLog(@"lookupNameFromPhone - Time elapsed %f", ([[NSDate date] timeIntervalSince1970]-start));
    return name;
}

- (void) buildAddressBookDictionaryAsync {
    /* Create our NSInvocationOperation to call buildAddressBookDictionary, passing in nil */
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                            selector:@selector(buildAddressBookDictionary)
                                                                              object:nil];
    
    /* Add the operation to the queue */
    [queue addOperation:operation];
}

- (void) buildAddressBookDictionary {
    @autoreleasepool {
        //double start = [[NSDate date] timeIntervalSince1970];
        
        [contactsDictionary removeAllObjects];
        ABAddressBookRef ab = ABAddressBookCreate();
        
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(ab);
        CFIndex nPeople = ABAddressBookGetPersonCount(ab);
        
        for (int i = 0; i < nPeople; i++) {
            ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);
            
            ABRecordID recordId = ABRecordGetRecordID(ref); // get record id from address book record
            
            ABMultiValueRef ps = ABRecordCopyValue(ref, kABPersonPhoneProperty);
            CFIndex count = ABMultiValueGetCount (ps);
            for (int i = 0; i < count; i++) {
                CFStringRef phone = ABMultiValueCopyValueAtIndex (ps, i);
                [contactsDictionary setObject:[NSNumber numberWithInteger:recordId] forKey:[self formatPhone:((NSString *) CFBridgingRelease(phone))]];
            }
            if (ps)
                CFRelease(ps);
        }
        if (allPeople) {
            CFRelease(allPeople);
        }
        
        //NSLog(@"buildAddressBookDictionary - Time elapsed %f", ([[NSDate date] timeIntervalSince1970]-start));
        if (ab)
            CFRelease(ab);
    }
}

// Update lead with info from address book
- (void) updateLeadFromAddressbook {
    if ([[self leads]count] == 0)
        return;
    
    // Get contact from Address Book
    ABAddressBookRef addressBook = ABAddressBookCreate();
    
    for (HKMLead *lead in [self leads]) {
        NSNumber *contactId = [contactsDictionary objectForKey:lead.phone];
        if (!contactId) {
            NSLog(@"updateContactDetails - contact[%@] not found in dictionary", lead.phone);
            continue;
        }
        
        ABRecordID recordId = (ABRecordID)[contactId intValue];
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, recordId);
        lead.name = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName((ABRecordRef)person));
        
        // Check for contact picture
        if (person != nil && ABPersonHasImageData(person)) {
            // iOS >= 4.1
            if ( &ABPersonCopyImageDataWithFormat != nil )
                lead.image = [UIImage imageWithData:(NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail))];
            else // iOS < 4.1
                lead.image = [UIImage imageWithData:(NSData *)CFBridgingRelease(ABPersonCopyImageData(person))];
        }
    }
    
    CFRelease(addressBook);
}

- (NSString *) formatPhone:(NSString *)p {
    p = [p stringByReplacingOccurrencesOfString:@"(" withString:@""];
    p = [p stringByReplacingOccurrencesOfString:@")" withString:@""];
    p = [p stringByReplacingOccurrencesOfString:@" " withString:@""];
    p = [p stringByReplacingOccurrencesOfString:@"-" withString:@""];
    p = [p stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
    int length = [p length];
    if(length == 10) {
        p = [NSString stringWithFormat:@"+1%@", p];
    } else if (length == 11) {
        p = [NSString stringWithFormat:@"+%@", p];
    }
    
    return p;
}

- (BOOL) checkNewAddresses:(NSString *)ab {
    NSString *saved = [self cachedAddresses];
    if (saved == nil || ![saved isEqualToString:ab]) {
        addressbook = ab;
        return YES;
    } else {
        return NO;
    }
    return YES;
}

- (NSString *) cachedAddresses {
    NSString *saved = nil;
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if (standardUserDefaults) {
        saved = [standardUserDefaults objectForKey:@"HOOKADDRESSBOOK"];
    }
    return saved;
}

- (void) readTelephonyInfo {
    _isoCountryCode = @"";
    _operatorCode = @"";
    
    // Setup the Network Info and create a CTCarrier object
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    
    // Get mobile country code
    NSString *mcc = [carrier mobileCountryCode];
    NSString *mnc = [carrier mobileNetworkCode];
    _isoCountryCode = [carrier isoCountryCode];
    
    if (mcc != nil && mnc != nil)
        _operatorCode = [NSString stringWithFormat:@"%@%@", mcc, mnc];
    
    NSLog(@"OperatorCode: %@", _operatorCode);
    
    if (_isoCountryCode == nil || [_isoCountryCode isEqualToString:@""]) {
        NSString *locale = [[NSLocale currentLocale] localeIdentifier];
        if (locale != nil) {
            NSArray *array = [locale componentsSeparatedByString:@"_"];
            if ([array count] == 2)
                _isoCountryCode = [array objectAtIndex:1];
        }
    }
    
    NSLog(@"iso Country code: %@", _isoCountryCode);
    
}

- (NSString *) getMacAddress {
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    NSString            *errorFlag = NULL;
    size_t              length;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    // Get the size of the data available (store in len)
    else if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
        errorFlag = @"sysctl mgmtInfoBase failure";
    // Alloc memory based on above call
    else if ((msgBuffer = (char *) malloc(length)) == NULL)
        errorFlag = @"buffer allocation failure";
    // Get system information, store in buffer
    else if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
    {
        free(msgBuffer);
        errorFlag = @"sysctl msgBuffer failure";
    }
    else
    {
        // Map msgbuffer to interface message structure
        struct if_msghdr *interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
        
        // Map to link-level socket structure
        struct sockaddr_dl *socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
        
        // Copy link layer address data in socket structure to an array
        unsigned char macAddress[6];
        memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
        
        // Read from char array into a string object, into traditional Mac address format
        NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                      macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5]];
        //NSLog(@"Mac Address: %@", macAddressString);
        
        // Release the buffer memory
        free(msgBuffer);
        
        return macAddressString;
    }
    
    // Error...
    NSLog(@"Error: %@", errorFlag);
    
    return errorFlag;
}

- (int) murmurHash:(NSString *)s {
    NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
    return MurmurHash2([d bytes], [d length], 0);
}

unsigned int MurmurHash2 ( const void * key, int len, unsigned int seed ) {
    // 'm' and 'r' are mixing constants generated offline.
    // They're not really 'magic', they just happen to work well.
    
    const unsigned int m = 0x5bd1e995;
    const int r = 24;
    
    // Initialize the hash to a 'random' value
    
    unsigned int h = seed ^ len;
    
    // Mix 4 bytes at a time into the hash
    
    const unsigned char * data = (const unsigned char *)key;
    
    while(len >= 4)
    {
        unsigned int k = *(unsigned int *)data;
        
        k *= m;
        k ^= k >> r;
        k *= m;
        
        h *= m;
        h ^= k;
        
        data += 4;
        len -= 4;
    }
    
    // Handle the last few bytes of the input array
    
    switch(len)
    {
        case 3: h ^= data[2] << 16;
        case 2: h ^= data[1] << 8;
        case 1: h ^= data[0];
            h *= m;
    };
    
    // Do a few final mixes of the hash to ensure the last few
    // bytes are well-incorporated.
    
    h ^= h >> 13;
    h *= m;
    h ^= h >> 15;
    
    return h;
}

- (NSString *)getDeviceInfoJson {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:16];
    [dic setObject:@"Apple" forKey:@"manufacturer"];
    [dic setObject:@"Apple" forKey:@"brand"];
    [dic setObject:[[UIDevice currentDevice] platformString] forKey:@"product"];
    [dic setObject:@"ios" forKey:@"os"];
    [dic setObject:[[UIDevice currentDevice] systemVersion] forKey:@"osVersion"];
    [dic setObject:[[UIDevice currentDevice] platform] forKey:@"model"];
    [dic setObject:[[UIDevice currentDevice] hwmodel] forKey:@"device"];
    
    // create json for phone and name based on phones
    NSError *error;
    NSData *aData = [NSJSONSerialization dataWithJSONObject:dic
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    NSString* jsonStr = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
    
    //NSLog(@"getDeviceInfoJson --> %@", jsonStr);
    
    return jsonStr;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    [viewController dismissModalViewControllerAnimated:YES];
    [UIApplication sharedApplication].statusBarHidden = fullScreen;
    if (fullScreen) {
        CGRect nFrame = viewController.view.frame;
        nFrame.size.height = nFrame.size.height + 20;
        nFrame.origin.y = nFrame.origin.y - 20;
        viewController.view.frame = nFrame;
    }
    
    if (result == MessageComposeResultCancelled) {
        if (forceVerificationSms) {
            // the SMS stays. No cancel
            UIAlertView* alert = [[UIAlertView alloc] init];
            alert.title = @"Confirmation";
            alert.message = @"You can only proceed after you send the confirmation SMS";
            [alert addButtonWithTitle:@"Okay"];
            // alert.cancelButtonIndex = 0;
            alert.delegate = self;
            [alert show];
        } else {
            NSLog(@"messageComposeViewController: post notification %@", NOTIF_HOOK_VERIFICATION_SMS_NOT_SENT);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_VERIFICATION_SMS_NOT_SENT object:nil];
        }
        
    } else {
        NSLog(@"messageComposeViewController: post notification %@", NOTIF_HOOK_VERIFICATION_SMS_SENT);
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_VERIFICATION_SMS_SENT object:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self createVerificationSms];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog (@"Received response");
    if (connection == verifyDeviceConnection) {
        [verifyDeviceData setLength:0];
    } else if (connection == verificationConnection) {
        [verificationData setLength:0];
    } else if (connection == discoverConnection) {
        [discoverData setLength:0];
    } else if (connection == queryOrderConnection) {
        [queryOrderData setLength:0];
    } else if (connection == shareTemplateConnection) {
        [shareTemplateData setLength:0];
    } else if (connection == newReferralConnection) {
        [newReferralData setLength:0];
    } else if (connection == updateReferralConnection) {
        [updateReferralData setLength:0];
    } else if (connection == queryInstallsConnection) {
        [queryInstallsData setLength:0];
    } else if (connection == queryReferralConnection) {
        [queryReferralData setLength:0];
    } else if (connection == newInstallConnection) {
        [newInstallData setLength:0];
    } else if (connection == claimRewardConnection) {
        [claimRewardData setLength:0];
    } else if (connection == trackEventConnection) {
        [trackEventData setLength:0];
    } else if (connection == queryPhoneNumberTypeConnection) {
        [queryPhoneNumberTypeData setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (connection == verifyDeviceConnection) {
        [verifyDeviceData appendData:data];
    } else if (connection == verificationConnection) {
        [verificationData appendData:data];
    } else if (connection == discoverConnection) {
        [discoverData appendData:data];
    } else if (connection == queryOrderConnection) {
        [queryOrderData appendData:data];
    } else if (connection == shareTemplateConnection) {
        [shareTemplateData appendData:data];
    } else if (connection == newReferralConnection) {
        [newReferralData appendData:data];
    } else if (connection == updateReferralConnection) {
        [updateReferralData appendData:data];
    } else if (connection == queryInstallsConnection) {
        [queryInstallsData appendData:data];
    } else if (connection == queryReferralConnection) {
        [queryReferralData appendData:data];
    } else if (connection == newInstallConnection) {
        [newInstallData appendData:data];
    } else if (connection == claimRewardConnection) {
        [claimRewardData appendData:data];
    } else if (connection == trackEventConnection) {
        [trackEventData appendData:data];
    } else if (connection == queryPhoneNumberTypeConnection) {
        [queryPhoneNumberTypeData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog (@"Received error with code %d", error.code);
    if (connection == verifyDeviceConnection) {
        verifyDeviceConnection = nil;
    } else if (connection == verificationConnection) {
        verificationConnection = nil;
    } else if (connection == discoverConnection) {
        discoverConnection = nil;
    } else if (connection == queryOrderConnection) {
        queryOrderConnection = nil;
    } else if (connection == shareTemplateConnection) {
        shareTemplateConnection = nil;
    } else if (connection == newReferralConnection) {
        newReferralConnection = nil;
    } else if (connection == updateReferralConnection) {
        updateReferralConnection = nil;
    } else if (connection == queryInstallsConnection) {
        queryInstallsConnection = nil;
    } else if (connection == queryReferralConnection) {
        queryReferralConnection = nil;
    } else if (connection == newInstallConnection) {
        newInstallConnection = nil;
    } else if (connection == claimRewardConnection) {
        claimRewardConnection = nil;
    } else if (connection == trackEventConnection) {
        trackEventConnection = nil;
    } else if (connection == queryPhoneNumberTypeConnection) {
        queryPhoneNumberTypeConnection = nil;
    }
    NSLog(@"connection:didFailwithError: post notification %@", NOTIF_HOOK_NETWORK_ERROR);
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_NETWORK_ERROR object:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog (@"Finished loading data");
    
    if (connection == verifyDeviceConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:verifyDeviceData encoding:NSUTF8StringEncoding];
        NSLog (@"verifyDevice data is %@", dataStr);
        
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[dataStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            if (standardUserDefaults) {
                //                installCode = [[resp objectForKey:@"installCode"] retain];
                self.installCode = [resp objectForKey:@"installCode"];
                [standardUserDefaults setObject:self.installCode forKey:@"installCode"];
                [standardUserDefaults synchronize];
            }
            verifyMessage = [resp objectForKey:@"verifyMessage"];
        }
        
        NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_VERIFY_DEVICE_COMPLETE);
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_VERIFY_DEVICE_COMPLETE object:[resp objectForKey:@"status"]];
        
        [self createVerificationSms];
        
        verifyDeviceConnection = nil;
    } else if (connection == verificationConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:verificationData encoding:NSUTF8StringEncoding];
        NSLog (@"verification data is %@", dataStr);
        
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[dataStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSString *verified = [resp objectForKey:@"verified"];
            if ([verified isEqualToString:@"true"]) {
                NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_DEVICE_VERIFIED);
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_DEVICE_VERIFIED object:nil];
            } else {
                NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_DEVICE_NOT_VERIFIED);
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_DEVICE_NOT_VERIFIED object:nil];
            }
        }
        
        verificationConnection = nil;
    } else if (connection == discoverConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:discoverData encoding:NSUTF8StringEncoding];
        NSLog (@"discover data is %@", dataStr);
        
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[dataStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            NSDate *now = [NSDate date];
            if (standardUserDefaults) {
                //                installCode = [[resp objectForKey:@"installCode"] retain];
                self.installCode = [resp objectForKey:@"installCode"];
                [standardUserDefaults setObject:self.installCode forKey:@"installCode"];
                
                // save the addressbook cache upon success
                [standardUserDefaults setObject:addressbook forKey:@"HOOKADDRESSBOOK"];
                
                // save last discover date
                [standardUserDefaults setObject:now forKey:@"lastDiscoverDate"];
                
                [standardUserDefaults synchronize];
            }
            
            //NSLog(@"installCode is %@", self.installCode);
            
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_DISCOVER_COMPLETE);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_DISCOVER_COMPLETE object:nil];
            
            // update lastDiscoverDate to current date
            lastDiscoverDate = now;
        } else {
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_DISCOVER_FAILED);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_DISCOVER_FAILED object:nil];
        }
        
        discoverConnection = nil;
    } else if (connection == queryOrderConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:queryOrderData encoding:NSUTF8StringEncoding];
        //NSLog (@"query order data is %@", dataStr);
        
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[dataStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        int status = [[resp objectForKey:@"status"] intValue];
        if (status == 1000) {
            self.queryStatus = YES;
        } else {
            self.queryStatus = NO;
            if (status == 3502) {
                NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_ADDRESSBOOK_CACHE_EXPIRED);
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_ADDRESSBOOK_CACHE_EXPIRED object:nil];
                return;
            }
        }
        if (status == 1000 || status == 1500) {
            if (self.leads == nil)
                self.leads = [NSMutableArray arrayWithCapacity:16];
            else
                [self.leads removeAllObjects];
            
            self.contactsLoaded = false;
            NSArray *ls = [resp objectForKey:@"leads"];
            NSLog (@"Server returned %d suggested contacts", [ls count]);
            
            if (ls != nil && [ls count] > 0) {
                for (NSDictionary *d in ls) {
                    HKMLead *lead = [[HKMLead alloc] init];
                    lead.phone = [d objectForKey:@"phone"];
                    lead.osType = [d objectForKey:@"osType"];
                    lead.invitationCount = [[resp objectForKey:@"invitationCount"] intValue];
                    //                    lead.name = [[HKMDiscoverer agent] lookupNameFromPhone:lead.phone];
                    //                    lead.name = [[HKMDiscoverer agent] lookupNameFromContactDictionary:lead.phone];
                    //[[HKMDiscoverer agent] updateContactDetails:lead];
                    NSString *dateStr = [d objectForKey:@"lastInvitationSent"];
                    if (dateStr == nil || [@"" isEqualToString:dateStr]) {
                    } else {
                        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss.S"];
                        lead.lastInvitationSent = [dateFormat dateFromString:dateStr];
                    }
                    
                    [self.leads addObject:lead];
                }
                [[HKMDiscoverer agent] updateLeadFromAddressbook];
                
            }
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_QUERY_ORDER_COMPLETE);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_QUERY_ORDER_COMPLETE object:nil];
        } else {
            NSLog (@"query order data is %@", dataStr);
            
            self.errorMessage = [resp objectForKey:@"desc"];
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_QUERY_ORDER_FAILED);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_QUERY_ORDER_FAILED object:nil];
        }
        /*
         else if ([[resp objectForKey:@"status"] intValue] == 1234) {
         // pending. Let's run this again after some delay
         // [self performSelector:@selector(queryOrder) withObject:nil afterDelay:10.0];
         [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(queryOrder) userInfo:nil repeats:NO];
         }
         */
        
        queryOrderConnection = nil;
    } else if (connection == newReferralConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:newReferralData encoding:NSUTF8StringEncoding];
        NSLog (@"new referral data is %@", dataStr);
        
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[dataStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            referralId = [[resp objectForKey:@"referralId"] intValue];
            self.referralMessage = [resp objectForKey:@"referralMessage"];
            invitationUrl = [resp objectForKey:@"url"];
        }
        
        NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_NEW_REFERRAL_COMPLETE);
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_NEW_REFERRAL_COMPLETE object:nil];
        
        newReferralConnection = nil;
    } else if (connection == updateReferralConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:updateReferralData encoding:NSUTF8StringEncoding];
        NSLog (@"update referral data is %@", dataStr);
        
        NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_UPDATE_REFERRAL_COMPLETE);
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_UPDATE_REFERRAL_COMPLETE object:nil];
        
        updateReferralConnection = nil;
    } else if (connection == queryInstallsConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:queryInstallsData encoding:NSUTF8StringEncoding];
        NSLog (@"query installs data is %@", dataStr);
        
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[dataStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        int status = [[resp objectForKey:@"status"] intValue];
        if (status == 1000) {
            self.installs = [NSMutableArray arrayWithCapacity:16];
            NSArray *ls = [resp objectForKey:@"leads"];
            if (ls != nil && [ls count] > 0) {
                for (NSString *p in ls) {
                    HKMLead *lead = [[HKMLead alloc] init];
                    lead.phone = p;
                    lead.name = [[HKMDiscoverer agent] lookupNameFromPhone:lead.phone];
                    [[self installs] addObject:lead];
                }
            }
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_QUERY_INSTALLS_COMPLETE);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_QUERY_INSTALLS_COMPLETE object:nil];
        } else {
            if (status == 3502) {
                NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_ADDRESSBOOK_CACHE_EXPIRED);
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_ADDRESSBOOK_CACHE_EXPIRED object:nil];
                return;
            }
            self.errorMessage = [resp objectForKey:@"desc"];
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_QUERY_INSTALLS_FAILED);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_QUERY_INSTALLS_FAILED object:nil];
        }
        
        queryInstallsConnection = nil;
    } else if (connection == queryReferralConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:queryReferralData encoding:NSUTF8StringEncoding];
        NSLog (@"query referral data is %@", dataStr);
        
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[dataStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        int status = [[resp objectForKey:@"status"] intValue];
        if (status == 1000) {
            self.referrals = [NSMutableArray arrayWithCapacity:16];
            NSArray *ls = [resp objectForKey:@"referrals"];
            if (ls != nil && [ls count] > 0) {
                for (NSDictionary *d in ls) {
                    HKMReferralRecord *rec = [[HKMReferralRecord alloc] init];
                    rec.totalClickThrough = [[d objectForKey:@"totalClickThrough"] intValue];
                    rec.totalInvitee = [[d objectForKey:@"totalInvitee"] intValue];
                    NSString *dateStr = [d objectForKey:@"date"];
                    if (dateStr == nil || [@"" isEqualToString:dateStr]) {
                    } else {
                        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss.S"];
                        rec.invitationDate = [dateFormat dateFromString:dateStr];
                    }
                    [[self referrals] addObject:rec];
                }
            }
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_QUERY_REFERRAL_COMPLETE);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_QUERY_REFERRAL_COMPLETE object:nil];
        } else {
            self.errorMessage = [resp objectForKey:@"desc"];
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_QUERY_REFERRAL_FAILED);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_QUERY_REFERRAL_FAILED object:nil];
        }
        
        queryReferralConnection = nil;
    } else if (connection == newInstallConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:newInstallData encoding:NSUTF8StringEncoding];
        NSLog (@"newInstall data is %@", dataStr);
        
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[dataStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            if (standardUserDefaults) {
                self.installCode = [resp objectForKey:@"installCode"];
                //                installCode = [[resp objectForKey:@"installCode"] retain];
                [standardUserDefaults setObject:self.installCode forKey:@"installCode"];
                [standardUserDefaults setObject:self.customParam forKey:@"customParam"];
                [standardUserDefaults synchronize];
            }
        }
        newInstallConnection = nil;
    } else if (connection == claimRewardConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:claimRewardData encoding:NSUTF8StringEncoding];
        NSLog (@"claimReward data is %@", dataStr);
        
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[dataStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if ([[resp objectForKey:@"status"] intValue] == 1600) {
            verifyMessage = [resp objectForKey:@"verifyMessage"];
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_CLAIM_REWARD_PENDING_SMS_VERIFICATION);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_CLAIM_REWARD_PENDING_SMS_VERIFICATION object:[resp objectForKey:@"status"]];
            [self createVerificationSms];
        } else if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_CLAIM_REWARD_COMPLETE);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_CLAIM_REWARD_COMPLETE object:[resp objectForKey:@"status"]];
        }
        
        claimRewardConnection = nil;
    } else if (connection == trackEventConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:trackEventData encoding:NSUTF8StringEncoding];
        NSLog (@"trackEvent data is %@", dataStr);
        trackEventConnection = nil;
    } else if (connection == queryPhoneNumberTypeConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:queryPhoneNumberTypeData encoding:NSUTF8StringEncoding];
        NSLog (@"query phone number type data is %@", dataStr);
        
        HKMSBJSON *jsonReader = [HKMSBJSON new];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        int status = [[resp objectForKey:@"status"] intValue];
        if (status == 1000) {
            if (self.phoneNumberTypes != nil) {
                [self.phoneNumberTypes removeAllObjects];
            }
            
            self.phoneNumberTypes = [resp objectForKey:@"phones"];
            
            if (self.phoneNumberTypes != nil && [self.phoneNumberTypes count] > 0 && self.queryPhoneNumberTypeListIndex != -1) {
                BOOL foundMobileNumber = false;
                HKMLead *lead = [[self leads] objectAtIndex:self.queryPhoneNumberTypeListIndex];
                for (NSDictionary *d in self.phoneNumberTypes) {
                    if ([@"mobile" isEqualToString:[d objectForKey:@"lineType"]]) {
                        lead.phone = [d objectForKey:@"phone"];
                        lead.selected = true;
                        foundMobileNumber = true;
                        break;
                    }
                }
                if (!foundMobileNumber) {
                    // prompt user that none of the phone numbers listed under chosen contact are mobile
                    NSLog (@"%@ has no mobile number", lead.name);
                }
            }
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_QUERY_PHONE_NUMBER_TYPE_COMPLETE);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_QUERY_PHONE_NUMBER_TYPE_COMPLETE object:nil];
        } else {
            self.errorMessage = [resp objectForKey:@"desc"];
            NSLog(@"connectionDidFinishLoading: post notification %@", NOTIF_HOOK_QUERY_PHONE_NUMBER_TYPE_FAILED);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_HOOK_QUERY_PHONE_NUMBER_TYPE_FAILED object:nil];
        }
        queryPhoneNumberTypeConnection = nil;
    }
    
}

// grab device owner name
+ (NSArray*) newNamesFromDeviceName: (NSString *) deviceName {
    NSCharacterSet* characterSet = [NSCharacterSet characterSetWithCharactersInString:@" '’\\"];
    NSArray* words = [deviceName componentsSeparatedByCharactersInSet:characterSet];
    NSMutableArray* names = [[NSMutableArray alloc] init];
    
    bool foundShortWord = false;
    for (NSString *word in words) {
        if ([word length] <= 2)
            foundShortWord = true;
        if ([word compare:@"iPhone" options:NSCaseInsensitiveSearch] != 0 && [word compare:@"iPod" options:NSCaseInsensitiveSearch] != 0 && [word compare:@"iPad" options:NSCaseInsensitiveSearch] != 0 && [word length] > 2) {
            NSString *newWord = [word stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[word substringToIndex:1] uppercaseString]];
            [names addObject:newWord];
        }
    }
    if (!foundShortWord && [names count] > 1) {
        int lastNameIndex = [names count] - 1;
        NSString* name = [names objectAtIndex:lastNameIndex];
        unichar lastChar = [name characterAtIndex:[name length] - 1];
        if (lastChar == 's') {
            [names replaceObjectAtIndex:lastNameIndex withObject:[name substringToIndex:[name length] - 1]];
        }
    }
    return names;
}

// return whether if device can compose and send native SMS
+ (BOOL) deviceSmsSupport {
    return [MFMessageComposeViewController canSendText];
}

// return device owner name
+ (NSString *) deviceOwnerName {
    if (_deviceOwnerName == nil) {
        // Add default values for first name and last name
        _deviceOwnerName = [NSString stringWithString:[[UIDevice currentDevice] name]];
        NSArray* names = [HKMDiscoverer newNamesFromDeviceName:_deviceOwnerName];
        if (names != nil && [names count] > 0)
            _deviceOwnerName = [names objectAtIndex:0];
        if (_deviceOwnerName == nil)
            _deviceOwnerName = @"";
    }
    //NSLog(@"device owner name is %@", _deviceOwnerName);
    return _deviceOwnerName;
}

+ (void) activate:(NSString *)ak {
    if (_agent == nil) {
        _agent = [[HKMDiscoverer alloc] init];
        _agent.server = AGE_SERVER;
        _agent.SMSDest = DEFAULT_VIRTUAL_NUMBER;
        _agent.appKey = ak;
        [_agent newInstall];
    }
}

+ (void) activateKey:(NSString *)ak customParam:(NSString *) customParam {
    if (_agent == nil) {
        _agent = [[HKMDiscoverer alloc] init];
        _agent.server = AGE_SERVER;
        _agent.SMSDest = DEFAULT_VIRTUAL_NUMBER;
        _agent.appKey = ak;
        _agent.customParam = customParam;
        [_agent newInstall];
    }
}

+ (void) retire {
    _agent = nil;
}

+ (HKMDiscoverer *) agent {
    if (_agent == nil) {
        [NSException raise:@"InstanceNotExists"
                    format:@"Attempted to access instance before initializaion. Please call activate: first."];
    }
    return _agent;
}


@end