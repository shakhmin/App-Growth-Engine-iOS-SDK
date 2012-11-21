#import <Foundation/Foundation.h>

@interface HKMLead : NSObject {
	
	NSString *_phone;
	NSString *_osType;
    NSString *_name;
    UIImage *_image;
    
    int _invitationCount;
    NSDate *_lastInvitationSent;
    
    BOOL _selected;
    
}

@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *osType;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic) int invitationCount;
@property (nonatomic, retain) NSDate *lastInvitationSent;

@property (nonatomic) BOOL selected;

- (id) init;
- (void) dealloc;
@end;