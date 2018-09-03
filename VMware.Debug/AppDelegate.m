//
//  AppDelegate.m
//  Test
//
//  Created by Martin Løbger on 12/02/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    if ([args containsObject:@"--reset"]) {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        for (NSString* key in [userDefaults dictionaryRepresentation].allKeys) {
            [userDefaults removeObjectForKey:key];
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender {
    return YES;
}


@end
