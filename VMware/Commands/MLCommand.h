//
//  MLCommand.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSErrorDomain const MLCommandErrorDomain;


typedef void (^completion_block_t)(NSError* error);


@interface MLCommand : NSObject

@property (nonatomic, readonly, strong) NSString*           path;
@property (nonatomic, readonly, strong) NSString*           command;
@property (nonatomic, readonly, strong) NSArray<NSString*>* arguments;

@property (nonatomic, readonly, assign) BOOL                isExecuting;

@property (nonatomic, readonly, strong) NSString*           standardOutput;
@property (nonatomic, readonly, strong) NSString*           standardError;


- (instancetype)initCommand:(NSString*)command;

- (instancetype)initCommand:(NSString*)command atPath:(NSString*)path;

- (instancetype)initCommand:(NSString*)command atPath:(NSString*)path withArguments:(NSArray<NSString*>*)arguments NS_DESIGNATED_INITIALIZER;

- (void)executeWithCompletion:(completion_block_t)completion;

@end
