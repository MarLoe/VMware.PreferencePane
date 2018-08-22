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
@property (nonatomic, strong) NSDictionary* service;
@end

@implementation MLLaunchCtrlCommand

+ (instancetype)listService:(NSString*)service
{
    return [[MLLaunchCtrlCommand alloc] initCommand:@"/bin/launchctl"
                                             atPath:@"/bin"
                                      withArguments:@[@"list", service]];
}

- (BOOL)parseStandardOutput:(NSString *)stdOutput error:(out NSError *__autoreleasing *)error
{
    self.service = [MLPlistParser parsePlist:stdOutput error:error];
    return *error == nil;
}

@end
