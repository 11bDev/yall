import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/post_manager.dart';
import 'providers/account_manager.dart';
import 'providers/theme_manager.dart';
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

class _MainWindowState extends State<MainWindow> {
  @override
  void initState() {
    super.initState();
    // Load accounts and initialize services when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountManager>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yall'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Open Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsWindow(),
                ),
              );
            },
          ),
        ],
      ),
      body: const PostingWidget(),
    );
  }
}

