#import "Discoverer.h"
#import "JSON.h"
#import "Lead.h"
#import <AddressBook/AddressBook.h>
#import "UIDevice-Hardware.h"

static Discoverer *_agent;

@implementation Discoverer

@synthesize server, SMSDest, appSecret, /* runQueryAfterOrder, */ queryStatus, leads;

- (id) init {
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults) {
		installCode = [[standardUserDefaults objectForKey:@"installCode"] retain];
    }
    
    return self;
}

- (BOOL) verifyDevice:(UIViewController *)vc {
    if (verifyDeviceConnection != nil) {
        return NO;
    }
    if (vc != nil) {
        viewController = [vc retain];
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/createverify", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"secret=%@", [appSecret stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&verifyMessageTemplate=%@", [@"Please send this SMS to confirm your device %installCode%" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		verifyDeviceData = [[NSMutableData data] retain];
        verifyDeviceConnection = [connection retain];
	}
    return YES;
}

- (BOOL) queryVerifiedStatus {
    if (verificationConnection != nil || installCode == nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryverify", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"secret=%@", [appSecret stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		verificationData = [[NSMutableData data] retain];
        verificationConnection = [connection retain];
	}
    return YES;
}


- (BOOL) discover {
    if (discoverConnection != nil) {
        return NO;
    }
    
    NSLog(@"installCode is %@", installCode);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/neworder", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"secret=%@", [appSecret stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    if (installCode != nil ) {
        [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    NSString *encodedJsonStr = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[self getAddressbook], NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
	[postBody appendData:[[NSString stringWithFormat:@"&addressBook=%@", encodedJsonStr] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceModel=%@", [[UIDevice currentDevice] platformString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceOs=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		discoverData = [[NSMutableData data] retain];
        discoverConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}

- (BOOL) queryOrder {
    if (queryOrderConnection != nil || orderid == 0) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryorder", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"secret=%@", [appSecret stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&order=%d", orderid] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		queryOrderData = [[NSMutableData data] retain];
        queryOrderConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}


- (NSString *) getAddressbook {
    ABAddressBookRef ab = ABAddressBookCreate();
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(ab);
    CFIndex nPeople = ABAddressBookGetPersonCount(ab);
    
    NSMutableArray *phones = [[NSMutableArray alloc] init];
    for (int i = 0; i < nPeople; i++) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);
        CFStringRef firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
        CFStringRef lastName = ABRecordCopyValue(ref, kABPersonLastNameProperty);
        
        NSString *firstNameStr = (NSString *) firstName;
        if (firstNameStr == nil) {
            firstNameStr = @"";
        }
        if (![firstNameStr canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            firstNameStr = @"NONASCII";
        }
        NSString *lastNameStr = (NSString *) lastName;
        if (lastNameStr == nil) {
            lastNameStr = @"";
        }
        if (![lastNameStr canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            lastNameStr = @"NONASCII";
        }
        
        ABMultiValueRef ps = ABRecordCopyValue(ref, kABPersonPhoneProperty);
        CFIndex count = ABMultiValueGetCount (ps);
        for (int i = 0; i < count; i++) {
            CFStringRef phone = ABMultiValueCopyValueAtIndex (ps, i);
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:16];
            [dic setObject:((NSString *) phone) forKey:@"phone"];
            [dic setObject:((NSString *) firstNameStr) forKey:@"firstName"];
            [dic setObject:((NSString *) lastNameStr) forKey:@"lastName"];
            [phones addObject:dic];
            [dic release];
            
            if (phone) {
                CFRelease(phone);
            }
        }
        
        if (firstName) {
            CFRelease(firstName);
        }
        if (lastName) {
            CFRelease(lastName);
        }
    }
	if (allPeople) {
        CFRelease(allPeople);
    }
    
    // create json for phone and name based on phones
    SBJSON *jsonWriter = [[SBJSON new] autorelease];
    jsonWriter.humanReadable = YES;
    NSString *jsonStr = [jsonWriter stringWithObject:phones];
    NSLog(@"JSON Object --> %@", jsonStr);
    
    return jsonStr;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [viewController dismissModalViewControllerAnimated:YES];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog (@"Received response");
    if (connection == verifyDeviceConnection) {
        [verifyDeviceData setLength:0];
    }
    if (connection == verificationConnection) {
        [verificationData setLength:0];
    }
    if (connection == discoverConnection) {
        [discoverData setLength:0];
    }
    if (connection == queryOrderConnection) {
        [queryOrderData setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (connection == verifyDeviceConnection) {
        [verifyDeviceData appendData:data];
    }
    if (connection == verificationConnection) {
        [verificationData appendData:data];
    }
    if (connection == discoverConnection) {
        [discoverData appendData:data];
    }
    if (connection == queryOrderConnection) {
        [queryOrderData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog (@"Received error with code %d", error.code);
    if (connection == verifyDeviceConnection) {
        [verifyDeviceData release];
        [verifyDeviceConnection release];
        verifyDeviceConnection = nil;
    }
    if (connection == verificationConnection) {
        [verificationData release];
        [verificationConnection release];
        verificationConnection = nil;
    }
    if (connection == discoverConnection) {
        [discoverData release];
        [discoverConnection release];
        discoverConnection = nil;
    }
    if (connection == queryOrderConnection) {
        [queryOrderData release];
        [queryOrderConnection release];
        queryOrderConnection = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog (@"Finished loading data");
    
    if (connection == verifyDeviceConnection) {
        NSString *dataStr = [[[NSString alloc] initWithData:verifyDeviceData encoding:NSUTF8StringEncoding] autorelease];
        NSLog (@"verifyDevice data is %@", dataStr);
        [verifyDeviceData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            if (standardUserDefaults) {
                installCode = [[resp objectForKey:@"installCode"] retain];
                [standardUserDefaults setObject:installCode forKey:@"installCode"];
                [standardUserDefaults synchronize];
            }
        }
        
        if (viewController != nil) {
            if ([MFMessageComposeViewController canSendText]) {
                MFMessageComposeViewController *controller = [[[MFMessageComposeViewController alloc] init] autorelease];
                controller.body = [resp objectForKey:@"verifyMessage"];
                controller.recipients = [NSArray arrayWithObjects:SMSDest, nil];
                controller.messageComposeDelegate = self;
                [viewController presentModalViewController:controller animated:YES];
            } else {
                NSLog(@"Not a SMS device. Fail silently.");
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HookVerifyDeviceComplete" object:[resp objectForKey:@"status"]];
        
        [verifyDeviceConnection release];
        verifyDeviceConnection = nil;
    }
    
    if (connection == verificationConnection) {
        NSString *dataStr = [[[NSString alloc] initWithData:verificationData encoding:NSUTF8StringEncoding] autorelease];
        NSLog (@"verification data is %@", dataStr);
        [verificationData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSLog(@"1");
            NSString *verified = [resp objectForKey:@"verified"];
            if ([verified boolValue]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"HookDeviceVerified" object:nil];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"HookDeviceNotVerified" object:nil];
                NSLog(@"2");
            }
            NSLog(@"3");
        }
        
        [verificationConnection release];
        verificationConnection = nil;
    }
    
    if (connection == discoverConnection) {
        NSString *dataStr = [[[NSString alloc] initWithData:discoverData encoding:NSUTF8StringEncoding] autorelease];
        NSLog (@"discover data is %@", dataStr);
        [discoverData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            if (standardUserDefaults) {
                installCode = [[resp objectForKey:@"installCode"] retain];
                [standardUserDefaults setObject:installCode forKey:@"installCode"];
                [standardUserDefaults synchronize];
            }
            orderid = [[resp objectForKey:@"order"] intValue];
            
            NSLog(@"installCode is %@", installCode);
            NSLog(@"orderid is %d", orderid);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HookDiscoverComplete" object:nil];
            /*
            if (runQueryAfterOrder) {
                [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(queryOrder) userInfo:nil repeats:NO];
                // [self queryOrder];
            }
            */
        }
        
        [discoverConnection release];
        discoverConnection = nil;
    }
        
    if (connection == queryOrderConnection) {
        NSString *dataStr = [[[NSString alloc] initWithData:queryOrderData encoding:NSUTF8StringEncoding] autorelease];
        NSLog (@"query order data is %@", dataStr);
        [queryOrderData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        int status = [[resp objectForKey:@"status"] intValue];
        if (status == 1000) {
            queryStatus = YES;
        } else {
            queryStatus = NO;
        }
        if (status == 1000 || status == 500) {
            leads = [[NSMutableArray arrayWithCapacity:16] retain];
            NSArray *ls = [resp objectForKey:@"leads"];
            if (ls != nil) {
                for (NSDictionary *d in ls) {
                    Lead *lead = [[Lead alloc] init];
                    lead.phone = (NSString *) [d objectForKey:@"phone"];
                    lead.osType = (NSString *) [d objectForKey:@"osType"];
                    [leads addObject:lead];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"HookQueryOrderComplete" object:nil];
            }
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HookQueryOrderFailed" object:nil];
        }
        /*
        else if ([[resp objectForKey:@"status"] intValue] == 1234) {
            // pending. Let's run this again after some delay
            // [self performSelector:@selector(queryOrder) withObject:nil afterDelay:10.0];
            [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(queryOrder) userInfo:nil repeats:NO];
        }
        */
        
        [queryOrderConnection release];
        queryOrderConnection = nil;
    }
}



+ (void) activate:(NSString *)secret {
    if (_agent) {
        return;
    }
    
    _agent = [[Discoverer alloc] init];
    _agent.server = @"http://age.hookmobile.com";
    _agent.SMSDest = @"3025175025";
    _agent.appSecret = secret;
    
    return;
}


+ (void) retire {
    [_agent release];
    _agent = nil;
}

+ (Discoverer *) agent {
    if (_agent == nil) {
        [NSException raise:@"InstanceNotExists"
                    format:@"Attempted to access instance before initializaion. Please call activate: first."];
    }
    return _agent;
}


@end