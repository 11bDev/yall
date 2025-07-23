# yall

**Y**et **A**nother **L**ink **L**ogger - Message to Nostr, Bluesky, and Mastodon from one place.

A cross-platform desktop application that allows you to post messages simultaneously to multiple social media platforms including Mastodon, Bluesky, and Nostr.

## Features

- 🚀 **Multi-Platform Posting**: Post to Mastodon, Bluesky, and Nostr simultaneously
- 🔒 **Secure Credential Storage**: Encrypted storage of account credentials
- 🎨 **Modern UI**: Clean Material Design 3 interface with dark/light theme support
- 💻 **Desktop Native**: System tray integration and window state management
- ⌨️ **Keyboard Shortcuts**: Efficient workflow with keyboard navigation
- 🔄 **Retry Logic**: Automatic retry for network failures
- 🛡️ **Error Handling**: Comprehensive error handling with user-friendly messages
- ♿ **Accessibility**: Full accessibility support with semantic labels and tooltips

## Keyboard Shortcuts

- `Ctrl+N`: Focus on new post input
- `Ctrl+Enter`: Submit post
- `Ctrl+,`: Open settings
- `Escape`: Cancel current operation
- `F1`: Show help

## Installation

### Prerequisites

- Flutter 3.8.1 or higher
- Linux desktop environment (primary target)
- Network connection for platform APIs

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/timappledotcom/yall.git
   cd yall
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run -d linux
   ```

4. Build for production:
   ```bash
   flutter build linux --release
   ```

## Platform Setup

### Mastodon
1. Go to your Mastodon instance settings
2. Navigate to Development > New Application
3. Create an application with read/write permissions
4. Copy the access token to the app settings

### Bluesky
1. Use your Bluesky handle (e.g., `user.bsky.social`)
2. Generate an app password in Bluesky settings
3. Use your handle and app password in the app settings

### Nostr
1. Generate a new key pair in the app
2. Or import an existing private key (hex format)
3. Configure relay servers for message distribution

## Development

### Project Structure

```
lib/
├── models/          # Data models and enums
├── providers/       # State management (Provider pattern)
├── services/        # Business logic and API integrations
├── widgets/         # UI components
└── main.dart        # Application entry point

test/
├── integration/     # Integration tests
├── models/         # Model unit tests
├── providers/      # Provider unit tests
├── services/       # Service unit tests
└── widgets/        # Widget tests
```

### Running Tests

```bash
# Unit and widget tests
flutter test

# Integration tests
flutter test integration_test/

# Test coverage
flutter test --coverage
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new features
4. Ensure all tests pass
5. Submit a pull request

## Architecture

The application follows a clean architecture pattern with:

- **Models**: Data structures and business entities
- **Services**: Platform integrations and business logic
- **Providers**: State management using Flutter's Provider pattern
- **Widgets**: UI components and screens

Key design principles:
- Dependency injection for testability
- Abstract interfaces for platform services
- Immutable data models
- Comprehensive error handling
- Secure credential management

## Privacy & Security

- All credentials are encrypted using platform-secure storage
- No sensitive data is logged or transmitted
- Network requests use HTTPS/WSS where supported
- Local data is stored securely using flutter_secure_storage

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, feature requests, or questions:
1. Check existing [GitHub Issues](https://github.com/timappledotcom/yall/issues)
2. Create a new issue with detailed information
3. Include platform and version information

## Roadmap

- [ ] Post scheduling
- [ ] Draft management
- [ ] Bulk account operations
- [ ] Analytics dashboard
- [ ] Plugin system for additional platforms
- [ ] Mobile companion app
