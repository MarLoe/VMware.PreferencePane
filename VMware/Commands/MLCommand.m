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
    assert("This initializer cannot be used");
    return [self initCommand:nil];
}


- (instancetype)initCommand:(NSString*)command
{
    if (self = [self initCommand:command atPath:nil]) {
    }
    return self;
}


- (instancetype)initCommand:(NSString*)command atPath:(NSString*)path
{
    if (self = [self initCommand:command atPath:path withArguments:nil]) {
    }
    return self;
}


- (instancetype)initCommand:(NSString*)command atPath:(NSString*)path withArguments:(NSArray<NSString*>*)arguments
{
    if (self = [super init]) {
        _command = command;
        _path = path;
        _arguments = arguments;
    }
    return self;
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


- (void)callCompletion:(completion_block_t)completion withError:(NSError*)error
{
    if (completion != nil) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            completion(error);
        });
    }
}


- (void)executeUserModeWithCompletion:(completion_block_t)completion
{
    NSError* error;
    
    NSTask *task = [[NSTask alloc] init];
    task.currentDirectoryPath = _path;
    task.launchPath = _command;
    task.arguments = _arguments;

    NSMutableData* dataOutput = [NSMutableData data];
    NSPipe *pipeOutput = [NSPipe pipe];
    pipeOutput.fileHandleForReading.readabilityHandler = ^(NSFileHandle * _Nonnull fh) {
        @synchronized(dataOutput) {
            [dataOutput appendData:[fh readDataToEndOfFile]];
        }
    };
    task.standardOutput = pipeOutput;

    NSMutableData* dataError = [NSMutableData data];
    NSPipe *pipeError = [NSPipe pipe];
    pipeError.fileHandleForReading.readabilityHandler = ^(NSFileHandle * _Nonnull fh) {
        @synchronized(dataError) {
            [dataError appendData:[fh readDataToEndOfFile]];
        }
    };
    task.standardError = pipeError;

    task.terminationHandler = ^(NSTask * _Nonnull _task) {
        
        NSError* error;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);

        self.terminationStatus = _task.terminationStatus;
 
        // Handle Output
        dispatch_sync(queue, ^{
            @synchronized(dataOutput) {
                [dataOutput appendData:[pipeOutput.fileHandleForReading readDataToEndOfFile]];
                [pipeOutput.fileHandleForReading closeFile];
                self.standardOutput = [[NSString alloc] initWithData:dataOutput encoding:NSUTF8StringEncoding];
            }
        });
        if (![self parseStandardOutput:self.standardOutput error:&error]) {
            completion(error);
            return;
        }

        // Handle Error
        dispatch_sync(queue, ^{
            @synchronized(dataError) {
                [dataError appendData:[pipeError.fileHandleForReading readDataToEndOfFile]];
                [pipeError.fileHandleForReading closeFile];
                self.standardError = [[NSString alloc] initWithData:dataError encoding:NSUTF8StringEncoding];
            }
        });
        if (![self parseStandardError:self.standardError error:&error]) {
            completion(error);
            return;
        }
        
        if (_task.terminationStatus != 0) {
            error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                        code:_task.terminationStatus
                                    userInfo:@{ NSLocalizedDescriptionKey: self.standardError }];
            completion(error);
            return;
        }
        
        completion(nil);
    };
    
    if (@available(macOS 10.13, *)) {
        if (![task launchAndReturnError:(&error)]) {
            completion(error);
            return;
        }
    }
    else {
        [task launch];
    }
}


- (BOOL)parseStandardOutput:(NSString*)stdOutput error:(out NSError **_Nullable)error
{
    return YES;
}


- (BOOL)parseStandardError:(NSString*)stdError error:(out NSError **_Nullable)error
{
    return YES;
}


@end
