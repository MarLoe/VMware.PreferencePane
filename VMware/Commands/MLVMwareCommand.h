//
//  MLVMwareCommand.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLShellCommand.h"

#pragma mark - MLVMwareCommand

extern NSString* const kVMwareToolsResolutionSet;
extern NSString* const kVMwareToolsCmdLineIntf;

@interface MLVMwareCommand : MLShellCommand

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initCommand:(NSString*)command NS_UNAVAILABLE;

- (instancetype)initCommand:(NSString*)command atPath:(NSString*)path NS_UNAVAILABLE;

- (instancetype)initCommand:(NSString*)command atPath:(NSString*)path withArguments:(NSArray<NSString*>*)arguments NS_UNAVAILABLE;

- (instancetype)initCommand:(NSString*)command withArguments:(NSArray<NSString*>*)arguments NS_DESIGNATED_INITIALIZER;

@end


#pragma mark - MLVMwareVersionCommand

@interface MLVMwareVersionCommand : MLVMwareCommand

@property (nonatomic, readonly, strong) NSString* version;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (instancetype)initCommand:(NSString*)command withArguments:(NSArray<NSString*>*)arguments NS_UNAVAILABLE;

+ (instancetype)version;

@end


#pragma mark - MLVMwareSessionCommand

@interface MLVMwareSessionCommand : MLVMwareCommand

@property (nonatomic, readonly, strong) NSDictionary* session;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (instancetype)initCommand:(NSString*)command withArguments:(NSArray<NSString*>*)arguments NS_UNAVAILABLE;

+ (instancetype)session;

@end
