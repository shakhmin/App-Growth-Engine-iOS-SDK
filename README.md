# App Growth Engine for iOS v1.0.1

Hook Mobile has developed a unique and powerful tool for mobile app developers to market your app: App Growth Engine (AGE) SDK. This open source library allows you to integrate AGE into your iOS application.


# Getting Started
<h3>Step 1: Register your iOS App with Hook Mobile</h3>

To use the SDK, you first need to <a href="signup.html">create an account</a> and <a href="add-app.html">register your application</a> with Hook Mobile. You will need your app key when setting up your app in Xcode.

<img src="http://hookmobile.com/images/screenshot/create-app.png" alt="Create App" />


<h3>Step 2: Install the iOS SDK</h3>

Before you begin development with the AGE iOS SDK, you will need to install the iOS development tools and download the AGE SDK.

* Install <a href="https://developer.apple.com/devcenter/ios/index.action">XCode</a>
* Download <a href="http://bit.ly/GiOSHM" target="_blank">AGE iOS SDK (GitHub)</a>

To install the SDK, copy all files under AppGrowthEngine/SDKClasses to your XCode project. You should also copy over the SBJson library files if your application does not already have them (e.g., if you use the Facebook iOS SDK, you would already have SBJson). In addition, you need to add the following two iOS SDK frameworks to your project as dependencies:

* AddressBook.framework
* MessageUI.framework

<h3>Step 3: Use the iOS SDK</h3>

Once you have created an application, you can start the SDK in your application delegate with the app key you have registered. You can also stop the SDK when you exit the application.

<pre><code>- (<FONT COLOR="FF00FF">BOOL</FONT>) application:(UIApplication *)application didFinishLaunchingWithOptions:(<a href="https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSDictionary_Class/Reference/Reference.html">NSDictionary</a> *)launchOptions {
   
    [HKMDiscoverer activate: <FONT COLOR="B22222">@"Your-App-Key"</FONT>];
    // ... ...    
}
 
- (<FONT COLOR="FF00FF">void</FONT>) applicationWillTerminate:(UIApplication *)application {
    [HKMDiscoverer retire];
}
</code></pre>

The usage of the SDK is illustrated in the sample application. Just open the XCode project, fill in the app key in the <code>SampleAppDelegate</code> class, and run the project (ideally in a physical iPhone attached to the dev computer). The buttons in the sample demonstrate key actions you can perform with the SDK.

<img src="http://hookmobile.com/images/screenshot/ios-sample-app.png"/>

# Device Verfication

<h3>Step 1: Send Confirmation Code</h3>

By calling the following SDK method, you can create an in-app SMS message box for the app user to send an confirmation message so that you can capture their phone number.

<code>[[HKMDiscoverer agent] verifyDevice:myViewController forceSms:<FONT COLOR="FF00FF">NO</FONT> userName:<FONT COLOR="B22222">@"John Doe"</FONT>];</code>

The SMS message screen is displayed as a modal view controller on top of the <code>myViewController</code> screen. The <code>forceSms</code> parameter indicates whether the user can cancel the SMS screen without sending the confirmation message. If it is set to <code>YES</code>, the user would have to send out the confirmation. The <code>userName</code> parameter takes the user's name. You can leave this to <code>nil</code> if you have not collected name from your user.

<h3>Step 2: Query Status</h3>

Once the user sends out the confirmation, you can query their confirmation status via the following call. Note that the call returns immediately and performs the confirmation in the background. Your application code needs to listen for <code>HookDeviceVerified</code> or <code>HookDeviceNotVerified</code> in <code>NSNotificationCenter</code> in order to receive the confirmation results.

<pre><code>[[HKMDiscoverer agent] queryVerifiedStatus];
 
... ...
 
- (<FONT COLOR="FF00FF">void</FONT>)viewDidLoad {
    ... ...
    [[<a href="http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/NSNotificationCenter_Class/">NSNotificationCenter</a> defaultCenter] addObserver:self selector:<FONT COLOR="FF00FF">@selector</font>(verificationStatusYes) name:<FONT COLOR="B22222">@"HookDeviceVerified"</font> object:<FONT COLOR="FF00FF">nil</font>];
    [[<a href="http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/NSNotificationCenter_Class/">NSNotificationCenter</a> defaultCenter] addObserver:self selector:<FONT COLOR="FF00FF">@selector</font>(verificationStatusYes) name:<FONT COLOR="B22222">@"HookDeviceNotVerified"</font> object:<FONT COLOR="FF00FF">nil</font>];
}
</code></pre>

# Smart Invitation

<h3>Step 1: Discover</h3>

To get a list of contacts from user's addressbook that are most likely to install your app, you need to execute a discovery call like this first. The call returns immediately, and processes the discovery in background.

<code>[[HKMDiscoverer agent] discover];</code>

<img src="http://hookmobile.com/images/screenshot/ios-sample-leads.png"/>

<h3>Step 2: Get Recommended Invites</h3>
It takes Hook Mobile seconds to determine the devices for each of the phone numbers, and come up with an optimized list. Once complete issue the following call. Again, the call returns immediately, and you should listen for the <code>HookQueryOrderComplete</code> event. When the <code>HookQueryOrderComplete</code> event is received, you can query a list of Leads, which contains phone numbers and device types.

<pre><code>
[[HKMDiscoverer agent] queryLeads];
 
- (<FONT COLOR="FF00FF">void</FONT>)viewDidLoad {
    ... ...
    [[<a href="http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/NSNotificationCenter_Class/">NSNotificationCenter</a> defaultCenter] addObserver:self selector:<FONT COLOR="FF00FF">@selector</Font>(queryComplete) name:<FONT COLOR="B22222">@"HookQueryOrderComplete"</Font> object:<FONT COLOR="FF00FF">nil</Font>];
}
 
- (<FONT COLOR="FF00FF">void</FONT>) queryComplete {
    [self.navigationController pushViewController:leadsController animated:<FONT COLOR="FF00FF">YES</Font>];
}
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(<a href="https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSIndexPath_Class/Reference/Reference.html">NSIndexPath</a> *)indexPath {
   
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<FONT COLOR="B22222">@"Leads"</Font>];
    ... ...
    cell.textLabel.text = ((Lead *)[[HKMDiscoverer agent].leads objectAtIndex:indexPath.row]).phone;
    cell.detailTextLabel.text = ((Lead *)[[HKMDiscoverer agent].leads objectAtIndex:indexPath.row]).osType;
    <FONT COLOR="FF00FF">return</Font> cell;
}
</code></pre>

Now, you can prompt your user to send personal invites to their friends in <code>[[HKMDiscoverer agent].leads</code> to maximize the chance of referral success!


<h3>Step 3: Send Invitations</h3>

The AGE platform enables you to track the performance of your referrals via customized URLs that you can use in invite messages. The <code>newReferral</code> method creates a referral message with the custom URL.

<pre><code>
[[HKMDiscoverer agent] newReferral:phones
    withMessage:<FONT COLOR="B22222">@"I thought you might be interested in this app 'AGE SDK', check it out here %link% "</font>
    useVirtualNumber:<FONT COLOR="FF00FF">YES</font>
];

</code></pre>


The <code>phones</code> parameter is an <code>NSArray</code> that contains a list of phone numbers you wish to send referrals to. It is typically a list selected from the leads returned by <code></code>[[HKMDiscoverer agent].leads. The <code>withMessage</code> parameter takes a message template with <code>%link%</code> referring to customized referral URL from the AGE platform. The <code>useVirtualNumber</code> option specifies whether AGE should send out the referrals via its own virtual number. If not, the application itself is responsible for letting the user send out the referrals via their own devices.

<img src="http://hookmobile.com/images/screenshot/ios-sample-send.png"/>

Once the AGE server returns, the SDK raises the <code>HookNewReferralComplete</code> notification and you can retrieve the referral message from <code>[HKMDiscoverer agent].referralMessage</code>. Then, you can prompt the user of your app to send that referral message via SMS. NOTE: if your device is not an SMS device (e.g., a WIFI iPad or an iPod Touch), the AGE server will send out the referral message automatically, and hence removing the need for the app to retrieve and send the <code>[HKMDiscoverer agent].referralMessage</code>.

<pre><code>
- (<FONT COLOR="FF00FF">void</FONT>)viewDidLoad {
    ... ...
    [[<a href="https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSNotificationCenter_Class/Reference/Reference.html">NSNotificationCenter</a> defaultCenter] addObserver:self selector:<FONT COLOR="FF00FF">@selector</Font>(showReferralMessage) name:<FONT COLOR="B22222">@"HookNewReferralComplete"</font> object:<FONT COLOR="FF00FF">nil</font>];
}
 
 
- (<FONT COLOR="FF00FF">void</FONT>) showReferralMessage {
    ... ...
    <FONT COLOR="FF00FF">if</font> ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *controller = [[[MFMessageComposeViewController alloc] init] autorelease];
        controller.body = [HKMDiscoverer agent].referralMessage;
        controller.recipients = phones;
        controller.messageComposeDelegate = self;
        [self presentModalViewController:controller animated:<FONT COLOR="FF00FF">YES</font>];
    } <FONT COLOR="FF00FF">else</font> {
        [self.navigationController popViewControllerAnimated:<FONT COLOR="FF00FF">YES</font>];
    }
}
</code></pre>

Optionally, you could also tell AGE that the user have sent the invitation messages. That helps AGE better correlate the installation statistics for you.

<pre><code>
- (<FONT COLOR="FF00FF">void</FONT>)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
   
    [self dismissModalViewControllerAnimated:<FONT COLOR="FF00FF">YES</font>];
   
    <FONT COLOR="FF00FF">if</font> (result == MessageComposeResultCancelled) {
        [[HKMDiscoverer agent] updateReferral:<FONT COLOR="FF00FF">NO</font>];
    } <FONT COLOR="FF00FF">else</font> {
        [[HKMDiscoverer agent] updateReferral:<FONT COLOR="FF00FF">YES</font>];
    }
   
    [self.navigationController popViewControllerAnimated:YES];
}
</code></pre>

# Tracking Referrals and Installs

<h3>Step 1: Track Your Referrals</h3>

The AGE API also allows you to track all referrals you have sent from any device, and get the referrals' click throughs. This makes it possible for you to track referral performance of individual devices, and potentially reward the users who generate the most referral click through.

<code>[[HKMDiscoverer agent] queryReferral];</code>

Once the referral data is retrieved from the AGE server, the SDK generates a notification event <code>HookQueryReferralComplete</code>. The referral data is stored in the <code>[HKMDiscoverer agent].referrals</code> array with each <code>HKMReferralRecord</code> element in the array representing a referral.

<pre><code>
<FONT COLOR="FF00FF">@interface</font> HKMReferralRecord : <a href="https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSObject_Class/Reference/Reference.html">NSObject</a> {
   
    <FONT COLOR="FF00FF">int</font> totalClickThrough;
    <FONT COLOR="FF00FF">int</font> totalInvitee;
    <a href=" https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSDate_Class/Reference/Reference.html">NSDate</a> *invitationDate;
   
}
</code></pre>

<h3>Step 2: Track Friends Who Install The Same App</h3>

The AGE platform allows you to find friends who also install the same app from your addressbook. To query for friends installs in your addressbook, you must call the <code>discover</code> method first. And then, you can call the <code>queryInstalls</code>. This method takes a string parameter that indicates how the searching and matching of addressbook should be done.

 *<code>FORWARD</code> - Find contacts within your address book who has the same app.

 *<code>BACKWARD</code> - Find other app users who has your phone number in their address book. When to use this? When the app wants to suggest a long lost friend who has your contact, but not vice versa.

 *<code>MUTUAL</code> - Find contacts within your address book who has the same app and who also has your contact in his/her address book. This query may be useful for engaging a friend to play in multi-player game who already plays the game.

Below is an example:

<code>[[HKMDiscoverer agent] queryInstalls:@"FORWARD"];</code>
Once the SDK receives the friends who have the same app, it generates a <code>HookQueryInstallsComplete</code> notification and saves the results in an array of <code>HKMLead</code> objects in <code>[HKMDiscoverer agent].installs</code>.

<img src="http://hookmobile.com/images/screenshot/ios-sample-track.png"/>
<img src="http://hookmobile.com/images/screenshot/ios-sample-installs.png"/>