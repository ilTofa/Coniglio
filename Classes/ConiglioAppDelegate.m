//
//  ConiglioAppDelegate.m
//  Coniglio
//
//  Created by Giacomo Tufano on 02/02/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "ConiglioAppDelegate.h"
#import "RootViewController.h"

// Dispatch period in seconds
static const NSInteger kGANDispatchPeriodSec = 10;

NSOperationQueue *theQueue;

@implementation ConiglioAppDelegate

@synthesize window;
@synthesize rootViewController;

// Register user default
+ (void)initialize
{	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *lastDays = [NSDate dateWithTimeIntervalSinceNow:-86400.0];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"",@"SerialNumber",@"",@"Token", @"0", @"Voice",
								 @"http://stream-ny2.radioparadise.com:8056", @"MusicURI", 
								 lastDays, @"lastFBReading", nil];
    [defaults registerDefaults:appDefaults];
}


- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	theQueue = [[NSOperationQueue alloc] init];
    [window addSubview:[rootViewController view]];
    [window makeKeyAndVisible];
}

- (void)dealloc
{
	[theQueue release];
    [rootViewController release];
    [window release];
    [super dealloc];
}

@end
