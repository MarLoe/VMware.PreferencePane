//
//  MLVMwareResolutionCommand.h
//  VMware
//
//  Created by Martin Løbger on 04/01/2022.
//  Copyright © 2022 ML-Consulting. All rights reserved.
//
#import "MLVMwareCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLVMwareResolutionCommand : MLVMwareCommand

- (instancetype)init:(NSUInteger)width height:(NSUInteger)height NS_DESIGNATED_INITIALIZER;

+ (instancetype)resolutionSet:(NSUInteger)width height:(NSUInteger)height;

@end

NS_ASSUME_NONNULL_END
