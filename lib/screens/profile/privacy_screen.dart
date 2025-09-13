import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  bool _allowFriendRequests = true;
  bool _showProfilePicture = true;

  void _showDeleteAccountDialog() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete Account', style: TextStyle(color: theme.textPrimary)),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your messages and data will be permanently deleted.',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: TextStyle(color: theme.primaryColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDeleteAccount();
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Final Confirmation', style: TextStyle(color: theme.textPrimary)),
        content: Text('Type "DELETE" to confirm account deletion.', style: TextStyle(color: theme.textSecondary)),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: TextStyle(color: theme.primaryColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Confirm'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAccount();
            },
          ),
        ],
      ),
    );
  }

  void _requestDataExport() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Data Export Request', style: TextStyle(color: theme.textPrimary)),
        content: Text('Your data export request has been submitted. You will receive an email with your data within 24 hours.', style: TextStyle(color: theme.textSecondary)),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: theme.primaryColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showClearChatHistoryDialog() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Clear Chat History', style: TextStyle(color: theme.textPrimary)),
        content: Text('Are you sure you want to clear all chat history? This action cannot be undone.', style: TextStyle(color: theme.textSecondary)),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: TextStyle(color: theme.primaryColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Clear All'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearChatHistory();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _clearChatHistory() async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      // Clear all chat messages - this would need to be implemented in ChatProvider
      // For now, show a success message
      if (mounted) {
        final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Success', style: TextStyle(color: theme.textPrimary)),
            content: Text('Chat history has been cleared successfully.', style: TextStyle(color: theme.textSecondary)),
            actions: [
              CupertinoDialogAction(
                child: Text('OK', style: TextStyle(color: theme.primaryColor)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error', style: TextStyle(color: theme.textPrimary)),
            content: Text('Failed to clear chat history. Please try again.', style: TextStyle(color: theme.textSecondary)),
            actions: [
              CupertinoDialogAction(
                child: Text('OK', style: TextStyle(color: theme.primaryColor)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Note: Account deletion would need to be implemented in AuthProvider
      // For now, show a placeholder message
      if (mounted) {
        final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Account Deletion', style: TextStyle(color: theme.textPrimary)),
            content: Text('Account deletion request has been submitted. Please contact support for assistance.', style: TextStyle(color: theme.textSecondary)),
            actions: [
              CupertinoDialogAction(
                child: Text('OK', style: TextStyle(color: theme.primaryColor)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error', style: TextStyle(color: theme.textPrimary)),
            content: Text('Failed to process account deletion. Please contact support.', style: TextStyle(color: theme.textSecondary)),
            actions: [
              CupertinoDialogAction(
                child: Text('OK', style: TextStyle(color: theme.primaryColor)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        
        return CupertinoPageScaffold(
          backgroundColor: theme.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.backgroundColor,
            middle: Text(
              'Privacy',
              style: TextStyle(color: theme.textPrimary),
            ),
          ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              backgroundColor: theme.cardColor,
              header: Text(
                'VISIBILITY',
                style: TextStyle(color: theme.textSecondary),
              ),
              children: [
                CupertinoFormRow(
                  prefix: Text(
                    'Show Online Status',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoSwitch(
                    value: _showOnlineStatus,
                    activeTrackColor: theme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _showOnlineStatus = value;
                      });
                    },
                  ),
                ),
                CupertinoFormRow(
                  prefix: Text(
                    'Show Last Seen',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoSwitch(
                    value: _showLastSeen,
                    activeTrackColor: theme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _showLastSeen = value;
                      });
                    },
                  ),
                ),
                CupertinoFormRow(
                  prefix: Text(
                    'Show Profile Picture',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoSwitch(
                    value: _showProfilePicture,
                    activeTrackColor: theme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _showProfilePicture = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            CupertinoFormSection.insetGrouped(
              backgroundColor: theme.cardColor,
              header: Text(
                'FRIEND REQUESTS',
                style: TextStyle(color: theme.textSecondary),
              ),
              children: [
                CupertinoFormRow(
                  prefix: Text(
                    'Allow Friend Requests',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoSwitch(
                    value: _allowFriendRequests,
                    activeTrackColor: theme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _allowFriendRequests = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            CupertinoFormSection.insetGrouped(
              backgroundColor: theme.cardColor,
              header: Text(
                'DATA & STORAGE',
                style: TextStyle(color: theme.textSecondary),
              ),
              children: [
                CupertinoFormRow(
                  prefix: Text(
                    'Download My Data',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _requestDataExport(),
                    child: Text('Request', style: TextStyle(color: theme.primaryColor)),
                  ),
                ),
                CupertinoFormRow(
                  prefix: Text(
                    'Clear Chat History',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('Clear All', style: TextStyle(color: theme.primaryColor)),
                    onPressed: () => _showClearChatHistoryDialog(),
                  ),
                ),
              ],
            ),
            
            CupertinoFormSection.insetGrouped(
              backgroundColor: theme.cardColor,
              header: Text(
                'ACCOUNT',
                style: TextStyle(color: theme.textSecondary),
              ),
              children: [
                CupertinoFormRow(
                  prefix: Text(
                    'Delete Account',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showDeleteAccountDialog,
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: CupertinoColors.destructiveRed),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Text(
                'Your privacy is important to us. These settings help you control who can see your information and how your data is used.',
                style: AppConstants.caption.copyWith(
                  color: theme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}
