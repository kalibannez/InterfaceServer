//
//  InterfaceServer.m
//  CocosTest
//
//  Created by Alexander Perepelitsyn on 17.11.12.
//  kalibannez@gmail.com
//

#import "InterfaceServer.h"
#import <objc/runtime.h>
#import <objc/objc.h>
#import <objc/objc-class.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "WindowManager.h"

static NSInputStream *iStream;
static NSOutputStream *oStream;

@implementation InterfaceServer

static InterfaceServer *_instance;

+(InterfaceServer *) instance {
	if (_instance == nil) {
		_instance = [[InterfaceServer alloc] init];
	}
	
	return _instance;
}

-(id) init {
	if ((self = [super init])) {
		supportedFuncEncodes = [[NSArray arrayWithObjects:@"v32@0:8{CGPoint=dd}16", @"v20@0:8f16", @"v20@0:8c16", @"v24@0:8@16", nil] retain];
		isReadyToSend = NO;
		currentRunloopTimer = nil;
		sendingQueue = [[NSMutableArray alloc] init];
		[self connectToServer];
	}
	return self;
}

#pragma mark -
#pragma mark Server routine

-(void) connectToServer {
	CFReadStreamRef readStream = NULL;
	CFWriteStreamRef writeStream = NULL;
	CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (CFStringRef)@"localhost", 46116, &readStream, &writeStream);
	if (readStream && writeStream) {
		iStream = (NSInputStream *)readStream;
		[iStream retain];
		[iStream setDelegate:self];
		[iStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[iStream open];
		
		oStream = (NSOutputStream *)writeStream;
		[oStream retain];
		[oStream setDelegate:self];
		[oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[oStream open];
	}
	if (readStream) CFRelease(readStream);
	if (writeStream) CFRelease(writeStream);
}

- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
	switch((int)eventCode) {
		case NSStreamEventOpenCompleted: {
			if(stream == oStream) {
				if (currentRunloopTimer) [currentRunloopTimer invalidate];
				currentRunloopTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(runloop) userInfo:nil repeats:YES];
			}
			break;
		}
			
		case NSStreamEventHasSpaceAvailable: {
			isReadyToSend = YES;
			break;
		}
		case NSStreamEventHasBytesAvailable: {
			[self performSelectorOnMainThread:@selector(parseInputCommand) withObject:nil waitUntilDone:YES];
			break;
		}
		case NSStreamEventEndEncountered: {
			if (currentRunloopTimer) {
				[currentRunloopTimer invalidate];
				currentRunloopTimer = nil;
			}
			break;
		}
	}
}

-(void) parseInputCommand {
	int32_t messageSize = 0;
	if ([iStream read:(uint8_t *)&messageSize maxLength:sizeof(messageSize)] != sizeof(messageSize)) {
		NSLog(@"Error in reading message size");
	}
	
	static uint8_t message[5000];
	memset(message, 0, sizeof(message));
	NSInteger readed = [iStream read:(uint8_t *)&message maxLength:messageSize];
	if (readed != messageSize) {
		NSLog(@"Error in reading message data");
		return;
	}
	
	NSString *command = [[[NSString alloc] initWithBytes:message length:messageSize encoding:NSUTF8StringEncoding] autorelease];
	
	NSArray *commandParts = [command componentsSeparatedByString:@"==="];
	if ([commandParts count] == 2) {
		NSString *commandName = [commandParts objectAtIndex:0];
		NSString *commandContent = [commandParts objectAtIndex:1];
		if ([commandName isEqualToString:@"ListObjectMethods"]) {
			[self sendObjectMethods:commandContent];
		}
		if ([commandName isEqualToString:@"UpdateObject"]) {
			[self updateObject:commandContent];
		}
	}
}

- (void) runloop {
	if (isReadyToSend == YES && [sendingQueue count] > 0) {
		isReadyToSend = NO;
		
		NSData *dataForSend = [sendingQueue objectAtIndex:0];
		NSUInteger bytesSended = [oStream write:(uint8_t *)[dataForSend bytes] maxLength:[dataForSend length]];
		NSLog(@"bytesSended = %ld", bytesSended);
		[sendingQueue removeObjectAtIndex:0];
	}
}

#pragma mark -
#pragma mark Logic

-(NSMutableArray *) enumAllSupportedMethodsAndDefaultParams:(NSObject *) object {
	NSMutableArray *methods = [NSMutableArray array];
	
	Class curClass = [object class];
	while(curClass != [NSObject class]) {
		unsigned int numMethods;
		Method *methodsList = class_copyMethodList(curClass, &numMethods);
		
		for (int i = 0; i < numMethods; i++) {
			if ([supportedFuncEncodes containsObject:[NSString stringWithFormat:@"%s", method_getTypeEncoding(methodsList[i])]]) {
				NSLog(@"SUPPORTED = %@, %s", NSStringFromSelector(method_getName(methodsList[i])), method_getTypeEncoding(methodsList[i]));
				NSString *methodSignature = [NSString stringWithFormat:@"%s", method_getTypeEncoding(methodsList[i])];
				NSString *methodName = NSStringFromSelector(method_getName(methodsList[i]));
				NSMutableString *methodDescription = [NSMutableString stringWithFormat:@"%@<->%@", methodName, methodSignature];
				
				NSRange setterRange = [methodName rangeOfString:@"set"];
				if (setterRange.location == 0 && setterRange.length == 3) {
					NSString *firstCharOfGetter = [NSString stringWithFormat:@"%c", [methodName characterAtIndex:setterRange.length]];
					NSMutableString *getterName = [NSMutableString stringWithFormat:@"%@%@", [firstCharOfGetter lowercaseString], [methodName substringFromIndex:setterRange.length+1]];
					[getterName deleteCharactersInRange:NSMakeRange([getterName length]-1, 1)];
					
					SEL getterSelector = NSSelectorFromString(getterName);
				
					if ([methodSignature isEqualToString:@"v32@0:8{CGPoint=dd}16"]) {
						if ([object respondsToSelector:getterSelector]) {
							typedef CGPoint (*func)(id, SEL);
							func imp = (func)[object methodForSelector:getterSelector];
							CGPoint p = imp(object, getterSelector);
							
							[methodDescription appendFormat:@":::%f___%f", p.x, p.y];
						}
					}
					if ([methodSignature isEqualToString:@"v20@0:8c16"]) {
						if ([object respondsToSelector:getterSelector]) {
							typedef BOOL (*func)(id, SEL);
							func imp = (func)[object methodForSelector:getterSelector];
							BOOL b = imp(object, getterSelector);
							
							[methodDescription appendFormat:@":::%d", b];
						}
					}
					if ([methodSignature isEqualToString:@"v20@0:8f16"]) {
						if ([object respondsToSelector:getterSelector]) {
							typedef float (*func)(id, SEL);
							func imp = (func)[object methodForSelector:getterSelector];
							float f = imp(object, getterSelector);
							
							[methodDescription appendFormat:@":::%f", f];
						}
					}
					if ([methodSignature isEqualToString:@"v24@0:8@16"]) {
						if ([object respondsToSelector:getterSelector]) {
							typedef NSObject *(*func)(id, SEL);
							func imp = (func)[object methodForSelector:getterSelector];
							NSObject *o = imp(object, getterSelector);
							
							[methodDescription appendFormat:@":::%@", o];
						}
					}
				}
				
				[methods addObject:methodDescription];
			}
		}
		curClass = [curClass superclass];
	}
		
	return methods;
}

-(void) addToSendingQueue:(NSString *) command {
	NSData *commandData = [command dataUsingEncoding:NSUTF8StringEncoding];
	int32_t commandDataLength = (int32_t)[commandData length];
	NSMutableData *mutablecommandData = [NSMutableData dataWithCapacity:[commandData length]+sizeof(commandDataLength)];
	[mutablecommandData appendBytes:&commandDataLength length:sizeof(commandDataLength)];
	[mutablecommandData appendBytes:[commandData bytes] length:[commandData length]];
	
	[sendingQueue addObject:mutablecommandData];
}

-(void) sendInfoAboutTopWindow:(CCNode *) win {
	CCNode *child;
	
	NSMutableString *command = [NSMutableString string];
	[command appendString:@"NewWindowContent==="];
	CCARRAY_FOREACH([win children], child) {
		[command appendFormat:@"%@<->%d|||", [child className], (int)child];
	}
	[self addToSendingQueue:command];
}

-(void) sendObjectMethods:(NSString *) commandContent {
	NSArray *commandParts = [commandContent componentsSeparatedByString:@"<->"];
	if ([commandParts count] != 2) {
		NSLog(@"Error: wrong argument %@", commandContent);
		return;
	}
	
	NSString *objClass = [commandParts objectAtIndex:0];
	int objAddress = [[commandParts objectAtIndex:1] intValue];
	
	CCNode *activeWindow = [[WindowManager instance] activeWindow];
	CCNode *child;
	CCNode *searchingObject = nil;
	CCARRAY_FOREACH([activeWindow children], child) {
		if ((int)child == objAddress && [[child className] isEqualToString:objClass]) {
			searchingObject = child;
		}
	}
	
	if (searchingObject == nil) {
		NSLog(@"Object %@ don't found in active window", commandContent);
		return;
	}
	
	NSMutableArray *supportedMethodsAndDefaultParams = [self enumAllSupportedMethodsAndDefaultParams:searchingObject];
	NSMutableString *command = [NSMutableString string];
	[command appendString:@"ListObjectMethods==="];
	for(NSString *m in supportedMethodsAndDefaultParams) {
		[command appendFormat:@"%@|||", m];
	}
	
	[self addToSendingQueue:command];
}

-(void) updateObject:(NSString *) commandContent {
	NSArray *commandParts = [commandContent componentsSeparatedByString:@"<-->"];
	if ([commandParts count] != 3) {
		NSLog(@"Error: wrong argument %@", commandContent);
		return;
	}
	
	NSString *objInfo = [commandParts objectAtIndex:0];
	NSString *updatedMethod = [commandParts objectAtIndex:1];
	NSString *arguments = [commandParts objectAtIndex:2];
	
	NSArray *objInfoParts = [objInfo componentsSeparatedByString:@"<->"];
	if ([objInfoParts count] != 2) return;
	NSString *objClass = [objInfoParts objectAtIndex:0];
	int objAddress = [[objInfoParts objectAtIndex:1] intValue];
	
	CCNode *activeWindow = [[WindowManager instance] activeWindow];
	CCNode *child;
	CCNode *searchingObject = nil;
	CCARRAY_FOREACH([activeWindow children], child) {
		if ((int)child == objAddress && [[child className] isEqualToString:objClass]) {
			searchingObject = child;
		}
	}
	
	if (searchingObject == nil) {
		NSLog(@"Object %@ don't found in active window", commandContent);
		return;
	}
	
	NSArray *methodParts = [updatedMethod componentsSeparatedByString:@"<->"];
	if ([methodParts count] != 2) {
		NSLog(@"updatedMethod wrong");
		return;
	}
	NSString *updatedSelectorName = [methodParts objectAtIndex:0];
	NSString *updatedSelectoSignature = [methodParts objectAtIndex:1];
	SEL updatedSelector = NSSelectorFromString(updatedSelectorName);
	
	if ([updatedSelectoSignature isEqualToString:@"v32@0:8{CGPoint=dd}16"]) {
		CGPoint arg = CCPointFromString(arguments);
		IMP imp = [searchingObject methodForSelector:updatedSelector];
		imp(searchingObject, updatedSelector, arg);
		return;
	}
	
	if ([updatedSelectoSignature isEqualToString:@"v20@0:8c16"]) {
		int arg = [arguments intValue];
		IMP imp = [searchingObject methodForSelector:updatedSelector];
		imp(searchingObject, updatedSelector, arg);
		return;
	}
	
	if ([updatedSelectoSignature isEqualToString:@"v20@0:8f16"]) {
		float arg = [arguments floatValue];
		typedef id (*func)(id, SEL, float);
		func imp = (func)[searchingObject methodForSelector:updatedSelector];
		imp(searchingObject, updatedSelector, arg);
		return;
	}
	
	if ([updatedSelectoSignature isEqualToString:@"v24@0:8@16"]) {
		typedef id (*func)(id, SEL, NSString *);
		func imp = (func)[searchingObject methodForSelector:updatedSelector];
		imp(searchingObject, updatedSelector, arguments);
		return;
	}
}

@end
