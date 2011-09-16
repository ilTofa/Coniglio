//
//  FlipsideViewController.h
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

@class FBSession;

@interface FlipsideViewController : UIViewController
									<UITableViewDelegate, UITableViewDataSource, FacebookDelegate>
{
	UITextField *fieldSN;
	UITextField *fieldToken;
	UILabel *labelBunny;
	UILabel *labelVersion;
	Nabaztag *theBunny;	
	UITableView *tableVoices;
	UIActivityIndicatorView *laRuota;
	int selectedVoice; 
	FBSession *theFBSession;
	BOOL fbLogged;
	UIButton *fbButton;
	UIButton *checkButton;
	UIButton *helpButton;
}

@property (retain, nonatomic) IBOutlet UIButton *buttonServersList;
@property (nonatomic, assign) FBSession *theFBSession;
@property (nonatomic, assign) BOOL fbLogged;
@property (nonatomic, retain) IBOutlet UITextField *fieldSN;
@property (nonatomic, retain) IBOutlet UITextField *fieldToken;
@property (nonatomic, retain) IBOutlet UILabel *labelBunny;
@property (nonatomic, retain) IBOutlet UILabel *labelVersion;
@property (nonatomic, retain) IBOutlet UITableView *tableVoices;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *laRuota;
@property (nonatomic, retain) IBOutlet UIButton *fbButton;
@property (nonatomic, retain) IBOutlet UIButton *checkButton;
@property (nonatomic, retain) IBOutlet UIButton *helpButton;

- (IBAction)checkBunnyInfo:(id)sender;
- (IBAction)getHelp:(id)sender;
- (IBAction)facebookLogInOut:(id)sender;
- (void)FBButtonSetup;
- (IBAction)sendToServerList:(id)sender;

@end
