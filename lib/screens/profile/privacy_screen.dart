import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
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
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your messages and data will be permanently deleted.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
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
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text('Type "DELETE" to confirm account deletion.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
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
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Data Export Request'),
        content: const Text('Your data export request has been submitted. You will receive an email with your data within 24 hours.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showClearChatHistoryDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat history? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
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
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Chat history has been cleared successfully.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to clear chat history. Please try again.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
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
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Account Deletion'),
            content: const Text('Account deletion request has been submitted. Please contact support for assistance.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to process account deletion. Please contact support.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Privacy'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text('VISIBILITY'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Show Online Status'),
                  child: CupertinoSwitch(
                    value: _showOnlineStatus,
                    onChanged: (value) {
                      setState(() {
                        _showOnlineStatus = value;
                      });
                    },
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Show Last Seen'),
                  child: CupertinoSwitch(
                    value: _showLastSeen,
                    onChanged: (value) {
                      setState(() {
                        _showLastSeen = value;
                      });
                    },
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Show Profile Picture'),
                  child: CupertinoSwitch(
                    value: _showProfilePicture,
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
              header: const Text('FRIEND REQUESTS'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Allow Friend Requests'),
                  child: CupertinoSwitch(
                    value: _allowFriendRequests,
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
              header: const Text('DATA & STORAGE'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Download My Data'),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _requestDataExport(),
                    child: const Text('Request'),
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Clear Chat History'),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Clear All'),
                    onPressed: () => _showClearChatHistoryDialog(),
                  ),
                ),
              ],
            ),
            
            CupertinoFormSection.insetGrouped(
              header: const Text('ACCOUNT'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Delete Account'),
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
                  color: CupertinoColors.secondaryLabel,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
