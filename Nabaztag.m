//
//  NabztagControl.m
//  iBunny
//
//  Created by Giacomo Tufano on 19/01/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "Nabaztag.h"

static Nabaztag *sharedNabaztag = nil;

@implementation Nabaztag

@synthesize valid;
@synthesize sleeping;
@synthesize tagTag;
@synthesize baseURI;
@synthesize streamURI;
@synthesize rabbitName;
@synthesize voices;
@synthesize tVoices;
@synthesize lastMessage;

+ (Nabaztag *)sharedInstance
{
    @synchronized(self) {
        if (sharedNabaztag == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedNabaztag;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedNabaztag == nil) {
            sharedNabaztag = [super allocWithZone:zone];
            return sharedNabaztag;  // assignment and return on first allocation
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
	if((self = [super init]))
	{
		self.valid = NO;
		return self;
	}
	else
		return nil;
}

// Build voices list
- (BOOL)getVoices
{
    // no support for voice list by the wizz.cc API
    NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"Voices" ofType:@"plist"];
    voices = [NSArray arrayWithContentsOfFile:plistPath];
    [voices retain];
    // Previous code follows...
    /*
	NSString *temp = [NSString stringWithFormat:@"%@action=9", baseURI];
	if(![self parse:temp])
		return NO;
	[voices release];
	voices = [self.tVoices sortedArrayUsingSelector:@selector(compare:)];
	[voices retain]; */    
	return YES;
}

// Check if nabaztag exists, setting baseURI with sn and token and getting the bunny name and basic informations
- (BOOL) validateBunny:(NSString *)sn:(NSString *)token
{
	self.rabbitName = nil;
	
	self.baseURI = [NSString stringWithFormat:kAPIBaseURI, sn, token];
    self.streamURI = [NSString stringWithString:self.baseURI];
	// get name
    NSString *temp = [NSString stringWithFormat:@"%@action=10", baseURI];
    if([self parse:temp] && rabbitName)
        self.valid = YES;
    else
    {
        self.valid = NO;
        return NO;
    }
    // is Sleeping?
    temp = [NSString stringWithFormat:@"%@action=7", baseURI];
    if(![self parse:temp])
        return NO;
    // is a Nabaztag/tag?
    temp = [NSString stringWithFormat:@"%@action=8", baseURI];
    if(![self parse:temp])
        return NO;
	return self.valid;
}

// Send bunny to sleep
// if successful returns YES and lastMessage == COMMANDSENT
- (BOOL)sleep
{
	NSString *temp = [NSString stringWithFormat:@"%@action=13", baseURI];
	if(![self parse:temp])
		return NO;
	return YES;
}

// Awake bunny
// if successful returns YES and lastMessage == COMMANDSENT
- (BOOL)awake
{
	NSString *temp = [NSString stringWithFormat:@"%@action=14", baseURI];
	if(![self parse:temp])
		return NO;
	return YES;
}

// Send message msg with voice voice
// if successful returns YES and lastMessage == TTSSENT
- (BOOL)sendMessage:(NSString *)msg withVoice:(NSString *)voice
{
	NSString *temp = [NSString stringWithFormat:@"%@tts=%@.&ws_acapela=%@", baseURI, [msg stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], voice];
	NSLog(@"About to send: %@", temp);
	if(![self parse:temp])
		return NO;
	return YES;
}

// Send ear position
// if successful returns YES and lastMessage == EARPOSITIONSENT
- (BOOL)setEar:(int)left:(int)right
{
	NSString *temp = [NSString stringWithFormat:@"%@posleft=%d&posright=%d&ears=ok", baseURI, left, right];
	DLog(@"About to send: %@", temp);
	if(![self parse:temp])
		return NO;
	return YES;
}

// start radio (mp3link)
// if successful returns YES and lastMessage == WEBRADIOSENT
- (BOOL)startRadio:(NSString *)url
{
	NSString *temp = [NSString stringWithFormat:@"%@urlList=%@", streamURI, [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSLog(@"About to send: %@", temp);
	if(![self parse:temp])
		return NO;
	return YES;
}

// Stop radio
// if successful returns YES and lastMessage == EARPOSITIONSENT
// This is an hack... to stop the webradio, we move the ears to 0:0
- (BOOL)stopRadio
{
	DLog(@"Sending ear move to stop radio");
	return [self setEar:0 :0];
}

// Get info
// returns YES if xml parsing succeeds, NO otherwise
- (BOOL) parse:(NSString *)urlString
{
	NSURL *url;
	DLog(@"Parser initing with URL: %@", urlString);
	url = [NSURL URLWithString:urlString];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url 
												cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
											timeoutInterval:30];
	NSData *xmlData;
	NSURLResponse *response;
	NSError *error;
    
	xmlData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
	DLog(@"xmlData: %@", xmlData);
	if(!xmlData)
	{
		DLog(@"Error reading URL: %@", [url absoluteString]);
		return NO;
	}
    // Protect from wizz.cc returning server name at the beginning of the flux.
    // ie: extract raw xml from answer
    NSData *extraneousData = [@"<?" dataUsingEncoding:NSUTF8StringEncoding];
    NSRange lookingIn;
    lookingIn.location = 0;
    lookingIn.length = [xmlData length];
    NSRange dataFound = [xmlData rangeOfData:extraneousData options:0 range:lookingIn];
    // If found, cut the data
    if(dataFound.location != NSNotFound)
    {
        dataFound.length = [xmlData length] - dataFound.location;
        xmlData = [xmlData subdataWithRange:dataFound];
    }
    if (addressParser) // addressParser is an NSXMLParser instance variable
        [addressParser release];
	addressParser = [[NSXMLParser alloc] initWithData:xmlData];
	[addressParser setDelegate:self];
    [addressParser setShouldResolveExternalEntities:YES];
    if([addressParser parse])
		return YES;
	else
		return NO;
}

// NSXMLParser delegates

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
//	DLog(@"Element Start: %@", elementName);

    if ([elementName isEqualToString:@"voiceListTTS"])
	{
		if (!tVoices)
			tVoices = [[NSMutableArray alloc] init];
        return;
    }
	
	// Voices (and languages) are in attributes
	if ([elementName isEqualToString:@"voice"])
	{
//		DLog(@"Voice %@ for lang: %@", [attributeDict objectForKey:@"command"], [attributeDict objectForKey:@"lang"]);
		NSString *temp = [attributeDict objectForKey:@"command"];
		if([tVoices indexOfObject:temp] == NSNotFound)
			[tVoices addObject:temp];
		return;
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	DLog(@"Data: %@", string);
    if (!currentStringValue)
        // currentStringValue is an NSMutableString instance variable
        currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
    [currentStringValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
//	DLog(@"Element End: %@", elementName);
    if ([elementName isEqualToString:@"rabbitName"] )
	{
		self.rabbitName = currentStringValue;
		DLog(@"Rabbit Name: %@", currentStringValue);
    }

    if ([elementName isEqualToString:@"rabbitSleep"] )
	{
		DLog(@"rabbitSleep is %@", currentStringValue);
		if([currentStringValue isEqualToString:@"YES"])
			self.sleeping = YES;
		else
			self.sleeping = NO;
    }

	if ([elementName isEqualToString:@"rabbitVersion"] )
	{
		DLog(@"rabbitVersion is %@", currentStringValue);
		if([currentStringValue isEqualToString:@"V2"])
			self.tagTag = YES;
		else
			self.tagTag = NO;
    }
	
	// preserve last message
	if([elementName isEqualToString:@"message"])
	{
		DLog(@"Got message: %@", currentStringValue);
		self.lastMessage = currentStringValue;
	}
	
    // reset currentStringValue for the next cycle
    [currentStringValue release];
    currentStringValue = nil;
}

@end
