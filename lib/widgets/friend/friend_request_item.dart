import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import '../../providers/theme_provider.dart';
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        final userName = senderUser?.name ?? 'Unknown User';
        final userEmail = senderUser?.email ?? '';
        final profileImageUrl = senderUser?.profileImageUrl;

        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: Row(
            children: [
              // Profile Image
              _buildProfileImage(profileImageUrl, userName, theme),
              
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
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: AppConstants.bodyMedium.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sent ${AppHelpers.formatTimestamp(request.createdAt)}',
                      style: AppConstants.caption.copyWith(
                        color: theme.textSecondary,
                      ),
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
                    color: theme.primaryColor,
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
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    onPressed: onDecline,
                    child: Text(
                      AppStrings.decline,
                      style: TextStyle(
                        color: theme.textPrimary,
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
      },
    );
  }

  Widget _buildProfileImage(String? imageUrl, String name, dynamic theme) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: AppConstants.profileImageSize,
          height: AppConstants.profileImageSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(name, theme),
          errorWidget: (context, url, error) => _buildPlaceholder(name, theme),
        ),
      );
    } else {
      return _buildPlaceholder(name, theme);
    }
  }

  Widget _buildPlaceholder(String name, dynamic theme) {
    return Container(
      width: AppConstants.profileImageSize,
      height: AppConstants.profileImageSize,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          AppHelpers.getInitials(name),
          style: AppConstants.bodyMedium.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
