# Release Notes - Version 1.0.8

## Critical Hotfix - Android Network Permissions

### Release Date
January 2025

### Overview
This is a critical hotfix release that addresses Android authentication failures discovered in version 1.0.7.

### Critical Fixes

#### Android Network Permissions (CRITICAL)
- **Fixed**: Added missing `INTERNET` permission to AndroidManifest.xml
- **Fixed**: Added `ACCESS_NETWORK_STATE` permission for connectivity checks
- **Fixed**: Enabled cleartext traffic support for HTTP connections
- **Impact**: Resolves "authentication failed" errors when adding Nostr accounts
- **Impact**: Resolves "Network Connection failed" errors when adding Mastodon accounts
- **Severity**: HIGH - Without these permissions, Android users could not add any accounts

### Technical Details

The Android version was missing critical network permissions in the AndroidManifest.xml file:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

Additionally, the application configuration now includes:
```xml
android:usesCleartextTraffic="true"
```

This allows HTTP connections which may be required by some Mastodon instances and Nostr relays.

### Affected Platforms
- ✅ **Android**: Critical fix applied
- ⚪ Windows: No changes (was working correctly)
- ⚪ Linux: No changes
- ⚪ macOS: No changes
- ⚪ iOS: No changes
- ⚪ Web: No changes

### Upgrade Priority
**CRITICAL** - All Android users on version 1.0.7 should upgrade immediately as they cannot add accounts without this fix.

### Installation
Download the appropriate installer for your platform:
- **Android**: `yall-1.0.8.apk`
- **Windows**: `yall-1.0.8-windows-installer.exe` or `yall-1.0.8-windows.zip`

### Known Issues
None reported in this version.

### What's Next
- Implement full functionality for Accounts and History views (currently placeholders)
- Address remaining feature requests from the community

---

For detailed installation instructions, see [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md) for Windows or the README for other platforms.
