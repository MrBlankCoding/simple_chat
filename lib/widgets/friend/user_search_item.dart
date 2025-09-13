import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../providers/friend_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class UserSearchItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onSendRequest;

  const UserSearchItem({
    super.key,
    required this.user,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        final isFriend = friendProvider.isFriend(user.uid);
        final hasPendingRequest = friendProvider.hasPendingRequest(user.uid);
        final hasIncomingRequest = friendProvider.hasIncomingRequest(user.uid);

        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: Row(
            children: [
              // Profile Image with Online Status
              Stack(
                children: [
                  _buildProfileImage(),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppConstants.successColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.surfaceColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: AppConstants.paddingMedium),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppConstants.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppConstants.bodyMedium.copyWith(
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    if (user.isOnline) ...[
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.online,
                        style: AppConstants.caption.copyWith(
                          color: AppConstants.successColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action Button
              _buildActionButton(
                isFriend, 
                hasPendingRequest, 
                hasIncomingRequest,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.profileImageUrl!,
          width: AppConstants.profileImageSize,
          height: AppConstants.profileImageSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: AppConstants.profileImageSize,
      height: AppConstants.profileImageSize,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          AppHelpers.getInitials(user.name),
          style: AppConstants.bodyMedium.copyWith(
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    bool isFriend, 
    bool hasPendingRequest, 
    bool hasIncomingRequest,
  ) {
    if (isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppConstants.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: AppConstants.successColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Friends',
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (hasPendingRequest) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey4,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Text(
          'Pending',
          style: AppConstants.bodyMedium.copyWith(
            color: CupertinoColors.secondaryLabel,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (hasIncomingRequest) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Text(
          'Respond',
          style: AppConstants.bodyMedium.copyWith(
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        onPressed: onSendRequest,
        child: const Text(
          AppStrings.sendRequest,
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}
