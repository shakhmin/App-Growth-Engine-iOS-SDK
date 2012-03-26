#import <UIKit/UIKit.h>

@interface RecommendsController : UIViewController <UITableViewDataSource, UITableViewDelegate,UIActionSheetDelegate> {
    
	IBOutlet UITableView *entriesView;
    NSArray *recommends;
    NSMutableArray *phones;
    
    BOOL sendNow;
}

@property (nonatomic,retain) UITableView *entriesView;
- (IBAction) refer: (id) sender;

-(void)initRecommends;

- (void) showReferralMessage;
- (void) sendReferral;

-(void)addLoadingView;
-(void)removeLoadingView;
@end
