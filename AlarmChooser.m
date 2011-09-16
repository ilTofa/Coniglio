//
//  AlarmChooser.m
//  Coniglio
//
//  Created by Giacomo Tufano on 25/01/11.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "AlarmChooser.h"

#import "ASIHTTPRequest.h"
// for SHA-256
#include <CommonCrypto/CommonDigest.h>

@implementation AlarmChooser

@synthesize alarmSwitch, dateTimeChooser, tableRadio, theRadioList, dialogTitle, delegate;

- (NSString *)radioNameForURI:(NSString *)URI
{
	return @"Radio Stikazzi";
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	request.delegate = nil;
	NSString *responseString = [request responseString];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSString *theRequest = [request.userInfo objectForKey:@"kindOfRequest"];
	NSLog(@"requestFinished called for request %@\nReturned strng is: <%@>", theRequest, responseString);
	// If we have data on server setup the user interface
	if(responseString && [responseString length] > 0 && [responseString characterAtIndex:0] != '0')
	{
		NSArray *retValues = [responseString componentsSeparatedByString:@"|"];
		if([retValues count] != 3)
		{	// Something got really wrong
			UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
																message:responseString
															   delegate:nil
													  cancelButtonTitle:@"OK" 
													  otherButtonTitles:nil] autorelease];
			[theAlert show];
		}
		else 
		{
			NSLog(@"Entering else");
			NSString *radioURL = [retValues objectAtIndex:1];
			// Find the radio iterating the array
			NSUInteger i, count = [self.theRadioList count];
			for (i = 0; i < count; i++) 
			{
				NSDictionary *obj = [self.theRadioList objectAtIndex:i];
				if([radioURL compare:[obj objectForKey:@"URI"]] == NSOrderedSame)
				{
					NSLog(@"Found %@", [obj objectForKey:@"Name"]);
					break;
				}
				else
					NSLog(@"Skipped %@", [obj objectForKey:@"URI"]);
			}
			if(i == count)
			{
				selectedRadio = 0;
				self.alarmSwitch.on = NO;
			}
			else
			{
				selectedRadio = i;
				self.alarmSwitch.on = YES;
			}
			[self.tableRadio reloadData];
			[self.tableRadio scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRadio inSection:0] 
								   atScrollPosition:UITableViewScrollPositionMiddle 
										   animated:YES];			
			// Now set date
			[self.dateTimeChooser setDate:[NSDate dateWithTimeIntervalSince1970:[[retValues objectAtIndex:0] doubleValue]]];
			// Now set the switch
			alarmSwitch.on = ([(NSString *)[retValues objectAtIndex:2] compare:@"1"] == NSOrderedSame);
		}

	}
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	request.delegate = nil;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	NSLog(@"Error: %@", error);
	UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil] autorelease];
	[theAlert show];
}

- (void)getCurrentSetup
{
	NSLog(@"getCurrentSetup called");
	NSMutableString *theFullUrl = [NSMutableString stringWithString:kAlarmBaseURI];
	// build an authenticator using SHA-256
	unsigned char hashedChars[32];
	NSString *inputString = [NSString stringWithFormat:kSHASalt, 
							 [[UIDevice currentDevice] uniqueIdentifier]];
	CC_SHA256([inputString UTF8String],
			  [inputString lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 
			  hashedChars);
	NSString *hashedData = [[NSData dataWithBytes:hashedChars length:32] description];
	hashedData = [hashedData stringByReplacingOccurrencesOfString:@" " withString:@""];
	hashedData = [hashedData stringByReplacingOccurrencesOfString:@"<" withString:@""];
	hashedData = [hashedData stringByReplacingOccurrencesOfString:@">" withString:@""];
	[theFullUrl appendFormat:@"?authenticator=%@&device=%@&sn=%@", 
	 hashedData, [[UIDevice currentDevice] uniqueIdentifier], 
	 [[NSUserDefaults standardUserDefaults] stringForKey:@"SerialNumber"]];
	NSLog(@"URL is: <%@>", theFullUrl);
	// the request
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:theFullUrl]];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(requestFinished:)];
	[request setDidFailSelector:@selector(requestFailed:)];
	// mark this is the query request
	request.userInfo = [NSDictionary dictionaryWithObject:@"queryingAlarm" forKey:@"kindOfRequest"];
	// setup indicators and start sending asyncronous
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[request setUseHTTPVersionOne:YES];
	[request setValidatesSecureCertificate:NO];
    [request setCachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy];
	[request startAsynchronous];	
}

- (IBAction)alarmSetupDone:(id)sender
{
	NSDictionary *theOne = [self.theRadioList objectAtIndex:selectedRadio];
	NSString *selectedURI = [theOne objectForKey:@"URI"];
	NSString *selectedRadioName = [theOne objectForKey:@"Name"];
	NSDate *selectedDate = self.dateTimeChooser.date;
	NSLog(@"Radio: %@ (%@) @ %@ - %@", selectedRadioName, selectedURI, selectedDate, (self.alarmSwitch.on) ? @"ON" : @"OFF");
	[delegate alarmSetupTo:selectedURI atTime:selectedDate active:self.alarmSwitch.on];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	// There is a saved archive?
	NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *archivePath = [docsDirectory stringByAppendingPathComponent:@"Radio.archive"];
	if([[NSFileManager defaultManager] fileExistsAtPath:archivePath])
	{ // if YES, load it
		self.theRadioList = [NSKeyedUnarchiver unarchiveObjectWithFile:archivePath];
	}
	else
	{
		// Read default plist of radio station from bundle
		NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ConiglioRadio" ofType:@"plist"];  
		self.theRadioList = [NSArray arrayWithContentsOfFile:filePath];
	}
    // Set title (if iPad, where title is visible)
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        dialogTitle.text = NSLocalizedString(@"Radio Alarm", @"");
	selectedRadio = 1;
	self.alarmSwitch.on = NO;
	// Meanwhile... set the time to now + 5 minuti (and no alarm in the past)
	[self.dateTimeChooser setDate:[NSDate dateWithTimeIntervalSinceNow:300]];
	self.dateTimeChooser.minimumDate = [NSDate dateWithTimeIntervalSinceNow:300];
	[self getCurrentSetup];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return NSLocalizedString(@"Choose a radio", @"");
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [self.theRadioList count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	NSDictionary *theOne = [self.theRadioList objectAtIndex:indexPath.row];
	cell.textLabel.text = [theOne objectForKey:@"Name"];
	cell.detailTextLabel.text = [theOne objectForKey:@"Desc"];
	if(indexPath.row != selectedRadio)
		cell.accessoryType = UITableViewCellAccessoryNone;
	else
		cell.accessoryType = UITableViewCellAccessoryCheckmark;	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	DLog(@"Selected row %i", indexPath.row);
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
	// Is the same row as before?
    if (selectedRadio == indexPath.row)
        return;
	
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:selectedRadio inSection:0];
	selectedRadio = indexPath.row;
	
    UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
    if (newCell.accessoryType == UITableViewCellAccessoryNone)
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;
	
    UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
    if (oldCell.accessoryType == UITableViewCellAccessoryCheckmark)
        oldCell.accessoryType = UITableViewCellAccessoryNone;
}

@end
