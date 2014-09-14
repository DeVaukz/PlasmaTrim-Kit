//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//|             PTKDeviceState.m
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

#import "PTKDeviceState.h"

struct ptk_lamp_color {
    uint8_t red, green, blue;
};


//----------------------------------------------------------------------------//
@implementation PTKDeviceState {
    struct ptk_lamp_color _color[8];
}

//|++++++++++++++++++++++++++++++++++++|//
+ (PTKDeviceState*)emptyDeviceStateForCompatibilityWithDevice:(PTKDevice*)device
{
#pragma unused (device) //Future proofing.
    PTKDeviceState *retValue = [[self alloc] init];
    return retValue;
}

//|++++++++++++++++++++++++++++++++++++|//
- (id)copyWithZone:(NSZone *)zone
{
    PTKDeviceState *retValue = [[PTKDeviceState allocWithZone:zone] init];
    retValue->_brightness = _brightness;
    memcpy(retValue->_color, _color, sizeof(_color));
    return retValue;
}

//|++++++++++++++++++++++++++++++++++++|//
- (void)getRed:(uint8_t*)red green:(uint8_t*)green blue:(uint8_t*)blue forLampsInRange:(NSRange)range
{
    if (range.location + range.length >= 8)
        @throw [NSException exceptionWithName:NSRangeException reason:@"Range must be between [0, 8)" userInfo:nil];
    
    for (NSUInteger i = range.location; i < range.location + range.length; i++) {
        *red = _color[i].red; red++;
        *green = _color[i].green; green++;
        *blue = _color[i].blue; blue++;
    }
}

//|++++++++++++++++++++++++++++++++++++|//
- (void)setRed:(uint8_t*)red green:(uint8_t*)green blue:(uint8_t*)blue forLampsInRange:(NSRange)range
{
    if (range.location + range.length >= 8)
        @throw [NSException exceptionWithName:NSRangeException reason:@"Range must be between [0, 8)" userInfo:nil];
    
    for (NSUInteger i = range.location; i < range.location + range.length; i++) {
        _color[i].red = *red; red++;
        _color[i].green = *green; green++;
        _color[i].blue = *blue; blue++;
    }
}

@end
