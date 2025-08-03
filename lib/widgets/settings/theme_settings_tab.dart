import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../providers/theme_manager.dart';

/// Tab for managing theme and appearance preferences in the settings window
class ThemeSettingsTab extends StatefulWidget {
  final VoidCallback? onChanged;
  final VoidCallback? onSaved;

  const ThemeSettingsTab({super.key, this.onChanged, this.onSaved});

  @override
  State<ThemeSettingsTab> createState() => _ThemeSettingsTabState();
}

class _ThemeSettingsTabState extends State<ThemeSettingsTab> {
  late AppSettings _tempSettings;
  bool _hasChanges = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    final themeManager = context.read<ThemeManager>();
    _tempSettings = themeManager.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading theme settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _initializeSettings();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildThemeSection(context, themeManager),
              const SizedBox(height: 24),
              _buildAppearanceSection(context),
              const SizedBox(height: 24),
              _buildBehaviorSection(context),
              const SizedBox(height: 32),
              _buildActionButtons(context, themeManager),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance & Behavior',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Customize the look and behavior of the application.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSection(BuildContext context, ThemeManager themeManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text('Theme', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Choose your preferred theme mode',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  subtitle: const Text('Always use light theme'),
                  value: ThemeMode.light,
                  groupValue: _tempSettings.themeMode,
                  onChanged: (value) => _updateThemeMode(value!),
                  secondary: const Icon(Icons.light_mode),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  subtitle: const Text('Always use dark theme'),
                  value: ThemeMode.dark,
                  groupValue: _tempSettings.themeMode,
                  onChanged: (value) => _updateThemeMode(value!),
                  secondary: const Icon(Icons.dark_mode),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('System'),
                  subtitle: const Text('Follow system theme setting'),
                  value: ThemeMode.system,
                  groupValue: _tempSettings.themeMode,
                  onChanged: (value) => _updateThemeMode(value!),
                  secondary: const Icon(Icons.auto_mode),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildThemePreview(context, themeManager),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(BuildContext context, ThemeManager themeManager) {
    final isDark = themeManager.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Current theme: ${isDark ? 'Dark' : 'Light'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Display Options',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show Character Count'),
              subtitle: const Text('Display character count while typing'),
              value: _tempSettings.showCharacterCount,
              onChanged: (value) => _updateSetting(
                _tempSettings.copyWith(showCharacterCount: value),
              ),
              secondary: const Icon(Icons.text_fields),
            ),
            SwitchListTile(
              title: const Text('Auto-save Content'),
              subtitle: const Text('Automatically save draft content'),
              value: _tempSettings.autoSaveContent,
              onChanged: (value) => _updateSetting(
                _tempSettings.copyWith(autoSaveContent: value),
              ),
              secondary: const Icon(Icons.save),
            ),
            SwitchListTile(
              title: const Text('Confirm Before Posting'),
              subtitle: const Text('Show confirmation dialog before posting'),
              value: _tempSettings.confirmBeforePosting,
              onChanged: (value) => _updateSetting(
                _tempSettings.copyWith(confirmBeforePosting: value),
              ),
              secondary: const Icon(Icons.help_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Application Behavior',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Minimize to System Tray'),
              subtitle: const Text(
                'Allow application to minimize to system tray',
              ),
              value: _tempSettings.minimizeToTray,
              onChanged: (value) =>
                  _updateSetting(_tempSettings.copyWith(minimizeToTray: value)),
              secondary: const Icon(Icons.minimize),
            ),
            SwitchListTile(
              title: const Text('Close to System Tray'),
              subtitle: const Text(
                'Minimize to tray instead of closing when X button is clicked',
              ),
              value: _tempSettings.closeToTray,
              onChanged: (value) =>
                  _updateSetting(_tempSettings.copyWith(closeToTray: value)),
              secondary: const Icon(Icons.close),
            ),
            SwitchListTile(
              title: const Text('Start Minimized'),
              subtitle: const Text('Start the application minimized to tray'),
              value: _tempSettings.startMinimized,
              onChanged: (value) =>
                  _updateSetting(_tempSettings.copyWith(startMinimized: value)),
              secondary: const Icon(Icons.launch),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeManager themeManager) {
    return Row(
      children: [
        if (_hasChanges) ...[
          ElevatedButton(
            onPressed: () => _saveChanges(themeManager),
            child: const Text('Save Changes'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: _discardChanges,
            child: const Text('Discard Changes'),
          ),
          const SizedBox(width: 12),
        ],
        OutlinedButton(
          onPressed: () => _resetToDefaults(themeManager),
          child: const Text('Reset to Defaults'),
        ),
      ],
    );
  }

  void _updateThemeMode(ThemeMode mode) {
    _updateSetting(_tempSettings.copyWith(themeMode: mode));
  }

  void _updateSetting(AppSettings newSettings) {
    setState(() {
      _tempSettings = newSettings;
      _hasChanges = true;
    });
    widget.onChanged?.call();
  }

  Future<void> _saveChanges(ThemeManager themeManager) async {
    try {
      setState(() => _isLoading = true);
      await themeManager.updateSettings(_tempSettings);
      setState(() => _hasChanges = false);
      widget.onSaved?.call();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theme settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to save theme settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _discardChanges() {
    setState(() {
      _initializeSettings();
      _hasChanges = false;
    });
    widget.onSaved?.call();
  }

  Future<void> _resetToDefaults(ThemeManager themeManager) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all theme settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      try {
        setState(() => _isLoading = true);
        await themeManager.resetToDefaults();
        _initializeSettings();
        setState(() => _hasChanges = false);
        widget.onSaved?.call();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings reset to defaults'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _error = 'Failed to reset settings: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
