import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../providers/friend_provider.dart';
import '../../providers/theme_provider.dart';
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
    return Consumer2<FriendProvider, ThemeProvider>(
      builder: (context, friendProvider, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        final isFriend = friendProvider.isFriend(user.uid);
        final hasPendingRequest = friendProvider.hasPendingRequest(user.uid);
        final hasIncomingRequest = friendProvider.hasIncomingRequest(user.uid);

        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: Row(
            children: [
              // Profile Image with Online Status
              Stack(
                children: [
                  _buildProfileImage(theme),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.onlineColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.cardColor,
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
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppConstants.bodyMedium.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                    if (user.isOnline) ...[
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.online,
                        style: AppConstants.caption.copyWith(
                          color: theme.onlineColor,
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
                theme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(theme) {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.profileImageUrl!,
          width: AppConstants.profileImageSize,
          height: AppConstants.profileImageSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(theme),
          errorWidget: (context, url, error) => _buildPlaceholder(theme),
        ),
      );
    } else {
      return _buildPlaceholder(theme);
    }
  }

  Widget _buildPlaceholder(theme) {
    return Container(
      width: AppConstants.profileImageSize,
      height: AppConstants.profileImageSize,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          AppHelpers.getInitials(user.name),
          style: AppConstants.bodyMedium.copyWith(
            color: theme.primaryColor,
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
    theme,
  ) {
    if (isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: theme.onlineColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: theme.onlineColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Friends',
              style: AppConstants.bodyMedium.copyWith(
                color: theme.onlineColor,
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
          color: theme.textSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Text(
          'Pending',
          style: AppConstants.bodyMedium.copyWith(
            color: theme.textSecondary,
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
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Text(
          'Respond',
          style: AppConstants.bodyMedium.copyWith(
            color: theme.primaryColor,
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
        color: theme.primaryColor,
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
