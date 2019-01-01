//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//|             PTKDeviceManager.m
//|
//|             D.V.
//|             Copyright (c) 2014-2019 D.V. All rights reserved.
//|
//| Permission is hereby granted, free of charge, to any person obtaining a
//| copy of this software and associated documentation files (the "Software"),
//| to deal in the Software without restriction, including without limitation
//| the rights to use, copy, modify, merge, publish, distribute, sublicense,
//| and/or sell copies of the Software, and to permit persons to whom the
//| Software is furnished to do so, subject to the following conditions:
//|
//| The above copyright notice and this permission notice shall be included
//| in all copies or substantial portions of the Software.
//|
//| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//| OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//| MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//| IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//| CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//| TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//| SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//----------------------------------------------------------------------------//

@import IOKit.hid;
#import "PTKDeviceManager.h"
#import "PTKDevice.h"
#import "NSError+PKT.h"

extern const uint32_t kPTKPlasmaTrimVendorID;
extern const uint32_t kPTKPlasmaTrimProductID;

//---------------------------------------------------------------------------//
NSString * const PTKDeviceConnectedNotification = @"PTKDeviceConnectedNotification";
NSString * const PTKDeviceDisconnectedNotification = @"PTKDeviceDisconnectedNotification";
NSString * const PTKDeviceNotificationDeviceKey = @"PTKDeviceNotificationDeviceKey";



//----------------------------------------------------------------------------//
@implementation PTKDeviceManager {
    dispatch_semaphore_t _sema;
    IOHIDManagerRef _hidManager;
    NSMutableSet<PTKDevice*> *_devices;
}

//|++++++++++++++++++++++++++++++++++++|//
+ (void)hidThreadMain:(NSValue*)object
{
    PTKDeviceManager *deviceManager = [object nonretainedObjectValue];
    
    // Get all current devices
    NSSet *devices = (__bridge_transfer NSSet*)IOHIDManagerCopyDevices(deviceManager->_hidManager);
    [devices enumerateObjectsUsingBlock:^(id device, BOOL __unused *stop) {
        PTKDevice *newDevice = [[PTKDevice alloc] initWithIOHIDDevice:(__bridge IOHIDDeviceRef)device error:NULL];
        if (device)
            [deviceManager->_devices addObject:newDevice];
    }];
    
    IOHIDManagerRegisterDeviceMatchingCallback(deviceManager->_hidManager, &hid_device_matched, (__bridge void *)deviceManager);
    IOHIDManagerRegisterDeviceRemovalCallback(deviceManager->_hidManager, &hid_device_removed, (__bridge void *)deviceManager);
    IOHIDManagerScheduleWithRunLoop(deviceManager->_hidManager, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    dispatch_semaphore_signal(deviceManager->_sema);
    
    CFRunLoopRun();
}

//|++++++++++++++++++++++++++++++++++++|//
- (instancetype)initWithError:(NSError**)error
{
    self = [super init];
    if (self) {
        _devices = [[NSMutableSet alloc] initWithCapacity:10];
        _hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        if (!_hidManager)
            return nil;
        
        NSDictionary *matchingDictionary = @{
            @(kIOHIDVendorIDKey): @(kPTKPlasmaTrimVendorID),
            @(kIOHIDProductIDKey): @(kPTKPlasmaTrimProductID)
        };
        IOHIDManagerSetDeviceMatching(_hidManager, (__bridge CFDictionaryRef)matchingDictionary);
        
        IOReturn status = IOHIDManagerOpen(_hidManager, kIOHIDOptionsTypeNone);
        if (status != kIOReturnSuccess) {
            if (error) *error = [NSError ioKitErrorWithCode:status description:@"Failed to open IOHIDManager."];
            return nil;
        }
        
        _sema = dispatch_semaphore_create(0);
        [NSThread detachNewThreadSelector:@selector(hidThreadMain:) toTarget:self.class withObject:[NSValue valueWithNonretainedObject:self]];
        dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
    }
    return self;
}

//|++++++++++++++++++++++++++++++++++++|//
- (instancetype)init
{ return [self initWithError:NULL]; }

//|++++++++++++++++++++++++++++++++++++|//
- (void)dealloc
{
    if (_hidManager) {
        IOHIDManagerClose(_hidManager, kIOHIDOptionsTypeNone);
        CFRelease(_hidManager);
    }
}

//|++++++++++++++++++++++++++++++++++++|//
- (NSSet<PTKDevice*> *)connectedDevices
{
    @synchronized(_devices) {
        return [_devices copy];
    }
}

//|++++++++++++++++++++++++++++++++++++|//
static void hid_device_matched(void *context, IOReturn result, void *sender, IOHIDDeviceRef device)
{
#pragma unused (result)
#pragma unused (sender)
    PTKDeviceManager *self = (__bridge PTKDeviceManager*)context;
    
    PTKDevice *newDevice = [[PTKDevice alloc] initWithIOHIDDevice:device error:NULL];
    if (!device)
        return;
    
    @synchronized(self->_devices) {
        [self->_devices addObject:newDevice];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PTKDeviceConnectedNotification object:self userInfo:@{PTKDeviceNotificationDeviceKey: newDevice}];
    });
}

//|++++++++++++++++++++++++++++++++++++|//
static void hid_device_removed(void *context, IOReturn result, void *sender, IOHIDDeviceRef device)
{
#pragma unused (result)
#pragma unused (sender)
    PTKDeviceManager *self = (__bridge PTKDeviceManager*)context;
    
    __block PTKDevice *outgoingDevice;
    @synchronized(self->_devices) {
        [self->_devices enumerateObjectsUsingBlock:^(PTKDevice *obj, BOOL *stop) {
            if (CFEqual(obj.device, device)) { outgoingDevice = obj; *stop = YES; }
        }];
        
        if (outgoingDevice) [self->_devices removeObject:outgoingDevice];
    }
    
    if (outgoingDevice)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PTKDeviceDisconnectedNotification object:self userInfo:@{PTKDeviceNotificationDeviceKey: outgoingDevice}];
        });
}

@end
