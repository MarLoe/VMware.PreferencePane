//
//  MLLaunchCtrlCommand.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLShellCommand.h"

@interface MLLaunchCtrlCommand : MLShellCommand

@property (nonatomic, readonly, strong) NSDictionary* service;

+ (instancetype)listService:(NSString*)service;

@end
