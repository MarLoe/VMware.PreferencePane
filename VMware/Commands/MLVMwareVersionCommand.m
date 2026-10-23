//
//  MLVMwareCommand.m
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLVMwareVersionCommand.h"

@interface MLVMwareVersionCommand ()
@property (nonatomic, strong) NSString* version;
@end

@implementation MLVMwareVersionCommand

- (instancetype)init
{
    NSArray<NSString*>* arguments = @[@"--version"];
    return self = [super initToolsWithArguments:arguments];
}

+ (instancetype)version
{
    return [[MLVMwareVersionCommand alloc] init];
}

- (BOOL)parseStandardOutput:(NSString *)stdOutput error:(out NSError *__autoreleasing *)error
{
    self.version = [stdOutput stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return YES;
}

@end
