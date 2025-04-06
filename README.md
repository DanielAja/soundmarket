# SoundMarket

A Flutter application for simulating a music stock market where users can buy and sell shares of songs.

## Getting Started

This project is a Flutter application that uses the Spotify API to fetch music data.

### Prerequisites

- Flutter SDK
- Dart SDK
- Spotify Developer Account (for API access)

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure your Spotify API credentials in `lib/core/config/api_keys.dart`
4. Run the app with `flutter run`

## Troubleshooting

### iOS Local Network Permission Issue

If you encounter the following error when running the app on iOS:

```
[ERROR:flutter/shell/platform/darwin/ios/framework/Source/FlutterDartVMServicePublisher.mm(129)] Could not register as server for FlutterDartVMServicePublisher, permission denied. Check your 'Local Network' permissions for this app in the Privacy section of the system Settings.
```

Follow these steps to fix it:

1. Run the app on your iOS device
2. When prompted for Local Network access, tap "Allow"
3. If you missed the prompt or denied it previously:
   - Go to iOS Settings
   - Scroll down to find the SoundMarket app
   - Tap on the app
   - Enable "Local Network" permission
   - Restart the app

This permission is required for Flutter's hot reload and debugging features to work properly.

### Spotify API Issues

If you encounter Spotify API errors, check:

1. Your API credentials in `lib/core/config/api_keys.dart`
2. Your internet connection
3. Spotify API service status

## Features

- Browse top songs
- View song price history
- Buy and sell shares of songs
- Track portfolio performance
- Discover new releases
