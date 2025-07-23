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

    // Set window options
    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      minimumSize: Size(400, 300),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
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
            title: 'Multi-Platform Poster',
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

class _MainWindowState extends State<MainWindow> {
  @override
  void initState() {
    super.initState();
    // Load accounts and initialize services when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountManager>().loadAccounts();
      _initializeWindowManager();
      _initializeSystemTray();
    });
  }

  Future<void> _initializeWindowManager() async {
    final windowStateManager = context.read<WindowStateManager>();

    try {
      await windowStateManager.initialize();
      debugPrint('Window state manager initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize window state manager: $e');
      // Continue without window state persistence if initialization fails
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
              title: const Text('Multi-Platform Poster'),
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

  @override
  void dispose() {
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
