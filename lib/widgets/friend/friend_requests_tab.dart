import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/friend/friend_request_item.dart';

class FriendRequestsTab extends StatelessWidget {
  const FriendRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        final friendRequests = friendProvider.friendRequests;

        if (friendRequests.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          itemCount: friendRequests.length,
          itemBuilder: (context, index) {
            final request = friendRequests[index];
            final senderUser = friendProvider.friendUsers[request.senderId];
            
            return FriendRequestItem(
              request: request,
              senderUser: senderUser,
              onAccept: () => friendProvider.acceptFriendRequest(request.id),
              onDecline: () => friendProvider.declineFriendRequest(request.id),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
                CupertinoIcons.person_add,
                size: 40,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'No Friend Requests',
              style: AppConstants.titleMedium.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'When someone sends you a friend request, it will appear here.',
              style: AppConstants.bodyMedium.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
