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

- (instancetype)initCommand:(NSString *)command withArguments:(NSArray<NSString *> *)arguments
{
    return [super initCommand:[kVMwareToolsFolder stringByAppendingPathComponent:command]
                       atPath:kVMwareToolsFolder
                withArguments:arguments];
}


+ (instancetype)resolutionSet:(NSInteger)width height:(NSInteger)height
{
    NSArray* arguments = @[@(width).stringValue, @(height).stringValue];
    return [[MLVMwareCommand alloc] initCommand:kVMwareToolsResolutionSet
                                  withArguments:arguments];
}


+ (instancetype)toolsCli:(NSArray<NSString*>*)arguments
{
    return [[MLVMwareCommand alloc] initCommand:kVMwareToolsCmdLineIntf
                                  withArguments:arguments];
}

@end


#pragma mark - MLVMwareVersionCommand

@interface MLVMwareVersionCommand ()
@property (nonatomic, strong) NSString* version;
@end

@implementation MLVMwareVersionCommand

- (instancetype)init
{
    return self = [super initCommand:kVMwareToolsCmdLineIntf
                       withArguments:@[@"--version"]];
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


#pragma mark - MLVMwareSessionCommand

@interface MLVMwareSessionCommand ()
@property (nonatomic, strong) NSDictionary* session;
@end

@implementation MLVMwareSessionCommand

- (instancetype)init
{
    NSArray* arguments = @[@"stat", @"raw", @"json", @"session"];
    return self = [super initCommand:kVMwareToolsCmdLineIntf
                       withArguments:arguments];
}

+ (instancetype)session
{
    return [[MLVMwareSessionCommand alloc] init];
}

- (BOOL)parseStandardOutput:(NSString*)stdOutput error:(out NSError **_Nullable)error
{
    NSData* jsonData = [stdOutput dataUsingEncoding:NSUTF8StringEncoding];
    self.session = [NSJSONSerialization JSONObjectWithData:jsonData
                                                   options:kNilOptions
                                                     error:error];
    return *error == nil;
}

@end

