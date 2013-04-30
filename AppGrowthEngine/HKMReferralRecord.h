#import <Foundation/Foundation.h>


@interface HKMReferralRecord : NSObject {
    
    int totalClickThrough;
    int totalInvitee;
    NSDate *invitationDate;
    
}

@property (nonatomic) int totalClickThrough;
@property (nonatomic) int totalInvitee;
@property (nonatomic, strong) NSDate *invitationDate;

- (id) init;

@end
