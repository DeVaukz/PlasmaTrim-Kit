//----------------------------------------------------------------------------//
//|
//|             PlasmaTrimKit - The Objective-C SDK for the USB PlasmaTrim
//|             NSError+PKT.m
//|
//|             D.V.
//|             Copyright (c) 2014-2018 D.V. All rights reserved.
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

#import "NSError+PKT.h"

NSString * const IOKitErrorDomain = @"IOKitErrorDomain";
NSString * const PTKErrorDomain = @"PTKErrorDomain";


//----------------------------------------------------------------------------//
@implementation NSError (PKT)

//|++++++++++++++++++++++++++++++++++++|//
+ (NSString*)stringForIOKitError:(IOReturn)code
{
    switch (code)
    {
        case kIOReturnSuccess:
            return @"kIOReturnSuccess";
        case kIOReturnError:
            return @"kIOReturnError";
        case kIOReturnNoMemory:
            return @"kIOReturnNoMemory";
        case kIOReturnNoResources:
            return @"kIOReturnNoResources";
        case kIOReturnIPCError:
            return @"kIOReturnIPCError";
        case kIOReturnNoDevice:
            return @"kIOReturnNoDevice";
        case kIOReturnNotPrivileged:
            return @"kIOReturnNotPrivileged";
        case kIOReturnBadArgument:
            return @"kIOReturnBadArgument";
        case kIOReturnLockedRead:
            return @"kIOReturnLockedRead";
        case kIOReturnLockedWrite:
            return @"kIOReturnLockedWrite";
        case kIOReturnExclusiveAccess:
            return @"kIOReturnExclusiveAccess";
        case kIOReturnBadMessageID:
            return @"kIOReturnBadMessageID";
        case kIOReturnUnsupported:
            return @"kIOReturnUnsupported";
        case kIOReturnVMError:
            return @"kIOReturnVMError";
        case kIOReturnIOError:
            return @"kIOReturnIOError";
        case kIOReturnCannotLock:
            return @"kIOReturnCannotLock";
        case kIOReturnNotOpen:
            return @"kIOReturnNotOpen";
        case kIOReturnNotReadable:
            return @"kIOReturnNotReadable";
        case kIOReturnNotWritable:
            return @"kIOReturnNotWritable";
        case kIOReturnNotAligned:
            return @"kIOReturnNotAligned";
        case kIOReturnBadMedia:
            return @"kIOReturnBadMedia";
        case kIOReturnStillOpen:
            return @"kIOReturnStillOpen";
        case kIOReturnRLDError:
            return @"kIOReturnRLDError";
        case kIOReturnDMAError:
            return @"kIOReturnDMAError";
        case kIOReturnBusy:
            return @"kIOReturnBusy";
        case kIOReturnTimeout:
            return @"kIOReturnTimeout";
        case kIOReturnOffline:
            return @"kIOReturnOffline";
        case kIOReturnNotReady:
            return @"kIOReturnNotReady";
        case kIOReturnNotAttached:
            return @"kIOReturnNotAttached";
        case kIOReturnNoChannels:
            return @"kIOReturnNoChannels";
        case kIOReturnNoSpace:
            return @"kIOReturnNoSpace";
        case kIOReturnPortExists:
            return @"kIOReturnPortExists";
        case kIOReturnCannotWire:
            return @"kIOReturnCannotWire";
        case kIOReturnNoInterrupt:
            return @"kIOReturnNoInterrupt";
        case kIOReturnNoFrames:
            return @"kIOReturnNoFrames";
        case kIOReturnMessageTooLarge:
            return @"kIOReturnMessageTooLarge";
        case kIOReturnNotPermitted:
            return @"kIOReturnNotPermitted";
        case kIOReturnNoPower:
            return @"kIOReturnNoPower";
        case kIOReturnNoMedia:
            return @"kIOReturnNoMedia";
        case kIOReturnUnformattedMedia:
            return @"kIOReturnUnformattedMedia";
        case kIOReturnUnsupportedMode:
            return @"kIOReturnUnsupportedMode";
        case kIOReturnUnderrun:
            return @"kIOReturnUnderrun";
        case kIOReturnOverrun:
            return @"kIOReturnOverrun";
        case kIOReturnDeviceError:
            return @"kIOReturnDeviceError";
        case kIOReturnNoCompletion:
            return @"kIOReturnNoCompletion";
        case kIOReturnAborted:
            return @"kIOReturnAborted";
        case kIOReturnNoBandwidth:
            return @"kIOReturnNoBandwidth";
        case kIOReturnNotResponding:
            return @"kIOReturnNotResponding";
        case kIOReturnIsoTooOld:
            return @"kIOReturnIsoTooOld";
        case kIOReturnIsoTooNew:
            return @"kIOReturnIsoTooNew";
        case kIOReturnNotFound:
            return @"kIOReturnNotFound";
        case kIOReturnInvalid:
            return @"kIOReturnInvalid";
        default:
            return [NSString stringWithFormat:@"Error %d", code];
    }
}

//|++++++++++++++++++++++++++++++++++++|//
+ (instancetype)ioKitErrorWithCode:(IOReturn)code userInfo:(NSDictionary*)userInfo
{
    return [NSError errorWithDomain:IOKitErrorDomain code:code userInfo:userInfo];
}

//|++++++++++++++++++++++++++++++++++++|//
+ (instancetype)ioKitErrorWithCode:(IOReturn)code description:(NSString*)description
{
    return [NSError errorWithDomain:IOKitErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey: [self stringForIOKitError:code]}];
}

@end
