#import <Foundation/Foundation.h>

@interface Lead : NSObject {
	
	NSString *phone;
	NSString *osType;

}

@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *osType;

- (id) init;

@end;