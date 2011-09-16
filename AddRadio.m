//
//  AddRadio.m
//  Coniglio
//
//  Created by Giacomo Tufano on 05/02/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "AddRadio.h"


@implementation AddRadio

@synthesize lName, lDesc;
@synthesize tName, tURL, tDesc;
@synthesize parent;

-(IBAction)cancelIt:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

-(IBAction)itIsOK:(id)sender
{
	NSDictionary *theRadio = [[NSDictionary alloc] initWithObjectsAndKeys:
							  tName.text, @"Name", tURL.text, @"URI", tDesc.text, @"Desc", nil];
	[parent addANamedRadio:theRadio];
	[theRadio release];
	[self dismissModalViewControllerAnimated:YES];
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	self.lName.text = NSLocalizedString(@"Name", @"");
	self.lDesc.text = NSLocalizedString(@"Description", @"");
}


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


- (void)dealloc {
    [super dealloc];
}


@end
