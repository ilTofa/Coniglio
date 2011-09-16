//
//  ConiglioAppDelegate.h
//  Coniglio
//
//  Created by Giacomo Tufano on 02/02/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface ConiglioAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
    RootViewController *rootViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;

@end

