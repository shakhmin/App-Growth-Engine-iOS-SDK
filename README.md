# App Growth Engine for iOS

Hook Mobile has developed a unique offering for Mobile app developers ­ App
Growth Engine SDK.  The SDK supports both iOS and Android mobile.  The SDK
will assist in user authentication during registration and help promote app
sharing via Hookąs device discovery platform without the need to add or
implement any middleware solutions to your current environment.

# Create an account and a key for your app

To use the SDK, you first need to register an account and create an application.

<h3><center><a href="http://addressbook.ringfulhealth.com:8081/addressbook/register.jsp">Register</a></center></h3>

# Install the SDK

To install the SDK, copy all files under AppGrowthEngine/SDKClasses to your XCode project. You should also copy over the SBJson library files if your application does not already have them (e.g., if you use the Facebook iOS SDK, you would already have SBJson).

In addition, you need to add the following two iOS SDK frameworks to your project as dependencies:

* AddressBook.framework
* MessageUI.framework

# Use the SDK

Once you have created an application, you can start the SDK in your application
delegate with the application secret you have registered. You can also stop the SDK when you exit the
application.

<pre>
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [Discoverer activate:@"your-app-secret"];
    // ... ...    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [Discoverer retire];
}
</pre>

The usage of the SDK is illustrated in the sample application. Just open the
XCode project, fill in the application secret in the <code>SampleAppDelegate</code> class, and run the project (ideally in
a physical iPhone attached to the dev computer).  The buttons in the sample
demonstrates key actions you can perform with the SDK.

![logo](App-Growth-Engine-iOS-SDK/raw/master/screen-shot.png)


## Verify the customer device that runs your app (optional, and iPhone-only)

By calling the following SDK method, you can create an in-app SMS message box
for the app user to send an confirmation message so that you can capture their
phone number. 

<pre>
[[Discoverer agent] verifyDevice:myViewController forceSms:NO userName:@"John Doe"];
</pre>

The SMS message screen is displayed as a modal view controller on top of the
<code>myViewController</code> screen. The <code>forceSms</code> parameter indicates whether
the user can cancel the SMS screen without sending the confirmation message. If it is set to <code>YES</code>,
the user would have to send out the confirmation. The <code>userName</code> parameter takes the user's name.
You can leave this to <code>nil</code> if you have not collected name from your user.

Once the user sends out the confirmation, you can query their confirmation
status via the following call. Note that the call returns immediately and
performs the confirmation in the background. Your application code needs to
listen for HookDeviceVerified or HookDeviceVerified in NSNotificationCenter in
order to receive the confirmation results.

<pre>
[[Discoverer agent] queryVerifiedStatus];

... ...

- (void)viewDidLoad {
    ... ...
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verificationStatusYes) name:@"HookDeviceVerified" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verificationStatusNo) name:@"HookDeviceNotVerified" object:nil];
}
</pre>

## Get a list of contacts from the user's addressbook that are most likely to install your app.

First, you need to execute a discovery call like this. The call returns immediately, and processes the discovery in background.

<pre>
[[Discoverer agent] discover];
</pre>

It takes Hook Mobile anywhere from 10 minutes to several hours to determine the
devices for each of the phone numbers, and come up with an optimized list. If
you have a server side callback registered with your application in Hook
Mobile's developer portal, you will receive a callback when the data is ready.
But if you would prefer to have everything self-contained in the app, you can
wait for 10 minutes and issue the following call. Again, the call returns
immediately, and you should listen for the <code>HookQueryOrderComplete</code> event. When
the <code>HookQueryOrderComplete</code> event is received, you can query a list of Leads,
which contains phone numbers and device types.

<pre>
[[Discoverer agent] queryOrder];

- (void)viewDidLoad {
    ... ...
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryComplete) name:@"HookQueryOrderComplete" object:nil];
}

- (void) queryComplete {
    [self.navigationController pushViewController:leadsController animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Leads"];
    ... ...
    cell.textLabel.text = ((Lead *)[[Discoverer agent].leads objectAtIndex:indexPath.row]).phone;
    cell.detailTextLabel.text = ((Lead *)[[Discoverer agent].leads objectAtIndex:indexPath.row]).osType;
    return cell;
}
</pre>

Now, you can prompt your user to send personal invites to their friends in
[[Discoverer agent].leads to maximize the chance of referral success!

## Track your referrals

The AGE platform enables you to track the performance of your referrals via customized URLs that you can use
in invite messages. The <code>newReferral</code> method creates a referral message with the custom URL.

<pre>
[[Discoverer agent] newReferral:phones 
    withMessage:@"I thought you might be interested in this app 'AGE SDK', check it out here %link% "];
</pre>

The <code>phones</code> parameter is an <code>NSArray</code> that contains a list of phone numbers you wish to send
referrals to. It is typically a list selected from the leads generated from the last section of this document. The <code>withMessage</code>
parameter takes a message template with <code>%link%</code> referring to customized referral URL from the AGE platform.

Once the AGE server returns, the SDK raises the <code>HookNewReferralComplete</code> notification, and you can retrieve the referral
message from <code>[Discoverer agent].referralMessage</code>. Then, you can prompt the user of your app to send that referral message via SMS.
NOTE: if your device is not an SMS device (e.g., a WIFI iPad or an iPod Touch), the AGE server will send out the referral message
automatically, and hence removing the need for the app to retrieve and send the <code>[Discoverer agent].referralMessage</code>.

<pre>
- (void)viewDidLoad {
    ... ...
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showReferralMessage) name:@"HookNewReferralComplete" object:nil];
}


- (void) showReferralMessage {
    ... ...
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
</pre>

Optionally, you could also tell AGE that the user have sent the invitation messages. That helps AGE better correlate the
installation statistics for you.

<pre>
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    [self dismissModalViewControllerAnimated:YES];
    
    if (result == MessageComposeResultCancelled) {
        [[Discoverer agent] updateReferral:NO];
    } else {
        [[Discoverer agent] updateReferral:YES];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}
</pre>




