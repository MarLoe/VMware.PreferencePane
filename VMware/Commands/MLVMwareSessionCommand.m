//
//  MLVMwareSessionCommand.m
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLVMwareSessionCommand.h"


@interface MLVMwareSessionCommand ()
@property (nonatomic, strong) NSDictionary* session;
@end

@implementation MLVMwareSessionCommand

- (instancetype)init
{
    NSArray<NSString*>* arguments = @[@"stat", @"raw", @"json", @"session"];
    return self = [super initToolsWithArguments:arguments];
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

