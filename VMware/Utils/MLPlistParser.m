//
//  MLPlistParser.m
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLPlistParser.h"

@implementation MLPlistParser

+ (NSDictionary*)parsePlist:(NSString*)plist error:(out NSError **)error
{
    // The plist does not conform to standard.
    // So we must groom it a bit.
    
    // 1. Remove trailing semicolon (;)
    NSCharacterSet* semicolenCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@";\n"];
    plist = [plist stringByTrimmingCharactersInSet:semicolenCharacterSet];
    
    // 2. Convert array seperation from semicolon (;) to comma (,)
    NSMutableArray* lines = [NSMutableArray arrayWithCapacity:20];
    [plist enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        if (![line containsString:@" = "] && ![line hasSuffix:@");"]  && ![line hasSuffix:@"};"] && [line hasSuffix:@";"]) {
            line = [line stringByTrimmingCharactersInSet:semicolenCharacterSet];
            line = [line stringByAppendingString:@","];
        }
        [lines addObject:line];
    }];
    plist = [lines componentsJoinedByString:@"\n"];
    
    NSPropertyListFormat format;
    return [NSPropertyListSerialization propertyListWithData:[plist dataUsingEncoding:NSUTF8StringEncoding]
                                                     options:NSPropertyListImmutable
                                                      format:&format
                                                       error:error];
}

@end
