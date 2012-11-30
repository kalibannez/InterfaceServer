//
//  InterfaceServer.h
//  CocosTest
//
//  Created by Alexander Perepelitsyn on 17.11.12.
//  kalibannez@gmail.com
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface InterfaceServer:NSObject<NSStreamDelegate> {
	NSArray *supportedFuncEncodes;
	
	BOOL isReadyToSend;
	NSMutableArray *sendingQueue;
	NSTimer *currentRunloopTimer;
}

+(InterfaceServer *) instance;

-(void) sendInfoAboutTopWindow:(CCNode *) win;

@end
