<div align="center">
  <h1>📱 Stashpad Android Client</h1>
  <p>The primary client application for Android devices. This serves as the master storage location for all notes and handles encryption/decryption of user data.</p>
</div>

---

## ✨ Features

- **Note Management**: Create, modify, delete, and share secure notes.
- **Rich Media**: Support for various media types (text, audio, video, documents).
- **Strong Security**: End-to-end encryption to keep your data safe.
- **Authentication**: QR code scanning to authenticate and securely pair with web clients.
- **Live Sync**: Real-time synchronization with active web sessions.

## 🏗 Architecture & Tech Stack

- **Framework**: Built with Flutter (Dart) for high-performance cross-platform rendering.
- **Local Storage**: Encrypted local database utilizing `sqflite` + `sqlcipher`.
- **Networking**: Real-time communication layer using `web_socket_channel`.
- **Hardware Integration**: Secure QR scanning powered by `mobile_scanner`.

---

## 🚀 Running and Stopping

Unlike the server and web clients, the Android client relies on an emulator or a physical device and cannot be run via the root Docker scripts.

### 💻 Local Development & Testing

1. **Environment Setup**:
   - Ensure the Flutter SDK is installed.
   - Start an **Android Emulator** or connect a **physical Android device** with USB debugging enabled.

2. **Install Dependencies**:

   ```bash
   cd stashpad-android
   flutter pub get
   ```

3. **Run the App**:
   Launch the app on your selected device:

   ```bash
   flutter run
   ```

   _If multiple devices are connected, you will be prompted to choose one._

4. **Stop the App**:
   Press `q` or `Ctrl+C` in the terminal session running the app.

### 🛠 IDE Support (Android Studio / VS Code)

For an improved development experience, it is highly recommended to use an IDE:

1. Open the `stashpad-android` directory as a project in Android Studio or VS Code.
2. **Run/Debug**: Select your target device and click the standard **Play (Run/Debug)** button.
3. **Stop**: Click the red **Stop** button in the IDE console to terminate the app.
4. Add breakpoints, hot reload, and inspect the widget tree seamlessly.

---

## 🧪 Testing

To ensure the integrity of the application, you can run the automated test suites:

```bash
# Run all unit and widget tests
flutter test
```

---

## 🚢 Building for Deployment

When you're ready to deploy the app to production or distribute it via APK/AppBundle:

1. **Build an APK**:

   ```bash
   flutter build apk --release
   ```

   _The built APK will be located in `build/app/outputs/flutter-apk/app-release.apk`._

2. **Build an App Bundle (for Google Play Store)**:
   ```bash
   flutter build appbundle --release
   ```
   _The built App Bundle will be located in `build/app/outputs/bundle/release/app-release.aab`._

_(Ensure all ProGuard rules, signing keys, and package names are configured correctly within the `android/` subfolder prior to a production build)._
