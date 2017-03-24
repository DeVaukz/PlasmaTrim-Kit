//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//|             PTKDeviceStateSpec.m
//|
//|             D.V.
//|             Copyright (c) 2014-2017 D.V. All rights reserved.
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
@import Specta;
#import <Expecta/Expecta.h>

SpecBegin(PTKDeviceState)

describe(@"The brightness value", ^{
    __block PTKDeviceState *state;
    
    beforeEach(^{
        state = [PTKDeviceState emptyDeviceStateForCompatibilityWithDevice:nil];
    });
    
    it(@"should accept a brightness of 0", ^{
        int8_t brightness = 0;
        state.brightness = brightness;
        expect([state valueForKey:@"brightness"]).to.equal(@(brightness));
    });
    
    it(@"should accept a brightness of 100", ^{
        int8_t brightness = 100;
        state.brightness = brightness;
        expect([state valueForKey:@"brightness"]).to.equal(@(brightness));
    });
    
    it(@"should accept a brightness between [0, 100]", ^{
        int8_t brightness = (arc4random() % 98) + 1;
        state.brightness = brightness;
        expect([state valueForKey:@"brightness"]).to.equal(@(brightness));
    });
});

describe(@"The RGB components of each lamp", ^{
    __block PTKDeviceState *state;
    
    beforeEach(^{
        state = [PTKDeviceState emptyDeviceStateForCompatibilityWithDevice:nil];
    });
    
    it(@"should return 0 for all components of all lamps by default", ^{
        uint8_t result[3][8];
        uint8_t goodResult[3][8];
        bzero(goodResult, sizeof(goodResult));
        [state getRed:result[0] green:result[1] blue:result[2] forLampsInRange:NSMakeRange(0, 8)];
        int cmp = memcmp(result, goodResult, sizeof(result));
        expect(@(cmp)).to.equal(@(0));
    });
    
    it(@"should throw an exception when getting the component values for and index above 7", ^{
        NSNumber *threwException = @(NO);
        @try {
            uint8_t r,g,b;
            [state getRed:&r green:&g blue:&b forLampsInRange:NSMakeRange(0, 9)];
        }
        @catch(id exception) {
            threwException = @(YES);
        }
        @finally {
            expect(threwException).to.equal(@(YES));
        }
    });
    
    it(@"should set the components for a range of lamps", ^{
        uint8_t in_val[3][8];
        for (int i=0; i<8; i++) { in_val[0][i] = 40; in_val[1][i] = 80; in_val[2][i] = 120; }
        [state setRed:in_val[0] green:in_val[1] blue:in_val[2] forLampsInRange:NSMakeRange(0, 8)];
        uint8_t result[3][8];
        bzero(result, sizeof(result));
        [state getRed:result[0] green:result[1] blue:result[2] forLampsInRange:NSMakeRange(0, 8)];
        int cmp = memcmp(result, in_val, sizeof(result));
        expect(@(cmp)).to.equal(@(0));
    });
});

SpecEnd
