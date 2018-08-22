//
//  MLVMwareCommand.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLCommand.h"

extern NSString* const kVMwareToolsFolder;
extern NSString* const kVMwareToolsResolutionSet;
extern NSString* const kVMwareToolsCmdLineIntf;

#pragma mark - MLVMwareCommand

@interface MLVMwareCommand : MLCommand

+ (instancetype)resolutionSet:(NSInteger)width height:(NSInteger)height;

@end


#pragma mark - MLVMwareVersionCommand

@interface MLVMwareVersionCommand : MLVMwareCommand

@property (nonatomic, readonly, strong) NSString* version;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

+ (instancetype)version;

@end


#pragma mark - MLVMwareSessionCommand

@interface MLVMwareSessionCommand : MLVMwareCommand

@property (nonatomic, readonly, strong) NSDictionary* session;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

+ (instancetype)session;

@end
