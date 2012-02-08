#import "SampleViewController.h"
#import "Discoverer.h"

@implementation SampleViewController

- (void)dealloc {
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction) verify: (id)sender {
    verifyButton.enabled = NO;
    [[Discoverer agent] verifyDevice:self forceSms:NO userName:nil];
}

- (void) verifyComplete {
    verifyButton.enabled = YES;
    verifyStatusButton.enabled = YES;
}

- (IBAction) verifyStatus: (id)sender {
    verifyStatusButton.enabled = NO;
    [[Discoverer agent] queryVerifiedStatus];
}

- (void) verificationStatusYes {
    verifyStatusButton.enabled = YES;
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Verified";
	alert.message = @"Your device has been verified.";
	[alert addButtonWithTitle:@"Dismiss"];
    alert.cancelButtonIndex = 0;
    [alert show];
	[alert release];
}

- (void) verificationStatusNo {
    verifyStatusButton.enabled = YES;
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Verified";
	alert.message = @"Your device has NOT been verified. It might take a few minutes for us to receive and process the verification SMS.";
	[alert addButtonWithTitle:@"Dismiss"];
    alert.cancelButtonIndex = 0;
    [alert show];
	[alert release];
}

- (IBAction) discover: (id)sender {
    discoverButton.enabled = NO;
    [[Discoverer agent] discover];
}

- (void) discoverComplete {
    discoverButton.enabled = YES;
    queryButton.enabled = YES;
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Finished";
	alert.message = @"Discover order successfully submitted. Please wait a few minutes to query the recommednations from the API.";
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
	[alert release];
}

- (IBAction) query: (id)sender {
    queryButton.enabled = NO;
    [[Discoverer agent] queryOrder];
}

- (void) queryComplete {
    queryButton.enabled = YES;
    
    [self.navigationController pushViewController:leadsController animated:YES];
}

- (void) queryFailed {
    queryButton.enabled = YES;
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Finished";
	alert.message = @"Hook Mobile server encountered a problem processing your addressbook.";
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
	[alert release];
}

/*
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[[Discoverer agent] queryOrder];
        // NSLog(@"Number of Leads is %d", [[Discoverer agent].leads count]);
	}
}
*/


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Hook SDK Sample";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoverComplete) name:@"HookDiscoverComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryComplete) name:@"HookQueryOrderComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryFailed) name:@"HookQueryOrderFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verifyComplete) name:@"HookVerifyDeviceComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verificationStatusYes) name:@"HookDeviceVerified" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verificationStatusNo) name:@"HookDeviceNotVerified" object:nil];
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
