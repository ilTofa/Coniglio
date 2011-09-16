//
//  AlarmChooser.h
//  Coniglio
//
//  Created by Giacomo Tufano on 25/01/11.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

// #define kAlarmBaseURI @"http://129.157.82.145:8080/alarm"
#define kAlarmBaseURI @"https://website/code.py/alarm"
#define kSHASalt @"%@SHAsalt"

@protocol AlarmChooserDelegate
-(void)alarmSetupTo:(NSString *)radioURL atTime:(NSDate *)alarmTime active:(BOOL)active;
@end

@interface AlarmChooser : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	UIDatePicker *dateTimeChooser;
	UISwitch *alarmSwitch;
	UITableView *tableRadio;
    UILabel *dialogTitle;
	NSArray *theRadioList;
	int selectedRadio;
	id<AlarmChooserDelegate> delegate;
}

@property (nonatomic, assign) IBOutlet UIDatePicker *dateTimeChooser;
@property (nonatomic, assign) IBOutlet UISwitch *alarmSwitch;
@property (nonatomic, assign) IBOutlet UILabel *dialogTitle;
@property (nonatomic, retain) IBOutlet UITableView *tableRadio;
@property (nonatomic, retain) NSArray *theRadioList;
@property (nonatomic, assign) id<AlarmChooserDelegate> delegate;

- (IBAction)alarmSetupDone:(id)sender;

@end
