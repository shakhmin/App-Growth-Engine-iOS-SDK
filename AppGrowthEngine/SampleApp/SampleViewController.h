#import <UIKit/UIKit.h>

@interface SampleViewController : UIViewController <UIActionSheetDelegate> {
    
    IBOutlet UIButton *discoverButton;
    IBOutlet UIButton *queryButton;
    IBOutlet UIButton *verifyButton;
    IBOutlet UIButton *verifyStatusButton;
    IBOutlet UIButton *queryInstallsButton;
    IBOutlet UIButton *queryReferralButton;
    
    IBOutlet UIViewController *leadsController;
    IBOutlet UIViewController *installsController;
    IBOutlet UIViewController *referralsController;
}

- (IBAction) discover: (id)sender;
- (IBAction) query: (id)sender;
- (IBAction) verify: (id)sender;
- (IBAction) verifyStatus: (id)sender;
- (IBAction) queryInstalls: (id)sender;
- (IBAction) queryReferral: (id)sender;

@end
