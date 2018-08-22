//
//  MLCommand+internal.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLCommand ()

@property (nonatomic, assign) BOOL                isExecuting;

@property (nonatomic, strong) NSString*           standardOutput;
@property (nonatomic, strong) NSString*           standardError;

- (BOOL)parseStandardOutput:(NSString*)stdOutput error:(out NSError **_Nullable)error;
- (BOOL)parseStandardError:(NSString*)stdError error:(out NSError **_Nullable)error;

@end
