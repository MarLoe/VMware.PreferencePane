//
//  NSTabViewScreenResolution.m
//  VMware
//
//  Created by Martin Løbger on 26/10/2026.
//  Copyright © 2026 ML-Consulting. All rights reserved.
//

#import "NSTabViewScreenResolution.h"
#import <STPrivilegedTask/STPrivilegedTask.h>

@interface NSTabViewScreenResolution ()

@end

@implementation NSTabViewScreenResolution

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithIdentifier:(nullable id)identifier
{
    if (self = [super initWithIdentifier:identifier]) {
        [self setup];
    }
    return self;
}


- (void)setup
{
}

- (void)refresh
{
}

@end
