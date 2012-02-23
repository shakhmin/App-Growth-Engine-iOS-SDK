#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface LeadsController : UIViewController <UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate> {
    
    IBOutlet UITableView *entriesView;
    
    NSMutableArray *phones;
    
    BOOL sendNow;
}

- (IBAction) refer: (id) sender;

- (void) showReferralMessage;
- (void) sendReferral;

@end
