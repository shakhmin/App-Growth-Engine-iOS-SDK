#import <UIKit/UIKit.h>


@interface InstallsController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    
    IBOutlet UITableView *entriesView;
    
    NSMutableArray *phones;
}

@end
