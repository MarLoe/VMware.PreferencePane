//
//  MLVMwareCommand.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLShellCommand.h"

#pragma mark - MLVMwareCommand

@interface MLVMwareCommand : MLShellCommand

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initCommand:(NSString*)command NS_UNAVAILABLE;

- (instancetype)initCommand:(NSString*)command atPath:(NSString*)path NS_UNAVAILABLE;

- (instancetype)initCommand:(NSString*)command atPath:(NSString*)path withArguments:(NSArray<NSString*>*)arguments NS_UNAVAILABLE;

- (instancetype)initToolsWithArguments:(NSArray<NSString*>*)arguments NS_DESIGNATED_INITIALIZER;

- (instancetype)initResolutionWithArguments:(NSArray<NSString*>*)arguments NS_DESIGNATED_INITIALIZER;

@end
