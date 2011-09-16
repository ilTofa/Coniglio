//
//  RadioChooser.m
//  Coniglio
//
//  Created by Giacomo Tufano on 22/01/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RadioChooser.h"
#import "AddRadio.h"

@implementation RadioChooser

@synthesize theRadioList;
@synthesize delegate;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

// FIXME: this and the next one should go to a model class
-(void)saveRadioArray
{
	NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *archivePath = [docsDirectory stringByAppendingPathComponent:@"Radio.archive"];
	[NSKeyedArchiver archiveRootObject:self.theRadioList toFile:archivePath];
}

-(void)addANamedRadio:(NSDictionary *)theRadio
{
	NSMutableArray *temp = [NSMutableArray arrayWithArray:self.theRadioList];
	[temp addObject:theRadio];
	self.theRadioList = temp;
	[self saveRadioArray];
	[self.tableView reloadData];
}

-(IBAction)addRadio:(id)sender
{
	AddRadio *addController = [[AddRadio alloc] initWithNibName:@"AddRadio" bundle:nil];
	addController.parent = self;
	[self presentModalViewController:addController animated:YES];
	[addController release];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];

	self.navigationItem.title = NSLocalizedString(@"Radio Chooser", @"");

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
	UIBarButtonItem *theLeftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
																					target:self
																					action:@selector(addRadio:)];
	self.navigationItem.leftBarButtonItem = theLeftButton;
	[theLeftButton release];
	
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
		[self saveRadioArray];
	}
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
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
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	NSDictionary *theOne = [self.theRadioList objectAtIndex:indexPath.row];
	NSString *retValue = [theOne objectForKey:@"URI"];
	[delegate listenTo:retValue];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) 
	{
		NSMutableArray *temp = [NSMutableArray arrayWithArray:self.theRadioList];
		[temp removeObjectAtIndex:indexPath.row];
		self.theRadioList = temp;
		[self saveRadioArray];		
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath 
{
	NSMutableArray *temp = [NSMutableArray arrayWithArray:self.theRadioList];
	[temp exchangeObjectAtIndex:fromIndexPath.row withObjectAtIndex:toIndexPath.row];
	self.theRadioList = temp;
	[self saveRadioArray];
}

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // Return NO if you do not want the item to be re-orderable.
	if(indexPath.row == 1)
		return NO;
    return YES;
}
*/


- (void)dealloc {
    [super dealloc];
}


@end

