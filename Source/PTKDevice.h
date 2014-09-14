//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//! @file       PTKDevice.h
//!
//! @author     D.V.
//! @copyright  Copyright (c) 2014 D.V. All rights reserved.
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

@import Foundation;
@import IOKit.hid;

@class PTKDeviceState;

//----------------------------------------------------------------------------//
@interface PTKDevice : NSObject

- (instancetype)initWithIOHIDDevice:(IOHIDDeviceRef)device error:(NSError**)error;

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark -  Establishing A Connection To The Device
//! @name       Establishing A Connection To The Device
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//! A Boolean value that reports whether a connection has been established to
//! the device.
@property (nonatomic, readonly, getter=isOpen) BOOL open;

//! Attempts to establish a connection to the device.
//!
//! @return
//! \e YES if the connection was succesfully opened; otherwise \e NO.
- (BOOL)openWithError:(NSError**)error;

//! Attempts to close a previously established connection to the device.
//!
//! @return
//! \e YES if the connection was succesfully closed; otherwise \e NO.
- (BOOL)closeWithError:(NSError**)error;

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark -  Device Properties
//! @name       Device Properties
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//! The serial number printed on the label on the back of the PlasmaTrim, which
//! can be used to absolutely identify a unit.
//!
//! This peroperty is \e nil if a connection to the device has not been
//! established.
@property (nonatomic, readonly) NSString *serialNumber;

//! The number of lamps in the receiver.  This is currently always eight.
@property (nonatomic, readonly) NSUInteger lampCount;

- (void)storeName:(NSString *)name completion:(void (^)(NSError *error))completion;
- (void)recallNameWithCompletion:(void (^)(NSString *name, NSError *error))completion;

- (void)storeBrightness:(uint8_t)brightness completion:(void (^)(NSError *error))completion;
- (void)recallBrightnessWithCompletion:(void (^)(uint8_t brightness, NSError *error))completion;

- (void)setDeviceState:(PTKDeviceState*)deviceState cancelPending:(BOOL)cancelPending completion:(void (^)(NSError *error))completion;
- (void)getDeviceStateWithCompletion:(void (^)(PTKDeviceState *deviceState, NSError *error))completion;

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark -  Working With Sequences
//! @name       Working With Sequences
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

- (void)stopCurrentSequenceWithCompletion:(void (^)(NSError *error))completion;
- (void)startCurrentSequenceWithCompletion:(void (^)(NSError *error))completion;

@end
