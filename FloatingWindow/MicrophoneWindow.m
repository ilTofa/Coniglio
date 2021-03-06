//
//  MicrophoneWindow.m
//
//  Created by Giacomo Tufano on 15/12/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "MicrophoneWindow.h"

#import <CoreAudio/CoreAudioTypes.h>

@implementation MicrophoneWindow

@synthesize theText;
@synthesize textString;
@synthesize background;
@synthesize bAction, bOK, bCancel;
@synthesize delegate;
@synthesize recordingURL;
@synthesize bRecorded, bRecording, bPlaying;
@synthesize theRecorder, thePlayer;

#define kBeforeAll		1
#define kRecordingStart	2
#define kRecordingEnd	3
#define kPlayingStart	4
#define kPlayingEnd		5

#define kLastAnimation	@"LastAnimation"

-(void)setState:(int)state
{
	// setup UI depending on the application state
	switch (state) 
	{
		case kRecordingStart:
			self.bRecording = YES;
			self.bOK.enabled = self.bCancel.enabled = NO;
			self.theText.text = NSLocalizedStringFromTable(@"Click above to stop recording", @"MicrophoneStrings", @"");
			break;
		case kRecordingEnd:
			// Release memory, set flags, housekeeping
			[self.theRecorder release];
			self.bRecording = NO;
			self.bRecorded = YES;
			// restore buttons and set image and text
			self.bOK.enabled = self.bCancel.enabled = YES;
			self.theText.text = NSLocalizedStringFromTable(@"Click above to play", @"MicrophoneStrings", @"");
			[bAction setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Speaker" ofType:@"png"]] forState:UIControlStateNormal];
			NSLog(@"filename is: %@", self.recordingURL);
			break;
		case kPlayingStart:
			self.bOK.enabled = self.bCancel.enabled = NO;
			bPlaying = YES;
			self.theText.text = NSLocalizedStringFromTable(@"Click above to stop playing", @"MicrophoneStrings", @"");
			break;
		case kPlayingEnd:
			[self.thePlayer release];
			self.bOK.enabled = self.bCancel.enabled = YES;
			self.theText.text = NSLocalizedStringFromTable(@"Click above to play", @"MicrophoneStrings", @"");
			self.bPlaying = NO;
			break;
		default:
			break;
	}
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
	NSLog(@"audioRecorderDidFinishRecording called with a %@", flag ? @"success" : @"failure");
	[self setState:kRecordingEnd];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
	NSLog(@"audioRecorderEncodeErrorDidOccur called with error:\n%@", [error description]);
	[self setState:kRecordingEnd];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	NSLog(@"audioPlayerDidFinishPlaying called with a %@", flag ? @"success" : @"failure");
	[self setState:kPlayingEnd];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
	NSLog(@"audioPlayerDecodeErrorDidOccur called with error:\n%@", [error description]);
	[self setState:kPlayingEnd];
}

-(IBAction)saveIt
{
	[delegate recordingOK:[self.recordingURL path]];
}

-(IBAction)cancelIt
{
	// delete recording, if any, and get back to caller.
	if(self.bRecorded)
		[[NSFileManager defaultManager] removeItemAtPath:[self.recordingURL path] error:NULL];
	[delegate recordingCancelled];
}

int countDown;

- (void)timerFireMethod:(NSTimer*)theTimer
{
	switch (countDown)
	{
		case 2:
			[bAction setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"two" ofType:@"png"]] forState:UIControlStateNormal];
			countDown--;
			break;
		case 1:
			[bAction setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"one" ofType:@"png"]] forState:UIControlStateNormal];
			countDown--;
			[self.theRecorder prepareToRecord];
			break;
		case 0:
			[bAction setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BigMic" ofType:@"png"]] forState:UIControlStateNormal];
			[self setState:kRecordingStart];	
			[theTimer invalidate];
			[self.theRecorder recordForDuration:30];
			NSLog(@"theRecorder recordForDuration: called");
			break;
		default:
			break;
	}
}

-(IBAction)doIt
{
	NSError *outError;

	// if recording
	if(self.bRecording)
	{
		NSLog(@"Stopping recorder per user request");
		[self.theRecorder stop];
		return;
	}
	// if playing
	if(self.bPlaying)
	{
		NSLog(@"Stopping player per user request");
		[self.thePlayer stop];
		self.thePlayer.currentTime = 0.0;
		[self setState:kPlayingEnd];
		return;
	}
	
	// if not recorded already start recording
	if(self.bRecorded == NO)
	{
		// Record audio, very low quality (output device is a Nabaztag, after all) :)
		NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
										[NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
										[NSNumber numberWithFloat: 11025.0], AVSampleRateKey,
										[NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
										[NSNumber numberWithInt: AVAudioQualityMin], AVEncoderAudioQualityKey,
										nil];
		self.theRecorder = [[AVAudioRecorder alloc] initWithURL:self.recordingURL settings:recordSettings error:&outError];
		if(theRecorder == nil)
		{
			[[[UIAlertView alloc] initWithTitle:@"Error" 
										message:[outError localizedDescription]
									   delegate:nil
							  cancelButtonTitle:nil
							  otherButtonTitles:nil]
			 autorelease];
			NSLog(@"%@", [outError description]);
			[outError release];
		}
		self.theRecorder.delegate = self;
		[recordSettings release];
		// Now setup a timer. Record start will be started on the timer at third invocation.
		[bAction setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"three" ofType:@"png"]] forState:UIControlStateNormal];
		countDown = 2;
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
	}
	else // if already recorded (implicitly not recording or playing now), play it :)
	{
		self.thePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordingURL error:&outError];
		self.thePlayer.delegate = self;
		[self.thePlayer prepareToPlay];
		[self.thePlayer play];
		NSLog(@"thePlayer play: called");
		[self setState:kPlayingStart];
	}
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
	// set transparent background...
	[self.view setBackgroundColor:[UIColor clearColor]];

	// Prepare the URL for the recorder
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSLog(@"%.0f", [[NSDate date] timeIntervalSince1970]);
	NSLog(@"%@", [[UIDevice currentDevice] uniqueIdentifier]);
	NSLog(@"%.0f-%@.m4a", [[NSDate date] timeIntervalSince1970], [[UIDevice currentDevice] uniqueIdentifier]);
	NSString *fileName = [NSString stringWithFormat:@"%.0f-%@.m4a", 
  						  [[NSDate date] timeIntervalSince1970],
						  [[UIDevice currentDevice] uniqueIdentifier]];
	NSString *path = [documentsDirectory stringByAppendingPathComponent:fileName];
	self.recordingURL = [NSURL fileURLWithPath:path];
	
	// set default for things not set by the caller
	self.theText.text = NSLocalizedStringFromTable(@"Click above to record", @"MicrophoneStrings", @"");
	[bOK setTitle:NSLocalizedStringFromTable(@"Save", @"MicrophoneStrings", @"") forState:UIControlStateNormal];
	
	self.bRecorded = self.bRecording = NO;
	self.bOK.enabled = NO;
	
	// Now let it fade in...
	self.view.alpha = 0.0;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	self.view.alpha = 0.85;
	[UIView commitAnimations];
}

-(void)viewWillAppear:(BOOL)animated
{
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

- (void)viewDidUnload
{
}


- (void)dealloc {
    [super dealloc];
}


@end
