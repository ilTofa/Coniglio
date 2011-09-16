//
//  RadioChooser.h
//  Coniglio
//
//  Created by Giacomo Tufano on 22/01/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

@protocol RadioChooserDelegate
-(void)listenTo:(NSString *)radioURL;
@end


@interface RadioChooser : UITableViewController 
{
	NSArray *theRadioList;
	id<RadioChooserDelegate> delegate;
}

@property (nonatomic, retain) NSArray *theRadioList;
@property (nonatomic, assign) id<RadioChooserDelegate> delegate;

-(void)addANamedRadio:(NSDictionary *)theRadio;

@end
