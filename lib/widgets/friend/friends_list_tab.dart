import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/friend/friend_list_item.dart';
import '../../screens/friends/search_users_screen.dart';

class FriendsListTab extends StatelessWidget {
  const FriendsListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        final friends = friendProvider.getFriendsList();
        final onlineCount = friendProvider.getOnlineFriends().length;

        if (friends.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          itemCount: friends.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(
                  top: AppConstants.paddingSmall,
                  bottom: AppConstants.paddingMedium,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: CupertinoColors.activeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      onlineCount == 1
                          ? '1 friend online'
                          : '$onlineCount friends online',
                      style: AppConstants.bodyMedium.copyWith(
                        color: CupertinoColors.secondaryLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final friend = friends[index - 1];
            return FriendListItem(
              user: friend,
              onTap: () => _startChat(context, friend.uid),
              onLongPress: () => _confirmUnfriend(context, friend.uid, friend.name),
            );
          },
        );
      },
    );
  }

  Future<void> _startChat(BuildContext context, String friendUserId) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chatId = await chatProvider.getOrCreateDirectChat(friendUserId);
      
      if (context.mounted) {
        Navigator.of(context).pushNamed(
          '/chat',
          arguments: {'chatId': chatId},
        );
      }
    } catch (e) {
      // Handle error
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to start chat. Please try again.'),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.person_2,
                size: 40,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'No Friends Yet',
              style: AppConstants.titleMedium.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Search for users and send friend requests to start building your network.',
              style: AppConstants.bodyMedium.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXLarge),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const SearchUsersScreen()),
                );
              },
              child: const Text('Find Friends'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmUnfriend(BuildContext context, String friendUserId, String friendName) async {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          'Remove Friend',
          style: AppConstants.titleMedium.copyWith(color: theme.textPrimary),
        ),
        message: Text(
          'Do you want to remove $friendName from your friends? You will also be removed from their list.',
          style: AppConstants.bodyMedium.copyWith(color: theme.textSecondary),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final friendProvider = Provider.of<FriendProvider>(context, listen: false);
              final success = await friendProvider.unfriend(friendUserId);
              if (!success && context.mounted) {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Error'),
                    content: const Text('Failed to remove friend. Please try again.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              }
            },
            isDestructiveAction: true,
            child: const Text('Remove Friend'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
