//
//  main.m
//  Test
//
//  Created by Martin Løbger on 12/02/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[])
{
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    if ([args containsObject:@"--reset"]) {
        NSLog(@"Resetting NSUserDefaults");
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        for (NSString* key in [userDefaults dictionaryRepresentation].allKeys) {
            [userDefaults removeObjectForKey:key];
        }
    }

    return NSApplicationMain(argc, argv);
}
