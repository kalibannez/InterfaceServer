//
//  HelloWorldLayer.m
//  CocosTest
//
//  Created by Alexander Perepelitsyn on 17.11.12.
//  kalibannez@gmail.com
//

#import "HelloWorldLayer.h"
#import "WindowManager.h"

@implementation HelloWorldLayer

+(CCScene *) scene {
	CCScene *scene = [CCScene node];
	
	[scene addChild:[WindowManager instance]];
	
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	[[WindowManager instance] addWindow:layer];
	
	return scene;
}

-(id) init {
	if( (self=[super init])) {
		CCLabelBMFont *label = [CCLabelBMFont labelWithString:@"Hello World!" fntFile:@"Tahoma40.fnt"];
		CGSize size = [[CCDirector sharedDirector] winSize];
		label.position =  ccp( size.width /2 , size.height/2 );
		
		CCSprite *sprite = [CCSprite spriteWithFile:@"fps_images.png"];
		[sprite setPosition:ccp(100, 100)];
		[self addChild:sprite];
		
		[self addChild: label];
	}
	return self;
}

- (void) dealloc {
	[super dealloc];
}
@end
