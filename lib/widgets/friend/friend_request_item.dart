import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class FriendRequestItem extends StatelessWidget {
  final FriendRequest request;
  final UserModel? senderUser;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const FriendRequestItem({
    super.key,
    required this.request,
    required this.senderUser,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final userName = senderUser?.name ?? 'Unknown User';
    final userEmail = senderUser?.email ?? '';
    final profileImageUrl = senderUser?.profileImageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          // Profile Image
          _buildProfileImage(profileImageUrl, userName),
          
          const SizedBox(width: AppConstants.paddingMedium),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppConstants.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: AppConstants.bodyMedium.copyWith(
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sent ${AppHelpers.formatTimestamp(request.createdAt)}',
                  style: AppConstants.caption,
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Column(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                onPressed: onAccept,
                child: const Text(
                  AppStrings.accept,
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                onPressed: onDecline,
                child: Text(
                  AppStrings.decline,
                  style: TextStyle(
                    color: CupertinoColors.label,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl, String name) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: AppConstants.profileImageSize,
          height: AppConstants.profileImageSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(name),
          errorWidget: (context, url, error) => _buildPlaceholder(name),
        ),
      );
    } else {
      return _buildPlaceholder(name);
    }
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      width: AppConstants.profileImageSize,
      height: AppConstants.profileImageSize,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          AppHelpers.getInitials(name),
          style: AppConstants.bodyMedium.copyWith(
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
