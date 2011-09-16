//
//  RootViewController.m
//  Coniglio
//
//  Created by Giacomo Tufano on 02/02/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RootViewController.h"
#import "MainViewController.h"
#import "FlipsideViewController.h"
#import "Facebook.h"

@implementation RootViewController

@synthesize infoButton;
@synthesize flipsideNavigationBar;
@synthesize mainViewController;
@synthesize flipsideViewController;

- (void)viewDidLoad
{
    DLog(@"RootViewController viewDidLoad");
    [super viewDidLoad];
	MainViewController *viewController;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		// The device is an iPad running iPhone 3.2 or later.
		viewController = [[MainViewController alloc] initWithNibName:@"MainView-iPad" bundle:nil];
	}
	else
	{
		// The device is an iPhone or iPod touch.
		viewController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
	}    
	self.mainViewController = viewController;
    [viewController release];
    
    [self.view insertSubview:mainViewController.view belowSubview:infoButton];
	
	// Facebook session init
	[Facebook sharedInstance];
	
	// init the bunny voice list
	NSString *temp = [[NSUserDefaults standardUserDefaults] stringForKey:@"SerialNumber"];
	if(temp != nil && temp.length != 0)
		[[Nabaztag sharedInstance] getVoices];
	else 	// flip immediately if no defaults ever setup
	{
		if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		{
			[self toggleView];
		}
	}
}


- (void)loadFlipsideViewController
{
    FlipsideViewController *viewController = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    self.flipsideViewController = viewController;
    [viewController release];
	
    // Set up the navigation bar
    UINavigationBar *aNavigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
    aNavigationBar.barStyle = UIBarStyleBlackOpaque;
    self.flipsideNavigationBar = aNavigationBar;
    [aNavigationBar release];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toggleView)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:@"Preferences"];
    navigationItem.rightBarButtonItem = buttonItem;
    [flipsideNavigationBar pushNavigationItem:navigationItem animated:NO];
    [navigationItem release];
    [buttonItem release];
}


- (IBAction)toggleView
{    
    /*
     This method is called when the info or Done button is pressed.
     It flips the displayed view from the main view to the flipside view and vice-versa.
     */
    if (flipsideViewController == nil) {
        [self loadFlipsideViewController];
    }
	
	DLog(@"RootViewController toggleView");
    UIView *mainView = mainViewController.view;
    UIView *flipsideView = flipsideViewController.view;
    
	// Check if data are OK and save default if needed
	if ([mainView superview] == nil)
		[flipsideViewController checkBunnyInfo:nil];
	
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1];
    [UIView setAnimationTransition:([mainView superview] ? UIViewAnimationTransitionCurlUp : UIViewAnimationTransitionCurlDown)
						   forView:self.view
							 cache:YES];
    
    if ([mainView superview] != nil)
	{
        [flipsideViewController viewWillAppear:YES];
        [mainViewController viewWillDisappear:YES];
        [mainView removeFromSuperview];
        [infoButton removeFromSuperview];
        [self.view addSubview:flipsideView];
        [self.view insertSubview:flipsideNavigationBar aboveSubview:flipsideView];
        [mainViewController viewDidDisappear:YES];
        [flipsideViewController viewDidAppear:YES];		
    } 
	else
	{
        [mainViewController viewWillAppear:YES];
        [flipsideViewController viewWillDisappear:YES];
        [flipsideView removeFromSuperview];
        [flipsideNavigationBar removeFromSuperview];
        [self.view addSubview:mainView];
        [self.view insertSubview:infoButton aboveSubview:mainViewController.view];
        [flipsideViewController viewDidDisappear:YES];
        [mainViewController viewDidAppear:YES];
    }
    [UIView commitAnimations];
}




 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	DLog(@"RootViewController shouldAutorotateToInterfaceOrientation called: %d", interfaceOrientation);
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [infoButton release];
    [flipsideNavigationBar release];
    [mainViewController release];
    [flipsideViewController release];
    [super dealloc];
}

@end
