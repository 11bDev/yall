# Yall 📱

> **Message to Nostr, Bluesky, and Mastodon from one place.**

A Flutter-based cross-platform social media poster that lets you send messages to multiple social platforms simultaneously. Built with privacy and ease of use in mind.

## ✨ Features

- **Multi-Platform Posting**: Post to Nostr, Bluesky, and Mastodon from one interface
- **Smart Character Limits**: Platform-aware character limits with automatic truncation
  - Bluesky: 300 characters
  - Mastodon: 500 characters
  - Nostr: Unlimited
- **Truncation Warnings**: Real-time warnings showing which platforms will have content truncated
- **Nostr Support**: Full BIP-340 Schnorr signatures with nsec-to-hex conversion
- **Custom Relay Management**: Configure up to 10 custom Nostr relays
- **Cross-Platform**: Runs on Linux, Windows, macOS, Android, and iOS
- **System Tray Integration**: Minimize to system tray with quick access
- **Desktop Integration**: Proper app icons, dock/taskbar pinning, and desktop menu entries
- **Secure Storage**: Credentials stored securely using platform-specific storage
- **Dark/Light Themes**: Automatic theme switching based on system preferences

## 🚀 Installation

### Linux

1. **Build from source:**
   ```bash
   git clone https://github.com/timappledotcom/yall.git
   cd yall
   flutter build linux
   ```

2. **Install system-wide:**
   ```bash
   ./install-linux.sh
   ```

3. **Find Yall in your applications menu** or run from terminal:
   ```bash
   yall
   ```

### Windows

1. **Build from source:**
   ```cmd
   git clone https://github.com/timappledotcom/yall.git
   cd yall
   flutter build windows
   ```

2. **Install:**
   ```cmd
   install-windows.bat
   ```

3. **Find Yall in Start Menu** or use the Desktop shortcut

### macOS, Android, iOS

Flutter support is available for these platforms. Build instructions:

```bash
flutter build macos    # for macOS
flutter build apk      # for Android
flutter build ios      # for iOS
```

## 📋 Prerequisites

- **Flutter SDK**: Version 3.8.1 or higher
- **Platform-specific requirements**:
  - Linux: GTK3 development headers
  - Windows: Visual Studio with C++ support
  - macOS: Xcode

## 🔧 Configuration

### Content Management
- **Character Limits**: Each platform has different limits that are automatically enforced:
  - **Bluesky**: 300 characters maximum
  - **Mastodon**: 500 characters maximum
  - **Nostr**: No character limit
- **Smart Truncation**: Content automatically truncated per platform with "..." indicator
- **Real-time Warnings**: Visual indicators show which platforms will receive truncated content
- **Platform-specific Posting**: Each platform receives optimally sized content for its limits

### Nostr Setup
1. Open Settings → Accounts → Add Nostr Account
2. **Option 1**: Paste your nsec private key (recommended)
   - The app automatically converts nsec to hex format
3. **Option 2**: Enter hex private key directly
4. **Relay Configuration**: Settings → Nostr → Manage up to 10 relays

### Bluesky Setup
1. Generate an App Password at [bsky.app](https://bsky.app)
2. Add Bluesky Account with your handle and app password

### Mastodon Setup
1. Create application in your Mastodon instance
2. Get access token and server URL
3. Add Mastodon Account with these credentials

## ⌨️ Keyboard Shortcuts

- `Ctrl+N` / `Cmd+N`: New post
- `Ctrl+Enter` / `Cmd+Enter`: Submit post
- `Ctrl+,` / `Cmd+,`: Open settings
- `Escape`: Cancel/close
- `F1`: Show help

## 🏗️ Architecture

### Key Components

- **Services Layer**: Platform-specific integrations (NostrService, BlueskyService, MastodonService)
- **Providers**: State management using Flutter Provider pattern
- **Cryptography**: BIP-340 Schnorr signatures for Nostr using PointyCastle
- **Storage**: Secure credential storage with flutter_secure_storage
- **UI**: Material Design 3 with responsive layout

### Security Features

- **Local Storage**: All credentials stored locally using platform keychain
- **No Cloud Sync**: Data never leaves your device
- **Secure Key Conversion**: nsec keys converted to hex locally
- **Memory Safety**: Sensitive data cleared from memory when possible

## 🛠️ Development

### Building

```bash
# Get dependencies
flutter pub get

# Run in development
flutter run -d linux    # or windows, macos

# Build release
flutter build linux
flutter build windows
flutter build macos
```

### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📦 Dependencies

### Core
- `flutter`: Framework
- `provider`: State management
- `window_manager`: Desktop window controls

### Networking & Crypto
- `http`: HTTP client
- `web_socket_channel`: WebSocket for Nostr
- `pointycastle`: Cryptography
- `bech32`: nsec key decoding

### Storage & UI
- `flutter_secure_storage`: Secure credential storage
- `system_tray`: System tray integration
- `flutter_launcher_icons`: Cross-platform app icons

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is open source. See LICENSE file for details.

## 🐛 Troubleshooting

### Linux Issues
- **Icon not showing**: Ensure `~/.local/share/icons/` is in icon theme path
- **System tray missing**: Install `libayatana-appindicator3-dev`

### Windows Issues
- **Build fails**: Ensure Visual Studio Build Tools are installed
- **DLL missing**: Redistribute Visual C++ Runtime may be needed

### General Issues
- **Flutter not found**: Ensure Flutter SDK is in PATH
- **Build errors**: Run `flutter clean && flutter pub get`

## 🔗 Links

- **Source**: [GitHub Repository](https://github.com/timappledotcom/yall)
- **Nostr**: [NIP Specifications](https://github.com/nostr-protocol/nips)
- **Bluesky**: [AT Protocol](https://atproto.com)
- **Mastodon**: [API Documentation](https://docs.joinmastodon.org/api/)

---

**Built with ❤️ using Flutter**

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
