import 'package:flutter/foundation.dart';
import 'system_tray_manager.dart';

/// Mock implementation of SystemTrayManager for testing
class MockSystemTrayManager extends ChangeNotifier {
  bool _mockInitialized = false;
  bool _mockVisible = true;
  String? _mockError;

  /// Callback functions for tray menu actions
  VoidCallback? onShowWindow;
  VoidCallback? onHideWindow;
  VoidCallback? onOpenSettings;
  VoidCallback? onQuitApplication;

  bool get isInitialized => _mockInitialized;
  bool get isVisible => _mockVisible;
  String? get error => _mockError;

  Future<void> initialize() async {
    try {
      _mockError = null;
      _mockInitialized = true;
      notifyListeners();
    } catch (e) {
      _mockError = 'Failed to initialize system tray: $e';
      throw SystemTrayException('Failed to initialize system tray', e);
    }
  }

  Future<void> showWindow() async {
    _mockVisible = true;
    notifyListeners();
    onShowWindow?.call();
  }

  Future<void> hideWindow() async {
    _mockVisible = false;
    notifyListeners();
    onHideWindow?.call();
  }

  Future<void> minimizeToTray() async {
    await hideWindow();
  }

  Future<bool> isWindowVisible() async {
    return _mockVisible;
  }

  Future<void> updateTooltip(String tooltip) async {
    // Mock implementation - no-op
  }

  Future<void> updateIcon(String iconPath) async {
    // Mock implementation - no-op
  }

  Future<void> showNotification({
    required String title,
    required String message,
    String? iconPath,
  }) async {
    // Mock implementation - no-op
  }

  bool _disposed = false;

  @override
  Future<void> dispose() async {
    if (_disposed) return;

    if (_mockInitialized) {
      _mockInitialized = false;
    }
    _disposed = true;
    super.dispose();
  }

  void clearError() {
    _mockError = null;
    notifyListeners();
  }

  Future<bool> handleWindowClose() async {
    await minimizeToTray();
    return false;
  }

  Map<String, dynamic> getStatus() {
    return {
      'initialized': _mockInitialized,
      'visible': _mockVisible,
      'error': _mockError,
      'platform': 'test',
    };
  }

  // Test helper methods
  void setMockError(String error) {
    _mockError = error;
    notifyListeners();
  }

  void setMockInitialized(bool initialized) {
    _mockInitialized = initialized;
    notifyListeners();
  }

  void setMockVisible(bool visible) {
    _mockVisible = visible;
    notifyListeners();
  }
}
