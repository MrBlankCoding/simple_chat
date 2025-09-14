import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
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
    return Consumer2<ChatProvider, ThemeProvider>(
      builder: (context, chatProvider, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        final chatTitle = chatProvider.getChatTitle(chat, currentUserId);
        final chatImageUrl = chatProvider.getChatImageUrl(chat, currentUserId);
        final unreadCount = chat.getUnreadCount(currentUserId);
        final isOnline = !chat.isGroup && _getOtherUserOnlineStatus(chatProvider);

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingSmall / 2,
          ),
          child: GestureDetector(
            onTap: onTap,
            onLongPress: () => _showChatOptions(context, chatProvider),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Row(
                children: [
                  // Profile Image
                  Stack(
                    children: [
                      _buildProfileImage(chatImageUrl, chatTitle, theme),
                      if (isOnline)
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
                  
                  // Chat Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Pin indicator
                            if (chat.isPinnedBy(currentUserId)) ...[
                              Icon(
                                CupertinoIcons.pin_fill,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                chatTitle,
                                style: AppConstants.bodyLarge.copyWith(
                                  fontWeight: unreadCount > 0 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                                  color: theme.textPrimary,
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
                                    ? theme.primaryColor
                                    : theme.textSecondary,
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
                                    ? theme.textPrimary
                                    : theme.textSecondary,
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
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
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

  Widget _buildProfileImage(String? imageUrl, String title, theme) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: AppConstants.profileImageSize,
          height: AppConstants.profileImageSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(title, theme),
          errorWidget: (context, url, error) => _buildPlaceholder(title, theme),
        ),
      );
    } else {
      return _buildPlaceholder(title, theme);
    }
  }

  Widget _buildPlaceholder(String title, theme) {
    return Container(
      width: AppConstants.profileImageSize,
      height: AppConstants.profileImageSize,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          AppHelpers.getInitials(title),
          style: AppConstants.bodyMedium.copyWith(
            color: theme.primaryColor,
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

  void _showChatOptions(BuildContext context, ChatProvider chatProvider) {
    final unreadCount = chat.getUnreadCount(currentUserId);
    final isPinned = chat.isPinnedBy(currentUserId);
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          // Pin/Unpin option
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              chatProvider.pinChat(chat.id);
            },
            child: Row(
              children: [
                Icon(isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin),
                const SizedBox(width: 12),
                Text(isPinned ? 'Unpin Chat' : 'Pin Chat'),
              ],
            ),
          ),
          
          // Mark as read option (only if there are unread messages)
          if (unreadCount > 0)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                chatProvider.markChatAsRead(chat.id);
              },
              child: const Row(
                children: [
                  Icon(CupertinoIcons.checkmark_circle),
                  SizedBox(width: 12),
                  Text('Mark as Read'),
                ],
              ),
            ),
          
          // Delete chat option
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, chatProvider);
            },
            isDestructiveAction: true,
            child: const Row(
              children: [
                Icon(CupertinoIcons.trash),
                SizedBox(width: 12),
                Text('Delete Chat'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ChatProvider chatProvider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              chatProvider.deleteChat(chat.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
