import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../models/window_state.dart';
import 'secure_storage_service.dart';

/// Exception thrown by WindowStateManager operations
class WindowStateException implements Exception {
  final String message;
  final dynamic originalError;

  const WindowStateException(this.message, [this.originalError]);

  @override
  String toString() => 'WindowStateException: $message';
}

/// Manager for window state persistence and management
class WindowStateManager extends ChangeNotifier with WindowListener {
  static const String _windowStateKey = 'window_state';

  final SecureStorageService _storageService;
  WindowState _currentState = WindowState.defaultState;
  bool _isInitialized = false;
  String? _error;

  /// Constructor
  WindowStateManager({SecureStorageService? storageService})
    : _storageService = storageService ?? SecureStorageService();

  /// Get current window state
  WindowState get currentState => _currentState;

  /// Get initialization status
  bool get isInitialized => _isInitialized;

  /// Get current error message
  String? get error => _error;

  /// Initialize window manager and restore window state
  Future<void> initialize() async {
    try {
      _clearError();

      // Check if platform supports window management
      if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
        throw WindowStateException(
          'Window management not supported on this platform',
        );
      }

      // Ensure window manager is initialized
      await windowManager.ensureInitialized();

      // Add this as a window listener
      windowManager.addListener(this);

      // Load saved window state
      await _loadWindowState();

      // Apply the loaded state
      await _applyWindowState();

      _isInitialized = true;
      notifyListeners();
      debugPrint('Window state manager initialized successfully');
    } catch (e) {
      _setError('Failed to initialize window state manager: $e');
      throw WindowStateException(
        'Failed to initialize window state manager',
        e,
      );
    }
  }

  /// Load window state from storage
  Future<void> _loadWindowState() async {
    try {
      final stateJson = await _storageService.getSetting(_windowStateKey);
      if (stateJson != null) {
        final loadedState = WindowState.fromJsonString(stateJson);

        // Check if current window size matches our desired defaults
        final currentSize = await windowManager.getSize();
        const desiredWidth = 760.0;
        const desiredHeight = 575.0;

        // If current window size matches desired size, prefer current over saved
        if ((currentSize.width - desiredWidth).abs() < 10 &&
            (currentSize.height - desiredHeight).abs() < 10) {
          // Use current position but prefer current size
          _currentState = WindowState(
            x: loadedState.x,
            y: loadedState.y,
            width: currentSize.width,
            height: currentSize.height,
            isMaximized: loadedState.isMaximized,
            isMinimized: loadedState.isMinimized,
            isVisible: loadedState.isVisible,
          );
          debugPrint(
            'Using current window size over saved state (matches desired defaults)',
          );
        } else {
          // Validate loaded state against minimum size constraints
          _currentState = _validateWindowSize(loadedState);
        }
        debugPrint('Loaded window state: $_currentState');
      } else {
        _currentState = WindowState.defaultState;
        debugPrint('Using default window state');
      }
    } catch (e) {
      debugPrint('Error loading window state: $e');
      _currentState = WindowState.defaultState;
    }
  }

  /// Validate and adjust window size to respect minimum constraints
  WindowState _validateWindowSize(WindowState state) {
    const double minWidth = 500.0; // Match main.dart minimum
    const double minHeight = 600.0; // Match main.dart minimum
    const double preferredWidth = 760.0; // Preferred width from main.dart
    const double preferredHeight = 575.0; // Preferred height from main.dart

    double? adjustedWidth = state.width;
    double? adjustedHeight = state.height;

    // Ensure minimum width
    if (adjustedWidth != null && adjustedWidth < minWidth) {
      adjustedWidth = preferredWidth; // Use preferred instead of just minimum
      debugPrint(
        'Adjusted width from ${state.width} to $adjustedWidth (using preferred size)',
      );
    }

    // Ensure minimum height and prefer better height for UI
    if (adjustedHeight != null && adjustedHeight < minHeight) {
      adjustedHeight = preferredHeight; // Use preferred instead of just minimum
      debugPrint(
        'Adjusted height from ${state.height} to $adjustedHeight (using preferred size)',
      );
    }

    // If the saved size is too small for good UX, upgrade to preferred
    if (adjustedWidth != null && adjustedHeight != null) {
      if (adjustedWidth < preferredWidth || adjustedHeight < preferredHeight) {
        adjustedWidth = preferredWidth;
        adjustedHeight = preferredHeight;
        debugPrint(
          'Upgraded window size to preferred dimensions for better UX: ${preferredWidth}x$preferredHeight',
        );
      }
    }

    // Return adjusted state if changes were made
    if (adjustedWidth != state.width || adjustedHeight != state.height) {
      return WindowState(
        x: state.x,
        y: state.y,
        width: adjustedWidth,
        height: adjustedHeight,
        isMaximized: state.isMaximized,
        isMinimized: state.isMinimized,
        isVisible: state.isVisible,
      );
    }

    return state;
  }

  /// Save current window state to storage
  Future<void> _saveWindowState() async {
    try {
      await _storageService.storeSetting(
        _windowStateKey,
        _currentState.toJsonString(),
      );
      debugPrint('Saved window state: $_currentState');
    } catch (e) {
      debugPrint('Error saving window state: $e');
    }
  }

  /// Apply window state to the actual window
  Future<void> _applyWindowState() async {
    try {
      // Set window size
      if (_currentState.hasValidSize) {
        await windowManager.setSize(
          Size(_currentState.width!, _currentState.height!),
        );
      }

      // Set window position
      if (_currentState.hasValidPosition) {
        await windowManager.setPosition(
          Offset(_currentState.x!, _currentState.y!),
        );
      }

      // Handle maximized state
      if (_currentState.isMaximized) {
        await windowManager.maximize();
      } else {
        await windowManager.unmaximize();
      }

      // Handle minimized state
      if (_currentState.isMinimized) {
        await windowManager.minimize();
      }

      // Handle visibility
      if (_currentState.isVisible) {
        await windowManager.show();
      } else {
        await windowManager.hide();
      }

      debugPrint('Applied window state successfully');
    } catch (e) {
      debugPrint('Error applying window state: $e');
    }
  }

  /// Update current window state from actual window
  Future<void> _updateCurrentState() async {
    try {
      final bounds = await windowManager.getBounds();
      final isMaximized = await windowManager.isMaximized();
      final isMinimized = await windowManager.isMinimized();
      final isVisible = await windowManager.isVisible();

      _currentState = WindowState(
        x: bounds.left,
        y: bounds.top,
        width: bounds.width,
        height: bounds.height,
        isMaximized: isMaximized,
        isMinimized: isMinimized,
        isVisible: isVisible,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating current state: $e');
    }
  }

  /// Show the window
  Future<void> showWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
      await _updateCurrentState();
      await _saveWindowState();
    } catch (e) {
      _setError('Failed to show window: $e');
      debugPrint('Error showing window: $e');
    }
  }

  /// Hide the window
  Future<void> hideWindow() async {
    try {
      await windowManager.hide();
      await _updateCurrentState();
      await _saveWindowState();
    } catch (e) {
      _setError('Failed to hide window: $e');
      debugPrint('Error hiding window: $e');
    }
  }

  /// Minimize the window
  Future<void> minimizeWindow() async {
    try {
      await windowManager.minimize();
      await _updateCurrentState();
      await _saveWindowState();
    } catch (e) {
      _setError('Failed to minimize window: $e');
      debugPrint('Error minimizing window: $e');
    }
  }

  /// Maximize the window
  Future<void> maximizeWindow() async {
    try {
      await windowManager.maximize();
      await _updateCurrentState();
      await _saveWindowState();
    } catch (e) {
      _setError('Failed to maximize window: $e');
      debugPrint('Error maximizing window: $e');
    }
  }

  /// Restore the window from minimized/maximized state
  Future<void> restoreWindow() async {
    try {
      await windowManager.unmaximize();
      await windowManager.show();
      await windowManager.focus();
      await _updateCurrentState();
      await _saveWindowState();
    } catch (e) {
      _setError('Failed to restore window: $e');
      debugPrint('Error restoring window: $e');
    }
  }

  /// Center the window on screen
  Future<void> centerWindow() async {
    try {
      await windowManager.center();
      await _updateCurrentState();
      await _saveWindowState();
    } catch (e) {
      _setError('Failed to center window: $e');
      debugPrint('Error centering window: $e');
    }
  }

  /// Set window size
  Future<void> setWindowSize(double width, double height) async {
    try {
      await windowManager.setSize(Size(width, height));
      await _updateCurrentState();
      await _saveWindowState();
    } catch (e) {
      _setError('Failed to set window size: $e');
      debugPrint('Error setting window size: $e');
    }
  }

  /// Set window position
  Future<void> setWindowPosition(double x, double y) async {
    try {
      await windowManager.setPosition(Offset(x, y));
      await _updateCurrentState();
      await _saveWindowState();
    } catch (e) {
      _setError('Failed to set window position: $e');
      debugPrint('Error setting window position: $e');
    }
  }

  /// Check if window is currently visible
  Future<bool> isWindowVisible() async {
    try {
      return await windowManager.isVisible();
    } catch (e) {
      debugPrint('Error checking window visibility: $e');
      return _currentState.isVisible;
    }
  }

  /// Check if window is currently maximized
  Future<bool> isWindowMaximized() async {
    try {
      return await windowManager.isMaximized();
    } catch (e) {
      debugPrint('Error checking window maximized state: $e');
      return _currentState.isMaximized;
    }
  }

  /// Check if window is currently minimized
  Future<bool> isWindowMinimized() async {
    try {
      return await windowManager.isMinimized();
    } catch (e) {
      debugPrint('Error checking window minimized state: $e');
      return _currentState.isMinimized;
    }
  }

  /// Handle window close event (return true to prevent close)
  Future<bool> handleWindowClose() async {
    try {
      // Save current state before potentially closing
      await _updateCurrentState();
      await _saveWindowState();

      // Return false to allow normal close behavior
      // The calling code should handle minimize to tray logic
      return false;
    } catch (e) {
      debugPrint('Error handling window close: $e');
      return false;
    }
  }

  // WindowListener overrides
  @override
  void onWindowClose() {
    debugPrint('Window close event received');
    // This should not actually close the window - we prevent it and handle it ourselves
    // The PopScope in main.dart will handle the minimize to tray logic
  }

  @override
  void onWindowResize() {
    debugPrint('Window resize event received');
    _updateCurrentState();
    _saveWindowState();
  }

  @override
  void onWindowMove() {
    debugPrint('Window move event received');
    _updateCurrentState();
    _saveWindowState();
  }

  @override
  void onWindowMaximize() {
    debugPrint('Window maximize event received');
    _updateCurrentState();
    _saveWindowState();
  }

  @override
  void onWindowUnmaximize() {
    debugPrint('Window unmaximize event received');
    _updateCurrentState();
    _saveWindowState();
  }

  @override
  void onWindowMinimize() {
    debugPrint('Window minimize event received');
    _updateCurrentState();
    _saveWindowState();
  }

  @override
  void onWindowRestore() {
    debugPrint('Window restore event received');
    _updateCurrentState();
    _saveWindowState();
  }

  @override
  void onWindowFocus() {
    debugPrint('Window focus event received');
  }

  @override
  void onWindowBlur() {
    debugPrint('Window blur event received');
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

  /// Get window state status information
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'currentState': _currentState.toJson(),
      'error': _error,
      'platform': Platform.operatingSystem,
    };
  }

  /// Dispose of window state manager resources
  @override
  Future<void> dispose() async {
    try {
      if (_isInitialized) {
        // Save current state before disposing
        await _updateCurrentState();
        await _saveWindowState();

        // Remove window listener
        windowManager.removeListener(this);

        _isInitialized = false;
        debugPrint('Window state manager disposed');
      }
    } catch (e) {
      debugPrint('Error disposing window state manager: $e');
    }
    super.dispose();
  }
}
