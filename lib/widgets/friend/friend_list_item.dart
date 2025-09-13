import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class FriendListItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const FriendListItem({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
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
                      user.isOnline 
                        ? AppStrings.online 
                        : 'Last seen ${AppHelpers.formatLastSeen(user.lastSeen)}',
                      style: AppConstants.bodyMedium.copyWith(
                        color: user.isOnline 
                          ? AppConstants.successColor 
                          : CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Message Icon
              const Icon(
                CupertinoIcons.chat_bubble,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
}
