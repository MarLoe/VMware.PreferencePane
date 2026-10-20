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

- (instancetype)initWithArguments:(NSArray<NSString *> *)arguments;

@end


#pragma mark - MLVMwareVersionCommand

@interface MLVMwareVersionCommand : MLVMwareCommand

@property (nonatomic, readonly, strong) NSString* version;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

+ (instancetype)version;

@end


#pragma mark - MLVMwareSessionCommand

@interface MLVMwareSessionCommand : MLVMwareCommand

@property (nonatomic, readonly, strong) NSDictionary* session;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

+ (instancetype)session;

@end
