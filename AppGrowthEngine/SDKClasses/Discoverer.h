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
    NSMutableArray *leads;
    
    
    NSMutableData *discoverData;
    NSURLConnection *discoverConnection;
    
    NSMutableData *queryOrderData;
    NSURLConnection *queryOrderConnection;
    
    NSMutableData *verifyDeviceData;
    NSURLConnection *verifyDeviceConnection;
    UIViewController *viewController;
    
    NSMutableData *verificationData;
    NSURLConnection *verificationConnection;
}

@property (nonatomic, retain) NSString *server;
@property (nonatomic, retain) NSString *SMSDest;
@property (nonatomic, retain) NSString *appSecret;
// @property (nonatomic) BOOL runQueryAfterOrder;
@property (nonatomic) BOOL queryStatus;
@property (nonatomic, retain) NSMutableArray *leads;

+ (Discoverer *) agent;
+ (void) activate:(NSString *)secret;
+ (void) retire;

- (BOOL) verifyDevice:(UIViewController *)vc;
- (BOOL) queryVerifiedStatus;
- (BOOL) discover;
- (BOOL) queryOrder;

- (NSString *) getAddressbook;

@end