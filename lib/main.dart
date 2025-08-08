import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/post_manager.dart';
import 'providers/account_manager.dart';
import 'providers/theme_manager.dart';
import 'services/error_handler.dart';
import 'services/system_tray_manager.dart';
import 'services/window_state_manager.dart';
import 'services/floating_window_manager.dart';
import 'widgets/posting_widget.dart';
import 'widgets/settings_window.dart';

// Intent classes for keyboard shortcuts
class NewPostIntent extends Intent {
  const NewPostIntent();
}

class SubmitPostIntent extends Intent {
  const SubmitPostIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class CancelOperationIntent extends Intent {
  const CancelOperationIntent();
}

class ShowHelpIntent extends Intent {
  const ShowHelpIntent();
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling
  _setupGlobalErrorHandling();

  // Initialize window manager for desktop platforms
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // Set window options for floating window (optimized for COSMIC)
    WindowOptions windowOptions = const WindowOptions(
      size: Size(650, 750), // Larger size to fit all UI elements comfortably
      minimumSize: Size(500, 600), // Increased minimum to ensure usability
      maximumSize: Size(800, 900), // Increased maximum size
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
      alwaysOnTop: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Configure window to be floating/non-tiling
      await FloatingWindowManager.configureFloatingWindow();

      // Print helpful configuration instructions for tiling WMs
      FloatingWindowManager.printWMConfigInstructions();

      await windowManager.show();
      await windowManager.focus();

      // Set window icon
      try {
        if (Platform.isLinux || Platform.isWindows) {
          await windowManager.setIcon('assets/icons/app_icon.png');
        }
      } catch (e) {
        print('Failed to set window icon: $e');
      }
    });
  }

  runApp(const MultiPlatformPosterApp());
}

class MultiPlatformPosterApp extends StatelessWidget {
  const MultiPlatformPosterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => AccountManager()),
        ChangeNotifierProvider(create: (_) => PostManager()),
        ChangeNotifierProvider(create: (_) => SystemTrayManager()),
        ChangeNotifierProvider(create: (_) => WindowStateManager()),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            title: 'Yall',
            theme: themeManager.lightTheme,
            darkTheme: themeManager.darkTheme,
            themeMode: themeManager.themeMode,
            home: const MainWindow(),
          );
        },
      ),
    );
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {
  @override
  void initState() {
    super.initState();
    // Load accounts and initialize services when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountManager>().loadAccounts();
      _initializeWindowManager();
      _initializeSystemTray();
      _setupWindowCloseHandling();
    });
  }

  /// Initialize services with settings
  Future<void> _initializeServices() async {
    final themeManager = context.read<ThemeManager>();
    final postManager = context.read<PostManager>();

    print('Initializing services...');

    // Wait for ThemeManager to load settings
    if (!themeManager.isInitialized) {
      print('ThemeManager not initialized, loading settings...');
      await themeManager.initialize();
    } else {
      print('ThemeManager already initialized');
    }

    print(
      'Current Nostr relays from settings: ${themeManager.settings.nostrRelays.join(', ')}',
    );

    // Update NostrService with relay settings
    postManager.updateNostrRelays(themeManager.settings.nostrRelays);

    print('Services initialization complete');
  }

  Future<void> _initializeWindowManager() async {
    final windowStateManager = context.read<WindowStateManager>();

    try {
      // Wait a moment to ensure window is properly sized first
      await Future.delayed(const Duration(milliseconds: 500));

      await windowStateManager.initialize();

      // Ensure floating behavior is maintained
      await _maintainFloatingBehavior();

      debugPrint('Window state manager initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize window state manager: $e');
      // Continue without window state persistence if initialization fails
    }
  }

  /// Maintain floating window behavior throughout the app lifecycle
  Future<void> _maintainFloatingBehavior() async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
      return;
    }

    try {
      // Re-apply floating window configuration
      await FloatingWindowManager.configureFloatingWindow();

      // Set up a periodic check to maintain floating behavior
      // This helps in case the window manager tries to tile the window
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        try {
          final isVisible = await windowManager.isVisible();
          if (isVisible) {
            await FloatingWindowManager.maintainFloatingBehavior();
          }
        } catch (e) {
          // Ignore errors in periodic check
        }
      });
    } catch (e) {
      debugPrint('Failed to maintain floating behavior: $e');
    }
  }

  Future<void> _setupWindowCloseHandling() async {
    try {
      // Enable window close interception
      await windowManager.setPreventClose(true);
      // Add this as a window listener
      windowManager.addListener(this);
      debugPrint('Window close prevention enabled and listener added');
    } catch (e) {
      debugPrint('Failed to set up window close handling: $e');
    }
  }

  Future<void> _initializeSystemTray() async {
    final systemTrayManager = context.read<SystemTrayManager>();
    final windowStateManager = context.read<WindowStateManager>();

    // Set up system tray callbacks
    systemTrayManager.onShowWindow = () async {
      // Show the window using WindowStateManager
      if (windowStateManager.isInitialized) {
        await windowStateManager.showWindow();
      }
    };

    systemTrayManager.onHideWindow = () async {
      // Hide the window using WindowStateManager
      if (windowStateManager.isInitialized) {
        await windowStateManager.hideWindow();
      }
    };

    systemTrayManager.onOpenSettings = () {
      // Show settings window
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const SettingsWindow()));
      }
    };

    systemTrayManager.onQuitApplication = () {
      // Quit the application properly
      _quitApplication();
    };

    // Initialize the system tray
    try {
      await systemTrayManager.initialize();
    } catch (e) {
      debugPrint('Failed to initialize system tray: $e');
      // Continue without system tray if initialization fails
    }
  }

  Future<void> _handleWindowClose() async {
    final systemTrayManager = context.read<SystemTrayManager>();
    final windowStateManager = context.read<WindowStateManager>();

    try {
      // Save window state before closing/minimizing
      if (windowStateManager.isInitialized) {
        await windowStateManager.handleWindowClose();
      }

      // If system tray is available, minimize to tray instead of closing
      if (systemTrayManager.isInitialized) {
        if (windowStateManager.isInitialized) {
          await windowStateManager.hideWindow();
        } else {
          await systemTrayManager.minimizeToTray();
        }
      } else {
        // If system tray is not available, allow normal close
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error handling window close: $e');
      // Fallback to normal close behavior
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _quitApplication() async {
    try {
      // Get references before async operations to avoid BuildContext issues
      final windowStateManager = context.read<WindowStateManager>();
      final systemTrayManager = context.read<SystemTrayManager>();

      // Clean up window state manager
      if (windowStateManager.isInitialized) {
        await windowStateManager.dispose();
      }

      // Clean up system tray
      await systemTrayManager.dispose();

      // Exit the application
      if (Platform.isAndroid || Platform.isIOS) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    } catch (e) {
      debugPrint('Error during application quit: $e');
      // Force exit if cleanup fails
      exit(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Handle window close behavior with tray integration
          await _handleWindowClose();
        }
      },
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
              const NewPostIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter):
              const SubmitPostIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma):
              const OpenSettingsIntent(),
          LogicalKeySet(LogicalKeyboardKey.escape):
              const CancelOperationIntent(),
          LogicalKeySet(LogicalKeyboardKey.f1): const ShowHelpIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            NewPostIntent: CallbackAction<NewPostIntent>(
              onInvoke: (intent) => _handleNewPost(),
            ),
            SubmitPostIntent: CallbackAction<SubmitPostIntent>(
              onInvoke: (intent) => _handleSubmitPost(),
            ),
            OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
              onInvoke: (intent) => _handleOpenSettings(),
            ),
            CancelOperationIntent: CallbackAction<CancelOperationIntent>(
              onInvoke: (intent) => _handleCancelOperation(),
            ),
            ShowHelpIntent: CallbackAction<ShowHelpIntent>(
              onInvoke: (intent) => _handleShowHelp(),
            ),
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Yall'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Open Settings (Ctrl+,)',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsWindow(),
                      ),
                    );
                  },
                ),
                Consumer2<SystemTrayManager, WindowStateManager>(
                  builder:
                      (context, systemTrayManager, windowStateManager, child) {
                        if (systemTrayManager.isInitialized) {
                          return IconButton(
                            icon: const Icon(Icons.minimize),
                            tooltip: 'Minimize to tray',
                            onPressed: () async {
                              if (windowStateManager.isInitialized) {
                                await windowStateManager.hideWindow();
                              } else {
                                await systemTrayManager.minimizeToTray();
                              }
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                ),
              ],
            ),
            body: Semantics(
              label: 'Main posting area',
              child: const SingleChildScrollView(child: PostingWidget()),
            ),
          ),
        ),
      ),
    );
  }

  // Keyboard shortcut handlers
  void _handleNewPost() {
    // Focus on the text input area if possible
    // This would require accessing the posting widget state
    debugPrint('New post shortcut triggered');
  }

  void _handleSubmitPost() {
    final postManager = context.read<PostManager>();
    if (!postManager.isPosting) {
      // Trigger posting if conditions are met
      debugPrint('Submit post shortcut triggered');
      // This would require accessing the posting widget to trigger submission
    }
  }

  void _handleOpenSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsWindow()));
  }

  void _handleCancelOperation() {
    final postManager = context.read<PostManager>();
    if (postManager.canCancel) {
      postManager.cancelPosting();
    }
  }

  void _handleShowHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ctrl+N: Focus on new post input'),
              Text('Ctrl+Enter: Submit post'),
              Text('Ctrl+,: Open settings'),
              Text('Escape: Cancel current operation'),
              Text('F1: Show this help'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // WindowListener implementation
  @override
  void onWindowClose() {
    debugPrint('WindowListener: onWindowClose called');
    // Handle the close event by minimizing to tray
    _handleWindowClose();
  }

  @override
  void onWindowFocus() {
    // Not needed but required by interface
  }

  @override
  void onWindowBlur() {
    // Not needed but required by interface
  }

  @override
  void onWindowMaximize() {
    // Not needed but required by interface
  }

  @override
  void onWindowUnmaximize() {
    // Not needed but required by interface
  }

  @override
  void onWindowMinimize() {
    // Not needed but required by interface
  }

  @override
  void onWindowRestore() {
    // Not needed but required by interface
  }

  @override
  void onWindowResize() {
    // Not needed but required by interface
  }

  @override
  void onWindowMove() {
    // Not needed but required by interface
  }

  @override
  void dispose() {
    // Remove the window listener
    windowManager.removeListener(this);
    // Clean up system tray when the app is disposed
    // Note: We don't need to manually dispose the SystemTrayManager here
    // as it will be disposed automatically when the provider is disposed
    super.dispose();
  }
}

/// Set up global error handling for uncaught exceptions and Flutter errors
void _setupGlobalErrorHandling() {
  final errorHandler = ErrorHandler();

  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    errorHandler.logError(
      'Flutter Framework Error',
      details.exception,
      stackTrace: details.stack,
      context: {
        'library': details.library,
        'context': details.context.toString(),
        'information_collected': details.informationCollector?.call(),
      },
    );

    // In debug mode, also print to console
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  // Handle platform errors (like platform channel errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    errorHandler.logError('Platform Error', error, stackTrace: stack);
    return true;
  };

  // Set up custom error widget for production
  if (!kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  errorHandler.getUserFriendlyMessage(details.exception),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // In a real app, you might want to restart or navigate to a safe screen
                    SystemNavigator.pop();
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }
}
