//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//|             PTKDeviceSpec.m
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

@import PlasmaTrimKit;
#import "Specta.h"
#define EXP_SHORTHAND 1
#import "Expecta.h"

extern const uint32_t kPTKPlasmaTrimVendorID;
extern const uint32_t kPTKPlasmaTrimProductID;

SpecBegin(PTKDevice)

describe(@"the creation of a device", ^{
    
    it(@"should initialize, open and close with a PlasmaTrim device", ^{
        IOHIDManagerRef hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        NSDictionary *matchingDictionary = @{
            @(kIOHIDVendorIDKey): @(kPTKPlasmaTrimVendorID),
            @(kIOHIDProductIDKey): @(kPTKPlasmaTrimProductID)
        };
        IOHIDManagerSetDeviceMatching(hidManager, (__bridge CFDictionaryRef)matchingDictionary);
        
        NSSet *devices = (__bridge NSSet*)IOHIDManagerCopyDevices(hidManager);
        //Can't do this test without a device.
        expect(@(devices.count)).to.beGreaterThan(@(0));
        
        if (devices.count > 0) {
            NSError *error;
            PTKDevice *device = [[PTKDevice alloc] initWithIOHIDDevice:(__bridge IOHIDDeviceRef)[devices anyObject] error:&error];
            expect(device).toNot.beNil();
            expect(error).to.beNil();
            
            error = nil;
            BOOL didOpen = [device openWithError:&error];
            expect(didOpen).to.beTruthy();
            expect(error).to.beNil();
            
            error = nil;
            BOOL didClose = [device closeWithError:&error];
            expect(didClose).to.beTruthy();
            expect(error).to.beNil();
        }
        
        IOHIDManagerClose(hidManager, kIOHIDOptionsTypeNone);
    });
    
});

describe(@"a connection to the device", ^{
    __block PTKDevice *device;
    
    beforeAll(^{
        IOHIDManagerRef hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        NSDictionary *matchingDictionary = @{
            @(kIOHIDVendorIDKey): @(kPTKPlasmaTrimVendorID),
            @(kIOHIDProductIDKey): @(kPTKPlasmaTrimProductID)
        };
        IOHIDManagerSetDeviceMatching(hidManager, (__bridge CFDictionaryRef)matchingDictionary);
        
        NSSet *devices = (__bridge NSSet*)IOHIDManagerCopyDevices(hidManager);
        //Can't do this test without a device.
        expect(@(devices.count)).to.beGreaterThan(@(0));
        
        if (devices.count > 0) {
            device = [[PTKDevice alloc] initWithIOHIDDevice:(__bridge IOHIDDeviceRef)[devices anyObject] error:NULL];
            expect(device).toNot.beNil();
            expect([device openWithError:NULL]).to.beTruthy();
        }
        
        IOHIDManagerClose(hidManager, kIOHIDOptionsTypeNone);
    });
    
    it(@"should be able to stop the current sequence", ^{
        __block BOOL done = NO;
        __block NSError *error = nil;
        [device stopCurrentSequenceWithCompletion:^(NSError *e) {
            error = e;
            done = YES;
        }];
        do {
            [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        } while (!done);
        expect(error).to.beNil();
    });
    
    it(@"should read the serial number", ^{
        __block BOOL done = NO;
        __block NSError *error = nil;
        __block NSString *serial = nil;
        [device recallSerialNumberWithCompletion:^(NSString *s, NSError *e) {
            serial = s;
            error = e;
            done = YES;
        }];
        do {
            [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        } while (!done);
        expect(error).to.beNil();
        expect(serial).toNot.beNil();
        NSLog(@"Serial: %@", serial);
    });
    
    it(@"should read the name", ^{
        __block BOOL done = NO;
        __block NSError *error = nil;
        __block NSString *name = nil;
        [device recallNameWithCompletion:^(NSString *n, NSError *e) {
            name = n;
            error = e;
            done = YES;
        }];
        do {
            [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        } while (!done);
        expect(error).to.beNil();
        expect(name).toNot.beNil();
        NSLog(@"Name: %@", name);
    });
    
    it(@"should read the brightness", ^{
        __block BOOL done = NO;
        __block NSError *error = nil;
        __block int8_t brightness = -1;
        [device recallBrightnessWithCompletion:^(int8_t b, NSError *e) {
            brightness = b;
            error = e;
            done = YES;
        }];
        do {
            [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        } while (!done);
        expect(error).to.beNil();
        expect(brightness).toNot.equal(@(-1));
        NSLog(@"Brightness: %d", brightness);
    });
    
    it(@"should write and read the device state", ^{
        __block BOOL done = NO;
        __block NSError *error = nil;
        __block PTKDeviceState *incomingState = nil;
        __block PTKDeviceState *outgoingState = nil;
        
        uint8_t values[3][8] = { {0x0} };
        outgoingState = [PTKDeviceState emptyDeviceStateForCompatibilityWithDevice:device];
        outgoingState.brightness = 100;
        
        for (int l = 0; l < 8; l++)
        {
            for (int c = 0; c < 3; c++)
            {
                values[c][l] = 255;
                [outgoingState setRed:values[0] green:values[1] blue:values[2] forLampsInRange:NSMakeRange(0, 8)];
                
                [device setDeviceState:outgoingState completion:^(NSError *e) {
                    error = e;
                    done = YES;
                }];
                do {
                    [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                } while (!done);
                expect(error).to.beNil();
                error = nil;
                done = NO;
                
                [device getDeviceStateWithCompletion:^(PTKDeviceState *deviceState, NSError *e) {
                    incomingState = deviceState;
                    // So they compare equal.
                    incomingState.brightness = outgoingState.brightness;
                    error = e;
                    done = YES;
                }];
                do {
                    [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                } while (!done);
                expect(error).to.beNil();
                expect(incomingState).to.equal(outgoingState);
                error = nil;
                done = NO;
                incomingState = nil;
            }
        }
    });
    
    it(@"should be able to start the current sequence", ^{
        __block BOOL done = NO;
        __block NSError *error = nil;
        [device startCurrentSequenceWithCompletion:^(NSError *e) {
            error = e;
            done = YES;
        }];
        do {
            [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        } while (!done);
        expect(error).to.beNil();
    });
    
    afterAll(^{
        expect([device closeWithError:NULL]).to.beTruthy();
        device = nil;
    });
});

SpecEnd
