#import <UIKit/UIKit.h>

@interface SampleViewController : UIViewController {
    
    IBOutlet UIButton *discoverButton;
    IBOutlet UIButton *queryButton;
    IBOutlet UIButton *verifyButton;
    IBOutlet UIButton *verifyStatusButton;
    
    IBOutlet UIViewController *leadsController;
    
}

- (IBAction) discover: (id)sender;
- (IBAction) query: (id)sender;
- (IBAction) verify: (id)sender;
- (IBAction) verifyStatus: (id)sender;

@end
