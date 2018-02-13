//
//  IntegerValueFormatter.m
//  VMware Screen Resulution
//
//  Created by Martin Løbger on 12/02/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "IntegerValueFormatter.h"
#import <AppKit/AppKit.h>

@implementation IntegerValueFormatter

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}


- (BOOL)isPartialStringValid:(NSString*)partialString newEditingString:(NSString**)newString errorDescription:(NSString**)error
{
    if ([partialString length] == 0) {
        return YES;
    }

    NSScanner* scanner = [NSScanner scannerWithString:partialString];

    if (!([scanner scanInt:0] && [scanner isAtEnd])) {
        NSBeep();
        return NO;
    }

    return YES;
}

@end
