import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../themes/app_theme.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        
        return CupertinoPageScaffold(
          backgroundColor: theme.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.surfaceColor,
            border: Border(
              bottom: BorderSide(
                color: theme.borderColor,
                width: 0.5,
              ),
            ),
            middle: Text(
              'Appearance',
              style: TextStyle(color: theme.textPrimary),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Theme Mode Selection
                  Container(
                    decoration: BoxDecoration(
                      color: theme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildThemeOption(
                          context,
                          themeProvider,
                          ThemeMode.light,
                          'Light',
                          'Always use light mode',
                          CupertinoIcons.sun_max,
                        ),
                        _buildDivider(theme),
                        _buildThemeOption(
                          context,
                          themeProvider,
                          ThemeMode.dark,
                          'Dark',
                          'Always use dark mode',
                          CupertinoIcons.moon,
                        ),
                        _buildDivider(theme),
                        _buildThemeOption(
                          context,
                          themeProvider,
                          ThemeMode.system,
                          'System',
                          'Follow system setting',
                          CupertinoIcons.gear,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Preview Section
                  Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Preview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.borderColor,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.person,
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'John Doe',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.onlineColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Message bubbles preview
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.sentMessageColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              'Hello! How are you?',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.receivedMessageColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              'I\'m doing great, thanks!',
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    final theme = themeProvider.currentTheme;
    
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onPressed: () => themeProvider.setThemeMode(mode),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              CupertinoIcons.checkmark,
              color: theme.primaryColor,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(left: 56),
      height: 0.5,
      color: theme.borderColor,
    );
  }
}
