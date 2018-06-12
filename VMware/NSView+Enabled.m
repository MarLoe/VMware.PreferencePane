//
//  NSView+Enabled.m
//  VMware
//
//  Created by Martin Løbger on 13/06/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "NSView+Enabled.h"
#import <objc/runtime.h>

@implementation NSView (Enabled)

- (BOOL)enabled
{
    NSNumber* enabled = objc_getAssociatedObject(self, @selector(enabled));
    return enabled.boolValue;
}

- (void)setEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(enabled), @(enabled), OBJC_ASSOCIATION_RETAIN);
    [self setSubViewsEnabled:enabled];
}

- (void)setSubViewsEnabled:(BOOL)enabled
{
    NSView* currentView = NULL;
    NSEnumerator* viewEnumerator = [[self subviews] objectEnumerator];
    while( currentView = [viewEnumerator nextObject] )
    {
        currentView.enabled = enabled;
        [currentView display];
    }
}

@end
