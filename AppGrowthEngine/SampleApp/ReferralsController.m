#import "ReferralsController.h"
#import "HKMReferralRecord.h"
#import "HKMDiscoverer.h"

@implementation ReferralsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([HKMDiscoverer agent].referrals != nil) {
        return [[HKMDiscoverer agent].referrals count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Referrals"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Referrals"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    HKMReferralRecord *rec = (HKMReferralRecord *)[[HKMDiscoverer agent].referrals objectAtIndex:indexPath.row];
    
    NSLog (@"Invite date %@", [rec.invitationDate description]);
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm"];
    cell.textLabel.text = [dateFormat stringFromDate:rec.invitationDate];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d invited %d clicked", rec.totalInvitee, rec.totalClickThrough];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // nothing
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Referrals";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [entriesView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
