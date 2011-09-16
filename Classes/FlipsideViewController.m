//
//  FlipsideViewController.m
//  Coniglio
//
//  Created by Giacomo Tufano on 02/02/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "FlipsideViewController.h"
#import "RootViewController.h"

@implementation FlipsideViewController

@synthesize fieldSN;
@synthesize fieldToken;
@synthesize labelBunny;
@synthesize tableVoices;
@synthesize laRuota;
@synthesize buttonServersList;
@synthesize theFBSession;
@synthesize fbLogged;
@synthesize fbButton, checkButton, helpButton;
@synthesize labelVersion;

// Get help page on safari
- (IBAction)getHelp:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.ilTofa.com/Coniglio/help.html"]];
}

// Check data
- (IBAction)checkBunnyInfo:(id)sender
{
	NSString *temp;
	
	[laRuota startAnimating];
	DLog(@"Check Button pressed, starting nabaztag verification");
	theBunny = [Nabaztag sharedInstance];
	if([theBunny validateBunny:fieldSN.text:fieldToken.text])
	{
		DLog(@"Bunny validated! Name is: %@", [theBunny rabbitName]);
		// Set defaults
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:fieldSN.text forKey:@"SerialNumber"];
		[defaults setObject:fieldToken.text forKey:@"Token"];
		[defaults setObject:[NSString stringWithFormat:@"%d", selectedVoice] forKey:@"Voice"];
		DLog(@"Default set. SN: %@, token: %@, voice: %d",
			 fieldSN.text, fieldToken.text, selectedVoice);
		// if no voices loaded already, load them
		if([theBunny.voices count] == 0)
		{
			[theBunny getVoices];
			// and reload table data...
			[tableVoices reloadData];
			[tableVoices scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:selectedVoice inSection:0] 
							   atScrollPosition:UITableViewScrollPositionMiddle 
									   animated:NO];
		}			
		
		temp = [NSString stringWithFormat:NSLocalizedString(@"Nabaztag%@ %@ is %@.", @""), 
				(theBunny.isTagTag) ? @"/tag" : @"",
				theBunny.rabbitName,
				(theBunny.isSleeping) ? NSLocalizedString(@"sleeping", @"") : NSLocalizedString(@"awake", @"")];
	}
	else
	{
		DLog(@"Bunny validation failed!");
		temp = [NSString stringWithFormat:NSLocalizedString(@"Error: %@", @""), theBunny.lastMessage];
	}
	labelBunny.text = temp;
	[laRuota stopAnimating];
}

// dismiss keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
	DLog(@"textFieldShouldReturn called");
    if (theTextField == fieldSN)
        [fieldSN resignFirstResponder];
    if (theTextField == fieldToken)
        [fieldToken resignFirstResponder];
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	//    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];
	theBunny = [Nabaztag sharedInstance];
	// Get defaults
	DLog(@"FlipsideViewController viewDidLoad");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.fieldSN.placeholder = NSLocalizedString(@"Serial Number: ", @"");
	self.fieldToken.placeholder = NSLocalizedString(@"Token: ", @"");
	self.labelVersion.text = [NSString stringWithFormat:@"Coniglio %@",
							  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [self.buttonServersList setTitle:NSLocalizedString(@"Choose a server for your nabaztag", @"") forState:UIControlStateNormal];
    [self.buttonServersList setTitle:NSLocalizedString(@"Choose a server for your nabaztag", @"") forState:UIControlStateHighlighted];
    [self.buttonServersList setTitle:NSLocalizedString(@"Choose a server for your nabaztag", @"") forState:UIControlStateHighlighted];

	[checkButton setTitle:NSLocalizedString(@"Check", @"") forState:UIControlStateNormal];
	[checkButton setTitle:NSLocalizedString(@"Check", @"") forState:UIControlStateHighlighted];
	[checkButton setTitle:NSLocalizedString(@"Check", @"") forState:UIControlStateSelected];
	[helpButton setTitle:NSLocalizedString(@"Help", @"") forState:UIControlStateNormal];
	[helpButton setTitle:NSLocalizedString(@"Help", @"") forState:UIControlStateHighlighted];
	[helpButton setTitle:NSLocalizedString(@"Help", @"") forState:UIControlStateSelected];
	
	fieldSN.text = [defaults stringForKey:@"SerialNumber"];
	fieldToken.text = [defaults stringForKey:@"Token"];
	selectedVoice = [[defaults stringForKey:@"Voice"] integerValue];	
	DLog(@"Default loaded. SN: %@, token: %@, voice: %d", fieldSN.text, fieldToken.text, selectedVoice);
	// validate bunny on default (IF there is a default)
	if([fieldSN.text length] == 0 || [fieldToken.text length] == 0)
		// No default set
		labelBunny.text = NSLocalizedString(@"No bunny setup", @"");
	else
	{ // we have a default...
		[self checkBunnyInfo:nil];
		// set voices table view. Load voices...
		[theBunny getVoices];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	DLog(@"FlipsideViewController viewDidAppear");
	[super viewWillAppear:animated];
	
	// load data and scroll to default row in TableView ...if the bunny is valid...
	if(theBunny.isValid)
	{
		[tableVoices reloadData];
        if(selectedVoice > [tableVoices numberOfRowsInSection:0])
            selectedVoice = 0;
		[tableVoices scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:selectedVoice inSection:0] 
						   atScrollPosition:UITableViewScrollPositionMiddle 
								   animated:NO];
	}
	// Setup FB button...
	[self FBButtonSetup];
}

// TableView delegate rows
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return theBunny.voices.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	DLog(@"Cell for row %d (selected: %d)", indexPath.row, selectedVoice);
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Normal"];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Normal"] autorelease];
	
    cell.textLabel.text = [theBunny.voices objectAtIndex:indexPath.row];
	if(indexPath.row != selectedVoice)
		cell.accessoryType = UITableViewCellAccessoryNone;
	else
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Voice", @"");
}

// Table Row selected
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	DLog(@"Selected row %i", indexPath.row);
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
	// Is the same row as before?
    if (selectedVoice == indexPath.row)
        return;
	
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:selectedVoice inSection:0];
	
    UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
    if (newCell.accessoryType == UITableViewCellAccessoryNone)
	{
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;
        selectedVoice = indexPath.row;
		[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", selectedVoice] forKey:@"Voice"];		
    }
	
    UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
    if (oldCell.accessoryType == UITableViewCellAccessoryCheckmark)
	{
        oldCell.accessoryType = UITableViewCellAccessoryNone;
    }
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [buttonServersList release];
    [super dealloc];
}

// Facebook login
- (IBAction)facebookLogInOut:(id)sender
{
	if([Facebook sharedInstance].isLogged)
		[[Facebook sharedInstance] fbLogout:self];
	else
		[[Facebook sharedInstance] fbLogin:self];
	// in any case, reset time for reading statuses
	NSDate *lastDay = [NSDate dateWithTimeIntervalSinceNow:-86400.0];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:lastDay forKey:@"lastFBReading"];
}

- (void)FBButtonSetup
{
	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *theImageName = [NSString stringWithString:([Facebook sharedInstance].isLogged) ? @"Logout_iphone" : @"Connect_iphone"];
	[fbButton setImage:[UIImage imageWithContentsOfFile:[thisBundle pathForResource:theImageName ofType:@"png"]] 
			  forState:UIControlStateNormal];	
}

- (IBAction)sendToServerList:(id)sender 
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://ojn.psnet.fr/ojn_admin/"]];
}

#pragma mark FacebookDelegate

- (void)loggedInOut
{
	// Only react setting up the right button
	[self FBButtonSetup];
}

- (void)viewDidUnload {
    [self setButtonServersList:nil];
    [super viewDidUnload];
}
@end
