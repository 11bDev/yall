# Release Notes - Version 1.0.9

**Release Date:** October 24, 2025

## Media Upload Improvements

This release focuses on fixing critical issues with image uploads across all platforms and improving the Nostr account management experience.

### 🔧 Bug Fixes

#### Nostr Account Management
- **Added Blossom Server Field to Edit Dialog**: Users can now add or edit the Blossom server URL for existing Nostr accounts
  - Previously, Blossom server could only be set during account creation
  - Now appears as an optional field when editing Nostr accounts
  - Enables users to configure image uploads after initial account setup
  - Proper validation ensures URLs are correctly formatted

#### Bluesky Image Uploads
- **Fixed Image Size Limit**: Corrected maximum file size from 1MB to Bluesky's actual limit of 976KB (976,560 bytes)
  - Images now properly compress to fit within Bluesky's requirements
  - Prevents upload failures due to exceeding size limits
  - Improves reliability of image posting to Bluesky

#### X (Twitter) Image Uploads  
- **Implemented Chunked Upload API**: Completely rewrote image upload to use X's proper INIT/APPEND/FINALIZE workflow
  - Fixed OAuth 1.0a signature issues with multipart requests
  - Images now upload successfully to X without silent failures
  - Added comprehensive error logging for debugging
  - Follows X's recommended upload process for media attachments

### 🎯 Technical Improvements

- Enhanced error handling and logging for media uploads
- Improved validation for Blossom server URLs
- Better field management in account edit dialogs
- More accurate platform-specific size limits

### 📱 Android

- APK size: 56.2 MB
- All three media upload fixes included
- Google Photos access support (from v1.0.8)
- Network permissions configured (from v1.0.8)

### 🔄 Migration Notes

- Existing Nostr users can now edit their accounts to add Blossom server URLs
- No database migration required
- All existing accounts remain fully functional

### 🐛 Known Issues

None reported for this release.

---

## Installation

### Obtainium (Recommended)
1. Install Obtainium from https://obtainium.imranr.dev/
2. Add App → Paste: `https://github.com/11bDev/yall`
3. Install

### Direct Download
Download the appropriate file for your platform from the [releases page](https://github.com/11bDev/yall/releases/tag/v1.0.9).

---

**Full Changelog**: https://github.com/11bDev/yall/compare/v1.0.8...v1.0.9
