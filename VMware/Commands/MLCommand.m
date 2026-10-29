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
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^(void) {
        
        dispatch_barrier_sync(queue, ^{
            
            if (self.isExecuting) {
                NSError* error = [NSError errorWithDomain:MLCommandErrorDomain
                                                     code:1
                                                 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Execution in progress", -) }];
                [self callCompletion:completion withError:error];
                return;
            }
            
            self.isExecuting = YES;
            @try {
                [self executeUserModeWithCompletion:^(NSError *error) {
                    if (error != nil) {
                        NSLog(@"ERROR:\n%@", error);
                    }
                    [self callCompletion:completion withError:error];
                    self.isExecuting = NO;
                }];
            }
            @catch (NSException* e) {
                self.isExecuting = NO;
            }
        });
    });
}


- (void)executeUserModeWithCompletion:(completion_block_t)completion
{
    [self callCompletion:completion withError:nil];
}


- (void)callCompletion:(completion_block_t)completion withError:(NSError*)error
{
    if (completion != nil) {
        if ([NSThread isMainThread]) {
            completion(error);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
        }
    }
}

@end
