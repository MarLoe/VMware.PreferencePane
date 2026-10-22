//
//  MLCommand+internal.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLCommand ()

@property (nonatomic, assign) BOOL                  isExecuting;

- (NSError*)execute;
@property (nonatomic, assign) int                   terminationStatus;


- (void)callCompletion:(completion_block_t)completion withError:(NSError*)error;

@end
