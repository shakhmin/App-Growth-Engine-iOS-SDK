#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface LeadsController : UIViewController <UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate> {
    
    IBOutlet UITableView *entriesView;
    
    NSMutableArray *phones;
}

- (IBAction) refer: (id) sender;

- (void) showReferralMessage;

@end
