//
//  MLCommand.m
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MLShellCommand.h"
#import "MLCommand+internal.h"

@interface MLShellCommand ()

@property (nullable, nonatomic, strong) NSString*   standardOutput;
@property (nullable, nonatomic, strong) NSString*   standardError;

- (BOOL)parseStandardOutput:(nonnull NSString*)stdOutput error:(out NSError *_Nullable*_Nullable)error;
- (BOOL)parseStandardError:(nonnull NSString*)stdError error:(out NSError *_Nullable*_Nullable)error;

@end


@implementation MLShellCommand

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


- (NSError*)execute
{
    NSError* error;
    
    NSPipe *pipeError = [NSPipe pipe];
    NSPipe *pipeOutput = [NSPipe pipe];
    
    NSTask *task = [[NSTask alloc] init];
    task.currentDirectoryPath = _path;
    task.launchPath = _command;
    task.arguments = _arguments;
    task.standardError = pipeError;
    task.standardOutput = pipeOutput;
    
    if (@available(macOS 10.13, *)) {
        if (![task launchAndReturnError:(&error)]) {
            NSLog(@"ERROR:\n%@", error);
            return error;
        }
    }
    else {
        [task launch];
    }
    
    [task waitUntilExit];
    
    self.standardError = [self readAndClosePipe:pipeError];
    self.standardOutput = [self readAndClosePipe:pipeOutput];

    if (![self parseStandardError:_standardError error:&error]) {
        NSLog(@"ERROR:\n%@", error);
        return error;
    }
    
    if (![self parseStandardOutput:_standardOutput error:&error]) {
        NSLog(@"ERROR:\n%@", error);
        return error;
    }
    
    if (task.terminationStatus != 0) {
        error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                    code:task.terminationStatus
                                userInfo:@{ NSLocalizedDescriptionKey: _standardError }];
        NSLog(@"ERROR:\n%@", error);
        return error;
    }
    
    return nil;
}


- (NSString*)readAndClosePipe:(NSPipe*)pipe
{
    NSFileHandle *file = pipe.fileHandleForReading;
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
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
