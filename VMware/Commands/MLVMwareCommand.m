//
//  MLVMwareCommand.m
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLVMwareCommand.h"

NSString* const kVMwareToolsFolder          = @"/Library/Application Support/VMware Tools/";
NSString* const kVMwareToolsResolutionSet   = @"vmware-resolutionSet";
NSString* const kVMwareToolsCmdLineIntf     = @"vmware-tools-cli";


@implementation MLVMwareCommand

- (instancetype)initToolsWithArguments:(NSArray<NSString*>*)arguments
{
    return [super initCommand:[kVMwareToolsFolder stringByAppendingPathComponent:kVMwareToolsCmdLineIntf]
                       atPath:kVMwareToolsFolder
                withArguments:arguments];
}

- (instancetype)initResolutionWithArguments:(NSArray<NSString*>*)arguments
{
    return [super initCommand:[kVMwareToolsFolder stringByAppendingPathComponent:kVMwareToolsResolutionSet]
                       atPath:kVMwareToolsFolder
                withArguments:arguments];
}

@end
