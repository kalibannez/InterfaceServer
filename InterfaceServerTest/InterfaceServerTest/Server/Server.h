//
//  Server.h
//  InterfaceServerTest
//
//  Created by kalibannez on 17.11.12.
//  Copyright (c) 2012 kalibannez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Server : NSObject<NSStreamDelegate> {
	BOOL isReadyToSend;
	NSMutableArray *sendingQueue;
	NSTimer *currentRunloopTimer;
	NSLock *lock;
}

+(Server *) instance;
-(void) addToSendingQueue:(NSString *) command;

-(void) startListening;

@end
