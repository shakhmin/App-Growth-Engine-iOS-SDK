#import "RecommendsController.h"
#import <QuartzCore/QuartzCore.h>
#import "HookMainWindow.h"
#import "JSON.h"
#import "ContactsController.h"
#import "Discoverer.h"
#import "Lead.h"


@implementation RecommendsController

#define LoadingViewTag 0x1364

@synthesize entriesView;

#define BARBUTTON(TITLE, STYLE, SELECTOR) [[[UIBarButtonItem alloc] initWithTitle:TITLE style:STYLE target:self action:SELECTOR] autorelease]

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
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
		return 1;
	}
	else if(section == 1)
	{
		if (IfSimulationData) {
			return [recommends count];
		}
		else {
			if ([Discoverer agent].leads != nil) {
				return [[Discoverer agent].leads count];
			} else {
				return 0;
			}
		}
	}
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		return 60.0f;
	}
	else if(indexPath.section == 1)
	{
		return 50.0f;
	}
	return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 1) {
		return @"Suggestions";
	}
	return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Referrals"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Referrals"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *subView in cell.contentView.subviews) {
		[subView removeFromSuperview];
	}
	cell.imageView.image = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;
	if (indexPath.section == 0)
	{
		UIImage *icon = nil;
		if (indexPath.row == 0) {
			cell.textLabel.text = @"Contacts";
			icon = [UIImage imageNamed:@"maillist_icon.png"];
		}
		else if(indexPath.row == 1)
		{
			cell.textLabel.text = @"Invite";
			icon = [UIImage imageNamed:@"mail_icon.png"];
		}
		cell.detailTextLabel.text = nil;
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.imageView.image = icon;
	}
	else if(indexPath.section == 1)
	{
		if (IfSimulationData) {
			NSDictionary *item = [recommends objectAtIndex:indexPath.row];
			NSString *firstName = [item valueForKey:@"firstName"];
			NSString *lastName = [item valueForKey:@"lastName"];
			NSString *name = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
			int selected = [[item valueForKey:@"selected"] intValue];
			NSString *osType = [item valueForKey:@"osType"];
			cell.textLabel.text = name;
			UIImage *icon = nil;
			if ([osType isEqual:@"android"]) {
				icon = [UIImage imageNamed:@"devicon0.png"];
			}
			else if([osType isEqual:@"ios"])
			{
				icon = [UIImage imageNamed:@"devicon1.png"];
			}
			else 
			{
				icon = [UIImage imageNamed:@"devicon2.png"];
			}
			UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
			if (selected) 
			{
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				[iconView setFrame:CGRectMake(tableView.frame.size.width - icon.size.width - 30, 10, icon.size.width, icon.size.height)];
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
				[iconView setFrame:CGRectMake(tableView.frame.size.width - icon.size.width - 10, 10, icon.size.width, icon.size.height)];
			}
			[cell.contentView addSubview:iconView];
			[iconView release];
		}
		else {
			Lead *lead = (Lead *)[[Discoverer agent].leads objectAtIndex:indexPath.row];
			cell.textLabel.text = lead.name;
			cell.detailTextLabel.text = lead.phone;
			UIImage *icon = nil;
			if ([lead.osType isEqual:@"android"]) {
				icon = [UIImage imageNamed:@"devicon0.png"];
			}
			else if([lead.osType isEqual:@"ios"])
			{
				icon = [UIImage imageNamed:@"devicon1.png"];
			}
			else 
			{
				icon = [UIImage imageNamed:@"devicon2.png"];
			}
			UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
			if (lead.selected) 
			{
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				[iconView setFrame:CGRectMake(tableView.frame.size.width - icon.size.width - 30, 10, icon.size.width, icon.size.height)];
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
				[iconView setFrame:CGRectMake(tableView.frame.size.width - icon.size.width - 10, 10, icon.size.width, icon.size.height)];
			}
			[cell.contentView addSubview:iconView];
			[iconView release];
		}
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if (indexPath.section == 0)
	{
		if (indexPath.row == 0)
		{
			ContactsController *contacts = [[ContactsController alloc] initWithNibName:@"ContactsController" bundle:nil];
			[self.navigationController pushViewController:contacts animated:YES];
			[contacts release];
		}
		else if(indexPath.row == 1)
		{
			[[HookMainWindow sharedHookMainWindow] showSMSPicker:nil msg:@"I thought you might be interested in this app 'AGE SDK', check it out here %link%" inControl:self];
		}
	}
	else 
	{
		if (IfSimulationData) {
			NSDictionary *item = [recommends objectAtIndex:indexPath.row];
			int selected = [[item valueForKey:@"selected"] intValue];
			if (selected) {
				[item setValue:[NSNumber numberWithInt:0] forKey:@"selected"];
			}
			else {
				[item setValue:[NSNumber numberWithInt:1] forKey:@"selected"];
			}
		}
		else {
			Lead *lead = [[Discoverer agent].leads objectAtIndex:indexPath.row];
			if (lead.selected) {
				lead.selected = NO;
			} else {
				lead.selected = YES;
			}
		}
		
		[entriesView reloadData];
	}
}

- (IBAction) refer: (id) sender 
{
	sendNow = YES;
	[self sendReferral];
	/****
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
	 ****/
}

- (void) sendReferral {
    phones = [[NSMutableArray arrayWithCapacity:16] retain];
	if (IfSimulationData) {
		for (NSDictionary *item in recommends) {
			int selected = [[item valueForKey:@"selected"] intValue];
			if (selected) {
				NSString *phone = [item valueForKey:@"phone"];
				[phones addObject:phone];
			}
		}
	}
	else 
	{
		for (Lead *lead in [Discoverer agent].leads) {
			if (lead.selected) {
				[phones addObject:lead.phone];
			}
		}
	}
    if ([phones count] > 0) {
        self.navigationItem.rightBarButtonItem.title = @"Wait ...";
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        [[Discoverer agent] newReferral:phones withMessage:@"I thought you might be interested in this app 'AGE SDK', check it out here %link% " useVirtualNumber:sendNow];
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


- (void) showReferralMessage 
{
    self.navigationItem.rightBarButtonItem.title = @"Send";
    self.navigationItem.rightBarButtonItem.enabled = YES;
	
    if (!sendNow && [MFMessageComposeViewController canSendText]) 
	{
		[[HookMainWindow sharedHookMainWindow] showArraySMSPicker:phones msg:[Discoverer agent].referralMessage inControl:nil];
        /***
		MFMessageComposeViewController *controller = [[[MFMessageComposeViewController alloc] init] autorelease];
        controller.body = [Discoverer agent].referralMessage;
        controller.recipients = phones;
        controller.messageComposeDelegate = self;
        [self presentModalViewController:controller animated:YES];
		 ****/
    } else {
        //[self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Invite Friends";
    self.navigationItem.rightBarButtonItem = BARBUTTON (@"Send", UIBarButtonItemStyleDone, @selector(refer:));
    if (IfSimulationData) {
		[self initRecommends];
	}
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
-(void)initRecommends
{
	NSBundle *bundle = [NSBundle mainBundle]; 
	NSString *filePath = [bundle pathForResource:@"addressbook" ofType:@"json"];
	NSString *str = [NSString stringWithContentsOfFile:filePath];
	NSArray *array = [str JSONValue];
	recommends = [array retain];
	
}
-(void)addLoadingView
{
	UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 100.0f)/2, 170.0f, 100.0f, 60.0f)];
	loadingView.tag = LoadingViewTag;
	loadingView.backgroundColor = [UIColor blackColor];
	loadingView.alpha = 0.55;
	loadingView.layer.masksToBounds = YES;
	loadingView.layer.cornerRadius = 5;
	loadingView.layer.borderWidth = 2;
	loadingView.layer.borderColor = [[UIColor grayColor] CGColor];
	UIActivityIndicatorView *_activityView = [[UIActivityIndicatorView alloc]
											  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	_activityView.frame = CGRectMake((loadingView.frame.size.width - 24.0f)/2, 20.0f, 24.0f, 24.0f );
	[_activityView startAnimating];
	[loadingView addSubview:_activityView];
	[_activityView release];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, loadingView.frame.size.width, 20)];
	[label setBackgroundColor:[UIColor clearColor]];
	[label setText:@"wait⋯⋯"];
	[label setTextColor:[UIColor whiteColor]];
	[label setFont:[UIFont boldSystemFontOfSize:15.0f]];
	label.textAlignment = UITextAlignmentCenter;
	[loadingView addSubview:label];
	[label release];
	
	[self.entriesView addSubview:loadingView];
	[loadingView release];
	
}
-(void)removeLoadingView
{
	UIView *LoadingView = [self.entriesView viewWithTag:LoadingViewTag];
	[LoadingView removeFromSuperview];
}
@end
