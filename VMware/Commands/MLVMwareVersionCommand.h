//
//  MLVMwareCommand.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLVMwareCommand.h"


@interface MLVMwareVersionCommand : MLVMwareCommand

@property (nonatomic, readonly, strong) NSString* version;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (instancetype)initToolsWithArguments:(NSArray<NSString *> *)arguments NS_UNAVAILABLE;

- (instancetype)initResolutionWithArguments:(NSArray<NSString *> *)arguments NS_UNAVAILABLE;

+ (instancetype)version;

@end
