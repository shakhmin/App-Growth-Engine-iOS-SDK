#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface HKMLead : NSObject
@property (strong, nonatomic) NSString *phone;
@property (strong, nonatomic) NSString *osType;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) UIImage *image;
@property (nonatomic) int addressbookIndex;
@property (nonatomic) int invitationCount;
@property (nonatomic) ABRecordID recordId;
@property (unsafe_unretained, nonatomic) NSDate *lastInvitationSent;

@property (nonatomic) BOOL selected;

- (id) init;
@end;