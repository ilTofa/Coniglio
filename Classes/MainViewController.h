//
//  MainViewController.h
//  Coniglio
//
//  Created by Giacomo Tufano on 02/02/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

#import "Nabaztag.h"

#import "FBConnect/FBConnect.h"
#import "Facebook.h"

#import "MicrophoneWindow.h"
#import "RadioChooser.h"
#import "AlarmChooser.h"

// For encoder for web
#import "ASIFormDataRequest.h"

#define kRecordingURI @"https://webserver/code.py/trans"

@interface MainViewController : UIViewController <UITextViewDelegate, FacebookDelegate, MicrophoneWindowDelegate, 
													RadioChooserDelegate, UIPopoverControllerDelegate, AlarmChooserDelegate>
{
	UITextView *textMessage;
	UILabel *labelStatus;
	UILabel *labelBunnyName;
	UILabel *labelSleeping;
	Nabaztag *theBunny;
	UIButton *buttonSleep;
	UIButton *buttonAwake;
	UIButton *buttonStart, *buttonStop, *buttonAlarm;
	UIButton *buttonSendMessage;
	UIButton *fbButton;
	UIButton *settingsButton;
	UIButton *recordingButton;
	UIProgressView *theSlider;
	MicrophoneWindow *recordView;
	RadioChooser *radioWindow;
	AlarmChooser *alarmWindow;
	UIPopoverController *popoverController;
}

@property (nonatomic, retain) IBOutlet UITextView *textMessage;
@property (nonatomic, retain) IBOutlet UILabel *labelStatus;
@property (nonatomic, retain) IBOutlet UILabel *labelBunnyName;
@property (nonatomic, retain) IBOutlet UILabel *labelSleeping;
@property (nonatomic, retain) IBOutlet UIButton *buttonSleep;
@property (nonatomic, retain) IBOutlet UIButton *buttonAwake;
@property (nonatomic, retain) IBOutlet UIButton *buttonStart;
@property (nonatomic, retain) IBOutlet UIButton *buttonStop;
@property (nonatomic, retain) IBOutlet UIButton *buttonAlarm;
@property (nonatomic, retain) IBOutlet UIButton *buttonSendMessage;
@property (nonatomic, retain) IBOutlet UIButton *fbButton;
@property (nonatomic, retain) IBOutlet UIButton *settingsButton;
@property (nonatomic, retain) IBOutlet UIButton *recordingButton;
@property (nonatomic, retain) IBOutlet UIProgressView *theSlider;
@property (nonatomic, retain) UIPopoverController *popoverController;

@property (assign, nonatomic) MicrophoneWindow *recordView;
@property (assign, nonatomic) RadioChooser *radioWindow;
@property (assign, nonatomic) AlarmChooser *alarmWindow;

- (IBAction)voiceMail:(id)sender;
- (IBAction)listenRP:(id)sender;
- (IBAction)stopRP:(id)sender;
- (IBAction)alarmSetup:(id)sender;
- (IBAction)sleepBunny:(id)sender;
- (IBAction)awakeBunny:(id)sender;
- (IBAction)sendMessage:(id)sender;
- (IBAction)fbQuery:(id)sender;

-(IBAction)startSettingsPopover:(id)sender;

- (BOOL)checkBunny;
- (void)setupLabels:(BOOL)isValidated;
- (void)gotStatus:(NSArray *)statusList;

-(void)listenTo:(NSString *)radioURL;

@end
