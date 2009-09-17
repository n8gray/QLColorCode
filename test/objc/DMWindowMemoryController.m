//
//  DMWindowMemoryController.m
//  DMWindowMemory
//
//  Created by Nathaniel Gray on 5/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "DMWindowMemoryController.h"
#import "Notifications.h"

@implementation DMWindowMemoryController

- someMethod {
}

- someOtherMethod
{}

- foo : (baz) bar {
}

+ blah {
}

- (NSString*) name {
    return @"Window Memory Plugin";
}
- (NSString*) description {
    return @"A plugin to save and restore the positions of your windows when your screen configuration changes";
}
- (int) interfaceVersion {
    return 1;
}
- (NSBundle*) preferencesBundle {
    return nil;
}

/* This is in response to notification that the screen geometry has changed */
- (void) handleScreenChange: (NSNotification *)notif {
    NSLog(@"*** handleScreenChange\n");
    [mConfigurationLock lock];
    NSEnumerator *configEnum = [mConfigurations objectEnumerator];
    ScreenConfiguration *config;
    BOOL found = NO;
    while (config = [configEnum nextObject]) {
        if ([config matchesCurrentConfig]) {
            NSLog(@"Found matching config: %@", config);
            mCurrentConfig = config;
            [config restoreWindowLayout];
            found = YES;
            break;
        }
    }
    if (!found) {
        config = [ScreenConfiguration configWithCurrent];
        [mConfigurations insertObject:config
                              atIndex:0];
        mCurrentConfig = config;
        NSLog(@"Added new config: %@", config);
    }
    [mConfigurationLock unlock];
}

/* This is in response to the periodic updates to the window layout on screen */
- (void) handleWindowChanges: (NSNotification *)notif { 
    //NSLog(@"handleWindowChanges\n");
    [mConfigurationLock lock];
    [mCurrentConfig updateWindowLayout];
    [mConfigurationLock unlock];
}

- (void) pluginLoaded: (DMController*) controller withBundle: (NSBundle*) thisBundle
{
    NSLog(@"DMWindowMemoryController pluginLoaded\n");
    mController = controller;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    mConfigurationLock = [[NSLock alloc] init];
    [mConfigurationLock lock];
    
    // Find out when screens are added/removed
    [nc addObserver: self
           selector: @selector(handleScreenChange:)
               name: NSApplicationDidChangeScreenParametersNotification
             object: nil];
    
    // Get the periodic window layout updates
    [nc addObserver: self
           selector: @selector(handleWindowChanges:)
               name: NOTIFICATION_WINDOWLAYOUTUPDATED
             object: nil];
    
    mCurrentConfig = [ScreenConfiguration configWithCurrent];
    mConfigurations = [[NSMutableArray arrayWithObject:mCurrentConfig] retain];
    [mConfigurationLock unlock];
    NSLog(@"Finished initializing plugin\n");
}

- (void) dealloc {
    [mConfigurationLock lock];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    // We don't release mCurrentConfig because we never actually retain it.
    if (mConfigurations) {
        [mConfigurations release];
        mConfigurations = nil;
    }
    if (mController) {
        [mController release];
        mController = nil;
    }
    [mConfigurationLock unlock];
    [mConfigurationLock release];
    [super dealloc];
}
@end
