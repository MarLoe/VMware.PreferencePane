//
//  MLShellCommand.h
//  VMware
//
//  Created by Martin Løbger on 20/10/2026.
//  Copyright © 2026 ML-Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLCommand.h"


@interface MLShellCommand : MLCommand

@property (nonatomic, readonly, strong) NSString*           path;
@property (nonatomic, readonly, strong) NSString*           command;
@property (nonatomic, readonly, strong) NSArray<NSString*>* arguments;

@property (nonatomic, readonly, strong) NSString*           standardOutput;
@property (nonatomic, readonly, strong) NSString*           standardError;

@property (nonatomic, readonly, assign) int                 terminationStatus;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initCommand:(NSString*)command;

- (instancetype)initCommand:(NSString*)command atPath:(NSString*)path;

- (instancetype)initCommand:(NSString*)command atPath:(NSString*)path withArguments:(NSArray<NSString*>*)arguments NS_DESIGNATED_INITIALIZER;

@end
