import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:yall/providers/theme_manager.dart';
import 'package:yall/services/secure_storage_service.dart';
import 'package:yall/models/app_settings.dart';

import 'theme_manager_test.mocks.dart';

@GenerateMocks([SecureStorageService])
void main() {
  group('ThemeManager', () {
    late MockSecureStorageService mockStorageService;
    late ThemeManager themeManager;

    setUp(() {
      mockStorageService = MockSecureStorageService();
      themeManager = ThemeManager(storageService: mockStorageService);
    });

    group('Initialization', () {
      test('should initialize with default settings when no stored settings exist', () async {
        // Arrange
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => null);

        // Act
        await themeManager.initialize();

        // Assert
        expect(themeManager.isInitialized, isTrue);
        expect(themeManager.settings, equals(AppSettings.defaultSettings()));
        expect(themeManager.themeMode, equals(ThemeMode.system));
      });

      test('should initialize with stored settings when they exist', () async {
        // Arrange
        final storedSettings = AppSettings(
          themeMode: ThemeMode.dark,
          minimizeToTray: false,
        );
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => storedSettings.toJsonString());

        // Act
        await themeManager.initialize();

        // Assert
        expect(themeManager.isInitialized, isTrue);
        expect(themeManager.themeMode, equals(ThemeMode.dark));
        expect(themeManager.settings.minimizeToTray, isFalse);
      });

      test('should throw ThemeException when initialization fails', () async {
        // Arrange
        when(mockStorageService.getSetting('app_settings'))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => themeManager.initialize(),
          throwsA(isA<ThemeException>()),
        );
      });
    });

    group('Theme Mode Management', () {
      setUp(() async {
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => null);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});
        await themeManager.initialize();
      });

      test('should set theme mode and persist changes', () async {
        // Arrange
        var notificationCount = 0;
        themeManager.addListener(() => notificationCount++);

        // Act
        await themeManager.setThemeMode(ThemeMode.dark);

        // Assert
        expect(themeManager.themeMode, equals(ThemeMode.dark));
        expect(notificationCount, equals(1));
        verify(mockStorageService.storeSetting('app_settings', any)).called(1);
      });

      test('should toggle between light and dark themes', () async {
        // Arrange
        await themeManager.setThemeMode(ThemeMode.light);
        reset(mockStorageService);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});

        // Act
        await themeManager.toggleTheme();

        // Assert
        expect(themeManager.themeMode, equals(ThemeMode.dark));

        // Act again
        await themeManager.toggleTheme();

        // Assert
        expect(themeManager.themeMode, equals(ThemeMode.light));
      });

      test('should throw ThemeException when setting theme mode fails', () async {
        // Arrange
        when(mockStorageService.storeSetting(any, any))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => themeManager.setThemeMode(ThemeMode.dark),
          throwsA(isA<ThemeException>()),
        );
      });
    });

    group('Settings Management', () {
      setUp(() async {
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => null);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});
        await themeManager.initialize();
      });

      test('should update settings and persist changes', () async {
        // Arrange
        final newSettings = AppSettings(
          themeMode: ThemeMode.light,
          minimizeToTray: false,
          autoSaveContent: false,
        );
        var notificationCount = 0;
        themeManager.addListener(() => notificationCount++);

        // Act
        await themeManager.updateSettings(newSettings);

        // Assert
        expect(themeManager.settings, equals(newSettings));
        expect(notificationCount, equals(1));
        verify(mockStorageService.storeSetting('app_settings', any)).called(1);
      });

      test('should reset to default settings', () async {
        // Arrange
        await themeManager.setThemeMode(ThemeMode.dark);
        reset(mockStorageService);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});

        // Act
        await themeManager.resetToDefaults();

        // Assert
        expect(themeManager.settings, equals(AppSettings.defaultSettings()));
        expect(themeManager.themeMode, equals(ThemeMode.system));
      });

      test('should clear stored settings', () async {
        // Arrange
        await themeManager.setThemeMode(ThemeMode.dark);
        when(mockStorageService.deleteSetting('app_settings'))
            .thenAnswer((_) async {});

        // Act
        await themeManager.clearStoredSettings();

        // Assert
        expect(themeManager.settings, equals(AppSettings.defaultSettings()));
        verify(mockStorageService.deleteSetting('app_settings')).called(1);
      });
    });

    group('Theme Data', () {
      test('should provide light theme with Material Design 3', () {
        // Act
        final lightTheme = themeManager.lightTheme;

        // Assert
        expect(lightTheme.useMaterial3, isTrue);
        expect(lightTheme.brightness, equals(Brightness.light));
        expect(lightTheme.colorScheme.brightness, equals(Brightness.light));
        expect(lightTheme.colorScheme.primary, equals(const Color(0xFF6750A4)));
      });

      test('should provide dark theme with Material Design 3', () {
        // Act
        final darkTheme = themeManager.darkTheme;

        // Assert
        expect(darkTheme.useMaterial3, isTrue);
        expect(darkTheme.brightness, equals(Brightness.dark));
        expect(darkTheme.colorScheme.brightness, equals(Brightness.dark));
        expect(darkTheme.colorScheme.primary, equals(const Color(0xFFD0BCFF)));
      });

      test('should have consistent theme structure between light and dark', () {
        // Act
        final lightTheme = themeManager.lightTheme;
        final darkTheme = themeManager.darkTheme;

        // Assert
        expect(lightTheme.appBarTheme.elevation, equals(darkTheme.appBarTheme.elevation));
        expect(lightTheme.cardTheme.elevation, equals(darkTheme.cardTheme.elevation));
        expect(lightTheme.useMaterial3, equals(darkTheme.useMaterial3));
      });
    });

    group('Brightness Detection', () {
      testWidgets('should return correct effective brightness for light mode', (tester) async {
        // Arrange
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => null);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});
        await themeManager.initialize();
        await themeManager.setThemeMode(ThemeMode.light);

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Act
                final brightness = themeManager.getEffectiveBrightness(context);
                final isDark = themeManager.isDarkMode(context);

                // Assert
                expect(brightness, equals(Brightness.light));
                expect(isDark, isFalse);

                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('should return correct effective brightness for dark mode', (tester) async {
        // Arrange
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => null);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});
        await themeManager.initialize();
        await themeManager.setThemeMode(ThemeMode.dark);

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Act
                final brightness = themeManager.getEffectiveBrightness(context);
                final isDark = themeManager.isDarkMode(context);

                // Assert
                expect(brightness, equals(Brightness.dark));
                expect(isDark, isTrue);

                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('should return system brightness for system mode', (tester) async {
        // Arrange
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => null);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});
        await themeManager.initialize();
        await themeManager.setThemeMode(ThemeMode.system);

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Act
                final brightness = themeManager.getEffectiveBrightness(context);
                final systemBrightness = MediaQuery.of(context).platformBrightness;

                // Assert
                expect(brightness, equals(systemBrightness));

                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully during settings update', () async {
        // Arrange
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => null);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});
        await themeManager.initialize();

        when(mockStorageService.storeSetting(any, any))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => themeManager.updateSettings(AppSettings.defaultSettings()),
          throwsA(isA<ThemeException>()),
        );
      });

      test('should handle storage errors gracefully during reset', () async {
        // Arrange
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => null);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});
        await themeManager.initialize();

        when(mockStorageService.storeSetting(any, any))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => themeManager.resetToDefaults(),
          throwsA(isA<ThemeException>()),
        );
      });

      test('should handle storage errors gracefully during clear', () async {
        // Arrange
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => null);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});
        await themeManager.initialize();

        when(mockStorageService.deleteSetting(any))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => themeManager.clearStoredSettings(),
          throwsA(isA<ThemeException>()),
        );
      });
    });

    group('Listener Notifications', () {
      setUp(() async {
        when(mockStorageService.getSetting('app_settings'))
            .thenAnswer((_) async => null);
        when(mockStorageService.storeSetting(any, any))
            .thenAnswer((_) async {});
        await themeManager.initialize();
      });

      test('should notify listeners when theme mode changes', () async {
        // Arrange
        var notificationCount = 0;
        themeManager.addListener(() => notificationCount++);

        // Act
        await themeManager.setThemeMode(ThemeMode.dark);
        await themeManager.setThemeMode(ThemeMode.light);

        // Assert
        expect(notificationCount, equals(2));
      });

      test('should notify listeners when settings are updated', () async {
        // Arrange
        var notificationCount = 0;
        themeManager.addListener(() => notificationCount++);

        // Act
        await themeManager.updateSettings(AppSettings(minimizeToTray: false));

        // Assert
        expect(notificationCount, equals(1));
      });

      test('should notify listeners when settings are reset', () async {
        // Arrange
        var notificationCount = 0;
        themeManager.addListener(() => notificationCount++);

        // Act
        await themeManager.resetToDefaults();

        // Assert
        expect(notificationCount, equals(1));
      });
    });
  });
}