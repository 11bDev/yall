import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yall/widgets/views/accounts_view.dart';
import 'package:yall/widgets/views/history_view.dart';

import '../providers/theme_manager.dart';
import '../providers/account_manager.dart';
import 'posting_widget.dart';
import 'settings_window.dart';

/// Beautiful Windows-optimized main layout
class WindowsMainLayout extends StatefulWidget {
  const WindowsMainLayout({super.key});

  @override
  State<WindowsMainLayout> createState() => _WindowsMainLayoutState();
}

class _WindowsMainLayoutState extends State<WindowsMainLayout> {
  int _selectedIndex = 0;
  bool _isSettingsOpen = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: _buildAppBar(context, colorScheme),
          body: Row(
            children: [
              // Beautiful side navigation
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: _buildSideNavigation(context, colorScheme),
              ),
              // Main content area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                  ),
                  child: _buildMainContent(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Yall',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          _buildQuickActions(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        // Theme toggle button
        Consumer<ThemeManager>(
          builder: (context, themeManager, child) {
            final isDark = themeManager.themeMode == ThemeMode.dark;
            return IconButton(
              onPressed: () => themeManager.toggleTheme(),
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: colorScheme.onSurface,
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            );
          },
        ),
        // Settings button
        IconButton(
          onPressed: () => setState(() => _isSettingsOpen = !_isSettingsOpen),
          icon: Icon(
            Icons.settings,
            color: colorScheme.onSurface,
          ),
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildSideNavigation(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // User info section
        Container(
          padding: const EdgeInsets.all(20),
          child: Consumer<AccountManager>(
            builder: (context, accountManager, child) {
              final totalAccounts = accountManager.accounts.length;
              return Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            child: Icon(
                              Icons.person,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connected Accounts',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '$totalAccounts accounts',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Navigation items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildNavItem(
                context,
                colorScheme,
                icon: Icons.edit,
                label: 'New Post',
                index: 0,
                isSelected: _selectedIndex == 0,
              ),
              _buildNavItem(
                context,
                colorScheme,
                icon: Icons.account_circle,
                label: 'Accounts',
                index: 1,
                isSelected: _selectedIndex == 1,
              ),
              _buildNavItem(
                context,
                colorScheme,
                icon: Icons.history,
                label: 'Post History',
                index: 2,
                isSelected: _selectedIndex == 2,
              ),
              const SizedBox(height: 16),
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: 16),
              _buildNavItem(
                context,
                colorScheme,
                icon: Icons.settings,
                label: 'Settings',
                index: 3,
                isSelected: _selectedIndex == 3,
              ),
              _buildNavItem(
                context,
                colorScheme,
                icon: Icons.help_outline,
                label: 'Help',
                index: 4,
                isSelected: _selectedIndex == 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: colorScheme.primaryContainer.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    if (_isSettingsOpen) {
      return const SettingsWindow();
    }

    switch (_selectedIndex) {
      case 0:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: PostingWidget(),
        );
      case 1:
        return const AccountsView();
      case 2:
        return const HistoryView();
      case 3:
        return const SettingsWindow();
      case 4:
        return _buildHelpView();
      default:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: PostingWidget(),
        );
    }
  }



  Widget _buildHelpView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Help & Support',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Get help with using Yall',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
