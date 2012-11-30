//
//  Server.m
//  InterfaceServerTest
//
//  Created by kalibannez on 17.11.12.
//  Copyright (c) 2012 kalibannez. All rights reserved.
//

#import "Server.h"
#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#import "AppDelegate.h"

static NSInputStream *iStream;
static NSOutputStream *oStream;

@implementation Server

static Server *_instance = nil;
+(Server *) instance {
	if (_instance == nil) {
		_instance = [[Server alloc] init];
	}
	return _instance;
}

-(id) init {
	if ((self = [super init])) {
		sendingQueue = [[NSMutableArray alloc] init];
		lock = [[NSLock alloc] init];
		isReadyToSend = NO;
		currentRunloopTimer = nil;
	}
	
	return self;
}

void sockCallback(CFSocketRef h, CFSocketCallBackType g, CFDataRef s,const void *data, void *info) {
	CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
	
    CFSocketNativeHandle sock = *(CFSocketNativeHandle *) data;
	
	CFStreamCreatePairWithSocket(kCFAllocatorDefault, sock, &readStream, &writeStream);
	
    if (!readStream || !writeStream) {
        close(sock);
        fprintf(stderr, "CFStreamCreatePairWithSocket() failed\n");
        return;
    }
	
	if (readStream && writeStream) {
		iStream = (NSInputStream *)readStream;
		[iStream retain];
		[iStream retain];
		[iStream setDelegate:[Server instance]];
		[iStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[iStream open];
		
		oStream = (NSOutputStream *)writeStream;
		[oStream retain];
		[oStream setDelegate:[Server instance]];
		[oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[oStream open];
		
		if (iStream && oStream) NSLog(@"Connection success!");
		else NSLog(@"ERROR: connection failed!");
	}
	if (readStream) CFRelease(readStream);
	if (writeStream) CFRelease(writeStream);
}


-(void) startListening {
	char punchline[] = "To get to the other side! Ha ha!\n\r";
	CFSocketContext context = { 0, punchline, NULL, NULL, NULL };
	CFSocketRef myipv4cfsock = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack	, sockCallback, &context);
	
	int yes = 1;
    setsockopt(CFSocketGetNative(myipv4cfsock), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
	
	struct sockaddr_in sin;
	
	memset(&sin, 0, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET;
	sin.sin_port = htons(46116);
	sin.sin_addr.s_addr= htonl(INADDR_ANY);
	
	NSData *addressData = [NSData dataWithBytes:&sin length:sizeof(sin)];
	
	if (kCFSocketSuccess != CFSocketSetAddress(myipv4cfsock, (CFDataRef)addressData)) {
		NSLog(@"Socket not gained address");
		exit(0);
	}
	
	CFRunLoopRef cfrl = CFRunLoopGetCurrent();
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, myipv4cfsock, 0);
    CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
	
	if (!CFSocketIsValid(myipv4cfsock)) {
		NSLog(@"Binding to socket failed");
		exit(0);
	}
	
	NSLog(@"Binded");
	
	CFRunLoopRun();
	
	while(1) {
        struct timeval tv;
        tv.tv_usec = 0;
        tv.tv_sec = 1;
        select(-1, NULL, NULL, NULL, &tv);
    }
}

-(void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
	switch((int)eventCode) {
		case NSStreamEventOpenCompleted: {
			if(stream == oStream) {
				if (currentRunloopTimer) [currentRunloopTimer invalidate];
				currentRunloopTimer = [NSTimer scheduledTimerWithTimeInterval:1/60.f target:self selector:@selector(runloop) userInfo:nil repeats:YES];
			}
			
			break;
		}
			
		case NSStreamEventHasSpaceAvailable: {
			isReadyToSend = YES;
			break;
		}
		case NSStreamEventHasBytesAvailable: {
			[self parseInputCommand];
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
	int32_t messageSize;
	if ([iStream read:(uint8_t *)&messageSize maxLength:sizeof(messageSize)] != sizeof(messageSize)) {
		NSLog(@"Error in reading message size");
		return;
	}
	
	static uint8_t message[5000];
	memset(message, 0, sizeof(message));
	NSInteger readed = [iStream read:(uint8_t *)&message maxLength:messageSize];
	if (readed != messageSize) {
		NSLog(@"Error in reading message data");
	}
	
	NSString *command = [[[NSString alloc] initWithBytes:message length:messageSize encoding:NSUTF8StringEncoding] autorelease];
	
	NSArray *commandParts = [command componentsSeparatedByString:@"==="];
	if ([commandParts count] == 2) {
		NSString *commandName = [commandParts objectAtIndex:0];
		NSString *commandContent = [commandParts objectAtIndex:1];
		if ([commandName isEqualToString:@"NewWindowContent"]) {
			[[AppDelegate instance] performSelectorOnMainThread:@selector(displayWindowContent:) withObject:commandContent waitUntilDone:NO];
		}
		if ([commandName isEqualToString:@"ListObjectMethods"]) {
			[[AppDelegate instance] performSelectorOnMainThread:@selector(displayObjectMethods:) withObject:commandContent waitUntilDone:NO];
		}
	}
}

-(void) addToSendingQueue:(NSString *) command {
	[lock lock];
	NSData *commandData = [command dataUsingEncoding:NSUTF8StringEncoding];
	int32_t commandDataLength = (int32_t)[commandData length];
	NSMutableData *mutablecommandData = [NSMutableData dataWithCapacity:[commandData length]+sizeof(commandDataLength)];
	[mutablecommandData appendBytes:&commandDataLength length:sizeof(commandDataLength)];
	[mutablecommandData appendBytes:[commandData bytes] length:[commandData length]];
	
	[sendingQueue addObject:mutablecommandData];
	
	[lock unlock];
}

- (void) runloop {
	if (isReadyToSend == YES && [lock tryLock] && [sendingQueue count] > 0) {
		isReadyToSend = NO;
		
		NSData *dataForSend = [sendingQueue objectAtIndex:0];
		[oStream write:(uint8_t *)[dataForSend bytes] maxLength:[dataForSend length]];
		[sendingQueue removeObjectAtIndex:0];
	}
	[lock unlock];
}

@end
