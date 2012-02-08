#import "LeadsController.h"
#import "Discoverer.h"
#import "Lead.h"

#define BARBUTTON(TITLE, STYLE, SELECTOR) [[[UIBarButtonItem alloc] initWithTitle:TITLE style:STYLE target:self action:SELECTOR] autorelease]

@implementation LeadsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
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
    if ([Discoverer agent].leads != nil) {
        return [[Discoverer agent].leads count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Leads"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Leads"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    Lead *lead = (Lead *)[[Discoverer agent].leads objectAtIndex:indexPath.row];
    cell.textLabel.text = lead.phone;
    cell.detailTextLabel.text = lead.osType;
    if (lead.selected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Lead *lead = [[Discoverer agent].leads objectAtIndex:indexPath.row];
    if (lead.selected) {
        lead.selected = NO;
    } else {
        lead.selected = YES;
    }
    [entriesView reloadData];
}

- (IBAction) refer: (id) sender {
    phones = [[NSMutableArray arrayWithCapacity:16] retain];
    for (Lead *lead in [Discoverer agent].leads) {
        if (lead.selected) {
            [phones addObject:lead.phone];
        }
    }
    if ([phones count] > 0) {
        self.navigationItem.rightBarButtonItem.title = @"Wait ...";
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        [[Discoverer agent] newReferral:phones withMessage:@"I thought you might be interested in this app 'AGE SDK', check it out here %link% "];
    } else {
        UIAlertView* alert = [[UIAlertView alloc] init];
        alert.title = @"Please select referral contacts";
        alert.message = @"Please select a few contacts you would like to refer.";
        [alert addButtonWithTitle:@"Dismiss"];
        alert.cancelButtonIndex = 0;
        [alert show];
        [alert release];
    }
}


- (void) showReferralMessage {
    self.navigationItem.rightBarButtonItem.title = @"Referral";
    self.navigationItem.rightBarButtonItem.enabled = YES;

    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *controller = [[[MFMessageComposeViewController alloc] init] autorelease];
        controller.body = [Discoverer agent].referralMessage;
        controller.recipients = phones;
        controller.messageComposeDelegate = self;
        [self presentModalViewController:controller animated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    [self dismissModalViewControllerAnimated:YES];
    
    if (result == MessageComposeResultCancelled) {
        [[Discoverer agent] updateReferral:NO];
    } else {
        [[Discoverer agent] updateReferral:YES];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Leads";
    self.navigationItem.rightBarButtonItem = BARBUTTON (@"Referral", UIBarButtonItemStyleDone, @selector(refer:));
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showReferralMessage) name:@"HookNewReferralComplete" object:nil];
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
