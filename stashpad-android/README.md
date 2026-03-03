# Stashpad Android Client

Primary client application for Android devices. This serves as the main storage location for all notes and handles encryption/decryption of user data.

## Features

- Create, modify, delete, and share notes
- Support for various media types (text, audio, video, documents)
- End-to-end encryption
- QR code authentication for web clients
- Synchronization with web clients

## Architecture

<!-- - Built with Android SDK -->

- Built with Flutter (Dart)
- Local encrypted storage using `sqflite` + `sqlcipher`
- Communication layer using `web_socket_channel`
- Secure QR scanning with `mobile_scanner`

## Running and Debugging

You can run and debug the Stashpad Android client using either the command line or Android Studio.

### Using the Terminal

1. **Ensure an emulator is running** or a physical device is connected.
2. **Run the app:**
   ```bash
   flutter run
   ```
3. **Run tests:**
   ```bash
   flutter test
   ```
   _To run a specific test file, use:_ `flutter test test/widget_test.dart`
4. **Analyze code:**
   ```bash
   flutter analyze
   ```

### Using Android Studio

1. Open Android Studio.
2. Select **Open** and choose the `stashpad/stashpad-android` directory.
3. **Run the App**:
   - Select your target device from the device drop-down menu in the toolbar.
   - Click the green **Run** (Play) button (`Shift + F10`), or go to `Run -> Run 'main.dart'`.
4. **Debug the App**:
   - Set breakpoints in your Dart code by clicking the gutter next to line numbers.
   - Click the green **Debug** (Bug) button (`Shift + F9`), or go to `Run -> Debug 'main.dart'`.
   - The app will pause at your breakpoints, allowing you to inspect variables and step through code.
5. **Run Tests**:
   - Right-click on the `test` directory or a specific test file (e.g., `widget_test.dart`).
   - Select **Run 'tests in [directory/file]'** or **Debug 'tests in...'** if you need to use breakpoints.
