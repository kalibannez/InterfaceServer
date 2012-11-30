//
//  AppDelegate.m
//  InterfaceServerTest
//
//  Created by kalibannez on 17.11.12.
//  Copyright (c) 2012 kalibannez. All rights reserved.
//

#import "AppDelegate.h"
#import "Server.h"

@implementation AppDelegate

@synthesize window=_window;
@synthesize windowObjectsList=_windowObjectsList;
@synthesize windowObjectMethodsList=_windowObjectMethodsList;

AppDelegate *_instance = nil;
+(AppDelegate *) instance {
	return _instance;
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
	_instance = self;
	unsupportedMethods = [[NSSet setWithObjects:@"setTextureAtlas:<->v24@0:8@16",
						  @"setTexture:<->v24@0:8@16",
						  @"setVertexZ:<->v20@0:8f16",
						  @"setDisplayFrame:<->v24@0:8@16",
						  @"setDirtyRecursively:<->v20@0:8c16",
						  @"setShaderProgram:<->v24@0:8@16",
						  @"setParent:<->v24@0:8@16",
						  @"setOpacityModifyRGB:<->v20@0:8c16",
						  @"removeFromParentAndCleanup:<->v20@0:8c16",
						  @"stopAction:<->v24@0:8@16",
						  @"setDirty:<->v20@0:8c16",
						  @"setBatchNode:<->v24@0:8@16",
						  @"setGrid:<->v24@0:8@16",
						  @"removeSpriteFromAtlas:<->v24@0:8@16",
					      @"removeAllChildrenWithCleanup:<->v20@0:8c16",
						  @"addChild:<->v24@0:8@16", nil] retain];
	methodsArr = [[NSMutableArray alloc] initWithCapacity:20];
	controlsList = [[NSMutableArray alloc] initWithCapacity:20];
	windowObjectsList = [[NSMutableArray alloc] initWithCapacity:20];
	self.windowObjectsList.dataSource = self;
	self.windowObjectsList.delegate = self;
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(tableViewSelectionDidChange:)
												 name: NSTableViewSelectionDidChangeNotification
											   object: windowObjectsList];
	[[Server instance] performSelectorInBackground:NSSelectorFromString(@"startListening") withObject:nil];
}

-(NSBox *) makeBoolControl:(NSString *) methodName numberOfControl:(NSInteger) numberOfControl arg:(BOOL) arg {
	NSBox *groupBox = [[[NSBox alloc] initWithFrame:NSMakeRect(5, 0, 450, 50)] autorelease];
	[groupBox setTitle:methodName];
	
	NSButton *checkbox = [[[NSButton alloc] initWithFrame:NSMakeRect(20, 5, 100, 20)] autorelease];
	[groupBox addSubview:checkbox];
	[checkbox setTag:numberOfControl];
	[checkbox setButtonType:NSSwitchButton];
	[checkbox setBezelStyle:0];
	[checkbox setTitle:@"Enabled"];
	[checkbox setTarget:self];
	if (arg == YES) {
		[checkbox setState:NSOnState];
	}
	[checkbox setAction:@selector(action:)];
	
	[controlsList addObject:checkbox];
	
	return groupBox;
}
-(NSBox *) makeStringControl:(NSString *) methodName numberOfControl:(NSInteger) numberOfControl stringValue:(NSString *) stringValue {
	NSBox *groupBox = [[[NSBox alloc] initWithFrame:NSMakeRect(5, 0, 450, 50)] autorelease];
	[groupBox setTitle:methodName];
	
	NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(5, 5, 300, 20)];
	[groupBox addSubview:textField];
	[textField setTag:numberOfControl];
	[textField setAction:@selector(action:)];
	[textField setTarget:self];
	[textField setStringValue:stringValue];
	[controlsList addObject:textField];
	
	return groupBox;
}

-(NSBox *) makeFloatControl:(NSString *) methodName numberOfControl:(NSInteger) numberOfControl arg:(float) arg {
	NSBox *groupBox = [[[NSBox alloc] initWithFrame:NSMakeRect(5, 0, 450, 90)] autorelease];
	[groupBox setTitle:methodName];
	
	NSTextField *intervalLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(5, 35, 70, 20)];
	[intervalLabel setStringValue:@"Интервал: "];
	[intervalLabel setEditable:NO];
    [intervalLabel setSelectable:NO];
	[intervalLabel setDrawsBackground:NO];
	[intervalLabel setBezeled:NO];
	[groupBox addSubview:intervalLabel];
	
	NSInteger intervalValue = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"INTERVAL%@", methodName]];
	
	NSTextField *intervalEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(100, 35, 50, 20)];
	[intervalEdit setStringValue:[NSString stringWithFormat:@"%ld", intervalValue]];
	[intervalEdit setAction:@selector(intervalChanged:)];
	[intervalEdit setTarget:self];
	[intervalEdit setTag:numberOfControl];
	[groupBox addSubview:intervalEdit];
	
	NSSlider *slider = [[NSSlider alloc] initWithFrame:NSMakeRect(5, 5, 420, 20)];
	[slider setMinValue:0];
	[slider setMaxValue:intervalValue];
	[groupBox addSubview:slider];
	[slider setAction:@selector(action:)];
	[slider setTag:numberOfControl];
	[slider setTarget:self];
	[controlsList addObject:slider];
	
	return groupBox;
}

-(NSBox *) makeCCPointControl:(NSString *) methodName numberOfControl:(NSInteger) numberOfControl arg1:(float) arg1 arg2:(float) arg2 {
	NSBox *groupBox = [[[NSBox alloc] initWithFrame:NSMakeRect(5, 0, 450, 110)] autorelease];
	[groupBox setTitle:methodName];
	
	NSTextField *intervalLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(5, 55, 70, 20)];
	[intervalLabel setStringValue:@"Интервал: "];
	[intervalLabel setEditable:NO];
    [intervalLabel setSelectable:NO];
	[intervalLabel setDrawsBackground:NO];
	[intervalLabel setBezeled:NO];
	[groupBox addSubview:intervalLabel];
	
	NSInteger intervalValue = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"INTERVAL%@", methodName]];
	
	NSTextField *intervalEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(100, 55, 50, 20)];
	[intervalEdit setStringValue:[NSString stringWithFormat:@"%ld", intervalValue]];
	[intervalEdit setAction:@selector(intervalChanged:)];
	[intervalEdit setTarget:self];
	[intervalEdit setTag:numberOfControl];
	[groupBox addSubview:intervalEdit];
	
	
	
	NSTextField *xLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(5, 30, 20, 20)];
	[xLabel setStringValue:@"x: "];
	[xLabel setEditable:NO];
    [xLabel setSelectable:NO];
	[xLabel setBezeled:NO];
	[xLabel setDrawsBackground:NO];
	[groupBox addSubview:xLabel];
	
	NSSlider *sliderX = [[NSSlider alloc] initWithFrame:NSMakeRect(40, 30, 380, 20)];
	[sliderX setMinValue:0];
	[sliderX setMaxValue:intervalValue];
	[groupBox addSubview:sliderX];
	[sliderX setAction:@selector(action:)];
	[sliderX setFloatValue:arg1];
	[sliderX setTag:numberOfControl];
	[sliderX setTarget:self];
	[controlsList addObject:sliderX];
	
	NSTextField *yLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(5, 5, 20, 20)];
	[yLabel setStringValue:@"y: "];
	[yLabel setEditable:NO];
	[yLabel setBezeled:NO];
    [yLabel setSelectable:NO];
	[yLabel setDrawsBackground:NO];
	[groupBox addSubview:yLabel];
	
	NSSlider *sliderY = [[NSSlider alloc] initWithFrame:NSMakeRect(40, 5, 380, 20)];
	[sliderY setMinValue:0];
	[sliderY setMaxValue:intervalValue];
	[groupBox addSubview:sliderY];
	[sliderY setAction:@selector(action:)];
	[sliderY setTag:numberOfControl];
	[sliderY setFloatValue:arg2];
	[sliderY setTarget:self];
	[controlsList addObject:sliderY];
	
	return groupBox;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [windowObjectsList count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return [windowObjectsList objectAtIndex:row];
}

-(void) intervalChanged:(NSTextField *) sender {
	NSInteger tag = sender.tag;
	if (tag-1 >= [methodsArr count]) return;
	NSString *selectedMethod = [methodsArr objectAtIndex:tag-1];
	
	NSArray *infoParts = [selectedMethod componentsSeparatedByString:@"<->"];
	
	if ([infoParts count] != 2) {
		return;
	}
	
	if (selectedMethod) {
		[[NSUserDefaults standardUserDefaults] setInteger:sender.intValue forKey:[NSString stringWithFormat:@"INTERVAL%@", [infoParts objectAtIndex:0]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

-(void) tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selectedRow = [self.windowObjectsList selectedRow];
	if (selectedRow >= [windowObjectsList count] || selectedRow < 0) return;
	NSString *selectedWindowObject = [windowObjectsList objectAtIndex:selectedRow];
	NSString *command = [NSString stringWithFormat:@"ListObjectMethods===%@", selectedWindowObject];
	[[Server instance] addToSendingQueue:command];
}

-(void) action:(NSView *) sender {
	NSInteger tag = sender.tag;
	NSString *selectedMethod = [methodsArr objectAtIndex:tag-1];
	
	NSInteger selectedRow = [self.windowObjectsList selectedRow];
	if (selectedRow >= [windowObjectsList count] || selectedRow < 0) return;
	NSString *selectedObject = [windowObjectsList objectAtIndex:selectedRow];
	
	NSMutableString *command = [NSMutableString stringWithFormat:@"UpdateObject===%@<-->%@<-->", selectedObject, selectedMethod];
	
	if ([selectedMethod rangeOfString:@"v32@0:8{CGPoint=dd}16"].location != NSNotFound) {
		int indexOfFirstSlider = -1;
		for(int i = 0; i < [controlsList count]; ++i) {
			NSView *control = [controlsList objectAtIndex:i];
			if (control.tag == sender.tag) {
				indexOfFirstSlider = i;
				break;
			}
		}
		if (indexOfFirstSlider == -1 || indexOfFirstSlider+1 >= [controlsList count]) {
			NSLog(@"First slider object not found or somsing goes wrong");
			return;
		}
		NSSlider *firstSlider = [controlsList objectAtIndex:indexOfFirstSlider];
		NSSlider *secondSlider = [controlsList objectAtIndex:indexOfFirstSlider+1];
		
		if ([firstSlider isKindOfClass:[NSSlider class]] == NO ||
			[secondSlider isKindOfClass:[NSSlider class]] == NO) {
			NSLog(@"Founding pair of sliders failed");
			return;
		}
		
		[command appendFormat:@"{%f, %f}", ((NSSlider *)firstSlider).floatValue, ((NSSlider *)secondSlider).floatValue];
	}
	
	if ([selectedMethod rangeOfString:@"v20@0:8c16"].location != NSNotFound) {
		int indexOfCheckbox = -1;
		for(int i = 0; i < [controlsList count]; ++i) {
			NSView *control = [controlsList objectAtIndex:i];
			if (control.tag == sender.tag) {
				indexOfCheckbox = i;
				break;
			}
		}
		NSButton *checkbox = [controlsList objectAtIndex:indexOfCheckbox];
		if ([checkbox isKindOfClass:[NSButton class]] == NO) {
			NSLog(@"Founding pair of sliders failed");
			return;
		}
		
		[command appendFormat:@"%d", ((NSButton *)checkbox).state == NSOnState];
	}
	
	
	if ([selectedMethod rangeOfString:@"v20@0:8f16"].location != NSNotFound) {
		int indexOfSlider = -1;
		for(int i = 0; i < [controlsList count]; ++i) {
			NSView *control = [controlsList objectAtIndex:i];
			if (control.tag == sender.tag) {
				indexOfSlider = i;
				break;
			}
		}
		NSSlider *checkbox = [controlsList objectAtIndex:indexOfSlider];
		if ([checkbox isKindOfClass:[NSSlider class]] == NO) {
			NSLog(@"Founding pair of sliders failed");
			return;
		}
		
		[command appendFormat:@"%f", ((NSSlider *)checkbox).floatValue];
	}
	
	if ([selectedMethod rangeOfString:@"v24@0:8@16"].location != NSNotFound) {
		int indexOfTextField = -1;
		for(int i = 0; i < [controlsList count]; ++i) {
			NSView *control = [controlsList objectAtIndex:i];
			if (control.tag == sender.tag) {
				indexOfTextField = i;
				break;
			}
		}
		if (indexOfTextField == -1) return;
		NSTextField *textField = [controlsList objectAtIndex:indexOfTextField];
		if ([textField isKindOfClass:[NSTextField class]] == NO) {
			NSLog(@"Founding pair of sliders failed");
			return;
		}
		
		[command appendFormat:@"%@", ((NSTextField *)textField).stringValue];
	}
	
	NSLog(@"command to send = %@", command);
	[[Server instance] addToSendingQueue:command];
}

-(void) displayObjectMethods:(NSString *) objectMethods {
	NSArray *methodsInfoArr = [objectMethods componentsSeparatedByString:@"|||"];
	NSUInteger summControlsHeight = 20;
	
	for(NSView *control in controlsList) {
		[control removeFromSuperview];
	}
	[controlsList removeAllObjects];
	
	for(NSString *mathodInfo in methodsInfoArr) {
		NSArray *infoParts = [mathodInfo componentsSeparatedByString:@"<->"];
		
		if ([infoParts count] != 2) {
			NSLog(@"Command format invalid at rect '%@'", mathodInfo);
			continue;
		}
		
		NSString *selectorName = [infoParts objectAtIndex:0];
		NSArray *signatureAndParameter = [[infoParts objectAtIndex:1] componentsSeparatedByString:@":::"];
		NSString *selectorSignature = [signatureAndParameter objectAtIndex:0];
		NSString *defaultArgs = @"";
		if ([signatureAndParameter count] > 1) {
			defaultArgs = [signatureAndParameter objectAtIndex:1];
		}
		
		NSString *methodDescription = [NSString stringWithFormat:@"%@<->%@", selectorName, selectorSignature];
		if ([unsupportedMethods containsObject:methodDescription]) continue;
		
		[methodsArr addObject:methodDescription];
		
		NSBox *control = nil;
		
		if ([selectorSignature isEqualToString:@"v20@0:8c16"]) {
			BOOL arg = [defaultArgs boolValue];
			control = [self makeBoolControl:selectorName numberOfControl:[methodsArr count] arg:arg];
		}
		
		if ([selectorSignature isEqualToString:@"v32@0:8{CGPoint=dd}16"]) {
			NSArray *args = [defaultArgs componentsSeparatedByString:@"___"];
			float arg1 = [[args objectAtIndex:0] floatValue];
			float arg2 = [[args objectAtIndex:1] floatValue];
			control = [self makeCCPointControl:selectorName numberOfControl:[methodsArr count] arg1:arg1 arg2:arg2];
		}
		
		if ([selectorSignature isEqualToString:@"v20@0:8f16"]) {
			float arg = [defaultArgs floatValue];
			control = [self makeFloatControl:selectorName numberOfControl:[methodsArr count] arg:arg];
		}
		
		if ([selectorSignature isEqualToString:@"v24@0:8@16"]) {
			NSString *string = defaultArgs;
			control = [self makeStringControl:selectorName numberOfControl:[methodsArr count] stringValue:string];
		}
		
		if (control == nil) {
			NSLog(@"Error: unsupported method: %@", mathodInfo);
		} else {
			NSRect controlFrame = control.frame;
			controlFrame.origin.y = summControlsHeight;
			[control setFrame:controlFrame];
			[self.windowObjectMethodsList.documentView addSubview:control];
			[self.windowObjectMethodsList.documentView setFrame:NSMakeRect(0, 0, self.windowObjectMethodsList.frame.size.width, summControlsHeight)];
			summControlsHeight += controlFrame.size.height+20;
			
			[controlsList addObject:control];
		}
	}
	NSLog(@"command = %@", objectMethods);
}

-(void) displayWindowContent:(NSString *) windowObjects {
	NSArray *objectsInfoArr = [windowObjects componentsSeparatedByString:@"|||"];
	[windowObjectsList removeAllObjects];
	
	for(NSString *objectInfo in objectsInfoArr) {
		[windowObjectsList addObject:objectInfo];
	}
	[self.windowObjectsList reloadData];
	//NSLog(@"command = %@", windowObjects);
}

-(void) dealloc {
	[methodsArr release];
	[controlsList release];
	[super dealloc];
}

@end
