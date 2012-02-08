#import <Foundation/Foundation.h>

@interface Lead : NSObject {
	
	NSString *phone;
	NSString *osType;
    
    int invitationCount;
    NSDate *lastInvitationSent;
    
    BOOL selected;

}

@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *osType;
@property (nonatomic) int invitationCount;
@property (nonatomic, retain) NSDate *lastInvitationSent;

@property (nonatomic) BOOL selected;

- (id) init;

@end;