#import "LeadsController.h"
#import "HKMDiscoverer.h"
#import "HKMLead.h"

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
    if ([HKMDiscoverer agent].leads != nil) {
        return [[HKMDiscoverer agent].leads count];
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
    
    HKMLead *lead = (HKMLead *)[[HKMDiscoverer agent].leads objectAtIndex:indexPath.row];
    cell.textLabel.text = lead.name;
    cell.detailTextLabel.text = lead.osType;
    if (lead.selected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HKMLead *lead = [[HKMDiscoverer agent].leads objectAtIndex:indexPath.row];
    if (lead.selected) {
        lead.selected = NO;
    } else {
        lead.selected = YES;
    }
    [entriesView reloadData];
}

- (IBAction) refer: (id) sender {
    if ([MFMessageComposeViewController canSendText]) {
        UIActionSheet* actionSheet = [[UIActionSheet alloc] init];
        actionSheet.title = @"Send the referral from";
        actionSheet.delegate = self;
        [actionSheet addButtonWithTitle:@"HookMobile virtual number"];
        [actionSheet addButtonWithTitle:@"The user's phone"];
        [actionSheet addButtonWithTitle:@"Cancel"];
        actionSheet.cancelButtonIndex = 2;
        [actionSheet showInView:self.view];
        [actionSheet release];
        
    } else {
        sendNow = YES;
        [self sendReferral];
    }
}

- (void) sendReferral {
    phones = [[NSMutableArray arrayWithCapacity:16] retain];
    for (HKMLead *lead in [HKMDiscoverer agent].leads) {
        if (lead.selected) {
            [phones addObject:lead.phone];
        }
    }
    if ([phones count] > 0) {
        self.navigationItem.rightBarButtonItem.title = @"Wait ...";
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        [[HKMDiscoverer agent] newReferral:phones withName:nil useVirtualNumber:sendNow];
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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        sendNow = YES;
        [self sendReferral];
    }
    if (buttonIndex == 1) {
        sendNow = NO;
        [self sendReferral];
    }
    if (buttonIndex == 2) {
        // Cancel
    }
    
    return;
}


- (void) showReferralMessage {
    self.navigationItem.rightBarButtonItem.title = @"Referral";
    self.navigationItem.rightBarButtonItem.enabled = YES;

    if (!sendNow && [MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *controller = [[[MFMessageComposeViewController alloc] init] autorelease];
        controller.body = [HKMDiscoverer agent].referralMessage;
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
        [[HKMDiscoverer agent] updateReferral:NO];
    } else {
        [[HKMDiscoverer agent] updateReferral:YES];
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
