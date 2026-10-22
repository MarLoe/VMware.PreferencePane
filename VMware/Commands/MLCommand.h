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

@property (nonatomic, readonly, assign) BOOL                isExecuting;

@property (nonatomic, readonly, assign) int                 terminationStatus;

- (instancetype)init;

- (void)executeWithCompletion:(completion_block_t)completion;

@end
