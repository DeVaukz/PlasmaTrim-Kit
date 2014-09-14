//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//|             PTKDevice.m
//|
//|             D.V.
//|             Copyright (c) 2014 D.V. All rights reserved.
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

#import "PTKDevice.h"
#import "NSError+PKT.h"

#define REPORT_SIZE 32

const uint32_t kPTKPlasmaTrimVendorID = 0x26f3;
const uint32_t kPTKPlasmaTrimProductID = 0x1000;

struct __attribute((packed)) PlasmaTrimHIDReport {
    uint8_t command;
    uint8_t data[31];
};

typedef void (^HIDResponse)(struct PlasmaTrimHIDReport const * report, NSError* error);
HIDResponse nullCallback = ^(struct PlasmaTrimHIDReport const * __unused report, NSError* __unused error) { };


//----------------------------------------------------------------------------//
@implementation PTKDevice {
    IOHIDDeviceRef _device;
    CFRunLoopRef _runLoop;
    dispatch_queue_t _queue;
    //! Array of \ref HIDResponse blocks.  The first block is executed each
    //! time a HID report is received.
    NSMutableArray *_replyQueue;
    uint8_t _inboundReportBuffer[REPORT_SIZE];
    struct {
        BOOL isConnectionOpen :1;
    } _flags;
}

//|++++++++++++++++++++++++++++++++++++|//
- (instancetype)initWithIOHIDDevice:(IOHIDDeviceRef)device error:(NSError**)error
{
#pragma unused (error)
    self = [super init];
    if (self)
    {
        char buffer[512];
        sprintf(buffer, "PlasmaTrimKit.device.%x", (unsigned int)device);
        _replyQueue = [[NSMutableArray alloc] initWithCapacity:2];
        _queue = dispatch_queue_create(buffer, NULL);
        _runLoop = (CFRunLoopRef)CFRetain( CFRunLoopGetCurrent() );
        _device = (IOHIDDeviceRef)CFRetain(device);
        
        // Verify that the vendor ID matches
        NSNumber *vendorID = [self _getNumberProperty:CFSTR(kIOHIDVendorIDKey) ofDevice:device error:error];
        if (!vendorID) return nil;
        if ([vendorID unsignedIntegerValue] != kPTKPlasmaTrimVendorID) {
            if (error) *error = [NSError ioKitErrorWithCode:0 description:[NSString stringWithFormat:@"IOHIDDeviceGetProperty(kIOHIDVendorIDKey) returned %@; expected %i.", vendorID, kPTKPlasmaTrimVendorID]];
            return nil;
        }
        
        // Verify that the product ID matches
        NSNumber *productID = [self _getNumberProperty:CFSTR(kIOHIDProductIDKey) ofDevice:device error:error];
        if (!productID) return nil;
        if ([productID unsignedIntegerValue] != kPTKPlasmaTrimProductID) {
            if (error) *error = [NSError ioKitErrorWithCode:0 description:[NSString stringWithFormat:@"IOHIDDeviceGetProperty(kIOHIDProductIDKey) returned %@; expected %i.", productID, kPTKPlasmaTrimProductID]];
            return nil;
        }
        
        // Verify that the report size is 32
        NSNumber *deviceInboundReportSize = [self _getNumberProperty:CFSTR(kIOHIDMaxInputReportSizeKey) ofDevice:device error:error];
        if (!deviceInboundReportSize) return nil;
        if ([deviceInboundReportSize unsignedIntegerValue] != REPORT_SIZE) {
            if (error) *error = [NSError ioKitErrorWithCode:0 description:[NSString stringWithFormat:@"IOHIDDeviceGetProperty(kIOHIDMaxInputReportSizeKey) returned %@; expected %d.", deviceInboundReportSize, REPORT_SIZE]];
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    [self closeWithError:NULL];
    if (_runLoop) CFRelease(_runLoop);
    if (_device) CFRelease(_device);
}

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark - I/O Kit Helpers
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//|++++++++++++++++++++++++++++++++++++|//
- (NSNumber*)_getNumberProperty:(CFStringRef)key ofDevice:(IOHIDDeviceRef)device error:(NSError**)error
{
    CFNumberRef retValue = IOHIDDeviceGetProperty(device, key);
    
    if (CFGetTypeID(retValue) != CFNumberGetTypeID()) {
        if (error) *error = [NSError ioKitErrorWithCode:0 description:[NSString stringWithFormat:@"IOHIDDeviceGetProperty(%@) returned an invalid value.", key]];
        return nil;
    }
    
    return (__bridge NSNumber*)retValue;
}

//|++++++++++++++++++++++++++++++++++++|//
- (NSString*)_getStringProperty:(CFStringRef)key ofDevice:(IOHIDDeviceRef)device error:(NSError**)error
{
    CFStringRef retValue = IOHIDDeviceGetProperty(device, key);
    
    if (CFGetTypeID(retValue) != CFStringGetTypeID()) {
        if (error) *error = [NSError ioKitErrorWithCode:0 description:[NSString stringWithFormat:@"IOHIDDeviceGetProperty(%@) returned an invalid value.", key]];
        return nil;
    }
    
    return (__bridge NSString*)retValue;
}

//|++++++++++++++++++++++++++++++++++++|//
//! Must be called from the device's dispatch queue.
- (void)_sendCommand:(struct PlasmaTrimHIDReport const *)command responseHandler:(void (^)(struct PlasmaTrimHIDReport const * response, NSError *error))responseHandler
{
    IOReturn res = IOHIDDeviceSetReport(_device, kIOHIDReportTypeOutput, command->command, (uint8_t*)command, REPORT_SIZE);
    if (res != kIOReturnSuccess) {
        NSError *error = [NSError ioKitErrorWithCode:res description:[NSString stringWithFormat:@"Failed to send message."]];
        responseHandler(NULL, error);
        return;
    }
    
    [_replyQueue addObject:responseHandler];
}

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark - Establishing A Connection To The Device
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//|++++++++++++++++++++++++++++++++++++|//
static void hid_report_callback(void *context, IOReturn result, void *sender, IOHIDReportType report_type, uint32_t report_id, uint8_t *report, CFIndex report_length)
{
#pragma unused (sender)
#pragma unused (report_id)
#if DEBUG
    NSLog(@"Got HID report: %@", [NSData dataWithBytes:report length:report_length]);
#endif
    
    PTKDevice *self = (__bridge PTKDevice*)context;
    NSCAssert(report_type == kIOHIDReportTypeInput, @"Did not receive an input report.");
    
    HIDResponse callback = [self->_replyQueue firstObject];
    NSCAssert(callback != nil, @"Got a report without a pending callback.");
    [self->_replyQueue removeObjectAtIndex:0];
    
    // If the originator does not care about receiving the response, don't
    // send it.
    if (callback != nullCallback)
    {
        if (result == kIOReturnSuccess) {
            // We need this to be copied by the block.
            struct PlasmaTrimHIDReport response;
            NSCAssert(report_length == REPORT_SIZE, @"Got an invalid report length %lu", report_length);
            memcpy(&response, report, report_length);
            
            callback(&response, nil);
        } else {
            callback(NULL, [NSError ioKitErrorWithCode:result description:@""]);
        }
    }
}

//|++++++++++++++++++++++++++++++++++++|//
- (BOOL)isOpen
{ return _flags.isConnectionOpen; }

//|++++++++++++++++++++++++++++++++++++|//
- (BOOL)openWithError:(NSError**)error
{
    __block BOOL success = NO;
    dispatch_sync(_queue, ^{
        if (_flags.isConnectionOpen)
            return;
        
        IOReturn ret = IOHIDDeviceOpen(_device, kIOHIDOptionsTypeNone);
        if (ret != kIOReturnSuccess) {
            if (error) *error = [NSError ioKitErrorWithCode:ret description:@"Failed to open device."];
            return;
        }
        
        IOHIDDeviceScheduleWithRunLoop(_device, _runLoop, kCFRunLoopDefaultMode);
        IOHIDDeviceRegisterInputReportCallback(_device, _inboundReportBuffer, sizeof(_inboundReportBuffer), &hid_report_callback, (__bridge void*)self);
        
        _flags.isConnectionOpen = YES;
        success = YES;
    });
    return success;
}

//|++++++++++++++++++++++++++++++++++++|//
- (BOOL)closeWithError:(NSError**)error
{
    __block BOOL success = NO;
    dispatch_sync(_queue, ^{
        if (!_flags.isConnectionOpen)
            return;
        
        // Pretend the connection always closed successfully.
        _flags.isConnectionOpen = NO;
        
        IOHIDDeviceRegisterInputReportCallback(_device, _inboundReportBuffer, sizeof(_inboundReportBuffer), NULL, (__bridge void*)self);
        IOHIDDeviceUnscheduleFromRunLoop(_device, _runLoop, kCFRunLoopDefaultMode);
        
        IOReturn ret = IOHIDDeviceClose(_device, kIOHIDOptionsTypeNone);
        if (ret != kIOReturnSuccess) {
            if (error) *error = [NSError ioKitErrorWithCode:ret description:@"Failed to close device cleanly."];
            return;
        }
        
        success = YES;
    });
    return success;
}

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark - Device Properties
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//|++++++++++++++++++++++++++++++++++++|//
- (NSNumber*)vendorID
{ return [self _getNumberProperty:CFSTR(kIOHIDVendorIDKey) ofDevice:_device error:NULL]; }

//|++++++++++++++++++++++++++++++++++++|//
- (NSNumber*)productID
{ return [self _getNumberProperty:CFSTR(kIOHIDProductIDKey) ofDevice:_device error:NULL]; }

//|++++++++++++++++++++++++++++++++++++|//
- (NSString*)vendorName
{ return [self _getStringProperty:CFSTR(kIOHIDManufacturerKey) ofDevice:_device error:NULL]; }

//|++++++++++++++++++++++++++++++++++++|//
- (NSString*)productName
{ return [self _getStringProperty:CFSTR(kIOHIDProductKey) ofDevice:_device error:NULL]; }

//|++++++++++++++++++++++++++++++++++++|//
- (NSUInteger)lampCount
{ return 8; }

//|++++++++++++++++++++++++++++++++++++|//
- (void)recallSerialNumberWithCompletion:(void (^)(NSString *serial, NSError *error))completion
{
    if (!completion)
        return;
    
    dispatch_async(_queue, ^{
        struct PlasmaTrimHIDReport command = { .command=0xA, .data={0x0} };
        [self _sendCommand:&command responseHandler:^(const struct PlasmaTrimHIDReport * response, NSError *error) {
            NSString *serialNumber;
            if (response->command != 0xA)
                error = [NSError errorWithDomain:PTKErrorDomain code:0x3 userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when reading device serial number."}];
            else
                serialNumber = [NSString stringWithFormat:@"%.2x%.2x%.2x%.2x", response->data[3], response->data[2], response->data[1], response->data[0]];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(serialNumber, error); });
        }];
    });
}

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark - Working With Sequences
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//|++++++++++++++++++++++++++++++++++++|//
- (void)stopCurrentSequenceWithCompletion:(void (^)(NSError *error))completion
{
    dispatch_async(_queue, ^{
        struct PlasmaTrimHIDReport command = { .command=0x3, .data={0x0} };
        if (completion == NULL)
            [self _sendCommand:&command responseHandler:nullCallback];
        else
            [self _sendCommand:&command responseHandler:^(const struct PlasmaTrimHIDReport * response, NSError *error) {
                if (response->command != 0x3)
                    error = [NSError errorWithDomain:PTKErrorDomain code:0x3 userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when stopping sequence."}];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(error); });
            }];
    });
}

//|++++++++++++++++++++++++++++++++++++|//
- (void)startCurrentSequenceWithCompletion:(void (^)(NSError *error))completion
{
    dispatch_async(_queue, ^{
        struct PlasmaTrimHIDReport command = { .command=0x2, .data={0x0} };
        if (completion == NULL)
            [self _sendCommand:&command responseHandler:nullCallback];
        else
            [self _sendCommand:&command responseHandler:^(const struct PlasmaTrimHIDReport * response, NSError *error) {
                if (response->command != 0x2)
                    error = [NSError errorWithDomain:PTKErrorDomain code:0x2 userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when starting sequence."}];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(error); });
            }];
    });
}

@end
