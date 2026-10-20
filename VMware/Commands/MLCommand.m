//
//  MLCommand.m
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLCommand.h"
#import "MLCommand+internal.h"

NSErrorDomain const MLCommandErrorDomain = @"kMLCommandErrorDomain";


@implementation MLCommand

- (instancetype)init
{
    return [super init];
}


- (void)executeWithCompletion:(completion_block_t)completion
{
    dispatch_queue_t queue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^(void) {
        
        dispatch_barrier_sync(queue, ^{
            
            if (self.isExecuting) {
                NSError* error = [NSError errorWithDomain:MLCommandErrorDomain
                                                     code:1
                                                 userInfo:@{ NSLocalizedDescriptionKey: @"Execution in progress" }];
                [self callCompletion:completion withError:error];
                return;
            }
            
            self.isExecuting = YES;
            @try {
                NSError* error = [self execute];
                [self callCompletion:completion withError:error];
            }
            @finally {
                self.isExecuting = NO;
            }
        });

    });
}


- (NSError*)execute
{
    return nil;
}


- (void)callCompletion:(completion_block_t)completion withError:(NSError*)error
{
    if (completion != nil) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            completion(error);
        });
    }
}

@end
