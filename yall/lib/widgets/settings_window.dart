import 'package:flutter/material.dart';

import 'settings/account_settings_tab.dart';
import 'settings/theme_settings_tab.dart';
import 'settings/nostr_settings_tab.dart';

/// Settings window with tabbed interface for managing application preferences
class SettingsWindow extends StatefulWidget {
  const SettingsWindow({super.key});

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Handle window closing with unsaved changes check
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to close without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Close Without Saving'),
          ),
        ],
      ),
    );

    return shouldClose ?? false;
  }

  /// Mark that there are unsaved changes
  void _markUnsavedChanges() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  /// Mark that changes have been saved
  void _markChangesSaved() {
    if (_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldClose = await _onWillPop();
          if (shouldClose && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _hasUnsavedChanges ? 'Settings*' : 'Settings',
            style: TextStyle(
              color: _hasUnsavedChanges
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.account_circle),
                text: 'Accounts',
              ),
              Tab(
                icon: Icon(Icons.palette),
                text: 'Appearance',
              ),
              Tab(
                icon: Icon(Icons.electrical_services),
                text: 'Nostr',
              ),
            ],
          ),
          actions: [
            if (_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Changes',
                onPressed: () async {
                  try {
                    // Save changes in both tabs
                    await _saveAllChanges();
                    _markChangesSaved();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings saved successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save settings: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
              ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            AccountSettingsTab(
              onChanged: _markUnsavedChanges,
              onSaved: _markChangesSaved,
            ),
            ThemeSettingsTab(
              onChanged: _markUnsavedChanges,
              onSaved: _markChangesSaved,
            ),
            NostrSettingsTab(
              onChanged: _markUnsavedChanges,
              onSaved: _markChangesSaved,
            ),
          ],
        ),
      ),
    );
  }

  /// Save all changes across tabs
  Future<void> _saveAllChanges() async {
    // This method would coordinate saving across all tabs
    // For now, individual tabs handle their own saving
    // This could be expanded to batch save operations
  }
}