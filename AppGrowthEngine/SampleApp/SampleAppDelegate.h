#import <UIKit/UIKit.h>

@class SampleViewController;

@interface SampleAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SampleViewController *viewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet SampleViewController *viewController;

@end
