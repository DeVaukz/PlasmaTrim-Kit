//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//! @file       PTKDeviceState.h
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

@class PTKDevice;

//----------------------------------------------------------------------------//
@interface PTKDeviceState : NSObject <NSCopying>

//! Creates and returns a \c PTKDeviceState object configured for the specified
//! \a device.
+ (PTKDeviceState*)emptyDeviceStateForCompatibilityWithDevice:(PTKDevice*)device;

//! The shared brightness value.
//!
//! This value globally scales the output without reducing the dynamic range.
@property (nonatomic, readwrite) uint8_t brightness;

//! Returns the RGB component values in the respective arguments for the lamp
//! at the specific \a index.
//!
//! The default value is \e 0 for all components.
//!
//! @param  index
//!         The range of lamps to retrieve the RGB component values for. All
//!         indecies in the range must be less than the value of the
//!         \e lampCount property of the \ref PTKDevice used to initialize the
//!         receiver.
- (void)getRed:(uint8_t*)red green:(uint8_t*)green blue:(uint8_t*)blue forLampsInRange:(NSRange)range;

//! Modifies the RGB component values for the lamps in the specific \a range.
//!
//! @param  range
//!         The range of lamps to apply the new component valus to.  All
//!         indecies in the range must be less than the value of the
//!         \e lampCount property of the \ref PTKDevice used to initialize the
//!         receiver.
- (void)setRed:(uint8_t*)red green:(uint8_t*)green blue:(uint8_t*)blue forLampsInRange:(NSRange)range;

@end
