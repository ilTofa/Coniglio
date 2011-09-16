//
//  AddRadio.h
//  Coniglio
//
//  Created by Giacomo Tufano on 05/02/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

#import "RadioChooser.h"

@interface AddRadio : UIViewController 
{
	RadioChooser *parent;
	UILabel *lName, *lDesc;
	UITextField *tName, *tURL, *tDesc;
}

@property(nonatomic, retain) IBOutlet UILabel *lName;
@property(nonatomic, retain) IBOutlet UILabel *lDesc;
@property(nonatomic, retain) IBOutlet UITextField *tName;
@property(nonatomic, retain) IBOutlet UITextField *tURL;
@property(nonatomic, retain) IBOutlet UITextField *tDesc;

@property(assign) RadioChooser *parent;

-(IBAction)itIsOK:(id)sender;
-(IBAction)cancelIt:(id)sender;

@end
