//
//  MLVMwareSessionCommand.m
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLVMwareSessionCommand.h"
#import "MLCommand+internal.h"
#import "VMToolsLibrary.h"

@interface MLVMwareSessionCommand ()
@property (nonatomic, strong) NSDictionary* session;
@end

@implementation MLVMwareSessionCommand

- (instancetype)init
{
    return self = [super init];
}

+ (instancetype)session
{
    return [[MLVMwareSessionCommand alloc] init];
}

- (void)executeWithCompletion:(completion_block_t)completion
{
    NSError* error = nil;
    self.session = [VMToolsLibrary.sharedLibrary sessionInfo:&error];
    [self callCompletion:completion withError:error];
}

@end

