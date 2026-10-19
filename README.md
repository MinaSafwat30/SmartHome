# SmartHome

A Flutter smart-home app for managing rooms and connected devices. It uses
Firebase Authentication for sign-in and Firebase Realtime Database for home,
room, and device data.

## Features

- Email and password sign-up, sign-in, and password reset
- Home dashboard with rooms and device status
- Real-time device and room updates
- Device controls, including climate mode and target temperature
- Light and dark themes, with the selected theme saved on the device
- Home profile and family-member views

## Requirements

- Flutter SDK (the project requires Dart `^3.10.4`; Flutter includes Dart)
- A Firebase project with **Email/Password** sign-in enabled and a Realtime
  Database created

## Getting started

1. Clone the repository and install its packages:

   ```powershell
   git clone https://github.com/MinaSafwat30/SmartHome.git
   cd SmartHome
   flutter pub get
   ```

2. Create the app's local Firebase configuration by copying the example:

   ```powershell
   Copy-Item lib\core\config\app_secrets.dart.example lib\core\config\app_secrets.dart
   ```

   Edit `lib/core/config/app_secrets.dart` and replace the placeholder values
   with the Firebase app's API key, app ID, messaging sender ID, project ID,
   Realtime Database URL, and storage bucket. The app loads these options at
   startup.

3. In the Firebase Console, enable the **Email/Password** provider in
   Authentication. Configure Realtime Database rules to require authentication
   and allow only the appropriate users to read or update their home data.
   Do not use open read/write rules for a deployed app.

4. Run the app on a connected device or emulator:

   ```powershell
   flutter run
   ```

New accounts are associated with the default home ID `home_alpha`. Add the
corresponding home, room, and device data to Realtime Database for the dashboard
to display devices. Home data is read from `homes/{homeId}`; user profiles are
stored under `users/{uid}`.

## Development

Run the test suite with:

```powershell
flutter test
```

Check Dart and Flutter diagnostics with:

```powershell
flutter analyze
```

## Configuration and secrets

The real `lib/core/config/app_secrets.dart` and native Firebase service files
are ignored by Git. Keep actual configuration files out of commits. The
repository includes placeholder examples for app configuration; replace all
placeholder values with values from your own Firebase project before running.
