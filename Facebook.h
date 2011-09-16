//
//  Facebook.h
//  Coniglio
//
//  Created by Giacomo Tufano on 07/04/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

#import "FBConnect/FBConnect.h"

@class FBSession;
@protocol FacebookDelegate;

@interface Facebook : NSObject <FBSessionDelegate, FBDialogDelegate, FBRequestDelegate>
{
	BOOL logged;
	FBRequest *firstQuery;
	FBSession *theFBSession;
	NSArray *theMessages;	
}

@property (nonatomic,  getter=isLogged) BOOL logged;
@property (nonatomic, retain) FBSession *theFBSession;
@property (nonatomic, retain) FBRequest *firstQuery;
@property (nonatomic, retain) NSArray *theMessages;

+ (Facebook *)sharedInstance;

- (void)fbLogin:(id<FacebookDelegate>)caller;
- (void)fbLogout:(id<FacebookDelegate>)caller;
- (void)statusQuery:(NSTimeInterval)howMuchTimeAgo delegate:(id<FacebookDelegate>)caller;

@end

@protocol FacebookDelegate

@optional

- (void)loggedInOut;
- (void)gotStatus:(NSArray *)statusList;

@end

