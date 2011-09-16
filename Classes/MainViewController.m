//
//  MainViewController.m
//  Coniglio
//
//  Created by Giacomo Tufano on 02/02/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "MainViewController.h"
#import "MainView.h"

#import "ConiglioAppDelegate.h"
#import "RootViewController.h"
#import "FlipsideViewController.h"

// for SHA-256
#include <CommonCrypto/CommonDigest.h>

@implementation MainViewController

@synthesize textMessage;
@synthesize labelStatus;
@synthesize labelBunnyName;
@synthesize labelSleeping;
@synthesize buttonSleep;
@synthesize buttonAwake;
@synthesize buttonStart;
@synthesize buttonStop;
@synthesize buttonAlarm;
@synthesize buttonSendMessage;
@synthesize fbButton;
@synthesize settingsButton;
@synthesize recordingButton;
@synthesize theSlider;

@synthesize recordView;
@synthesize radioWindow;
@synthesize alarmWindow;
@synthesize popoverController;

-(void)iPadInit
{
	DLog(@"iPadInit");
	theBunny = [Nabaztag sharedInstance];
	BOOL isValid = [self checkBunny];
	[self setupLabels:isValid];
}

-(void)invalidBunny:(NSNotification *)note
{
	DLog(@"invalidBunny called by notification");
	// Allow for the view to show herself...
	[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(startSettingsPopover:) userInfo:nil repeats:NO];
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
	// Allow the popup to close ONLY if the Bunny is valid...
	return [self checkBunny];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	// Setup the view. Bunny is valid for sure...
	[self setupLabels:YES];
	// Housekeeping of stale controllers
	if(self.radioWindow)
	{
		[self.radioWindow release];
		self.radioWindow = nil;
	}
	if(self.alarmWindow)
	{
		[self.alarmWindow release];
		self.alarmWindow = nil;
	}	
}

-(IBAction)startSettingsPopover:(id)sender
{
    FlipsideViewController *viewController = [[FlipsideViewController alloc] initWithNibName:@"SettingsView-iPad" bundle:nil];
	UIPopoverController* aPopover = [[UIPopoverController alloc]
									 initWithContentViewController:viewController];
	aPopover.popoverContentSize = CGSizeMake(320.0, 565.0);
	[viewController release];
	
	// Store the popover in a custom property for later use.
	self.popoverController = aPopover;
	[aPopover release];
	self.popoverController.delegate = self;
	[self.popoverController presentPopoverFromRect:self.settingsButton.frame 
											inView:self.view 
						  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];	
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	request.delegate = nil;
	NSString *responseString = [request responseString];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSString *theRequest = [request.userInfo objectForKey:@"kindOfRequest"];
	NSLog(@"requestFinished called for request %@ with answer '%@'\n", theRequest, responseString);
	// Got an error?
	if(responseString == nil || [responseString length] == 0)
	{
		NSString *theMessage = [NSString stringWithFormat:NSLocalizedString(@"Error %@ setting up the radio alarm. Please retry later", @""), @"in"];
		UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
															message:theMessage
														   delegate:nil
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil] autorelease];
		[theAlert show];
		return;
	}		
	if([responseString characterAtIndex:0] == '!')
	{
		UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
															message:[responseString substringFromIndex:1]
														   delegate:nil
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil] autorelease];
		[theAlert show];
		theSlider.hidden = YES;
		labelStatus.text = @"";
		return;
	}
	// If it's not an alarm setup request and it's OK (and probably a legal URI)... Send the data to the nabaztag
	if([theRequest compare:@"alarmSetup"] != NSOrderedSame)
	{
		NSLog(@"Sending <%@> to the nabaztag", responseString);
		if(![theBunny startRadio:responseString])
		{
			labelStatus.text = [NSString stringWithFormat:@"Error: %@", theBunny.lastMessage];
			return;
		}
	}
	theSlider.hidden = YES;
	labelStatus.text = @"";
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	request.delegate = nil;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	theSlider.hidden = YES;
	labelStatus.text = @"";
	NSError *error = [request error];
	NSLog(@"Error: %@", error);
	NSString *theRequest = [request.userInfo objectForKey:@"kindOfRequest"];
	NSString *theMessage;
	if([theRequest compare:@"alarmSetup"] == NSOrderedSame)
		theMessage = [NSString stringWithFormat:NSLocalizedString(@"Error %@ setting up the radio alarm. Please retry later", @""), 
					  [error localizedDescription]];
	else
		theMessage = [error localizedDescription];
	UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
														message:theMessage
													   delegate:nil
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil] autorelease];
	[theAlert show];
}

-(void)recordingOK:(NSString *)recordingFilename
{
	NSLog(@"recordingOK called with receiving filename of %@", recordingFilename);
	// Now get rid of the view
	[self recordingCancelled];
	NSURL *url = [NSURL URLWithString:kRecordingURI];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(requestFinished:)];
	[request setDidFailSelector:@selector(requestFailed:)];
	// mark this is the recording request
	request.userInfo = [NSDictionary dictionaryWithObject:@"recording" forKey:@"kindOfRequest"];
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
	[request setPostValue:hashedData forKey:@"authenticator"];
	[request setPostValue:[[UIDevice currentDevice] uniqueIdentifier] forKey:@"device"];
	[request setFile:recordingFilename forKey:@"myfile"];
	// setup indicators and start sending asyncronous
	labelStatus.text = NSLocalizedString(@"Sending voice message", @"");
	theSlider.hidden = NO;
	request.showAccurateProgress = YES;
	[theSlider setProgress:0.0];
	[request setUploadProgressDelegate:theSlider];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[request setUseHTTPVersionOne:YES];
	[request setValidatesSecureCertificate:NO];
	[request setShouldContinueWhenAppEntersBackground:YES];
    [request setCachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy];
	[request startAsynchronous];
}

- (void)recordingCancelled
{
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
	{
		[self.recordView.view removeFromSuperview];
		ConiglioAppDelegate *theDelegate = (ConiglioAppDelegate *) [UIApplication sharedApplication].delegate;
		RootViewController *theRootController = theDelegate.rootViewController;
		theRootController.infoButton.hidden = NO;
	}
	else
		[self.popoverController dismissPopoverAnimated:YES];
	[self.recordView release];
	self.recordView = nil;
}
- (IBAction)voiceMail:(id)sender
{
	NSLog(@"This is voiceMail: handler");
	// Check for audio... (only on actual device)
	if(![[AVAudioSession sharedInstance] inputIsAvailable])
	{
		UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
															message:NSLocalizedString(@"No audio input available", @"")
														   delegate:nil
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil] 
								 autorelease];
		[theAlert show];
		return;
	}
	if(self.recordView == nil)
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			self.recordView = [[MicrophoneWindow alloc] initWithNibName:@"MicrophoneWindow-iPad" bundle:nil];
		else
			self.recordView = [[MicrophoneWindow alloc] initWithNibName:@"MicrophoneWindow" bundle:nil];
		self.recordView.delegate = self;
		if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		{
			ConiglioAppDelegate *theDelegate = (ConiglioAppDelegate *) [UIApplication sharedApplication].delegate;
			RootViewController *theRootController = theDelegate.rootViewController;
			theRootController.infoButton.hidden = YES;
			[self.view addSubview:self.recordView.view];
		}
	}
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		UIPopoverController* aPopover = [[UIPopoverController alloc]
										 initWithContentViewController:self.recordView];
		aPopover.popoverContentSize = CGSizeMake(220.0, 300.0);
		
		// Store the popover in a custom property for later use.
		self.popoverController = aPopover;
		[aPopover release];
		
		[self.popoverController presentPopoverFromRect:self.recordingButton.frame 
												inView:self.view 
							  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];		
	}
}

- (IBAction)alarmSetup:(id)sender
{
	DLog(@"radioSetup called");
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		self.alarmWindow = [[AlarmChooser alloc] initWithNibName:@"AlarmChooser-iPad" bundle:nil];
	else
		self.alarmWindow = [[AlarmChooser alloc] initWithNibName:@"AlarmChooser" bundle:nil];
	self.alarmWindow.delegate = self;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.alarmWindow];
	navController.navigationBarHidden = YES;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		// The device is an iPad running iPhone 3.2 or later.
		UIPopoverController* aPopover = [[UIPopoverController alloc]
										 initWithContentViewController:navController];
		aPopover.popoverContentSize = CGSizeMake(400.0, 600.0);
		
		// Store the popover in a custom property for later use.
		self.popoverController = aPopover;
		[aPopover release];
		
		[self.popoverController presentPopoverFromRect:self.buttonAlarm.frame 
												inView:self.view 
							  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];	
	}
	else
	{
		// The device is an iPhone or iPod touch.
		// Hide the preferences button
		ConiglioAppDelegate *theDelegate = (ConiglioAppDelegate *) [UIApplication sharedApplication].delegate;
		RootViewController *theRootController = theDelegate.rootViewController;
		theRootController.infoButton.hidden = YES;
		navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentModalViewController:navController animated:YES];
	} 
	[navController release];
}

-(void)alarmSetupTo:(NSString *)radioURL atTime:(NSDate *)alarmTime active:(BOOL)active
{
	// Setup the alarm.
	NSURL *url = [NSURL URLWithString:kAlarmBaseURI];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(requestFinished:)];
	[request setDidFailSelector:@selector(requestFailed:)];
	// mark this is the recording request
	request.userInfo = [NSDictionary dictionaryWithObject:@"alarmSetup" forKey:@"kindOfRequest"];
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
	[request setPostValue:hashedData forKey:@"authenticator"];
	[request setPostValue:[[UIDevice currentDevice] uniqueIdentifier] forKey:@"device"];
	[request setPostValue:radioURL forKey:@"uri"];
	NSString *alarmTimeAsString = [NSString stringWithFormat:@"%.0f", [alarmTime timeIntervalSince1970]];
	[request setPostValue:alarmTimeAsString forKey:@"alarmtime"];
	[request setPostValue:active ? @"1" : @"0" forKey:@"active"];
	[request setPostValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"SerialNumber"] forKey:@"sn"];
	[request setPostValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"Token"] forKey:@"token"];
	// setup indicators and start sending asyncronous
	labelStatus.text = NSLocalizedString(@"Sending alarm setup", @"");
	theSlider.hidden = NO;
	request.showAccurateProgress = YES;
	[theSlider setProgress:0.0];
	[request setUploadProgressDelegate:theSlider];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[request setUseHTTPVersionOne:YES];
	[request setValidatesSecureCertificate:NO];
	[request setShouldContinueWhenAppEntersBackground:YES];
    [request setCachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy];
	[request startAsynchronous];
	
	// Housekeeping
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[self.popoverController dismissPopoverAnimated:YES];
	}
	else
	{
		[self.alarmWindow dismissModalViewControllerAnimated:YES];
		ConiglioAppDelegate *theDelegate = (ConiglioAppDelegate *) [UIApplication sharedApplication].delegate;
		RootViewController *theRootController = theDelegate.rootViewController;
		theRootController.infoButton.hidden = NO;
	}
	if(self.alarmWindow)
	{
		[self.alarmWindow release];
		self.alarmWindow = nil;
	}
    // Now, warn user (only two times)
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"alarmWarn"])
    {
        UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"")
                                                            message:NSLocalizedString(@"The radio alarm is dependent on many servers and many Internet connections. Do not rely totally on this service.", @"")
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil] 
                                 autorelease];
        [theAlert show];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"alarmWarn"];
    }
}

- (IBAction)listenRP:(id)sender
{
	NSLog(@"listenRP called.");
	self.radioWindow = [[RadioChooser alloc] initWithNibName:@"RadioChooser" bundle:nil];
	self.radioWindow.delegate = self;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.radioWindow];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		// The device is an iPad running iPhone 3.2 or later.
		UIPopoverController* aPopover = [[UIPopoverController alloc]
										 initWithContentViewController:navController];
		aPopover.popoverContentSize = CGSizeMake(400.0, 650.0);
		
		// Store the popover in a custom property for later use.
		self.popoverController = aPopover;
		[aPopover release];
		
		[self.popoverController presentPopoverFromRect:self.buttonStart.frame 
												inView:self.view 
							  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];	
	}
	else
	{
		// The device is an iPhone or iPod touch.
		// Hide the preferences button
		ConiglioAppDelegate *theDelegate = (ConiglioAppDelegate *) [UIApplication sharedApplication].delegate;
		RootViewController *theRootController = theDelegate.rootViewController;
		theRootController.infoButton.hidden = YES;
		navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentModalViewController:navController animated:YES];
	} 
	[navController release];
	// will get back on the delegate method below...
}

// This will be called as delegate method from radioWindow
- (void)listenTo:(NSString *)musicURI
{
	NSLog(@"listenTo:%@", musicURI);
	if(![theBunny startRadio:musicURI])
	{
		labelStatus.text = [NSString stringWithFormat:@"Error: %@", theBunny.lastMessage];
		return;
	}
	// Housekeeping
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[self.popoverController dismissPopoverAnimated:YES];
	}
	else
	{
		[self.radioWindow dismissModalViewControllerAnimated:YES];
		ConiglioAppDelegate *theDelegate = (ConiglioAppDelegate *) [UIApplication sharedApplication].delegate;
		RootViewController *theRootController = theDelegate.rootViewController;
		theRootController.infoButton.hidden = NO;
	}
	if(self.radioWindow)
	{
		[self.radioWindow release];
		self.radioWindow = nil;
	}
	labelStatus.text = @"";
	labelSleeping.text = NSLocalizedString(@"Playing Music", @"");
}

- (IBAction)stopRP:(id)sender
{
	DLog(@"listenRP called.");
	if(![theBunny stopRadio])
	{
		labelStatus.text = [NSString stringWithFormat:@"Error: %@", theBunny.lastMessage];
		return;
	}	
	if(theBunny.isSleeping)
		labelSleeping.text = NSLocalizedString(@"Sleeping", @"");
	else
		labelSleeping.text = NSLocalizedString(@"Awake", @"");
	
	labelStatus.text = @"";
}

- (BOOL)checkBunny
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *textSN = [defaults stringForKey:@"SerialNumber"];
	NSString *textToken = [defaults stringForKey:@"Token"];		
	return [theBunny validateBunny:textSN:textToken];
}

// Awake Bunny
- (IBAction)awakeBunny:(id)sender
{
	DLog(@"awakeBunny called");
	BOOL ret = [theBunny awake];
	if(ret)
	{
		[NSThread sleepForTimeInterval:5];
		[self setupLabels:[self checkBunny]];
	}
}

// Sleep Bunny
- (IBAction)sleepBunny:(id)sender
{
	theBunny = [Nabaztag sharedInstance];
    DLog(@"sleepBunny called");
	//	DLog(@"baseURI: %@", theBunny.baseURI);
	BOOL ret = [theBunny sleep];
	if(ret)
	{
		[NSThread sleepForTimeInterval:5];
		[self setupLabels:[self checkBunny]];
	}
}

// Send the message
- (IBAction)sendMessage:(id)sender
{
	// close keyboard if open
	[self.textMessage resignFirstResponder];
	theBunny = [Nabaztag sharedInstance];
	int selectedVoice = [[[NSUserDefaults standardUserDefaults] stringForKey:@"Voice"] integerValue];
    NSArray *voicesNames = [[theBunny.voices objectAtIndex:selectedVoice] componentsSeparatedByString:@" - "];
    NSString *theVoice = [[voicesNames objectAtIndex:1] lowercaseString];
	NSLog(@"sendMessage called with a %@ bunny. Voice #: %d (%@). Message: %@",
		 (theBunny.isValid) ? @"valid" : @"invalid", selectedVoice, theVoice, textMessage.text);
	if([textMessage.text length] == 0)
	{
		labelStatus.text = NSLocalizedString(@"Enter a message", @"");
		return;
	}
	if(theBunny.isValid)
	{
		if (![theBunny sendMessage:textMessage.text withVoice:theVoice])
			labelStatus.text = [NSString stringWithFormat:NSLocalizedString(@"Error: %@", @""), theBunny.lastMessage];
	}
	self.textMessage.text = @"";
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		DLog(@"initWithNibName called.");
    }
    return self;
}

-(void)setupLabels:(BOOL)isValidated
{
	theBunny = [Nabaztag sharedInstance];
	
	if(!isValidated)
	{
		labelBunnyName.text = NSLocalizedString(@"Invalid", @"");
		labelStatus.text = [NSString stringWithFormat:NSLocalizedString(@"Error: %@", @""), theBunny.lastMessage];
		fbButton.enabled = buttonAwake.enabled = buttonSleep.enabled = buttonAlarm.enabled = NO;
		recordingButton.enabled = buttonStart.enabled = buttonStop.enabled = NO;
		DLog(@"Posting invalidBunny");
		// Notify the world that we have no valid configuration...
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"invalidBunny" object:nil]];
	}
	else
	{
		labelBunnyName.text = theBunny.rabbitName;
		labelStatus.text = @"";
		buttonAlarm.enabled = YES;
		if(theBunny.isSleeping)
		{
			buttonAwake.enabled = YES;
			buttonSleep.enabled = NO;
			// No radio and no recording if bunny is sleeping
			recordingButton.enabled = buttonStart.enabled = buttonStop.enabled = NO;
			labelSleeping.text = NSLocalizedString(@"Sleeping", @"");
			// No fb in any case if bunny is sleeping
			fbButton.enabled = NO;
		}
		else
		{
			buttonAwake.enabled = NO;
			recordingButton.enabled = buttonStart.enabled = buttonStop.enabled = buttonSleep.enabled = YES;
			labelSleeping.text = NSLocalizedString(@"Awake", @"");
			// Check if fb session is on!
			fbButton.enabled = ([Facebook sharedInstance].isLogged);
		}
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	DLog(@"MainViewController viewDidLoad");
    [super viewDidLoad];
	theBunny = [Nabaztag sharedInstance];
	textMessage.text = @"";
	labelStatus.text = NSLocalizedString(@"Enter a message", @"");
	[buttonSendMessage setTitle:NSLocalizedString(@"Send Message", @"") forState:UIControlStateNormal];
	[buttonSendMessage setTitle:NSLocalizedString(@"Send Message", @"") forState:UIControlStateHighlighted];
	[buttonSendMessage setTitle:NSLocalizedString(@"Send Message", @"") forState:UIControlStateSelected];
	// Set the keyboard return to "Done" and the delegate
	textMessage.returnKeyType = UIReturnKeyDone;
	textMessage.delegate = self;
	
	// On iPad add as observer for not valid rabbit notification-
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidBunny:) 
													 name:@"invalidBunny" object:nil];
        // if iOS version < 5, then viewDidAppear will not be called, so setup here
        if ([[[UIDevice currentDevice] systemVersion] intValue] < 5)
        {
            DLog(@"iPadInit");
            BOOL isValid = [self checkBunny];
            [self setupLabels:isValid];
            // Stop any radio eventually running
            if(isValid)
                [[Nabaztag sharedInstance] stopRadio];
        }
 
    }
}

- (void)viewDidAppear:(BOOL)animated
{
	DLog(@"MainViewController viewDidAppear");
	[super viewDidAppear:animated];
	theBunny = [Nabaztag sharedInstance];
	BOOL isValid = [self checkBunny];
	[self setupLabels:isValid];
}	

// Text field delegate function. Called when the user tap return to dismiss keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
	DLog(@"textFieldShouldReturn called.");
	[theTextField resignFirstResponder];
	return NO;
}

// UITextView delegate to dismiss keyboard. Seems to me a terrible hack, but it works...
- (BOOL)textView:(UITextView *)theTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	if(([text isEqualToString:@"\n"]) == YES)
	{
		[theTextView resignFirstResponder];
		return NO;
	}
	return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}

- (IBAction)fbQuery:(id)sender
{
	labelStatus.text = NSLocalizedString(@"Querying for and sending Facebook statuses", @"");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *lastDate = [defaults objectForKey:@"lastFBReading"];
	// protect against lost preferences (it happened during debug, probably a bug in initialization code
	if(lastDate == nil)
		lastDate = [NSDate dateWithTimeIntervalSinceNow:-86400.0];
	[[Facebook sharedInstance] statusQuery:[lastDate timeIntervalSince1970] delegate:self];
}

double sliderStep;

- (void)sendFBStatuses:(id)status
{
	theBunny = [Nabaztag sharedInstance];
	NSString *theText = status;
	int selectedVoice = [[[NSUserDefaults standardUserDefaults] stringForKey:@"Voice"] integerValue];
    NSArray *voicesNames = [[theBunny.voices objectAtIndex:selectedVoice] componentsSeparatedByString:@" - "];
    NSString *theVoice = [[voicesNames objectAtIndex:1] lowercaseString];
    if (![theBunny sendMessage:theText withVoice:theVoice])
		labelStatus.text = [NSString stringWithFormat:NSLocalizedString(@"Error: %@", @""), theBunny.lastMessage];
	// increment the slider and check if work is ended and hid progressbar if true
	theSlider.progress += sliderStep;
	if(theSlider.progress > 0.99)
		theSlider.hidden = fbButton.enabled = YES;
//	NSLog(@"sendFBStatuses: sent message (%.0f%%):\"%@\".", theSlider.progress * 100.0, theText);
}

#pragma mark FacebookDelegate

extern NSOperationQueue *theQueue;

- (void)gotStatus:(NSArray *)statusList
{
	// Init slider bar
	theSlider.hidden = fbButton.enabled = NO;
	theSlider.progress = 0.05;	
	if(statusList == nil) // No more messages
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSDate *lastDate = [defaults objectForKey:@"lastFBReading"];
		// protect against lost preferences (it happened during debug, prbably a bug in initialization code
		if(lastDate == nil)
			lastDate = [NSDate dateWithTimeIntervalSinceNow:-86400.0];
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setLocale:[NSLocale currentLocale]];
		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		NSString *formattedDateString = [dateFormatter stringFromDate:lastDate];
		NSString *sentText = [NSString stringWithFormat:NSLocalizedString(@"Facebook: no new statuses since %@.", @""),
							  formattedDateString];
		sliderStep = 0.9;
		theSlider.progress = 0.1;
		// Call directly the selector (no need to enqueue it, it is only one call)
		[self sendFBStatuses:sentText];
		theSlider.hidden = fbButton.enabled = YES;
	}
	else
	{
		// Make execution slow so that emulator can emulate iPhone
		[theQueue setMaxConcurrentOperationCount:1];
		DLog(@"Loading NSOperationQueue in gotStatus");
		theBunny = [Nabaztag sharedInstance];
		if(!theBunny.isValid)
		{
			labelStatus.text = NSLocalizedString(@"Invalid bunny in Facebook status reading", @"");
			theSlider.hidden = fbButton.enabled = YES;
			return;
		}
		int maxMsgNum = 12;
		int MaxNum = ([statusList count] <= maxMsgNum) ? [statusList count] -1 : maxMsgNum - 1;
		sliderStep = (0.9) / (MaxNum + 1);
		for(int i = MaxNum; i >= 0; i--)
		{
			NSDictionary *status = [statusList objectAtIndex:i];
			NSString *userName = [status objectForKey:@"name"];
			NSString *formattedDateString = [status objectForKey:@"date"];
			NSString *message = [status objectForKey:@"message"];
			NSString *sentText = [NSString stringWithFormat:NSLocalizedString(@"FaceBook status: %@, %@: %@", @""), userName, formattedDateString, message];
			NSInvocationOperation *theOp = [[[NSInvocationOperation alloc] initWithTarget:self 
																				 selector:@selector(sendFBStatuses:) 
																				   object:sentText] autorelease];
			[theQueue addOperation:theOp];
//			NSLog(@"Enqueued %@", sentText);
		}
		theSlider.progress = 0.1;
	}
	// In any case, reset the status text
	labelStatus.text = @"";
	// and save last date
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSDate date] forKey:@"lastFBReading"];
}


@end
