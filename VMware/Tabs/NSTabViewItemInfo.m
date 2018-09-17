//
//  NSTabViewItemInfo.m
//  VMware
//
//  Created by Martin Løbger on 20/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "NSTabViewItemInfo.h"
#import "MLVMwareCommand.h"
#import "MLLaunchCtrlCommand.h"

@interface NSTabViewItemInfo ()

@property (nonatomic, weak) IBOutlet NSButton*              start;
@property (nonatomic, weak) IBOutlet NSButton*              stop;

- (IBAction)startService:(id)sender;
- (IBAction)stopService:(id)sender;

@end

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

- (void)refresh
{
    [self refreshVersion];
    [self refreshService];
}

- (void)refreshVersion
{
    MLVMwareVersionCommand* cmdVersion = [MLVMwareVersionCommand version];
    [cmdVersion executeWithCompletion:^(NSError *error) {
        self.toolsVersion = error == nil ? cmdVersion.version : @"N/A";
        
        MLVMwareSessionCommand* cmdSession = [MLVMwareSessionCommand session];
        [cmdSession executeWithCompletion:^(NSError *error) {
            self.hostVersion = cmdSession.session[@"version"] ?: @"N/A";
            self.uptime = [cmdSession.session[@"uptime"][@"value"] doubleValue] / 1000000.0;
        }];
    }];
}

- (void)refreshService
{
    MLLaunchCtrlCommand* cmdLaunchCtrl = [MLLaunchCtrlCommand printService:@"com.vmware.launchd.tools" inDomain:@"system"];
    [cmdLaunchCtrl executeWithCompletion:^(NSError *error) {
        if (cmdLaunchCtrl.state == nil) {
            NSLog(@"Service Error: %@", error);
            NSLog(@"Service State: %@", cmdLaunchCtrl.state);
            NSLog(@"Service Running: %@", @(cmdLaunchCtrl.isRunning));
        }
        self.serviceState = cmdLaunchCtrl.state;
        self.serviceRunning = cmdLaunchCtrl.isRunning;
    }];
}

#pragma mark - Interace Builder Action

- (IBAction)startService:(id)sender
{
    [self refreshService];
}

- (IBAction)stopService:(id)sender
{
    [self refreshService];
}


@end
