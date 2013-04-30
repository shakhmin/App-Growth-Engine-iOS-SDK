#import "HKMLead.h"

@implementation HKMLead

NSString *_phone;
NSString *_osType;
NSString *_name;
UIImage *_image;
int _addressbookIndex;
ABRecordID _recordId;

int _invitationCount;
NSDate *_lastInvitationSent;

BOOL _selected;

@synthesize phone=_phone, osType=_osType, name=_name, invitationCount=_invitationCount, lastInvitationSent=_lastInvitationSent, image=_image;
@synthesize selected=_selected, addressbookIndex=_addressbookIndex, recordId=_recordId;

- (id) init {
	return self;
}


@end