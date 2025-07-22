import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../models/app_settings.dart';

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

  /// Light theme data with custom Material Design 3 color scheme
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColorScheme.surface,
        foregroundColor: _lightColorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _lightColorScheme.surfaceVariant.withOpacity(0.3),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Dark theme data with custom Material Design 3 color scheme
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _darkColorScheme.surfaceVariant.withOpacity(0.3),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Custom light color scheme based on Material Design 3
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6750A4),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEADDFF),
    onPrimaryContainer: Color(0xFF21005D),
    secondary: Color(0xFF625B71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE8DEF8),
    onSecondaryContainer: Color(0xFF1D192B),
    tertiary: Color(0xFF7D5260),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFD8E4),
    onTertiaryContainer: Color(0xFF31111D),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    outline: Color(0xFF79747E),
    background: Color(0xFFFFFBFE),
    onBackground: Color(0xFF1C1B1F),
    surface: Color(0xFFFFFBFE),
    onSurface: Color(0xFF1C1B1F),
    surfaceVariant: Color(0xFFE7E0EC),
    onSurfaceVariant: Color(0xFF49454F),
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFFD0BCFF),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFF6750A4),
    outlineVariant: Color(0xFFCAC4D0),
    scrim: Color(0xFF000000),
  );

  /// Custom dark color scheme based on Material Design 3
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFD0BCFF),
    onPrimary: Color(0xFF381E72),
    primaryContainer: Color(0xFF4F378B),
    onPrimaryContainer: Color(0xFFEADDFF),
    secondary: Color(0xFFCCC2DC),
    onSecondary: Color(0xFF332D41),
    secondaryContainer: Color(0xFF4A4458),
    onSecondaryContainer: Color(0xFFE8DEF8),
    tertiary: Color(0xFFEFB8C8),
    onTertiary: Color(0xFF492532),
    tertiaryContainer: Color(0xFF633B48),
    onTertiaryContainer: Color(0xFFFFD8E4),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    outline: Color(0xFF938F99),
    background: Color(0xFF1C1B1F),
    onBackground: Color(0xFFE6E1E5),
    surface: Color(0xFF1C1B1F),
    onSurface: Color(0xFFE6E1E5),
    surfaceVariant: Color(0xFF49454F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: Color(0xFF6750A4),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFFD0BCFF),
    outlineVariant: Color(0xFF49454F),
    scrim: Color(0xFF000000),
  );

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