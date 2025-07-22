import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';

/// Exception thrown by SystemTrayManager operations
class SystemTrayException implements Exception {
  final String message;
  final dynamic originalError;

  const SystemTrayException(this.message, [this.originalError]);

  @override
  String toString() => 'SystemTrayException: $message';
}

/// Manager for system tray integration
class SystemTrayManager extends ChangeNotifier {
  late final SystemTray _systemTray;
  late final AppWindow _appWindow;

  bool _isInitialized = false;
  bool _isVisible = true;
  String? _error;

  /// Callback functions for tray menu actions
  VoidCallback? onShowWindow;
  VoidCallback? onHideWindow;
  VoidCallback? onOpenSettings;
  VoidCallback? onQuitApplication;

  /// Constructor
  SystemTrayManager() {
    _systemTray = SystemTray();
    _appWindow = AppWindow();
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;

  /// Get window visibility status
  bool get isVisible => _isVisible;

  /// Get current error message
  String? get error => _error;

  /// Initialize the system tray
  Future<void> initialize() async {
    try {
      _clearError();

      // Check if platform supports system tray
      if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
        throw SystemTrayException('System tray not supported on this platform');
      }

      // Initialize the system tray
      await _systemTray.initSystemTray(
        title: "Yall",
        iconPath: _getTrayIconPath(),
      );

      // Set up the context menu
      await _setupContextMenu();

      // Set up tray click handler
      _systemTray.registerSystemTrayEventHandler((eventName) {
        debugPrint('System tray event: $eventName');
        if (eventName == kSystemTrayEventClick) {
          _handleTrayClick();
        } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        }
      });

      _isInitialized = true;
      notifyListeners();
      debugPrint('System tray initialized successfully');
    } catch (e) {
      _setError('Failed to initialize system tray: $e');
      throw SystemTrayException('Failed to initialize system tray', e);
    }
  }

  /// Set up the context menu for the system tray
  Future<void> _setupContextMenu() async {
    final Menu menu = Menu();

    await menu.buildFrom([
      MenuItemLabel(
        label: 'Show Window',
        onClicked: (menuItem) => _handleShowWindow(),
      ),
      MenuItemLabel(
        label: 'Hide Window',
        onClicked: (menuItem) => _handleHideWindow(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Settings',
        onClicked: (menuItem) => _handleOpenSettings(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Quit',
        onClicked: (menuItem) => _handleQuitApplication(),
      ),
    ]);

    await _systemTray.setContextMenu(menu);
  }

  /// Get the appropriate tray icon path for the current platform
  String _getTrayIconPath() {
    if (Platform.isWindows) {
      return 'assets/icons/tray_icon.ico';
    } else if (Platform.isMacOS) {
      return 'assets/icons/tray_icon.png';
    } else {
      // Linux and other platforms
      return 'assets/icons/tray_icon.svg';
    }
  }

  /// Handle tray icon click
  void _handleTrayClick() {
    if (_isVisible) {
      hideWindow();
    } else {
      showWindow();
    }
  }

  /// Handle show window menu item
  void _handleShowWindow() {
    showWindow();
  }

  /// Handle hide window menu item
  void _handleHideWindow() {
    hideWindow();
  }

  /// Handle settings menu item
  void _handleOpenSettings() {
    onOpenSettings?.call();
  }

  /// Handle quit application menu item
  void _handleQuitApplication() {
    onQuitApplication?.call();
  }

  /// Show the application window
  Future<void> showWindow() async {
    try {
      await _appWindow.show();
      _isVisible = true;
      notifyListeners();
      onShowWindow?.call();
      debugPrint('Window shown');
    } catch (e) {
      _setError('Failed to show window: $e');
      debugPrint('Error showing window: $e');
    }
  }

  /// Hide the application window
  Future<void> hideWindow() async {
    try {
      await _appWindow.hide();
      _isVisible = false;
      notifyListeners();
      onHideWindow?.call();
      debugPrint('Window hidden');
    } catch (e) {
      _setError('Failed to hide window: $e');
      debugPrint('Error hiding window: $e');
    }
  }

  /// Minimize window to tray instead of taskbar
  Future<void> minimizeToTray() async {
    await hideWindow();
  }

  /// Check if window is currently visible
  Future<bool> isWindowVisible() async {
    try {
      // The system_tray package doesn't provide isVisible method
      // We'll track visibility state internally
      return _isVisible;
    } catch (e) {
      debugPrint('Error checking window visibility: $e');
      return _isVisible;
    }
  }

  /// Update tray tooltip
  Future<void> updateTooltip(String tooltip) async {
    try {
      await _systemTray.setToolTip(tooltip);
    } catch (e) {
      debugPrint('Error updating tray tooltip: $e');
    }
  }

  /// Update tray icon
  Future<void> updateIcon(String iconPath) async {
    try {
      await _systemTray.setImage(iconPath);
    } catch (e) {
      debugPrint('Error updating tray icon: $e');
    }
  }

  /// Show a notification from the system tray
  Future<void> showNotification({
    required String title,
    required String message,
    String? iconPath,
  }) async {
    try {
      // Note: system_tray package may not support notifications directly
      // This is a placeholder for future implementation
      debugPrint('Notification: $title - $message');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Dispose of system tray resources
  @override
  Future<void> dispose() async {
    try {
      if (_isInitialized) {
        await _systemTray.destroy();
        _isInitialized = false;
        debugPrint('System tray disposed');
      }
    } catch (e) {
      debugPrint('Error disposing system tray: $e');
    }
    super.dispose();
  }

  /// Clear current error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
  }

  /// Handle window close event (minimize to tray instead of closing)
  Future<bool> handleWindowClose() async {
    await minimizeToTray();
    return false; // Prevent actual window close
  }

  /// Get system tray status information
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'visible': _isVisible,
      'error': _error,
      'platform': Platform.operatingSystem,
    };
  }
}
