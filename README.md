# WPay iOS Frames SDK

This project contains an iOS framework that can facilitate
applications using the [Frames SDK](https://github.com/w-pay/sdk-wpay-web-frames)

It is recommended that developers understand the fundamentals of the Frames SDK before using
this library.

| :memo: | The SDK is currently in development. Therefore parts may change. |
|--------|:-----------------------------------------------------------------|

# Usage

This library loads the Frames Javascript SDK into a `WKWebView` and provides hooks for an application
to receive messages from the SDK. The Application provides the "host HTML" that the JS SDK uses to
load the web content to allow the user to securely enter information like credit card numbers.
Consequently the Application can tailor the HTML as required, applying styling and adding other
web content.

To use the Frames JS SDK in an iOS application, an instance of `FramesView` should be added
to a layout in the Application. To use in a Storyboard, add a `WKWebiView` to the layout and
set the `Custom Class` of the view to `FramesView` from the `WPayFramesSDK` module (XCode 12.2)

An Application can instruct the JS SDK via the posting of `JavascriptCommand`s, and receive messages
from the SDK via the use of the `FramesViewCallback`. This allows the Application to orchestrate
the usage of the SDK with native logic and UI components eg: Buttons.

## Frames SDK Version

The iOS SDK comes bundled with the Frames JS SDK so that the iOS SDK can use a known
version at runtime. The JS file in the `Assets` dir is taken from the `dist` of the Frames SDK
repo and currently targets version `2.1.0`.

## Authentication

The Application currently bears the responsibility for acquiring an access token for the SDK

## Logging

Logging within the SDK is comprised of two levels.

The first is the interaction between the Application and the Frames JS SDK/WebView. 
The `FramesViewLogger` interface allows the Application to provide a logger to the view.

The second is the logging from within the Frames JS SDK itself. The `LogLevel` enum allows the
log level for the JS SDK to be set at SDK creation time. If none is given, the log level defaults
to `ERROR` for security. Note that logging from the JS SDK is dumped to the Console.

# Sample App

The `Example` directory in the project contains a sample app that uses the SDK. The ViewController
in the sample app document the workflow/usage of the Frames SDK.

The sample app highlights the ability to combine native controls like buttons with web controls.

Once a card has been tokenised, the instrument ID is displayed. Using that ID the payment instrument
can then used. The new instrument will be in the customer's instrument list. To tokenise the same
card again, the instrument will need to be removed from the customer's profile first.

An example of how to use 3DS is also included. Apps will need to determine the best way to display
3DS challenges based on their needs.

See:
- List customer payment instruments `GET /instore/customer/instruments`
- Remove payment instrument `DELETE /instore/customer/instruments/:id`

# TODO

- Testing
- Publishing