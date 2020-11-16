//
//  MLLaunchCtrlCommand.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLCommand.h"

@class MLLaunchCtrlPrintCommand;

@interface MLLaunchCtrlCommand : MLCommand

+ (MLLaunchCtrlCommand*)loadService:(NSString*)service;

+ (MLLaunchCtrlCommand*)unloadService:(NSString*)service;

+ (MLLaunchCtrlPrintCommand*)printService:(NSString*)service inDomain:(NSString*)domain;

@end

@interface MLLaunchCtrlPrintCommand : MLLaunchCtrlCommand

@property (nonatomic, readonly, strong) NSString*       serviceName;
@property (nonatomic, readonly, strong) NSString*       domainName;

@property (nonatomic, readonly, strong) NSDictionary*   service;

@property (nonatomic, readonly, assign) NSString*       state;
@property (nonatomic, readonly, assign) BOOL            isRunning;
@property (nonatomic, readonly, assign) NSInteger       pid;

@end
