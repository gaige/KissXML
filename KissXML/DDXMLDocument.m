#import "DDXMLPrivate.h"
#import "NSString+DDXML.h"
#import <libxml/parser.h>

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/**
 * Welcome to KissXML.
 * 
 * The project page has documentation if you have questions.
 * https://github.com/robbiehanson/KissXML
 * 
 * If you're new to the project you may wish to read the "Getting Started" wiki.
 * https://github.com/robbiehanson/KissXML/wiki/GettingStarted
 * 
 * KissXML provides a drop-in replacement for Apple's NSXML class cluster.
 * The goal is to get the exact same behavior as the NSXML classes.
 * 
 * For API Reference, see Apple's excellent documentation,
 * either via Xcode's Mac OS X documentation, or via the web:
 * 
 * https://github.com/robbiehanson/KissXML/wiki/Reference
**/

@implementation DDXMLDocument

/**
 * Returns a DDXML wrapper object for the given primitive node.
 * The given node MUST be non-NULL and of the proper type.
**/
+ (instancetype)nodeWithDocPrimitive:(xmlDocPtr)doc owner:(DDXMLNode *)owner
{
	return [[DDXMLDocument alloc] initWithDocPrimitive:doc owner:owner];
}

- (instancetype)initWithDocPrimitive:(xmlDocPtr)doc owner:(DDXMLNode *)inOwner
{
	self = [super initWithPrimitive:(xmlKindPtr)doc owner:inOwner];
	return self;
}

+ (instancetype)nodeWithPrimitive:(xmlKindPtr)kindPtr owner:(DDXMLNode *)owner
{
#pragma unused(kindPtr,owner)
	// Promote initializers which use proper parameter types to enable compiler to catch more mistakes
	NSAssert(NO, @"Use nodeWithDocPrimitive:owner:");
	
	return nil;
}

- (instancetype)initWithPrimitive:(xmlKindPtr)kindPtr owner:(DDXMLNode *)inOwner
{
#pragma unused(kindPtr,inOwner)
	// Promote initializers which use proper parameter types to enable compiler to catch more mistakes.
	NSAssert(NO, @"Use initWithDocPrimitive:owner:");
	
	return nil;
}

- (instancetype)initWithRootElement:(DDXMLElement *)element
{
	xmlDocPtr doc = xmlNewDoc(BAD_CAST "1.0");
	if((self = [self initWithDocPrimitive: doc owner:nil])) {
		if(element) {
			[self setRootElement:element];
		}
    }
	
	return self;
}

/**
 * Initializes and returns a DDXMLDocument object created from an NSData object.
 * 
 * Returns an initialized DDXMLDocument object, or nil if initialization fails
 * because of parsing errors or other reasons.
**/
- (instancetype)initWithXMLString:(NSString *)string options:(NSUInteger)mask error:(NSError **)error
{
	return [self initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
	                  options:mask
	                    error:error];
}

/**
 * Initializes and returns a DDXMLDocument object created from an NSData object.
 * 
 * Returns an initialized DDXMLDocument object, or nil if initialization fails
 * because of parsing errors or other reasons.
**/
- (instancetype)initWithData:(NSData *)data options:(NSUInteger)mask error:(NSError **)error
{
#pragma unused(mask)
	if (data == nil || [data length] == 0)
	{
		if (error) *error = [NSError errorWithDomain:@"DDXMLErrorDomain" code:0 userInfo:nil];
		
		return nil;
	}
	
	// Even though xmlKeepBlanksDefault(0) is called in DDXMLNode's initialize method,
	// it has been documented that this call seems to get reset on the iPhone:
	// http://code.google.com/p/kissxml/issues/detail?id=8
	// 
	// Therefore, we call it again here just to be safe.
	xmlKeepBlanksDefault(0);
	
	xmlDocPtr doc = xmlParseMemory([data bytes], (int)[data length]);
	if (doc == NULL)
	{
		if (error) *error = [NSError errorWithDomain:@"DDXMLErrorDomain" code:1 userInfo:nil];
		
		return nil;
	}
	
	return [self initWithDocPrimitive:doc owner:nil];
}

/**
 * Returns the root element of the receiver.
**/
- (DDXMLElement *)rootElement
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	xmlDocPtr doc = (xmlDocPtr)self->genericPtr;
	
	// doc->children is a list containing possibly comments, DTDs, etc...
	
	xmlNodePtr rootNode = xmlDocGetRootElement(doc);
	
	if (rootNode != NULL)
		return [DDXMLElement nodeWithElementPrimitive:rootNode owner:self];
	else
		return nil;
}

- (void)setRootElement:(DDXMLNode *)root
{
	xmlDocPtr doc = (xmlDocPtr)genericPtr;
    xmlNodePtr copyRootPtr = xmlCopyNode((xmlNodePtr)root->genericPtr, 1);
    
	xmlDocSetRootElement(doc, (xmlNodePtr)copyRootPtr);
}

- (NSData *)XMLData
{
	// Zombie test occurs in XMLString
	
	return [[self XMLString] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)XMLDataWithOptions:(NSUInteger)options
{
	// Zombie test occurs in XMLString
	
	return [[self XMLStringWithOptions:options] dataUsingEncoding:NSUTF8StringEncoding];
}

- (instancetype)initWithContentsOfURL:(NSURL*)url options:(NSUInteger)mask error:(NSError**)errorPtr
{
#pragma unused(mask)
	if (!url) {
		NSError *error=[NSError errorWithDomain: @"DDXMLErrorDomain" code:0 userInfo:nil];
		if (errorPtr)
			*errorPtr=error;
		return nil;
	}
	if (![url isFileURL]) {
		// EEK!
		NSLog(@"Need file URL");
		NSError *error=[NSError errorWithDomain: @"DDXMLErrorDomain" code:0 userInfo:nil];
		if (errorPtr)
			*errorPtr=error;
		return nil;
	}
	
	NSString *path = [url path];
	xmlKeepBlanksDefault( 0);	// see initWithData:options:error:
	xmlDocPtr doc= xmlParseFile( [path cStringUsingEncoding:NSUTF8StringEncoding]);
    
	if(doc == NULL)
	{
		if(errorPtr)
			*errorPtr = [NSError errorWithDomain:@"DDXMLErrorDomain" code:1 userInfo:nil];
		
		return nil;
	}
	
	self= [self initWithDocPrimitive: doc owner:nil];
	if (!self) {
		if (errorPtr)
			*errorPtr = [NSError errorWithDomain:@"DDXMLErrorDomain" code:1 userInfo:nil];
	}
	
	return self;
}


@end
