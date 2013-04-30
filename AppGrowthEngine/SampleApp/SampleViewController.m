#import "SampleViewController.h"
#import "HKMDiscoverer.h"
#import "HKMSVProgressHUD.h"
#import <AddressBook/AddressBook.h>

@implementation SampleViewController


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction) verify: (id)sender {
    // verifyButton.enabled = NO;
    [HKMSVProgressHUD showWithStatus:@"Verifying ..."];
    [[HKMDiscoverer agent] verifyDevice:self forceSms:NO userName:nil];
}

- (void) verifyComplete {
    // verifyButton.enabled = YES;
    verifyStatusButton.enabled = YES;
    queryInstallsButton.enabled = YES;
    
    [HKMSVProgressHUD dismiss];
}

- (IBAction) verifyStatus: (id)sender {
    // verifyStatusButton.enabled = NO;
    [HKMSVProgressHUD showWithStatus:@"Querying status ..."];
    [[HKMDiscoverer agent] queryVerifiedStatus];
}

- (void) verificationStatusYes {
    // verifyStatusButton.enabled = YES;
    [HKMSVProgressHUD dismiss];
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Verified";
	alert.message = @"Your device has been verified.";
	[alert addButtonWithTitle:@"Dismiss"];
    alert.cancelButtonIndex = 0;
    [alert show];
}

- (void) verificationStatusNo {
    // verifyStatusButton.enabled = YES;
    [HKMSVProgressHUD dismiss];
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Not Verified";
	alert.message = @"Your device has NOT been verified. It might take a few minutes for us to receive and process the verification SMS.";
	[alert addButtonWithTitle:@"Dismiss"];
    alert.cancelButtonIndex = 0;
    [alert show];
}

- (IBAction) discover: (id)sender {
    ABAddressBookRef ab = ABAddressBookCreate();
    if (ABAddressBookRequestAccessWithCompletion != NULL) {
        ABAddressBookRequestAccessWithCompletion(ab, ^(bool granted, CFErrorRef error) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [HKMSVProgressHUD showWithStatus:@"Discovering ..."];
                    [[HKMDiscoverer agent] discover:0];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView* alert = [[UIAlertView alloc] init];
                    alert.title = @"Not Authorized";
                    alert.message = @"You denied access to your addressbook. Please go to Settings / Privacy / Contacts and enable access for this app.";
                    [alert addButtonWithTitle:@"Dismiss"];
                    alert.cancelButtonIndex = 0;
                    [alert show];
                });
            }
        });
    } else {
        // iOS 5
        if ([[HKMDiscoverer agent] discover:0]) {
            [HKMSVProgressHUD showWithStatus:@"Discovering ..."];
        }
    }
}


- (void) discoverComplete {
    NSLog(@"discoverComplete");
    // discoverButton.enabled = YES;
    queryButton.enabled = YES;
    [HKMSVProgressHUD dismiss];
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Finished";
	alert.message = @"Discover order successfully submitted. Please wait a few minutes to query the recommendations from the API.";
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
}

- (void) discoverFailed {
    NSLog(@"discoverFailed");
    // discoverButton.enabled = YES;
    queryButton.enabled = NO;
    [HKMSVProgressHUD dismiss];
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Error";
	alert.message = @"Discover has failed. Do you have contacts in your address book?";
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
}

- (void) discoverNoChange {
    NSLog(@"discoverNoChange");
    // discoverButton.enabled = YES;
    queryButton.enabled = YES;
    [HKMSVProgressHUD dismiss];
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"No Change";
	alert.message = @"The addressbook has not changed since last discovery. You can still get the recommended contacts. Or, you can delete the app and start over.";
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
}

- (IBAction) query: (id)sender {
    // queryButton.enabled = NO;
    [HKMSVProgressHUD showWithStatus:@"Querying ..."];
    [[HKMDiscoverer agent] queryLeads];
}

- (void) queryComplete {
    // queryButton.enabled = YES;
    [HKMSVProgressHUD dismiss];
    
    self.title = @"Back";
    [self.navigationController pushViewController:leadsController animated:YES];
}

- (void) queryFailed {
    // queryButton.enabled = YES;
    [HKMSVProgressHUD dismiss];
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Finished";
	alert.message = [NSString stringWithFormat:@"Hook Mobile server encountered a problem processing your addressbook: %@", [HKMDiscoverer agent].errorMessage];
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
}

- (IBAction) queryInstalls: (id)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] init];
    actionSheet.title = @"Direction of query";
    actionSheet.delegate = self;
    [actionSheet addButtonWithTitle:@"Forward"];
    [actionSheet addButtonWithTitle:@"Backward"];
    [actionSheet addButtonWithTitle:@"Mutual"];
    [actionSheet addButtonWithTitle:@"Cancel"];
    actionSheet.cancelButtonIndex = 3;
    [actionSheet showInView:self.view];
}

- (void) queryInstallsComplete {
    // queryInstallsButton.enabled = YES;
    [HKMSVProgressHUD dismiss];
    
    [self.navigationController pushViewController:installsController animated:YES];
}

- (void) queryInstallsFailed {
    // queryInstallsButton.enabled = YES;
    [HKMSVProgressHUD dismiss];
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Finished";
    alert.message = [NSString stringWithFormat:@"Hook Mobile server encountered a problem processing the installs database: %@", [HKMDiscoverer agent].errorMessage];
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
}

- (IBAction) queryReferral: (id)sender {
    // queryReferralButton.enabled = NO;
    [HKMSVProgressHUD showWithStatus:@"Querying ..."];
    
    [[HKMDiscoverer agent] queryReferral];
}

- (void) queryReferralComplete {
    NSLog(@"referral done");
    // queryReferralButton.enabled = YES;
    [HKMSVProgressHUD dismiss];
    
    [self.navigationController pushViewController:referralsController animated:YES];
}

- (void) queryReferralFailed {
    // queryReferralButton.enabled = YES;
    [HKMSVProgressHUD dismiss];
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Finished";
	alert.message = [NSString stringWithFormat:@"Hook Mobile server encountered a problem processing the referrals database: %@", [HKMDiscoverer agent].errorMessage];
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
}

- (IBAction) trackEvent: (id)sender {
    // send track event message
    [[HKMDiscoverer agent] trackEventName:@"testEvent" Value:@"Hello"];
}

- (void) notSmsDevice {
    [HKMSVProgressHUD dismiss];
    
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Not a SMS Device";
	alert.message = @"You are running this application on a non-SMS device. The SMS verification functionalities would not work.";
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        [[HKMDiscoverer agent] queryInstalls:@"FORWARD"];
        // queryInstallsButton.enabled = NO;
        [HKMSVProgressHUD showWithStatus:@"Querying ..."];
    }
    if (buttonIndex == 1) {
        [[HKMDiscoverer agent] queryInstalls:@"BACKWARD"];
        // queryInstallsButton.enabled = NO;
        [HKMSVProgressHUD showWithStatus:@"Querying ..."];
    }
    if (buttonIndex == 2) {
        [[HKMDiscoverer agent] queryInstalls:@"MUTUAL"];
        // queryInstallsButton.enabled = NO;
        [HKMSVProgressHUD showWithStatus:@"Querying ..."];
    }
    
    return;
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoverComplete) name:@"HookDiscoverComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoverFailed) name:@"HookDiscoverFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoverNoChange) name:@"HookDiscoverNoChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryComplete) name:@"HookQueryOrderComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryFailed) name:@"HookQueryOrderFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verifyComplete) name:@"HookVerifyDeviceComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verificationStatusYes) name:@"HookDeviceVerified" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verificationStatusNo) name:@"HookDeviceNotVerified" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryInstallsComplete) name:@"HookQueryInstallsComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryInstallsFailed) name:@"HookQueryInstallsFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryReferralComplete) name:@"HookQueryReferralComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryReferralFailed) name:@"HookQueryReferralFailed" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notSmsDevice) name:@"HookNotSMSDevice" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = @"Hook SDK Sample";
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
