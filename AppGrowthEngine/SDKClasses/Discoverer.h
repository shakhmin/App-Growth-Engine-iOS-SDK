#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface Discoverer : NSObject <MFMessageComposeViewControllerDelegate> {
    
    NSString *server;
    NSString *SMSDest;
    
    NSString *appSecret;
    // BOOL runQueryAfterOrder;
    
    // NSString *cudid;
    NSString *installCode;
    
    int orderid;
    
    BOOL queryStatus;
    
    NSMutableData *discoverData;
    NSURLConnection *discoverConnection;
    
    NSMutableData *queryOrderData;
    NSURLConnection *queryOrderConnection;
    NSMutableArray *leads;
    
    NSMutableData *verifyDeviceData;
    NSURLConnection *verifyDeviceConnection;
    UIViewController *viewController;
    BOOL forceVerificationSms;
    NSString *verifyMessage;
    
    NSMutableData *verificationData;
    NSURLConnection *verificationConnection;
    
    NSMutableData *shareTemplateData;
    NSURLConnection *shareTemplateConnection;
    NSString *fbTemplate;
    NSString *emailTemplate;
    NSString *smsTemplate;
    NSString *twitterTemplate;
    
    NSMutableData *newReferralData;
    NSURLConnection *newReferralConnection;
    int referralId;
    NSString *referralMessage;
    NSString *invitationUrl;
    
    NSMutableData *updateReferralData;
    NSURLConnection *updateReferralConnection;
}

@property (nonatomic, retain) NSString *server;
@property (nonatomic, retain) NSString *SMSDest;
@property (nonatomic, retain) NSString *appSecret;
// @property (nonatomic) BOOL runQueryAfterOrder;
@property (nonatomic) BOOL queryStatus;
@property (nonatomic, retain) NSMutableArray *leads;

@property (nonatomic, retain) NSString *fbTemplate;
@property (nonatomic, retain) NSString *emailTemplate;
@property (nonatomic, retain) NSString *smsTemplate;
@property (nonatomic, retain) NSString *twitterTemplate;

@property (nonatomic, retain) NSString *referralMessage;

+ (Discoverer *) agent;
+ (void) activate:(NSString *)secret;
+ (void) retire;

- (BOOL) isRegistered;
- (BOOL) verifyDevice:(UIViewController *)vc forceSms:(BOOL) force userName:(NSString *) userName;
- (BOOL) queryVerifiedStatus;
- (BOOL) discover;
- (BOOL) discoverWithoutVzw;
- (BOOL) discoverSelected:(NSMutableArray *)phones;
- (BOOL) queryOrder;
- (BOOL) downloadShareTemplates;
- (BOOL) newReferral:(NSMutableArray *)phones withMessage:(NSString *)message;
- (BOOL) updateReferral:(BOOL) sent;

- (NSString *) getAddressbook;
- (void) createVerificationSms;

@end