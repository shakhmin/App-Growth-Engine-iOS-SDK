#import <UIKit/UIKit.h>


@interface LeadsController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    
    IBOutlet UITableView *entriesView;
    
}

@end
