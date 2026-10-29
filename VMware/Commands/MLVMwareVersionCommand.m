//
//  MLVMwareVersionCommand.m
//  VMware
//
//  Created by Martin Løbger on 20/10/2026.
//  Copyright © 2026 ML-Consulting. All rights reserved.
//

#import "MLVMwareVersionCommand.h"
#import "VMToolsLibrary.h"

@interface MLVMwareVersionCommand ()
@property (nonatomic, strong) NSString* version;
@end

@implementation MLVMwareVersionCommand

- (instancetype)init
{
    return self = [super init];
}

+ (instancetype)version
{
    return [[MLVMwareVersionCommand alloc] init];
}

- (void)executeWithCompletion:(completion_block_t)completion
{
    NSError* error = nil;
    NSDictionary<NSString *, NSString *> * version = [VMToolsLibrary.sharedLibrary toolsVersionInfo:&error];
    self.version = version[VMToolsDescriptionKey];
    completion(error);
}

//- (BOOL)parseStandardOutput:(NSString *)stdOutput error:(out NSError *__autoreleasing *)error
//{
//    self.version = [stdOutput stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
//    return YES;
//}

@end
