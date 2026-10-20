//
//  MLVMwareCommand.m
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLVMwareCommand.h"

NSString* const kVMwareToolsFolder          = @"/Library/Application Support/VMware Tools/";
NSString* const kVMwareToolsCmdLineIntf     = @"vmware-tools-cli";


@implementation MLVMwareCommand

- (instancetype)initWithArguments:(NSArray<NSString *> *)arguments
{
    return [super initCommand:[kVMwareToolsFolder stringByAppendingPathComponent:kVMwareToolsCmdLineIntf]
                       atPath:kVMwareToolsFolder
                withArguments:arguments];
}


+ (instancetype)toolsCli:(NSArray<NSString*>*)arguments
{
    return [[MLVMwareCommand alloc] initWithArguments:arguments];
}

@end


#pragma mark - MLVMwareVersionCommand

@interface MLVMwareVersionCommand ()
@property (nonatomic, strong) NSString* version;
@end

@implementation MLVMwareVersionCommand

- (instancetype)init
{
    return self = [super initWithArguments:@[@"--version"]];
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
    return self = [super initWithArguments:arguments];
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

