import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../models/app_settings.dart';
import '../design_system/ubuntu_constants.dart';

/// Exception thrown when theme operations fail
class ThemeException implements Exception {
  final String message;
  final dynamic originalError;

  const ThemeException(this.message, [this.originalError]);

  @override
  String toString() => 'ThemeException: $message';
}

/// Provider for managing application theme state and persistence
class ThemeManager extends ChangeNotifier {
  static const String _themeSettingsKey = 'app_settings';

  final SecureStorageService _storageService;
  AppSettings _settings = AppSettings.defaultSettings();
  bool _isInitialized = false;

  ThemeManager({SecureStorageService? storageService})
    : _storageService = storageService ?? SecureStorageService();

  /// Current application settings
  AppSettings get settings => _settings;

  /// Current theme mode
  ThemeMode get themeMode => _settings.themeMode;

  /// Whether the theme manager has been initialized
  bool get isInitialized => _isInitialized;

  /// Light theme data with Material Design 3
  ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Ubuntu'),
      appBarTheme: ThemeData.light().appBarTheme.copyWith(
        elevation: UbuntuElevation.none,
        centerTitle: true,
        backgroundColor: ThemeData.light().colorScheme.surface,
        foregroundColor: ThemeData.light().colorScheme.onSurface,
      ),
      cardTheme: ThemeData.light().cardTheme.copyWith(
        elevation: UbuntuElevation.low,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UbuntuRadius.lg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UbuntuRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: UbuntuSpacing.lg,
            vertical: UbuntuSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UbuntuRadius.md),
        ),
        filled: true,
        fillColor: ThemeData.light().colorScheme.surfaceContainerHighest.withOpacity(
          0.3,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UbuntuSpacing.md,
          vertical: UbuntuSpacing.sm,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UbuntuRadius.sm),
        ),
      ),
    );
  }

  /// Dark theme data with Material Design 3  
  ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Ubuntu'),
      appBarTheme: ThemeData.dark().appBarTheme.copyWith(
        elevation: UbuntuElevation.none,
        centerTitle: true,
        backgroundColor: ThemeData.dark().colorScheme.surface,
        foregroundColor: ThemeData.dark().colorScheme.onSurface,
      ),
      cardTheme: ThemeData.dark().cardTheme.copyWith(
        elevation: UbuntuElevation.low,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UbuntuRadius.lg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UbuntuRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: UbuntuSpacing.lg,
            vertical: UbuntuSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UbuntuRadius.md),
        ),
        filled: true,
        fillColor: ThemeData.dark().colorScheme.surfaceContainerHighest.withOpacity(
          0.3,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UbuntuSpacing.md,
          vertical: UbuntuSpacing.sm,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UbuntuRadius.sm),
        ),
      ),
    );
  }

  /// Initialize the theme manager by loading saved settings
  Future<void> initialize() async {
    try {
      final settingsJson = await _storageService.getSetting(_themeSettingsKey);

      if (settingsJson != null) {
        _settings = AppSettings.fromJsonString(settingsJson);
      } else {
        _settings = AppSettings.defaultSettings();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      throw ThemeException('Failed to initialize theme manager', e);
    }
  }

  /// Update the theme mode and persist the change
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final newSettings = _settings.copyWith(themeMode: mode);
      await _saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      throw ThemeException('Failed to set theme mode', e);
    }
  }

  /// Toggle between light and dark themes (ignores system theme)
  Future<void> toggleTheme() async {
    final newMode = _settings.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Update the close to tray setting
  Future<void> setCloseToTray(bool closeToTray) async {
    try {
      final newSettings = _settings.copyWith(closeToTray: closeToTray);
      await _saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      throw ThemeException('Failed to set close to tray setting', e);
    }
  }

  /// Update the minimize to tray setting
  Future<void> setMinimizeToTray(bool minimizeToTray) async {
    try {
      final newSettings = _settings.copyWith(minimizeToTray: minimizeToTray);
      await _saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      throw ThemeException('Failed to set minimize to tray setting', e);
    }
  }

  /// Update application settings and persist changes
  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      await _saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      throw ThemeException('Failed to update settings', e);
    }
  }

  /// Reset settings to default values
  Future<void> resetToDefaults() async {
    try {
      final defaultSettings = AppSettings.defaultSettings();
      await _saveSettings(defaultSettings);
      _settings = defaultSettings;
      notifyListeners();
    } catch (e) {
      throw ThemeException('Failed to reset settings', e);
    }
  }

  /// Get the effective brightness based on current theme mode and system brightness
  Brightness getEffectiveBrightness(BuildContext context) {
    switch (_settings.themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Check if the current theme is dark
  bool isDarkMode(BuildContext context) {
    return getEffectiveBrightness(context) == Brightness.dark;
  }

  /// Save settings to secure storage
  Future<void> _saveSettings(AppSettings settings) async {
    try {
      final settingsJson = settings.toJsonString();
      await _storageService.storeSetting(_themeSettingsKey, settingsJson);
    } catch (e) {
      throw ThemeException('Failed to save settings', e);
    }
  }

  /// Clear all stored theme settings
  Future<void> clearStoredSettings() async {
    try {
      await _storageService.deleteSetting(_themeSettingsKey);
      _settings = AppSettings.defaultSettings();
      notifyListeners();
    } catch (e) {
      throw ThemeException('Failed to clear stored settings', e);
    }
  }
}
