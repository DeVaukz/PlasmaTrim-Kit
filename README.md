PlasmaTrimKit
=============

PlasmaTrimKit is a library that is designed to make it easy to control one or more [USB PlasmaTrim](http://www.thephotonfactory.com/pt_acces.shtml) LED light strips.  The aim of this library is to enable you to create your own applications for the USB PlasmaTrim.  It's tested and fully documented.

NOTE: Uploading and downloading sequences is not currently supported.

## The USB PlasmaTrim

A USB PlasmaTrim can be purchased from [The Photon Factory](http://www.thephotonfactory.com/) for $45 USD.  Each USB PlasmaTrim includes eight RGB LED lamps that are individually controllable.  The low level protocol documentation can be found [here](http://www.thephotonfactory.com/forum/viewtopic.php?f=5&t=104).

## Get Started

Add PlasmaTrimKit to your project as you would any other framework.  PlasmaTrimKit includes a module map, so it can be included in your code using  `@import PlasmaTrimKit;` or `#import <PlasmaTrimKit/PlasmaTrimKit.h>`.

### Getting a list of connected devices

An instance of `PTKDeviceManager` tracks the connected PlasmaTrim devices.

```objc
PTKDeviceManager *deviceManager = [[PTKDeviceManager alloc] initWithError:NULL];
NSSet *connectedDevices = [deviceManager connectedDevices];
```
A `PTKDeviceManager` emits notifications when a device is connected or disconnected.  See `PTKDeviceManager.h`.

### Interacting with a device

Each PlasmaTrim device is represented by an instance of `PTKDevice`.  Before interacting with a device, a connection must be established.

```objc
PTKDevice *device = [connectedDevices anyObject];
[device openWithError:NULL];
```

Commands are sent asynchronously.  A completion handler may be provided to receive the result of a command.  You may invoke the methods of a PTKDevice from any thread.  Completion blocks are always executed on the global dispatch queue.

```objc
// Before applying your own colors, you should stop any currently
// playing sequence.
[device stopCurrentSequenceWithCompletion:^(NSError *error) {
	if (error)
		NSLog(@"Couldn't stop the current sequence: %@");
}];
```

The color of each lamp and the shared brightness is an atomic value.  It is represented by an instance of `PTKDeviceState`.  

```objc
PTKDeviceState *offDeviceState = [PTKDeviceState emptyDeviceStateForCompatibilityWithDevice:device];
// You must configure a brightness between [0, 100]%.  Otherwise, 
// an exception is thrown when applying the new state to the device.
offDeviceState.brightness = 100; 
[device setDeviceState:offDeviceState];
// All lamps off.
```

Because it is not possible to read the immediate brightness value from the device, any `PTKDeviceState` retrieved from the device will have a brightness of `-1`, indicating that it is unknown.

### Building The Documentation

Make sure you have Doxygen installed.

	cd Docs
	doxygen

### Running The Unit Tests

You will need to have a USB PlasmaTrim device connected to your computer when running the included unit tests.

## System Requirements

PlasmaTrimKit has been tested on OS X 10.9.  However, it should be possible to deploy back to OS X 10.8.

## License

PlasmaTrimKit is released under the MIT license. See
[LICENSE.md](https://github.com/DeVaukz/PlasmaTrim-Kit/blob/master/LICENSE).
