//
//  MLLaunchCtrlCommand.m
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLLaunchCtrlCommand.h"
#import "MLCommand+internal.h"
#import "MLPlistParser.h"

@interface MLLaunchCtrlCommand()

- (instancetype)initService:(NSString*)service inDomain:(NSString*)domain withArguments:(NSArray<NSString *> *)arguments;

@end

@interface MLLaunchCtrlPrintCommand()

@property (nonatomic, assign) NSString*         state;
@property (nonatomic, assign) BOOL              isRunning;
@property (nonatomic, assign) NSInteger         pid;

@end


@implementation MLLaunchCtrlCommand

- (instancetype)initService:(NSString*)service inDomain:(NSString*)domain withArguments:(NSArray<NSString *> *)arguments
{
    if (self = [super initCommand:@"/bin/launchctl" atPath:@"/bin" withArguments:arguments])
    {
        _domainName = domain;
        _serviceName = service;
    }
    return self;
}

+ (instancetype)loadService:(NSString*)service inDomain:(NSString*)domain;
{
    NSString* plist = [NSString stringWithFormat:@"/Library/LaunchDaemons/%@.plist", service];
    MLLaunchCtrlCommand* _self = [[MLLaunchCtrlCommand alloc] initService:service
                                                                 inDomain:domain
                                                            withArguments:@[@"bootstrap", domain, plist]];
    return _self;
}

+ (instancetype)unloadService:(NSString*)service inDomain:(NSString*)domain;
{
    NSString* domainService = [domain stringByAppendingFormat:@"/%@", service];
    MLLaunchCtrlCommand* _self = [[MLLaunchCtrlCommand alloc] initService:service
                                                                 inDomain:domain
                                                            withArguments:@[@"bootout", domainService]];

    return _self;
}

@end


@implementation MLLaunchCtrlPrintCommand

- (instancetype)initService:(NSString*)service inDomain:(NSString*)domain
{
    NSString* domainService = [domain stringByAppendingFormat:@"/%@", service];
    return [super initService:service inDomain:domain withArguments:@[@"print", domainService]];
}

+ (instancetype)printService:(NSString*)service inDomain:(NSString*)domain
{
    return [[MLLaunchCtrlPrintCommand alloc] initService:service inDomain:domain];
}

- (BOOL)parseStandardOutput:(NSString *)stdOutput error:(out NSError *__autoreleasing *)error
{
    [stdOutput enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        if ([line containsString:@"state = "]) {
            NSArray* components = [line componentsSeparatedByString:@"="];
            self.state = [components.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            self.isRunning = [self.state containsString:@"running"];
        }
        else if ([line containsString:@"pid = "]) {
            NSArray* components = [line componentsSeparatedByString:@"="];
            self.pid = [components.lastObject integerValue];
        }
    }];
    
    return YES;
}

- (BOOL)parseStandardError:(NSString *)stdError error:(out NSError *__autoreleasing *)error
{
    if (self.terminationStatus == 113) {
        if ([stdError containsString:self.serviceName]) {
            self.state = @"stopped";
            self.isRunning = NO;
        }
    }
    return YES;
}

@end
