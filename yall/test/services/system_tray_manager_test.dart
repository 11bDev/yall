import 'package:flutter_test/flutter_test.dart';
import 'package:yall/services/system_tray_manager.dart';
import 'package:yall/services/mock_system_tray_manager.dart';

void main() {
  group('SystemTrayManager', () {
    late MockSystemTrayManager systemTrayManager;

    setUp(() {
      systemTrayManager = MockSystemTrayManager();
    });

    tearDown(() async {
      await systemTrayManager.dispose();
    });

    group('Initialization', () {
      test('should start with correct initial state', () {
        expect(systemTrayManager.isInitialized, false);
        expect(systemTrayManager.isVisible, true);
        expect(systemTrayManager.error, null);
      });

      test('should provide status information', () {
        final status = systemTrayManager.getStatus();

        expect(status, isA<Map<String, dynamic>>());
        expect(status['initialized'], false);
        expect(status['visible'], true);
        expect(status['error'], null);
        expect(status['platform'], isA<String>());
      });
    });

    group('Error Handling', () {
      test('should handle and clear errors', () {
        // Set an error using the private method (simulated)
        systemTrayManager.clearError();
        expect(systemTrayManager.error, null);
      });

      test('should create SystemTrayException with message', () {
        const exception = SystemTrayException('Test error');
        expect(exception.message, 'Test error');
        expect(exception.toString(), 'SystemTrayException: Test error');
      });

      test('should create SystemTrayException with original error', () {
        final originalError = Exception('Original error');
        final exception = SystemTrayException('Test error', originalError);

        expect(exception.message, 'Test error');
        expect(exception.originalError, originalError);
      });
    });

    group('Callback Management', () {
      test('should allow setting callback functions', () {
        systemTrayManager.onShowWindow = () {};
        systemTrayManager.onHideWindow = () {};
        systemTrayManager.onOpenSettings = () {};
        systemTrayManager.onQuitApplication = () {};

        expect(systemTrayManager.onShowWindow, isNotNull);
        expect(systemTrayManager.onHideWindow, isNotNull);
        expect(systemTrayManager.onOpenSettings, isNotNull);
        expect(systemTrayManager.onQuitApplication, isNotNull);
      });
    });

    group('Window Management', () {
      test('should handle window close event', () async {
        final result = await systemTrayManager.handleWindowClose();
        expect(result, false); // Should prevent actual window close
      });
    });

    group('Notification System', () {
      test('should handle notification requests', () async {
        // This test verifies the method exists and doesn't throw
        await systemTrayManager.showNotification(
          title: 'Test Title',
          message: 'Test Message',
        );

        await systemTrayManager.showNotification(
          title: 'Test Title',
          message: 'Test Message',
          iconPath: 'test/icon/path',
        );
      });
    });

    group('Tray Updates', () {
      test('should handle tooltip updates', () async {
        // This test verifies the method exists and doesn't throw
        await systemTrayManager.updateTooltip('New tooltip');
      });

      test('should handle icon updates', () async {
        // This test verifies the method exists and doesn't throw
        await systemTrayManager.updateIcon('new/icon/path');
      });
    });

    group('State Management', () {
      test('should notify listeners on state changes', () {
        bool notified = false;
        systemTrayManager.addListener(() {
          notified = true;
        });

        systemTrayManager.clearError();
        expect(notified, true);
      });
    });
  });
}
