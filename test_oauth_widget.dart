import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/models/platform_type.dart';
import 'lib/providers/account_manager.dart';
import 'lib/widgets/oauth_login_widget.dart';

void main() {
  runApp(const TestOAuthApp());
}

class TestOAuthApp extends StatelessWidget {
  const TestOAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountManager()),
      ],
      child: MaterialApp(
        title: 'OAuth Test',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const TestOAuthScreen(),
      ),
    );
  }
}

class TestOAuthScreen extends StatelessWidget {
  const TestOAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OAuth Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showOAuthDialog(context, PlatformType.mastodon),
              child: const Text('Test Mastodon OAuth'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showOAuthDialog(context, PlatformType.bluesky),
              child: const Text('Test Bluesky OAuth'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOAuthDialog(BuildContext context, PlatformType platform) {
    showDialog(
      context: context,
      builder: (context) => OAuthLoginWidget(
        platform: platform,
        onSuccess: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${platform.name} OAuth completed!')),
          );
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
