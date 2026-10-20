//
//  MLVMwareResolutionCommand.m
//  VMware
//
//  Created by Martin Løbger on 04/01/2022.
//  Copyright © 2022 ML-Consulting. All rights reserved.
//

#import "MLVMwareResolutionCommand.h"

NSString* const kVMwareToolsResolutionSet   = @"vmware-resolutionSet";

typedef struct
{
    uint32_t screen :32;
    uint32_t width  :32;
    uint32_t height :32;
} SetResReq;


//@interface MLVMwareResolutionCommand ()
//@end

@implementation MLVMwareResolutionCommand
{
    NSUInteger _width;
    NSUInteger _height;
}

- (instancetype)init:(NSUInteger)width height:(NSUInteger)height
{
    NSArray* arguments = @[@(width).stringValue, @(height).stringValue];
    if (self = [super initWithArguments:arguments])
    {
        _width = width;
        _height = height;
    }
    return self;
}

+ (instancetype)resolutionSet:(NSUInteger)width height:(NSUInteger)height
{
    return [[MLVMwareResolutionCommand alloc] init:width height:height];
}

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
        .screen = 1,
        .width = (uint32_t)_width,
        .height = (uint32_t)_height
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


