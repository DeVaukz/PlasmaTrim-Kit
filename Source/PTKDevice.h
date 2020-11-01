//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//! @file       PTKDevice.h
//!
//! @author     D.V.
//! @copyright  Copyright (c) 2014-2019 D.V. All rights reserved.
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

NS_ASSUME_NONNULL_BEGIN

//----------------------------------------------------------------------------//
//! Manages the communication with a single PlasmaTrim device.
//
@interface PTKDevice : NSObject

- (nullable instancetype)initWithIOHIDDevice:(IOHIDDeviceRef)device error:(NSError * __autoreleasing * _Nullable)error;

- (instancetype)init NS_UNAVAILABLE;

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark -  Establishing A Connection To The Device
//! @name       Establishing A Connection To The Device
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//! Returns \c YES if a connection has been established to the device; \c NO
//! otherwise.
- (BOOL)isOpen;

//! Attempts to establish a connection to the device.
//!
//! @return
//! \e YES if the connection was successfully opened; otherwise \e NO.
- (BOOL)openWithError:(NSError**)error;

//! Attempts to close a previously established connection to the device.
//!
//! @return
//! \e YES if the connection was successfully closed; otherwise \e NO.
- (BOOL)closeWithError:(NSError**)error;

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark -  Device Properties
//! @name       Device Properties
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//! The underlying HID device.
@property (nonatomic, readonly) IOHIDDeviceRef device;

//! The device's USB Vendor ID.
@property (nonatomic, readonly, nullable) NSNumber *vendorID;
//! The device's USB Product ID.
@property (nonatomic, readonly, nullable) NSNumber *productID;
//! The device's USB Vendor Name.
@property (nonatomic, readonly, nullable) NSString *vendorName;
//! The device's USB Product Name.
@property (nonatomic, readonly, nullable) NSString *productName;
//! The number of lamps in the receiver.  This is currently always eight.
@property (nonatomic, readonly) NSUInteger lampCount;

//! Invokes the \a completion handler with a string containing the serial number
//! printed on the label on the back of the PlasmaTrim, which can be used to
//! absolutely identify a unit.
- (void)recallSerialNumberWithCompletion:(void (^)(NSString* _Nullable serial, NSError* _Nullable error))completion;

//! Writes a new name the device's non-volatile memory.
//!
//! @warning
//! This method writes to the device's non-volatile memory.  Calling it
//! repeatedly may shorten the lifespan of the device.
- (void)storeName:(NSString *)name completion:(void (^)(NSError* _Nullable error))completion;

//! Invokes the \a completion handler with a string containing the name
//! assigned to the device.  This name can be modified using the
//! \c -storeName:completion: method.
- (void)recallNameWithCompletion:(void (^)(NSString* _Nullable name, NSError* _Nullable error))completion;

//! Writes a new brightness value to the device's non-volatile memory.  This
//! value globally scales the output of the device without reducing the dynamic
//! range.
//!
//! @param  brightness
//!         The new brightness percentage.  Must be between [0, 100].
//!
//! @warning
//! This method writes to the device's non-volatile memory.  Calling it
//! repeatedly may shorten the lifespan of the device.
- (void)storeBrightness:(int8_t)brightness completion:(void (^)(NSError* _Nullable error))completion;

//! Invokes the \a completion handler with a number between [0,100] representing
//! the brightness stored in the device's non-volatile memory.
- (void)recallBrightnessWithCompletion:(void (^)(int8_t brightness, NSError* _Nullable error))completion;

//! Writes a new \ref PKTDevice state to the volatile memory of the device.
//!
//! Writing a new new device state updates the color of each lamp as well as
//! the global brightness value.  This brightness value is not persistent
//! and will not affect the value received by calling
//! \c -recallBrightnessWithCompletion.
- (void)setDeviceState:(PTKDeviceState*)deviceState completion:(void (^)(NSError* _Nullable error))completion;

//! Invokes the \a completion handler with a \ref PTKDeviceState object
//! containing the color values of each lamp.
//!
//! The device state object passed to your completion handler will not have
//! a meaningful brightness value.  Color values from the currently playing
//! sequence are not captured in the device state.
- (void)getDeviceStateWithCompletion:(void (^)(PTKDeviceState* _Nullable deviceState, NSError*_Nullable error))completion;

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark -  Working With Sequences
//! @name       Working With Sequences
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//! Pauses the currently playing sequence.
- (void)stopCurrentSequenceWithCompletion:(void (^)(NSError* _Nullable error))completion;

//! Resumes the sequence currently stored in the device's non-voltile memory.
- (void)startCurrentSequenceWithCompletion:(void (^)(NSError* _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
