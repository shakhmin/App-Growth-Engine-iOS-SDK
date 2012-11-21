#import "HKMLead.h"

@implementation HKMLead

@synthesize phone=_phone, osType=_osType, name=_name, invitationCount=_invitationCount, lastInvitationSent=_lastInvitationSent, image=_image;
@synthesize selected;

- (id) init {
	return self;
}

- (void) dealloc {
    self.phone = nil;
    self.osType = nil;
    self.name = nil;
    self.lastInvitationSent = nil;
    self.image = nil;
    [super dealloc];
}

@end