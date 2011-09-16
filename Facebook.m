//
//  Facebook.m
//  Coniglio
//
//  Created by Giacomo Tufano on 07/04/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "Facebook.h"

static Facebook *sharedFacebook = nil;

static NSString* kApiKey = @"<yourAPIkey>";
static NSString* kApiSecret = @"<YOUR SECRET KEY>";

@implementation Facebook

@synthesize theFBSession;
@synthesize logged;
@synthesize firstQuery;
@synthesize theMessages;

#pragma mark SingletonSetup

+ (Facebook *)sharedInstance
{
    @synchronized(self) {
        if (sharedFacebook == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedFacebook;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedFacebook == nil) {
            sharedFacebook = [super allocWithZone:zone];
            return sharedFacebook;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

-(id) init
{
	if(self = [super init])
	{
		// Facebook session init
		self.theFBSession = [FBSession sessionForApplication:kApiKey secret:kApiSecret delegate:self];
		if([self.theFBSession resume])
			logged = YES;
		else
			logged = NO;
		return self;
	}
	else
		return nil;
}

#pragma mark LoginProcedures

// private var to hold FacebookDelegate pointer
id<FacebookDelegate> _theDelegate;

-(void)fbLogin:(id<FacebookDelegate>)caller
{
	_theDelegate = caller;

	FBLoginDialog* dialog = [[[FBLoginDialog alloc] initWithSession:theFBSession] autorelease];
	[dialog show];
	// the delegates will chain to the FBSessionDelegate didLogin method of _theCaller for housekeeping
}

-(void)fbLogout:(id<FacebookDelegate>)caller
{
	_theDelegate = caller;
	[theFBSession logout];
}

#pragma mark FBSessionDelegate

- (void)session:(FBSession*)session didLogin:(FBUID)uid
{
	self.logged = YES;
	[_theDelegate loggedInOut];
}

- (void)session:(FBSession*)session willLogout:(FBUID)uid
{
	self.logged = NO;
	[_theDelegate loggedInOut];
}

#pragma mark FB Status routines

NSTimeInterval _theTime;

- (void)statusQuery:(NSTimeInterval)howMuchTimeAgo delegate:(id<FacebookDelegate>)caller
{
	_theDelegate = caller;
	_theTime = howMuchTimeAgo;

	NSString* fql = [NSString stringWithFormat: 
					 @"select uid,time,message from status where uid in (select uid2 from friend where uid1= %lld) AND time > %.0f", 
					 theFBSession.uid, _theTime];
//	NSLog(@"Querying for: <%@>", fql);
	NSDictionary* params = [NSDictionary dictionaryWithObject:fql forKey:@"query"];
	firstQuery = [FBRequest requestWithDelegate:self];
	[firstQuery call:@"facebook.fql.query" params:params];	
}

-(void)getNamesQuery
{
	NSString* fql = [NSString stringWithFormat: 
					 @"select uid,name from user where uid in (select uid from status where uid in (select uid2 from friend where uid1= %lld) AND time > %.0f)", 
					 theFBSession.uid, _theTime];
//	NSLog(@"Querying for: <%@>", fql);
	NSDictionary* params = [NSDictionary dictionaryWithObject:fql forKey:@"query"];
	[[FBRequest requestWithDelegate:self] call:@"facebook.fql.query" params:params];		
}

#pragma mark FBRequestDelegate

- (void)request:(FBRequest*)request didLoad:(id)result
{
	// is this the first query? If yes, query back for the names
	if(firstQuery == request)
	{
		// Preserve data
		self.theMessages = [NSArray arrayWithArray:result];
		// If no messages, get back to the caller and quit processing
		if([self.theMessages count] == 0)
		{
			[_theDelegate gotStatus:nil];
			return;
		}
		[theMessages retain];
		[self getNamesQuery];
	}
	else // this is the return of the Jedi. :)
	{
		// This is the array for returing values
		NSMutableArray *backdata = [NSMutableArray arrayWithCapacity:[self.theMessages count]];
		NSArray *retValue = result;
//		NSLog(@"theMessages: %d elements, retValue: %d elements", [self.theMessages count], [retValue count]);
		for(int i = 0; i < [self.theMessages count]; i++)
		{
			NSDictionary *set1 = [self.theMessages objectAtIndex:i];
			NSDictionary *set2 = [retValue objectAtIndex:i];
//			NSString *uid = [set1 objectForKey:@"uid"];
			NSString *timeAsString = [set1 objectForKey:@"time"];
			double temp = [timeAsString doubleValue];
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormatter setLocale:[NSLocale currentLocale]];
			[dateFormatter setDateStyle:NSDateFormatterLongStyle];
			[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
			NSString *formattedDateString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:temp]];
			NSString *message = [set1 objectForKey:@"message"];
//			NSString *uid2 = [set2 objectForKey:@"uid"];
			NSString *userName = [set2 objectForKey:@"name"];
//			NSLog(@"uid %@=%@=%@ @ %@: %@", uid, uid2, userName, formattedDateString, message);
			NSDictionary *statusLine = [NSDictionary dictionaryWithObjectsAndKeys: 
										userName, @"name", formattedDateString, @"date", message, @"message", nil];
			[backdata addObject:statusLine];
		} 
		[self.theMessages release];
		// send data back to delegate (delegate must retain value)
		retValue = [NSArray arrayWithArray:backdata];
		[_theDelegate gotStatus:retValue];
	}
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error
{
	if(firstQuery != request)
	{
		[self.theMessages release];
		NSLog(@"Error(%d) %@", error.code, error.localizedDescription);
		[_theDelegate gotStatus:nil];
	}
}

@end
