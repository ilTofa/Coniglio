//
//  Nabaztag.h
//  iBunny
//
//  Created by Giacomo Tufano on 19/01/09.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

#define kAPIBaseURI @"http://api.wizz.cc/?sn=%@&token=%@&"

@interface Nabaztag : NSObject <NSXMLParserDelegate>
{
	NSString *baseURI;
	NSString *streamURI;
	BOOL valid, sleeping, tagTag;
	NSString *rabbitName, *lastMessage;
	NSArray *voices;

	// not properties, used by the NSXMLPartners and its delegates
	NSMutableArray * tVoices;
	
	NSXMLParser *addressParser;
	NSMutableString *currentStringValue;
}

@property (nonatomic, getter=isValid) BOOL valid;
@property (nonatomic, getter=isTagTag) BOOL tagTag;
@property (nonatomic, getter=isSleeping) BOOL sleeping;
@property(nonatomic, copy) NSString *baseURI;
@property(nonatomic, copy) NSString *streamURI;
@property(nonatomic, copy) NSString *rabbitName;
@property(nonatomic, copy) NSString *lastMessage;
@property(nonatomic, copy) NSArray *voices;
@property(nonatomic, copy) NSMutableArray *tVoices;

+ (Nabaztag *)sharedInstance;

// Methods
- (BOOL) validateBunny:(NSString *)sn:(NSString *)token;
- (BOOL) getVoices;
- (BOOL) sleep;
- (BOOL) awake;
- (BOOL)sendMessage:(NSString *)msg withVoice:(NSString *)voice;
- (BOOL) setEar:(int)left:(int)right;
- (BOOL) startRadio:(NSString *)url;
- (BOOL) stopRadio;

// XML parser init and run
- (BOOL) parse:(NSString *)urlString;

// XML parser delegates
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;

@end
