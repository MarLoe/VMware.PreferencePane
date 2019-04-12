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

@property (nullable, nonatomic, strong) NSString*   standardOutput;
@property (nullable, nonatomic, strong) NSString*   standardError;
@property (nonatomic, assign) int                   terminationStatus;


- (BOOL)parseStandardOutput:(nonnull NSString*)stdOutput error:(out NSError *_Nullable*_Nullable)error;
- (BOOL)parseStandardError:(nonnull NSString*)stdError error:(out NSError *_Nullable*_Nullable)error;

@end
