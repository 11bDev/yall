import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_manager.dart';
import '../../providers/post_manager.dart';

/// Settings tab for managing Nostr relay configuration
class NostrSettingsTab extends StatefulWidget {
  final VoidCallback? onChanged;
  final VoidCallback? onSaved;

  const NostrSettingsTab({super.key, this.onChanged, this.onSaved});

  @override
  State<NostrSettingsTab> createState() => _NostrSettingsTabState();
}

class _NostrSettingsTabState extends State<NostrSettingsTab> {
  final TextEditingController _relayController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<String> _currentRelays = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentRelays();
  }

  @override
  void dispose() {
    _relayController.dispose();
    super.dispose();
  }

  /// Load current relay configuration from settings
  void _loadCurrentRelays() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    setState(() {
      _currentRelays = List<String>.from(themeManager.settings.nostrRelays);
    });
  }

  /// Mark that changes have been made
  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
      widget.onChanged?.call();
    }
  }

  /// Save relay changes to settings
  Future<void> _saveChanges() async {
    try {
      final themeManager = Provider.of<ThemeManager>(context, listen: false);
      final postManager = Provider.of<PostManager>(context, listen: false);

      final newSettings = themeManager.settings.setNostrRelays(_currentRelays);
      await themeManager.updateSettings(newSettings);

      // Update the PostManager's NostrService with new relays
      postManager.updateNostrRelays(_currentRelays);

      setState(() {
        _hasChanges = false;
      });
      widget.onSaved?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nostr relay settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save relay settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Add a new relay
  void _addRelay() {
    final relayUrl = _relayController.text.trim();

    if (relayUrl.isEmpty) return;

    // Validate relay URL format
    if (!_isValidRelayUrl(relayUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid relay URL. Must start with wss:// or ws://'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if relay already exists
    if (_currentRelays.contains(relayUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relay already exists in the list'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check relay limit
    if (_currentRelays.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum of 10 relays allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _currentRelays.add(relayUrl);
      _relayController.clear();
    });
    _markChanged();
  }

  /// Remove a relay
  void _removeRelay(String relay) {
    setState(() {
      _currentRelays.remove(relay);
    });
    _markChanged();
  }

  /// Reset to default relays
  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset to the default Nostr relays? '
          'This will replace all current relays.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentRelays = [
                  'wss://relay.damus.io',
                  'wss://nos.lol',
                  'wss://relay.snort.social',
                  'wss://relay.nostr.band',
                ];
              });
              _markChanged();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  /// Validate relay URL
  bool _isValidRelayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return (uri.scheme == 'wss' || uri.scheme == 'ws') && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.electrical_services,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nostr Relays',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure the Nostr relays used for publishing posts. Maximum 10 relays.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Add relay section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _relayController,
                          decoration: const InputDecoration(
                            labelText: 'Relay URL',
                            hintText: 'wss://relay.example.com',
                            prefixIcon: Icon(Icons.link),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null; // Allow empty for optional field
                            }
                            if (!_isValidRelayUrl(value.trim())) {
                              return 'Invalid URL format';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _addRelay(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _addRelay,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Relay count and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Relays (${_currentRelays.length}/10)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    if (_hasChanges)
                      ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _resetToDefaults,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset to Defaults'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Relay list
            Expanded(
              child: _currentRelays.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.electrical_services_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No relays configured',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add some relays to get started',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _currentRelays.length,
                      itemBuilder: (context, index) {
                        final relay = _currentRelays[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.electrical_services,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(relay),
                            subtitle: Text(
                              Uri.parse(relay).host,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => _removeRelay(relay),
                              tooltip: 'Remove relay',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
