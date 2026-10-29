//
//  VMToolsLibrary.m
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "VMToolsLibrary.h"

#include <dlfcn.h>
#include <stdbool.h>

NSErrorDomain const VMToolsLibraryErrorDomain = @"VMToolsLibraryErrorDomain";

NSString * const kVMToolsSessionVersion     = @"version";
NSString * const kVMToolsSessionUptime      = @"uptime";
NSString * const kVMToolsVersionStringKey   = @"versionString";
NSString * const kVMToolsVersionNumberKey   = @"versionNumber";
NSString * const kVMToolsBuildNumberKey     = @"buildNumber";
NSString * const kVMToolsDescriptionKey     = @"description";

// Signatures from open-vm-tools (vmware/tools/guestrpc.h, vmcheck.h, util.h).
// gboolean is an int.
typedef int (*RpcChannel_SendOneRawFn)(const char *data, size_t dataLen,
                                       char **result, size_t *resultLen);
typedef bool (*VmCheck_IsVirtualWorldFn)(void);
typedef void (*vm_freeFn)(void *ptr);

@implementation VMToolsLibrary {
    void *_handle;
    RpcChannel_SendOneRawFn _sendOneRaw;
    VmCheck_IsVirtualWorldFn _isVirtualWorld;
    vm_freeFn _vmFree;
}

+ (NSString *)defaultLibraryPath
{
    return @"/Library/Application Support/VMware Tools/Frameworks/libvmtools.dylib";
}

+ (VMToolsLibrary *)sharedLibrary
{
    static VMToolsLibrary *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shared = [[self alloc] initWithPath:self.defaultLibraryPath];
    });
    return shared;
}

- (instancetype)initWithPath:(NSString *)path
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // The dylib's own dependencies (glib, libintl, libdnet) are referenced via
    // @loader_path, so they load from the same Frameworks folder.
    _handle = dlopen(path.fileSystemRepresentation, RTLD_NOW | RTLD_LOCAL);
    if (_handle == NULL) {
        _loadError = [self lastDlError];
        return self;
    }
    
    _sendOneRaw = (RpcChannel_SendOneRawFn)dlsym(_handle, "RpcChannel_SendOneRaw");
    _isVirtualWorld = (VmCheck_IsVirtualWorldFn)dlsym(_handle, "VmCheck_IsVirtualWorld");
    _vmFree = (vm_freeFn)dlsym(_handle, "vm_free");
    
    if (_sendOneRaw == NULL || _isVirtualWorld == NULL || _vmFree == NULL) {
        _loadError = [self lastDlError];
        dlclose(_handle);
        _handle = NULL;
        _sendOneRaw = NULL;
        _isVirtualWorld = NULL;
        _vmFree = NULL;
        return self;
    }
    
    _loaded = YES;
    return self;
}

// The singleton lives for the whole process, so dlclose() is never called.

- (NSString *)lastDlError
{
    const char *msg = dlerror();
    return msg != NULL ? @(msg) : @"unknown dlopen error";
}

#pragma mark - Raw functions

- (BOOL)isVirtualWorld
{
    return _loaded && _isVirtualWorld();
}

- (NSData *)sendRPC:(NSString *)command error:(NSError **)error
{
    if (![self checkReady:error]) {
        return nil;
    }
    
    const char *cmd = command.UTF8String;
    char *reply = NULL;
    size_t replyLen = 0;
    BOOL ok = _sendOneRaw(cmd, strlen(cmd), &reply, &replyLen) != 0;
    
    NSData *data = reply != NULL ? [NSData dataWithBytes:reply length:replyLen]
    : [NSData data];
    _vmFree(reply);
    
    if (!ok) {
        // On failure the reply, if any, holds the host's error text.
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self setError:error code:VMToolsLibraryErrorRPCFailed
           description:[NSString stringWithFormat:@"RPC '%@' failed: %@",
                        command, msg.length > 0 ? msg : @"no reply"]];
        return nil;
    }
    return data;
}

- (NSString *)sendRPCString:(NSString *)command error:(NSError **)error
{
    NSData *data = [self sendRPC:command error:error];
    if (data == nil) {
        return nil;
    }
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (str == nil) {
        [self setError:error code:VMToolsLibraryErrorBadReply
           description:@"RPC reply is not valid UTF-8"];
    }
    return str;
}

#pragma mark - Stats

- (NSString *)rawStat:(NSString *)stat encoding:(NSString *)encoding error:(NSError **)error
{
    // Same command vmware-tools-cli sends for `stat raw <encoding> <stat>`.
    NSString *cmd = [NSString stringWithFormat:@"guestlib.stat.get %@ %@", encoding, stat];
    return [self sendRPCString:cmd error:error];
}

- (NSDictionary<NSString *, id> *)sessionInfo:(NSError **)error
{
    NSData *data = [self sendRPC:@"guestlib.stat.get json session" error:error];
    if (data == nil) {
        return nil;
    }
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (json != nil && ![json isKindOfClass:[NSDictionary class]]) {
        [self setError:error code:VMToolsLibraryErrorBadReply
           description:@"session stat is not a JSON object"];
        return nil;
    }
    return json;
}

- (NSNumber *)uptimeMicrosecondsFromSession:(NSDictionary<NSString *, id> *)session
{
    // "uptime":{"type":"static","units":"us","value":685509824116}
    id uptime = session[kVMToolsSessionUptime];
    id value = [uptime isKindOfClass:[NSDictionary class]] ? uptime[@"value"] : nil;
    if (![value isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    return value;
}

- (NSString *)hostVersionFromSession:(NSDictionary<NSString *, id> *)session
{
    // "version":"VMware ESX 6.7.0 build-20497097"
    id version = session[kVMToolsSessionVersion];
    if (![version isKindOfClass:[NSString class]]) {
        return nil;
    }
    return version;
}

#pragma mark - Tools version

- (NSString *)guestInfoValue:(NSString *)key error:(NSError **)error
{
    NSString *cmd = [NSString stringWithFormat:@"info-get guestinfo.%@", key];
    return [self sendRPCString:cmd error:error];
}

- (NSDictionary<NSString *, NSString *> *)toolsVersionInfo:(NSError **)error
{
    // vmware-tools-daemon publishes these at startup with
    // "info-set guestinfo.vmtools.<key> <value>".
    NSArray<NSString *> *keys = @[
        kVMToolsVersionStringKey,
        kVMToolsVersionNumberKey,
        kVMToolsBuildNumberKey,
        kVMToolsDescriptionKey];
    
    NSMutableDictionary<NSString *, NSString *> *info = [NSMutableDictionary dictionary];
    NSError *lastError = nil;
    
    for (NSString *key in keys) {
        NSString *guestInfoKey = [@"vmtools." stringByAppendingString:key];
        NSString *value = [self guestInfoValue:guestInfoKey error:&lastError];
        if (value != nil) {
            info[key] = value;
        } else if (lastError.code == VMToolsLibraryErrorNotLoaded ||
                   lastError.code == VMToolsLibraryErrorNotVirtual) {
            break;
        }
    }
    
    if (info.count == 0 && error != NULL) {
        *error = lastError;
        return nil;
    }
    
    return info;
}


#pragma mark - Helpers

- (BOOL)checkReady:(NSError **)error
{
    if (!_loaded) {
        [self setError:error code:VMToolsLibraryErrorNotLoaded
           description:[NSString stringWithFormat:@"libvmtools not loaded: %@", _loadError]];
        return NO;
    }
    // Guest RPC goes through the VMware backdoor, which only exists in a VM.
    if (!_isVirtualWorld()) {
        [self setError:error code:VMToolsLibraryErrorNotVirtual
           description:@"Not running inside a VMware virtual machine"];
        return NO;
    }
    return YES;
}

- (void)setError:(NSError **)error code:(VMToolsLibraryError)code description:(NSString *)desc
{
    if (error != NULL) {
        *error = [NSError errorWithDomain:VMToolsLibraryErrorDomain
                                     code:code
                                 userInfo:@{NSLocalizedDescriptionKey: desc}];
    }
}

@end
