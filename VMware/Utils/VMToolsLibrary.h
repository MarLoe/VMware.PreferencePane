//
//  VMToolsLibrary.h
//
//  Loads libvmtools.dylib at runtime with dlopen() and exposes the guest RPC
//  functions. Nothing to link against: don't pass -lvmtools.
//
//  libvmtools.dylib is x86_64 only, so build the host process for x86_64.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const VMToolsLibraryErrorDomain;

typedef NS_ERROR_ENUM(VMToolsLibraryErrorDomain, VMToolsLibraryError) {
   VMToolsLibraryErrorNotLoaded = 1,   // dlopen()/dlsym() failed
   VMToolsLibraryErrorNotVirtual,      // not running inside a VMware VM
   VMToolsLibraryErrorRPCFailed,       // the host rejected or failed the RPC
   VMToolsLibraryErrorBadReply,        // reply could not be parsed
};

@interface VMToolsLibrary : NSObject

/// The shared instance. The library is loaded on first access.
@property (class, nonatomic, readonly) VMToolsLibrary *sharedLibrary;

/// Default: /Library/Application Support/VMware Tools/Frameworks/libvmtools.dylib
@property (class, nonatomic, readonly) NSString *defaultLibraryPath;

/// YES when the dylib and all required symbols were found.
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

/// The dlopen()/dlsym() message when loading failed, otherwise nil.
@property (nonatomic, readonly, copy, nullable) NSString *loadError;

/// Wraps VmCheck_IsVirtualWorld(). NO also when the library isn't loaded.
@property (nonatomic, readonly, getter=isVirtualWorld) BOOL virtualWorld;

/// Wraps RpcChannel_SendOneRaw(): sends a guest RPC and returns the reply
/// payload (without the "1 " status prefix).
- (nullable NSData *)sendRPC:(NSString *)command error:(NSError **)error;

/// Same as -sendRPC:error: but decodes the reply as UTF-8.
- (nullable NSString *)sendRPCString:(NSString *)command error:(NSError **)error;

/// Equivalent of `vmware-tools-cli stat raw <encoding> <stat>`.
/// encoding: "text", "json", "xml" or "yaml"; stat: "session", "host", ...
- (nullable NSString *)rawStat:(NSString *)stat
                      encoding:(NSString *)encoding
                         error:(NSError **)error;

/// `stat raw json session`, parsed with NSJSONSerialization.
- (nullable NSDictionary<NSString *, id> *)sessionInfo:(NSError **)error;

/// Host uptime in microseconds ("uptime".value from the session stat).
- (nullable NSNumber *)uptimeMicrosecondsFromSession:(NSDictionary<NSString *, id> *)session;

/// Host version string, e.g. "VMware ESX 6.7.0 build-20497097".
- (nullable NSString *)hostVersionFromSession:(NSDictionary<NSString *, id> *)session;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
