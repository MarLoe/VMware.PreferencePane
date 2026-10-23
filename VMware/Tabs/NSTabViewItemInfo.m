//
//  NSTabViewItemInfo.m
//  VMware
//
//  Created by Martin Løbger on 20/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "NSTabViewItemInfo.h"
#import "MLVMwareCommand.h"
#import "MLVMwareVersionCommand.h"
#import "MLVMwareSessionCommand.h"
#import "MLLaunchCtrlCommand.h"
#import <STPrivilegedTask/STPrivilegedTask.h>

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
        self.toolsVersion = error == nil ? cmdVersion.version : NSLocalizedString(@"N/A", -);
        
        MLVMwareSessionCommand* cmdSession = [MLVMwareSessionCommand session];
        [cmdSession executeWithCompletion:^(NSError *error) {
            self.hostVersion = cmdSession.session[@"version"] ?: NSLocalizedString(@"N/A", -);
            self.uptime = [cmdSession.session[@"uptime"][@"value"] doubleValue] / 1000000.0;
        }];
    }];
}

- (void)refreshService
{
    MLLaunchCtrlPrintCommand* cmd = [MLLaunchCtrlCommand printService:@"com.vmware.launchd.tools" inDomain:@"system"];
    [cmd executeWithCompletion:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Service Error: %@", error);
            self.serviceState = NSLocalizedString(@"N/A", -);
            self.serviceRunning = false;
            return;
        }
        self.serviceState = cmd.state;
        self.serviceRunning = cmd.isRunning;
    }];
}

#pragma mark - Interace Builder Action

- (IBAction)startService:(id)sender
{
    MLLaunchCtrlCommand* cmd = [MLLaunchCtrlCommand loadService:@"com.vmware.launchd.tools"];
    [cmd executeWithCompletion:^(NSError *error) {
        [self refreshService];
    }];
}

- (IBAction)stopService:(id)sender
{
//    MLLaunchCtrlCommand* cmd = [MLLaunchCtrlCommand unloadService:@"com.vmware.launchd.tools"];
//    [cmd executeWithCompletion:^(NSError *error) {
//        NSLog(@"%*", cmd);
//        [self refreshService];
//    }];
    NSArray* arguments = @[
                           @"unload",
                           @"/Library/LaunchDaemons/com.vmware.launchd.tools.plist"
                           ];
    STPrivilegedTask* privTask = [[STPrivilegedTask alloc] initWithLaunchPath:@"/bin/launchctl"
                                                                    arguments:arguments];
//    privTask.currentDirectoryPath = @"/Library/Application Support/VMware Tools";
    OSStatus processError = [privTask launchWithAuthorization:[self.authorization authorizationRef]];
    if (processError != errAuthorizationSuccess) {
//        handler(NO, [NSError errorWithDomain:NSOSStatusErrorDomain code:processError userInfo:nil]);
        NSLog(@"Error: %d", processError);
        return;
    }
    
    [privTask waitUntilExit];
    
    if (privTask.terminationStatus != errAuthorizationSuccess) {
        NSLog(@"Error: %d", privTask.terminationStatus);
    }
    
    [self refreshService];
}


@end
