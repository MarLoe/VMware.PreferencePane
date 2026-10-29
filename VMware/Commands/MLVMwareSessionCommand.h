//
//  MLVMwareSessionCommand.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLVMwareCommand.h"


@interface MLVMwareSessionCommand : MLCommand

@property (nonatomic, readonly, strong) NSDictionary* session;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

+ (instancetype)session;

@end
