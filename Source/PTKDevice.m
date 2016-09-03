//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//|             PTKDevice.m
//|
//|             D.V.
//|             Copyright (c) 2014-2015 D.V. All rights reserved.
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
#import "PTKDeviceState.h"
#import "NSError+PKT.h"

#define REPORT_SIZE 32
// All PlasmaTrim devices have 8 lamps.
#define LAMP_COUNT  8

const uint32_t kPTKPlasmaTrimVendorID = 0x26f3;
const uint32_t kPTKPlasmaTrimProductID = 0x1000;

struct __attribute((packed)) PlasmaTrimHIDReport {
    uint8_t command;
    uint8_t data[31];
};

typedef void (^HIDResponse)(struct PlasmaTrimHIDReport const * report, NSError* error);
// Callback used when the sender does not care about handling the response.
HIDResponse nullCallback = ^(struct PlasmaTrimHIDReport const * __unused report, NSError* __unused error) { };


//----------------------------------------------------------------------------//
@implementation PTKDevice {
    //! The run lopp this device was initialied on.  Used to schedule the
    //! I/O HID report callback once the device is opened.
    CFRunLoopRef _runLoop;
    dispatch_queue_t _queue;
    //! Array of \ref HIDResponse blocks.  The first block is executed each
    //! time a HID report is received.
    NSMutableArray *_replyQueue;
    //! Buffer to receive I/O HID reports.
    uint8_t _inboundReportBuffer[REPORT_SIZE];
    struct {
        BOOL isConnectionOpen :1;
    } _flags;
}

//|++++++++++++++++++++++++++++++++++++|//
- (instancetype)initWithIOHIDDevice:(IOHIDDeviceRef)device error:(NSError**)error
{
    if (!device) return nil;
    
    self = [super init];
    if (self)
    {
        char buffer[512];
        sprintf(buffer, "PlasmaTrimKit.device.%x", (unsigned int)device);
        _replyQueue = [[NSMutableArray alloc] initWithCapacity:2];
        _queue = dispatch_queue_create(buffer, NULL);
        _runLoop = (CFRunLoopRef)CFRetain(CFRunLoopGetCurrent());
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

//|++++++++++++++++++++++++++++++++++++|//
- (void)dealloc
{
    [self closeWithError:NULL];
    if (_runLoop) CFRelease(_runLoop);
    if (_device) CFRelease(_device);
}

//|++++++++++++++++++++++++++++++++++++|//
- (NSUInteger)hash
{
    return (NSUInteger)_device;
}

//|++++++++++++++++++++++++++++++++++++|//
- (BOOL)isEqual:(PTKDevice*)other
{
    if (![other isKindOfClass:PTKDevice.class])
        return NO;
    
    return !!CFEqual(self->_device, other->_device);
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
//! Callback to handle I/O HID reports.
static void hid_report_callback(void *context, IOReturn result, void *sender, IOHIDReportType report_type, uint32_t report_id, uint8_t *report, CFIndex report_length)
{
#pragma unused (sender)
#pragma unused (report_id)
#if DEBUG
    NSLog(@"Got HID report: %@", [NSData dataWithBytes:report length:(NSUInteger)report_length]);
#endif
    
    PTKDevice *self = (__bridge PTKDevice*)context;
    NSCAssert(report_type == kIOHIDReportTypeInput, @"Did not receive an input report.");
    
    __block HIDResponse callback;
    dispatch_sync(self->_queue, ^{
        callback = [self->_replyQueue firstObject];
        NSCAssert(callback != nil, @"Got a report without a pending callback.");
        [self->_replyQueue removeObjectAtIndex:0];
    });
    
    // If the originator does not care about receiving the response, don't
    // send it.
    if (callback != nullCallback)
    {
        if (result == kIOReturnSuccess) {
            // We need this to be copied by the block.
            struct PlasmaTrimHIDReport response;
            NSCAssert(report_length == REPORT_SIZE, @"Got an invalid report length %lu", report_length);
            memcpy(&response, report, (unsigned long)report_length);
            
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
        if (self->_flags.isConnectionOpen) {
            success = YES;
            return;
        }
        
        IOReturn ret = IOHIDDeviceOpen(self->_device, kIOHIDOptionsTypeNone);
        if (ret != kIOReturnSuccess) {
            if (error) *error = [NSError ioKitErrorWithCode:ret description:@"Failed to open device."];
            return;
        }
        
        IOHIDDeviceScheduleWithRunLoop(self->_device, self->_runLoop, kCFRunLoopDefaultMode);
        IOHIDDeviceRegisterInputReportCallback(self->_device, self->_inboundReportBuffer, sizeof(self->_inboundReportBuffer), &hid_report_callback, (__bridge void*)self);
        
        self->_flags.isConnectionOpen = YES;
        success = YES;
    });
    return success;
}

//|++++++++++++++++++++++++++++++++++++|//
- (BOOL)closeWithError:(NSError**)error
{
    __block BOOL success = NO;
    dispatch_sync(_queue, ^{
        if (!self->_flags.isConnectionOpen)  {
            success = YES;
            return;
        }
        
        // Pretend the connection always closed successfully.
        self->_flags.isConnectionOpen = NO;
        
        IOHIDDeviceRegisterInputReportCallback(self->_device, self->_inboundReportBuffer, sizeof(self->_inboundReportBuffer), NULL, (__bridge void*)self);
        IOHIDDeviceUnscheduleFromRunLoop(self->_device, self->_runLoop, kCFRunLoopDefaultMode);
        
        IOReturn ret = IOHIDDeviceClose(self->_device, kIOHIDOptionsTypeNone);
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
{ return LAMP_COUNT; }

//|++++++++++++++++++++++++++++++++++++|//
- (void)recallSerialNumberWithCompletion:(void (^)(NSString *serial, NSError *error))completion
{
    if (!completion)
        return;
    
    dispatch_async(_queue, ^{
        struct PlasmaTrimHIDReport command = { .command=0xA, .data={0x0} };
        [self _sendCommand:&command responseHandler:^(const struct PlasmaTrimHIDReport * response, NSError *error) {
            NSString *serialNumber;
            if (!response || response->command != 0xA)
                error = [NSError errorWithDomain:PTKErrorDomain code:0xA userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when reading device serial number."}];
            else
                serialNumber = [NSString stringWithFormat:@"%.2x%.2x%.2x%.2x", response->data[3], response->data[2], response->data[1], response->data[0]];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(serialNumber, error); });
        }];
    });
}

//|++++++++++++++++++++++++++++++++++++|//
- (void)storeName:(NSString *)name completion:(void (^)(NSError *error))completion
{
    name = [name copy];
    
    dispatch_async(_queue, ^{
        struct PlasmaTrimHIDReport command = { .command=0x8, .data={0x0} };
        [name getBytes:command.data maxLength:26 usedLength:NULL encoding:NSASCIIStringEncoding options:NSStringEncodingConversionAllowLossy range:NSMakeRange(0, name.length) remainingRange:NULL];
        
        if (completion == NULL)
            [self _sendCommand:&command responseHandler:nullCallback];
        else
            [self _sendCommand:&command responseHandler:^(const struct PlasmaTrimHIDReport * response, NSError *error) {
                if (!response || response->command != 0x8)
                    error = [NSError errorWithDomain:PTKErrorDomain code:0x8 userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when storing device name."}];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(error); });
            }];
    });
}

//|++++++++++++++++++++++++++++++++++++|//
- (void)recallNameWithCompletion:(void (^)(NSString *name, NSError *error))completion
{
    if (!completion)
        return;
    
    dispatch_async(_queue, ^{
        struct PlasmaTrimHIDReport command = { .command=0x9, .data={0x0} };
        [self _sendCommand:&command responseHandler:^(const struct PlasmaTrimHIDReport * response, NSError *error) {
            NSString *name;
            if (!response || response->command != 0x9)
                error = [NSError errorWithDomain:PTKErrorDomain code:0x9 userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when reading device name."}];
            else
                name = [[NSString alloc] initWithBytes:response->data length:strnlen((char*)response->data, 26) encoding:NSASCIIStringEncoding];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(name, error); });
        }];
    });
}

//|++++++++++++++++++++++++++++++++++++|//
- (void)storeBrightness:(int8_t)brightness completion:(void (^)(NSError *error))completion
{
    if (brightness < 0 || brightness > 100)
        @throw [NSException exceptionWithName:NSRangeException reason:@"Brightness must be within [0, 100]" userInfo:nil];
    
    dispatch_async(_queue, ^{
        struct PlasmaTrimHIDReport command = { .command=0xB, .data={0x0} };
        command.data[0] = (uint8_t)brightness;
        
        if (completion == NULL)
            [self _sendCommand:&command responseHandler:nullCallback];
        else
            [self _sendCommand:&command responseHandler:^(const struct PlasmaTrimHIDReport * response, NSError *error) {
                if (!response || response->command != 0xB)
                    error = [NSError errorWithDomain:PTKErrorDomain code:0xB userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when storing brightness."}];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(error); });
            }];
    });
}

//|++++++++++++++++++++++++++++++++++++|//
- (void)recallBrightnessWithCompletion:(void (^)(int8_t brightness, NSError *error))completion
{
    if (!completion)
        return;
    
    dispatch_async(_queue, ^{
        struct PlasmaTrimHIDReport command = { .command=0xC, .data={0x0} };
        [self _sendCommand:&command responseHandler:^(const struct PlasmaTrimHIDReport * response, NSError *error) {
            int8_t brightness = -1;
            if (!response || response->command != 0xC)
                error = [NSError errorWithDomain:PTKErrorDomain code:0xC userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when reading brightness."}];
            else
                brightness = (int8_t)response->data[0];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(brightness, error); });
        }];
    });
}

//|++++++++++++++++++++++++++++++++++++|//
- (void)setDeviceState:(PTKDeviceState*)deviceState completion:(void (^)(NSError *error))completion
{
    uint8_t brightness = (uint8_t)deviceState.brightness;
    if (brightness < 0 || brightness > 100)
        @throw [NSException exceptionWithName:NSRangeException reason:@"Brightness must be within [0, 100]" userInfo:nil];
    
    struct PlasmaTrimHIDReport command = { .command=0x0, .data={0x0} };
    uint8_t componentValues[3][LAMP_COUNT];
    [deviceState getRed:componentValues[0] green:componentValues[1] blue:componentValues[2] forLampsInRange:NSMakeRange(0, LAMP_COUNT)];
    for (uint8_t i = 0; i < LAMP_COUNT; i++) {
        command.data[i*3] = componentValues[0][i];
        command.data[i*3 + 1] = componentValues[1][i];
        command.data[i*3 + 2] = componentValues[2][i];
    }
    command.data[24] = brightness;
    
    dispatch_async(_queue, ^{
        if (completion == NULL)
            [self _sendCommand:&command responseHandler:nullCallback];
        else
            [self _sendCommand:&command responseHandler:^(const struct PlasmaTrimHIDReport * response, NSError *error) {
                if (!response || response->command != 0x0)
                    error = [NSError errorWithDomain:PTKErrorDomain code:0x0 userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when writing device state."}];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(error); });
            }];
    });
}

//|++++++++++++++++++++++++++++++++++++|//
- (void)getDeviceStateWithCompletion:(void (^)(PTKDeviceState *deviceState, NSError *error))completion
{
    if (!completion)
        return;
    
    dispatch_async(_queue, ^{
        struct PlasmaTrimHIDReport command = { .command=0x1, .data={0x0} };
        [self _sendCommand:&command responseHandler:^(const struct PlasmaTrimHIDReport * response, NSError *error) {
            PTKDeviceState *state;
            if (!response || response->command != 0x1)
                error = [NSError errorWithDomain:PTKErrorDomain code:0x1 userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when reading device state."}];
            else {
                state = [PTKDeviceState emptyDeviceStateForCompatibilityWithDevice:self];
                uint8_t componentValues[3][LAMP_COUNT];
                for (uint8_t i = 0; i < LAMP_COUNT; i++) {
                    componentValues[0][i] = response->data[i*3];
                    componentValues[1][i] = response->data[i*3 + 1];
                    componentValues[2][i] = response->data[i*3 + 2];
                }
                [state setRed:componentValues[0] green:componentValues[1] blue:componentValues[2] forLampsInRange:NSMakeRange(0, LAMP_COUNT)];
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(state, error); });
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
                if (!response || response->command != 0x3)
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
                if (!response || response->command != 0x2)
                    error = [NSError errorWithDomain:PTKErrorDomain code:0x2 userInfo:@{NSLocalizedDescriptionKey : @"Received an invalid response when starting sequence."}];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ completion(error); });
            }];
    });
}

@end
