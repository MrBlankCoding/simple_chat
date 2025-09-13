import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/friend/friend_list_item.dart';

class FriendsListTab extends StatelessWidget {
  const FriendsListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        final friends = friendProvider.getFriendsList();

        if (friends.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            
            return FriendListItem(
              user: friend,
              onTap: () => _startChat(context, friend.uid),
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
                color: AppConstants.primaryColor.withOpacity(0.1),
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
                Navigator.of(context).pushNamed('/search-users');
              },
              child: const Text('Find Friends'),
            ),
          ],
        ),
      ),
    );
  }
}
