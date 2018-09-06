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
@property (nonatomic, strong) NSDictionary*     service;

@property (nonatomic, assign) NSString*         state;
@property (nonatomic, assign) BOOL              isRunning;
@property (nonatomic, assign) NSInteger         pid;
@end

@implementation MLLaunchCtrlCommand

- (instancetype)initService:(NSString*)service inDomain:(NSString*)domain
{
    if (self = [super initCommand:@"/bin/launchctl"
                           atPath:@"/bin"
                    withArguments:@[@"print", [domain stringByAppendingFormat:@"/%@", service]]]) {
        _serviceName = service;
        _domainName = domain;
    }
    return self;
}

+ (instancetype)printService:(NSString*)service inDomain:(NSString*)domain
{
    return [[MLLaunchCtrlCommand alloc] initService:service inDomain:domain];
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
        if ([stdError containsString:_serviceName]) {
            self.state = @"stopped";
            self.isRunning = NO;
        }
    }
    return YES;
}

@end
