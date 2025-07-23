import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// About tab for displaying application information
class AboutSettingsTab extends StatefulWidget {
  const AboutSettingsTab({super.key});

  @override
  State<AboutSettingsTab> createState() => _AboutSettingsTabState();
}

class _AboutSettingsTabState extends State<AboutSettingsTab> {
  PackageInfo? _packageInfo;
  String _architecture = '';
  String _platform = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
        _platform = _getPlatformName();
        _architecture = _getArchitecture();
      });
    } catch (e) {
      debugPrint('Error loading app info: $e');
    }
  }

  String _getPlatformName() {
    if (Platform.isLinux) return 'Linux';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  String _getArchitecture() {
    // For now, we'll show the basic architecture info
    // This could be enhanced with more detailed system information
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return 'x86_64';
    }
    return 'Unknown';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Icon and Name Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.forum_outlined,
                      size: 40,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'YaLL',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Yet another Link Logger',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Multi-Platform Social Media Poster',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Version Information
            _buildInfoSection(
              context,
              'Version Information',
              [
                _buildInfoRow('Version', _packageInfo?.version ?? 'Loading...'),
                _buildInfoRow('Build Number', _packageInfo?.buildNumber ?? 'Loading...'),
                _buildInfoRow('Package Name', _packageInfo?.packageName ?? 'Loading...'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // System Information
            _buildInfoSection(
              context,
              'System Information',
              [
                _buildInfoRow('Platform', _platform),
                _buildInfoRow('Architecture', _architecture),
                _buildInfoRow('Flutter Version', '3.32.7'),
                _buildInfoRow('Dart Version', '3.8.1'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Features Section
            _buildInfoSection(
              context,
              'Features',
              [
                _buildFeatureRow('Multi-Platform Posting', 'Post to Nostr, Bluesky, and Mastodon simultaneously'),
                _buildFeatureRow('Secure Storage', 'Encrypted credential storage'),
                _buildFeatureRow('System Tray', 'Background operation with tray integration'),
                _buildFeatureRow('Character Limits', 'Platform-specific character validation'),
                _buildFeatureRow('Keyboard Shortcuts', 'Quick access with hotkeys'),
                _buildFeatureRow('Dark/Light Themes', 'Customizable appearance'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Character Limits Section
            _buildInfoSection(
              context,
              'Platform Character Limits',
              [
                _buildInfoRow('Mastodon', '500 characters'),
                _buildInfoRow('Bluesky', '300 characters'),
                _buildInfoRow('Nostr', '800 characters'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Support Section
            _buildInfoSection(
              context,
              'Support & Development',
              [
                _buildLinkRow(context, 'GitHub Repository', 'https://github.com/timappledotcom/yall'),
                _buildLinkRow(context, 'Report Issues', 'https://github.com/timappledotcom/yall/issues'),
                _buildLinkRow(context, 'Discussions', 'https://github.com/timappledotcom/yall/discussions'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Donations Section (Placeholder)
            _buildDonationSection(context),
            
            const SizedBox(height: 24),
            
            // License Section
            _buildInfoSection(
              context,
              'License',
              [
                _buildInfoRow('License', 'MIT'),
                _buildInfoRow('Copyright', '2024-2025 Tim Apple'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Build Information
            _buildInfoSection(
              context,
              'Build Information',
              [
                _buildInfoRow('Build Date', DateTime.now().toString().split(' ')[0]),
                _buildInfoRow('App Name', _packageInfo?.appName ?? 'Loading...'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(BuildContext context, String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(url),
              child: Text(
                url,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyToClipboard(url),
            tooltip: 'Copy URL',
          ),
        ],
      ),
    );
  }

  Widget _buildDonationSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Support Development',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'YaLL is free and open-source software. If you find it useful, consider supporting its development.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.construction,
                    size: 32,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Donation Options Coming Soon',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We\'re working on setting up donation options.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
