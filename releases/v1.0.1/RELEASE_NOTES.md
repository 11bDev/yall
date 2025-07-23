# Release Notes - v1.0.1

## 🚀 New Features & Improvements

### Nostr Character Limit Update
- **Updated Nostr character limit to 800 characters** - Previously unlimited (which caused confusion), now set to a practical limit of 800 characters to align with Nostr protocol best practices
- Enhanced character count display and validation for better user experience

### Service & Validation Improvements
- **Improved NostrService validation logic** - Fixed private key validation to properly reject invalid keys instead of attempting to pad them
- **Enhanced error handling** - Added better exception handling in credential validation with proper try-catch blocks
- **WebSocket timeout handling** - Added proper timeout management to prevent connection hanging issues

### Test Infrastructure Enhancements
- **Fixed test stability** - Resolved test hanging issues that occurred around test 442
- **Updated test expectations** - All tests now properly expect the new 800-character limit for Nostr
- **Enhanced timeout handling** - Added proper timeout management in test infrastructure

## 🔧 Technical Changes

### Code Changes
- `lib/models/platform_type.dart`: Updated Nostr enum value from 0 (unlimited) to 800
- `lib/services/nostr_service.dart`: Fixed `_convertToHex()` method and enhanced `validateCredentials()`
- `lib/providers/post_manager.dart`: Updated character limit handling
- `lib/widgets/posting_widget.dart`: Enhanced character count display

### Test Updates
- Updated 6 test files to reflect new character limits
- Fixed validation logic tests
- Enhanced integration tests with proper timeout handling

## 📦 Package Information
- **Version**: 1.0.1+1
- **Platforms**: Linux x64
- **Flutter**: 3.32.7
- **Dart**: 3.8.1

### Available Package Formats
- **Generic Linux**: `yall-1.0.1-linux-x64.tar.gz` (19MB)
- **Debian/Ubuntu**: `yall-1.0.1.deb` (15MB) 
- **Red Hat/Fedora/SUSE**: `yall-1.0.1-1.x86_64.rpm` (11MB)
- **Source RPM**: `yall-1.0.1-1.src.rpm` (19MB)

## 📋 Installation

### Debian/Ubuntu Systems
```bash
sudo dpkg -i yall-1.0.1.deb
sudo apt-get install -f  # If dependencies are missing
```

### Red Hat/Fedora/CentOS Systems  
```bash
sudo rpm -ivh yall-1.0.1-1.x86_64.rpm
# or with dnf/yum:
sudo dnf install yall-1.0.1-1.x86_64.rpm
```

### Generic Linux
1. Download the `yall-1.0.1-linux-x64.tar.gz` package
2. Extract: `tar -xzf yall-1.0.1-linux-x64.tar.gz`
3. Run: `cd yall-1.0.1-linux-x64 && ./yall`

## 🐛 Bug Fixes
- Fixed infinite waiting issues in WebSocket connections
- Resolved private key validation logic that was accepting invalid keys
- Fixed test infrastructure hanging problems
- Corrected character limit inconsistencies across the codebase

---
**Full Changelog**: https://github.com/timappledotcom/yall/compare/v1.0.0...v1.0.1
