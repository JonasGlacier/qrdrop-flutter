# TXQR

[![GoDoc](https://godoc.org/github.com/divan/txqr?status.svg)](https://godoc.org/github.com/divan/txqr)

TXQR (Transfer via QR) is a protocol and set of tools and libs to transfer data via animated QR codes. It uses [fountain codes](https://en.wikipedia.org/wiki/Fountain_code) for error correction.

See related blog posts for more details:
- [Animated QR data transfer with Gomobile and Gopherjs](https://divan.github.io/posts/animatedqr/)
- [Fountain codes and animated QR](https://divan.github.io/posts/fountaincodes/)

## Demo

![Demo](./docs/demo.gif)

Reader iOS app in the demo (uses this lib via Gomobile): [https://github.com/divan/txqr-reader](https://github.com/divan/txqr-reader)

## Flutter File Transfer App

A modern Flutter-based Android application for **bidirectional file transfer via animated QR codes**. Users can both send and receive files between phones without network connection. The app reuses the existing Go core library via `gomobile bind`, bridged to Flutter through Kotlin MethodChannels.

### Features

**Send:**
- Pick any file from device storage
- Automatically encode into fountain-coded animated QR frames
- Display animated QR codes on screen at configurable FPS (4–12 fps)
- Live loop counter and frame progress indicator
- Supports files of any size (within practical encoding limits)

**Receive:**
- Real-time QR frame scanning with `mobile_scanner`
- Live progress indicator with animated overlay
- Automatic base64 decode and file extraction
- Files saved to app documents directory
- Transfer speed and time tracking
- Share or open received files

**General:**
- Material 3 UI with dark mode support
- Home screen with Send/Receive buttons
- No network required — direct device-to-device transfer

### File Format

Files are transmitted as a payload: `filename\nbase64-encoded-bytes`

When a receiver completes the transfer, the app parses this format, decodes the base64 content, and saves the file with its original name.

### Building the Android App

#### Prerequisites

- Flutter SDK
- Android SDK / Android Studio
- Go 1.16+ (for `gomobile`)
- `gomobile` tool installed: `go install github.com/google/mobile/cmd/gomobile@latest`
- Android NDK installed via Android Studio (API level 21+)

#### Steps

1. **Build the Go AAR** (compiles `mobile/encode.go` and `mobile/decode.go` to Android archive):
   ```bash
   make aar
   ```
   This creates `flutter_app/android/app/libs/txqr.aar` using `gomobile bind -target=android`.

2. **Install Flutter dependencies**:
   ```bash
   cd flutter_app && flutter pub get
   ```

3. **Run the app on an Android device or emulator**:
   ```bash
   cd flutter_app && flutter run
   ```

4. **(Optional) Build APK for distribution**:
   ```bash
   cd flutter_app && flutter build apk --release
   ```

### Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── services/
│   │   └── txqr_service.dart       # MethodChannel client for encoder/decoder
│   ├── screens/
│   │   ├── home_screen.dart        # Send / Receive button screen
│   │   ├── send_screen.dart        # File picker + animated QR display
│   │   ├── receive_screen.dart     # Camera + QR scanning UI
│   │   └── result_screen.dart      # Results & file info display
│   └── widgets/
│       └── qr_scanner_overlay.dart # Scan overlay with progress arc
├── android/
│   └── app/
│       ├── libs/
│       │   └── txqr.aar            # Go library (built by `make aar`)
│       └── src/main/kotlin/.../
│           └── MainActivity.kt     # MethodChannels for encoder & decoder
├── pubspec.yaml                    # Flutter dependencies
└── ...
```

### Go Integration

The Flutter app integrates the Go TXQR core library via:

1. **Android AAR** — `gomobile bind -target=android` produces a compiled `.aar` library containing both encoder and decoder
2. **Dual MethodChannels** — Kotlin code in `MainActivity.kt` exposes two channels:
   - `com.divan.txqr/decoder` — For receiving files
   - `com.divan.txqr/encoder` — For sending files
3. **Dart wrapper** — `TxqrService` in `txqr_service.dart` provides a clean Dart interface

**Exported Go methods (Decoder):**
- `Decode(data string) error` — Feed a QR frame string
- `IsCompleted() bool` — Check if decoding is finished
- `getData() string` — Get the decoded payload
- `getProgress() int` — Decoding progress percentage
- `getSpeed() string` — Average read speed (human-readable)
- `getTotalTime() string` — Total scan duration (human-readable)
- `reset()` — Reset decoder for new session

**Exported Go methods (Encoder):**
- `Encode(data string) error` — Encode data into chunks
- `ChunkCount() int` — Number of encoded chunks
- `GetChunk(i int) string` — Get chunk at index
- `SetRedundancyFactor(rf double)` — Configure error resilience

### Dependencies

Key Flutter packages:
- `mobile_scanner` — QR code scanning via device camera
- `qr_flutter` — QR code rendering as Flutter widget
- `file_picker` — File selection from device storage
- `path_provider` — Access app documents directory for saving files
- `share_plus` — Share received files with other apps
- `permission_handler` — Request camera permission

## Automated Tester App

Also see `cmd/txqr-tester` app for automated testing of different encoder parameters.

## Troubleshooting

### `gomobile: ANDROID_NDK_HOME specifies ... unsupported API version`

This occurs when the NDK version doesn't support the required API level. Ensure you have an NDK version 21 or higher installed:
- Open Android Studio → Settings → Android SDK → SDK Tools
- Install "NDK (Side by side)" version 25 or higher
- gomobile typically requires NDK API level 21–35

### App crashes on startup

If the app crashes immediately, the AAR might not have been built or included properly:
1. Run `make aar` from the project root
2. Ensure `flutter_app/android/app/libs/txqr.aar` exists
3. Run `flutter clean && flutter pub get` in the Flutter app directory
4. Rebuild: `flutter run`

## License

MIT
