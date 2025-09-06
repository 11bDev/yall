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

  /// Light theme data with Windows Fluent Design
  ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0078D4), // Windows accent blue
      brightness: Brightness.light,
    );
    
    return ThemeData.light().copyWith(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Ubuntu'),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: ThemeData.light().textTheme.titleLarge?.copyWith(
          fontFamily: 'Ubuntu',
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }

  /// Dark theme data with Windows Fluent Design
  ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0078D4), // Windows accent blue
      brightness: Brightness.dark,
    );
    
    return ThemeData.dark().copyWith(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Ubuntu'),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: ThemeData.dark().textTheme.titleLarge?.copyWith(
          fontFamily: 'Ubuntu',
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
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
