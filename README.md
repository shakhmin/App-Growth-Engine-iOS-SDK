# App Growth Engine for iOS v1.0.1

Hook Mobile has developed a unique and powerful tool for mobile app developers to market your app: App Growth Engine (AGE) SDK. This open source library allows you to integrate AGE into your iOS application.


# Getting Started
Step 1: Register your iOS App with Hook Mobile

To use the SDK, you first need to <a href="signup.html">create an account</a> and <a href="add-app.html">register your application</a> with Hook Mobile. You will need your app key when setting up your app in Xcode.

<img src="http://hookmobile.com/images/screenshot/create-app.png" alt="Create App" />


Step 2: Install the iOS SDK

Before you begin development with the AGE iOS SDK, you will need to install the iOS development tools and download the AGE SDK.

* Install <a href="https://developer.apple.com/devcenter/ios/index.action">XCode</a>
* Download <a href="http://bit.ly/GiOSHM" target="_blank">AGE iOS SDK (GitHub)</a>

To install the SDK, copy all files under AppGrowthEngine/SDKClasses to your XCode project. You should also copy over the SBJson library files if your application does not already have them (e.g., if you use the Facebook iOS SDK, you would already have SBJson). In addition, you need to add the following two iOS SDK frameworks to your project as dependencies:

* AddressBook.framework
* MessageUI.framework

Step 3: Use the iOS SDK

Once you have created an application, you can start the SDK in your application delegate with the app key you have registered. You can also stop the SDK when you exit the application.

<pre><code>

- (<FONT COLOR="FF00FF">BOOL</FONT>) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   
    [HKMDiscoverer activate: <FONT COLOR="B22222">@"Your-App-Key"</FONT>];
    // ... ...    
}
 
- (<FONT COLOR="FF00FF">void</FONT>) applicationWillTerminate:(UIApplication *)application {
    [HKMDiscoverer retire];
}
</code></pre>

The usage of the SDK is illustrated in the sample application. Just open the XCode project, fill in the app key in the <code>SampleAppDelegate</code> class, and run the project (ideally in a physical iPhone attached to the dev computer). The buttons in the sample demonstrate key actions you can perform with the SDK.

<img src="http://hookmobile.com/images/screenshot/ios-sample-app.png"/>


See our <a href="http://hookmobile.com/ios-tutorial.html" target="_blank">iOS SDK Getting Started Guide</a>


# Sample Application

This library includes a sample application to guide you in development.
