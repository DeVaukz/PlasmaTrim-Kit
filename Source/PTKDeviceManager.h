//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//! @file       PTKDeviceManager.h
//!
//! @author     D.V.
//! @copyright  Copyright (c) 2014-2018 D.V. All rights reserved.
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

@class PTKDevice;

NS_ASSUME_NONNULL_BEGIN

//---------------------------------------------------------------------------//
//! @name       Notifications
//! @relates    PTKDeviceManager
//

//! A device was plugged in.
extern NSNotificationName const PTKDeviceConnectedNotification;
//! A device was removed.
extern NSNotificationName const PTKDeviceDisconnectedNotification;
//! The device that was either connected or disconnected.
extern NSString * const PTKDeviceNotificationDeviceKey;



//----------------------------------------------------------------------------//
@interface PTKDeviceManager : NSObject

//! Initializes the receiver.
//!
//! This sets up the underlying IOHIDManager and schedules the callbacks
//! on the current run loop.
- (nullable instancetype)initWithError:(NSError**)error;

//! Returns an set of \ref PTKDevice objects, each representing a connected
//! device.
- (NSSet<PTKDevice*> *)connectedDevices;

@end

NS_ASSUME_NONNULL_END
