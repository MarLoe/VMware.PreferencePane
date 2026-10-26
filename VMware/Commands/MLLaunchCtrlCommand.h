//
//  MLLaunchCtrlCommand.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLShellCommand.h"

@interface MLLaunchCtrlCommand : MLShellCommand

@property (nonatomic, readonly, strong) NSString*       serviceName;
@property (nonatomic, readonly, strong) NSString*       domainName;

+ (instancetype)loadService:(NSString*)service inDomain:(NSString*)domain;

+ (instancetype)unloadService:(NSString*)service inDomain:(NSString*)domain;

@end

@interface MLLaunchCtrlPrintCommand : MLLaunchCtrlCommand

@property (nonatomic, readonly, assign) NSString*       state;
@property (nonatomic, readonly, assign) BOOL            isRunning;
@property (nonatomic, readonly, assign) NSInteger       pid;

+ (instancetype)printService:(NSString*)service inDomain:(NSString*)domain;

@end
