import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final chatTitle = chatProvider.getChatTitle(chat, currentUserId);
        final chatImageUrl = chatProvider.getChatImageUrl(chat, currentUserId);
        final unreadCount = chat.getUnreadCount(currentUserId);
        final isOnline = !chat.isGroup && _getOtherUserOnlineStatus(chatProvider);

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingSmall / 2,
          ),
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
                  // Profile Image
                  Stack(
                    children: [
                      _buildProfileImage(chatImageUrl, chatTitle),
                      if (isOnline)
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
                  
                  // Chat Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chatTitle,
                                style: AppConstants.bodyLarge.copyWith(
                                  fontWeight: unreadCount > 0 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                                  color: CupertinoColors.label,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chat.lastMessageTime != null)
                              Text(
                                AppHelpers.formatTimestamp(chat.lastMessageTime!),
                                style: AppConstants.caption.copyWith(
                                  color: unreadCount > 0 
                                    ? AppConstants.primaryColor
                                    : CupertinoColors.secondaryLabel,
                                  fontWeight: unreadCount > 0 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppHelpers.getLastMessagePreview(chat.lastMessage),
                                style: AppConstants.bodyMedium.copyWith(
                                  color: unreadCount > 0 
                                    ? CupertinoColors.label
                                    : CupertinoColors.secondaryLabel,
                                  fontWeight: unreadCount > 0 
                                    ? FontWeight.w500 
                                    : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppConstants.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(String? imageUrl, String title) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: AppConstants.profileImageSize,
          height: AppConstants.profileImageSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(title),
          errorWidget: (context, url, error) => _buildPlaceholder(title),
        ),
      );
    } else {
      return _buildPlaceholder(title);
    }
  }

  Widget _buildPlaceholder(String title) {
    return Container(
      width: AppConstants.profileImageSize,
      height: AppConstants.profileImageSize,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          AppHelpers.getInitials(title),
          style: AppConstants.bodyMedium.copyWith(
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  bool _getOtherUserOnlineStatus(ChatProvider chatProvider) {
    if (chat.isGroup) return false;
    
    final otherUserId = chat.getOtherParticipant(currentUserId);
    if (otherUserId == null) return false;
    
    return chatProvider.isUserOnline(otherUserId);
  }
}
