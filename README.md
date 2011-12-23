# App Growth Engine for iOS

Hook Mobile has developed a unique offering for Mobile app developers ­ App
Growth Engine SDK.  The SDK supports both iOS and Android mobile.  The SDK
will assist in user authentication during registration and help promote app
sharing via Hookąs device discovery platform without the need to add or
implement any middleware solutions to your current environment.

To use the SDK, you first need to register an account and create an application.

<h3><center><a href="http://addressbook.ringfulhealth.com:8081/addressbook/register.jsp">Register</a></center></h3>

Once you have created an application, you can start the SDK in your application
delegate with the secret. You can also stop the SDK when you exit the
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
XCode project, fill in the application secret, and run the project in
simulator. The buttons in the sample demonstrates key actions you can perform
with the SDK.

![logo](App-Growth-Engine-iOS-SDK/raw/master/screen-shot.png)


1. Verify the customer device that runs your app (optional, and iPhone-only)

By calling the fowllowing SDK method, you can create an in-app SMS message box
for the app user to send an confirmation message so that you can capture their
phone number. 

<pre>
[[Discoverer agent] verifyDevice:myViewController];
</pre>

The SMS message screen is displayed as a modal view controller on top of the
myViewController screen.

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

2. Get a list of contacts from the user's addressbook that are most likely to install your app.

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
immediately, and you should listen for the HookQueryOrderComplete event. When
the HookQueryOrderComplete event is received, you can query a list of Leads,
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

