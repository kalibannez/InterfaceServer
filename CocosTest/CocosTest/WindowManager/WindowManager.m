//
//  WindowManager.m
//  CocosTest
//
//  Created by Alexander Perepelitsyn on 17.11.12.
//  kalibannez@gmail.com
//

#import "WindowManager.h"
#import "InterfaceServer.h"

@implementation WindowManager

static WindowManager *_instance = nil;
+(WindowManager *) instance {
	if (_instance == nil) {
		_instance = [[WindowManager alloc] init];
	}
	
	return _instance;
}

-(id) init {
	if ((self = [super init])) {
		windowStack = [[NSMutableArray alloc] initWithCapacity:5];
	}
	return self;
}

-(void) addWindow:(CCNode *) win {
	NSAssert(win != nil, @"win must be not nil");
	
	[windowStack addObject:win];
	[self addChild:win];
	
	[[InterfaceServer instance] sendInfoAboutTopWindow:win];
}

-(CCNode *) activeWindow {
	if ([windowStack count] == 0) return nil;
	return [windowStack objectAtIndex:[windowStack count]-1];
}

@end
