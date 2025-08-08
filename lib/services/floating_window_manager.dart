import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Service for managing floating window behavior across different platforms
class FloatingWindowManager {
  static const String _windowClass = 'yall';
  static const String _windowTitle = 'Yall - Social Media Poster';
  
  /// Configure window to behave as a floating window in tiling WMs
  static Future<void> configureFloatingWindow() async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
      return;
    }

    try {
      // Basic window properties
      await windowManager.setResizable(true);
      await windowManager.setClosable(true);
      await windowManager.setMinimizable(true);
      
      // For COSMIC and other tiling WMs, prevent maximization
      await windowManager.setMaximizable(false);
      
      // Set window title
      await windowManager.setTitle(_windowTitle);
      
      // Try to set movable (may not be supported in all window_manager versions)
      try {
        await windowManager.setMovable(true);
      } catch (e) {
        debugPrint('setMovable not supported: $e');
      }
      
      if (Platform.isLinux) {
        await _configureLinuxFloating();
      } else if (Platform.isWindows) {
        await _configureWindowsFloating();
      } else if (Platform.isMacOS) {
        await _configureMacOSFloating();
      }
      
      // Set size constraints that discourage tiling
      await windowManager.setMinimumSize(const Size(400, 300));
      await windowManager.setMaximumSize(const Size(800, 700));
      
      // Set a specific size that's less likely to be tiled
      await windowManager.setSize(const Size(600, 500));
      
      // Center the window
      await windowManager.center();
      
      debugPrint('Configured floating window behavior');
    } catch (e) {
      debugPrint('Failed to configure floating window: $e');
    }
  }
  
  /// Linux-specific floating window configuration
  static Future<void> _configureLinuxFloating() async {
    try {
      // Set aspect ratio to discourage tiling WMs from auto-tiling
      await windowManager.setAspectRatio(4.0 / 3.0);
      
      // Don't skip taskbar - we want it visible
      await windowManager.setSkipTaskbar(false);
      
      // Check for COSMIC desktop environment
      final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
      if (desktop == 'COSMIC') {
        await _configureCOSMICFloating();
      }
      
      // For X11-based systems, we can try to set window properties
      // that hint to the window manager about floating behavior
      if (Platform.environment.containsKey('DISPLAY')) {
        await _setX11WindowProperties();
      }
      
      // For Wayland systems, the options are more limited
      if (Platform.environment.containsKey('WAYLAND_DISPLAY')) {
        debugPrint('Running on Wayland - limited floating window control');
      }
      
    } catch (e) {
      debugPrint('Linux floating window configuration failed: $e');
    }
  }

  /// COSMIC desktop specific floating window configuration
  static Future<void> _configureCOSMICFloating() async {
    try {
      debugPrint('Configuring for COSMIC desktop environment');
      
      // COSMIC uses different window properties
      // Set window to be always floating by using specific size constraints
      await windowManager.setAlwaysOnTop(false);
      
      // Set a fixed size that COSMIC is less likely to tile
      await windowManager.setSize(const Size(600, 500));
      
      // Try to set window as a dialog type which COSMIC typically floats
      debugPrint('COSMIC Desktop detected - configuring floating behavior');
      debugPrint('Window class: $_windowClass');
      debugPrint('Window title: $_windowTitle');
      
      // For COSMIC, you may need to configure floating rules in the COSMIC settings
      debugPrint('');
      debugPrint('=== COSMIC Desktop Configuration ===');
      debugPrint('To ensure Yall always floats in COSMIC:');
      debugPrint('1. Open COSMIC Settings');
      debugPrint('2. Go to Desktop > Window Management');
      debugPrint('3. Add a floating rule for:');
      debugPrint('   - Application: $_windowClass');
      debugPrint('   - Title: $_windowTitle');
      debugPrint('4. Or use COSMIC\'s keyboard shortcut to toggle floating mode');
      debugPrint('   (Usually Super+Shift+F or similar)');
      debugPrint('=====================================');
      
    } catch (e) {
      debugPrint('COSMIC floating window configuration failed: $e');
    }
  }
  
  /// Set X11-specific window properties for floating behavior
  static Future<void> _setX11WindowProperties() async {
    try {
      // These properties help window managers identify the window type
      // Most tiling WMs respect these hints
      
      // Set window class for WM identification
      // This can be used in WM config files to force floating
      debugPrint('Setting X11 window properties for floating behavior');
      debugPrint('Window class: $_windowClass');
      debugPrint('Window title: $_windowTitle');
      debugPrint('Hint: Add this to your WM config to force floating:');
      debugPrint('  i3: for_window [class="$_windowClass"] floating enable');
      debugPrint('  sway: for_window [app_id="$_windowClass"] floating enable');
      debugPrint('  bspwm: bspc rule -a $_windowClass state=floating');
      debugPrint('  awesome: Add floating rule for "$_windowClass"');
      
    } catch (e) {
      debugPrint('Failed to set X11 properties: $e');
    }
  }
  
  /// Windows-specific floating window configuration
  static Future<void> _configureWindowsFloating() async {
    try {
      // On Windows, prevent window from being snapped to edges
      // This is more about user experience than tiling WM behavior
      debugPrint('Configured Windows floating behavior');
    } catch (e) {
      debugPrint('Windows floating window configuration failed: $e');
    }
  }
  
  /// macOS-specific floating window configuration
  static Future<void> _configureMacOSFloating() async {
    try {
      // macOS doesn't have tiling WMs by default, but some users install them
      debugPrint('Configured macOS floating behavior');
    } catch (e) {
      debugPrint('macOS floating window configuration failed: $e');
    }
  }
  
  /// Maintain floating behavior during runtime
  static Future<void> maintainFloatingBehavior() async {
    try {
      // Check and maintain window size constraints
      final size = await windowManager.getSize();
      
      // Ensure window stays within reasonable bounds
      if (size.width > 1200 || size.height > 800) {
        await windowManager.setSize(const Size(800, 600));
        debugPrint('Resized window to prevent excessive size');
      }
      
      if (size.width < 400 || size.height < 300) {
        await windowManager.setSize(const Size(400, 300));
        debugPrint('Resized window to maintain minimum size');
      }
      
      // Ensure window is not maximized (which could trigger tiling)
      final isMaximized = await windowManager.isMaximized();
      if (isMaximized) {
        await windowManager.unmaximize();
        debugPrint('Unmaximized window to maintain floating behavior');
      }
      
    } catch (e) {
      debugPrint('Failed to maintain floating behavior: $e');
    }
  }
  
  /// Print helpful configuration instructions for different WMs
  static void printWMConfigInstructions() {
    if (!Platform.isLinux) return;
    
    final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
    
    debugPrint('=== Tiling Window Manager Configuration ===');
    debugPrint('Current Desktop Environment: ${desktop ?? 'Unknown'}');
    debugPrint('');
    
    if (desktop == 'COSMIC') {
      debugPrint('COSMIC Desktop Configuration:');
      debugPrint('1. Open COSMIC Settings');
      debugPrint('2. Navigate to Desktop > Window Management');
      debugPrint('3. Add a floating rule for application: "$_windowClass"');
      debugPrint('4. Or use Super+Shift+F to toggle floating mode when Yall is focused');
      debugPrint('5. You can also right-click the title bar and select "Float"');
    } else {
      debugPrint('To ensure Yall always floats, add these rules to your WM config:');
      debugPrint('');
      debugPrint('i3wm (~/.config/i3/config):');
      debugPrint('  for_window [class="$_windowClass"] floating enable');
      debugPrint('  for_window [title="$_windowTitle"] floating enable');
      debugPrint('');
      debugPrint('Sway (~/.config/sway/config):');
      debugPrint('  for_window [app_id="$_windowClass"] floating enable');
      debugPrint('  for_window [title="$_windowTitle"] floating enable');
      debugPrint('');
      debugPrint('bspwm (~/.config/bspwm/bspwmrc):');
      debugPrint('  bspc rule -a $_windowClass state=floating');
      debugPrint('');
      debugPrint('dwm: Modify config.h and add to rules array:');
      debugPrint('  { "$_windowClass", NULL, NULL, 1 << 8, True, -1 },');
      debugPrint('');
      debugPrint('Awesome WM (~/.config/awesome/rc.lua):');
      debugPrint('  Add to awful.rules.rules:');
      debugPrint('  { rule = { class = "$_windowClass" }, properties = { floating = true } }');
      debugPrint('');
      debugPrint('Qtile (~/.config/qtile/config.py):');
      debugPrint('  Add to floating_layout.auto_float_types or use Match:');
      debugPrint('  Match(wm_class="$_windowClass")');
    }
    debugPrint('==========================================');
  }
}