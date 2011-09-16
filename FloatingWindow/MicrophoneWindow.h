//
//  FloatingWindow.h
//
//  Created by Giacomo Tufano on 15/12/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol MicrophoneWindowDelegate
-(void)recordingCancelled;
-(void)recordingOK:(NSString *)recordingFilename;
@end


@interface MicrophoneWindow : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate> 
{
	UITextView *theText;
	UIImageView *background;
	UIButton *bAction;
	UIButton *bOK, *bCancel;
	NSString *textString;
	id<MicrophoneWindowDelegate> delegate;
	NSURL *recordingURL;
	BOOL bRecorded;
	BOOL bRecording;
	BOOL bPlaying;
	AVAudioRecorder *theRecorder;
	AVAudioPlayer *thePlayer;
}

@property (retain, nonatomic) IBOutlet UITextView *theText;
@property (retain, nonatomic) IBOutlet UIImageView *background;
@property (retain, nonatomic) IBOutlet UIButton *bAction;
@property (retain, nonatomic) IBOutlet UIButton *bOK;
@property (retain, nonatomic) IBOutlet UIButton *bCancel;
@property (retain, nonatomic) NSString *textString;
@property (assign, nonatomic) id<MicrophoneWindowDelegate> delegate;
@property (retain, nonatomic) NSURL *recordingURL;
@property (assign, nonatomic) BOOL bRecorded;
@property (assign, nonatomic) BOOL bRecording;
@property (assign, nonatomic) BOOL bPlaying;
@property (assign, nonatomic) AVAudioRecorder *theRecorder;
@property (assign, nonatomic) AVAudioPlayer *thePlayer;

-(IBAction)saveIt;
-(IBAction)cancelIt;
-(IBAction)doIt;

@end
