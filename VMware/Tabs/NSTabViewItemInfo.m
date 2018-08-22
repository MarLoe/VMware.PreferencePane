//
//  NSTabViewItemInfo.m
//  VMware
//
//  Created by Martin Løbger on 20/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "NSTabViewItemInfo.h"

@implementation NSTabViewItemInfo
{
    dispatch_source_t timer;
}

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
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DISPATCH_QUEUE_SERIAL);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        if (self.uptime > 0) {
            self.uptime += 1.0;
        }
    });
    dispatch_resume(timer);
}

- (void)setUptime:(NSTimeInterval)uptime
{
    if (_uptime != uptime) {
        _uptime = uptime;
    }
}

@end
