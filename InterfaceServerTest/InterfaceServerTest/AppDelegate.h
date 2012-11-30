//
//  AppDelegate.h
//  InterfaceServerTest
//
//  Created by kalibannez on 17.11.12.
//  Copyright (c) 2012 kalibannez. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate> {
	NSSet *unsupportedMethods;
	NSMutableArray *methodsArr;
	NSMutableArray *controlsList;
	
	NSMutableArray *windowObjectsList;
}

+(AppDelegate *) instance;

-(void) displayWindowContent:(NSString *) windowObjects;
-(void) displayObjectMethods:(NSString *) objectMethods;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *windowObjectsList;
@property (assign) IBOutlet NSScrollView *windowObjectMethodsList;

@end
