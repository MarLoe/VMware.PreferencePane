//
//  MLVMwareGfxCommand.m
//  VMware
//
//  Created by Martin Løbger on 04/01/2022.
//  Copyright © 2022 ML-Consulting. All rights reserved.
//

#import "MLVMwareGfxCommand.h"

typedef struct
{
    uint32_t flags  :32;
    uint32_t width  :32;
    uint32_t height :32;
} SetResReq;


@interface MLVMwareGfxResolutionCommand ()

@property (nonatomic, assign) NSUInteger    flags;
@property (nonatomic, assign) NSUInteger    width;
@property (nonatomic, assign) NSUInteger    height;

@end


@implementation MLVMwareGfxResolutionCommand

- (NSError*)execute
{
    CFMutableDictionaryRef s = IOServiceMatching("VMwareGfx");
    
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, s);
    
    io_connect_t handle = 0;
    kern_return_t result = IOServiceOpen(service, mach_task_self(), 0x0103, &handle);
    IOObjectRelease(service);
    if (result != kIOReturnSuccess) {
        NSLog(@"%08x", result);
        return [NSError errorWithDomain:MLCommandErrorDomain
                                   code:result
                               userInfo:@{ NSLocalizedDescriptionKey: @"Failed to open service" }];
    }
    
    SetResReq req = {
        .flags = (uint32_t)_flags,
        .width = (uint32_t)_width,
        .height = (uint32_t)_height,
    };
    size_t szReq = sizeof(req);
    
    SetResReq res;
    size_t szRes = sizeof(res);
    memset(&res, 0xaa, szRes);
    
    result = IOConnectCallStructMethod(handle, 0x00, &req, szReq, &res, &szRes);
    IOServiceClose(handle);
    if (result != kIOReturnSuccess) {
        NSLog(@"%08x", result);
        return [NSError errorWithDomain:MLCommandErrorDomain
                                   code:result
                               userInfo:@{ NSLocalizedDescriptionKey: @"Failed to set resolution" }];
    }
    
    return nil;
}
@end


@implementation MLVMwareGfxGetResolutionCommand

- (instancetype)init {
    if (self = [super initCommand:kVMwareToolsResolutionSet withArguments:nil]) {
        self.flags = 0;
        self.width = 0;
        self.height = 0;
        return self;
    }
    
    return nil;
}

+ (instancetype)getResolution {
    return [[MLVMwareGfxGetResolutionCommand alloc] init];
}

@end


@implementation MLVMwareGfxSetResolutionCommand

- (instancetype)init:(NSUInteger)width height:(NSUInteger)height
{
    NSArray<NSString*>* arguments = @[@(width).stringValue, @(height).stringValue];
    if (self = [super initCommand:kVMwareToolsResolutionSet withArguments:arguments])
    {
        self.flags = 1;
        self.width = width;
        self.height = height;
    }
    return self;
}

+ (instancetype)resolutionSet:(NSUInteger)width height:(NSUInteger)height
{
    return [[MLVMwareGfxSetResolutionCommand alloc] init:width height:height];
}

@end


