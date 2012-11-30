//
//  WindowManager.h
//  CocosTest
//
//  Created by Alexander Perepelitsyn on 17.11.12.
//  kalibannez@gmail.com
//

#import "CCNode.h"

@interface WindowManager : CCNode {
	NSMutableArray *windowStack;
}


+(WindowManager *) instance;

-(void) addWindow:(CCNode *) win;
-(CCNode *) activeWindow;

@end
