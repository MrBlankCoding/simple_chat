import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final Function(Message)? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _buildDeletedMessage();
    }

    return Consumer2<ChatProvider, AuthProvider>(
      builder: (context, chatProvider, authProvider, child) {
        final currentUserId = authProvider.currentUser?.uid ?? '';
        
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
          child: Column(
            crossAxisAlignment: isCurrentUser 
                ? CrossAxisAlignment.end 
                : CrossAxisAlignment.start,
            children: [
              // Reply preview if this is a reply
              if (message.isReply) _buildReplyPreview(),
              
              // Main message bubble
              GestureDetector(
                onLongPress: () => _showMessageOptions(context, chatProvider, currentUserId),
                child: Row(
                  mainAxisAlignment: isCurrentUser 
                    ? MainAxisAlignment.end 
                    : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isCurrentUser) const Spacer(flex: 1),
                    Flexible(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium,
                          vertical: AppConstants.paddingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser 
                            ? AppConstants.primaryColor 
                            : AppConstants.surfaceColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppConstants.borderRadiusMedium),
                            topRight: const Radius.circular(AppConstants.borderRadiusMedium),
                            bottomLeft: Radius.circular(
                              isCurrentUser ? AppConstants.borderRadiusMedium : AppConstants.borderRadiusSmall,
                            ),
                            bottomRight: Radius.circular(
                              isCurrentUser ? AppConstants.borderRadiusSmall : AppConstants.borderRadiusMedium,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.type == MessageType.image)
                              _buildImageContent()
                            else
                              _buildTextContent(),
                            
                            const SizedBox(height: 4),
                            
                            // Message metadata
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppHelpers.formatMessageTime(message.timestamp),
                                  style: AppConstants.caption.copyWith(
                                    color: isCurrentUser 
                                      ? CupertinoColors.white.withOpacity(0.7)
                                      : CupertinoColors.secondaryLabel,
                                  ),
                                ),
                                if (message.isEdited) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '• edited',
                                    style: AppConstants.caption.copyWith(
                                      color: isCurrentUser 
                                        ? CupertinoColors.white.withOpacity(0.7)
                                        : CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                ],
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.readBy.length > 1 
                                      ? CupertinoIcons.checkmark_alt_circle_fill
                                      : CupertinoIcons.checkmark_circle,
                                    size: 12,
                                    color: CupertinoColors.white.withOpacity(0.7),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isCurrentUser) const Spacer(flex: 1),
                  ],
                ),
              ),
              
              // Reactions
              if (message.reactions.isNotEmpty) _buildReactions(chatProvider, currentUserId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextContent() {
    return Text(
      message.text,
      style: AppConstants.bodyMedium.copyWith(
        color: isCurrentUser 
          ? CupertinoColors.white 
          : CupertinoColors.label,
      ),
    );
  }

  Widget _buildImageContent() {
    if (message.imageUrl == null || message.imageUrl!.isEmpty) {
      return _buildTextContent();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          child: CachedNetworkImage(
            imageUrl: message.imageUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 200,
              height: 200,
              color: CupertinoColors.systemGrey5,
              child: const Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200,
              height: 200,
              color: CupertinoColors.systemGrey5,
              child: const Center(
                child: Icon(
                  CupertinoIcons.photo,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
          ),
        ),
        if (message.text.isNotEmpty && message.text != 'Photo') ...[
          const SizedBox(height: 8),
          _buildTextContent(),
        ],
      ],
    );
  }

  Widget _buildDeletedMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Row(
        mainAxisAlignment: isCurrentUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        children: [
          if (isCurrentUser) const Spacer(flex: 1),
          Flexible(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.trash,
                    size: 16,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'This message was deleted',
                    style: AppConstants.bodyMedium.copyWith(
                      color: CupertinoColors.secondaryLabel,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isCurrentUser) const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: EdgeInsets.only(
        bottom: 4,
        left: isCurrentUser ? 50 : 0,
        right: isCurrentUser ? 0 : 50,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: AppConstants.primaryColor,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Replying to ${message.replyToSenderId == message.senderId ? 'themselves' : 'message'}',
              style: AppConstants.caption.copyWith(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.replyToText ?? 'Original message',
              style: AppConstants.caption.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions(ChatProvider chatProvider, String currentUserId) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: message.reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final hasUserReacted = users.contains(currentUserId);
          
          return GestureDetector(
            onTap: () {
              if (hasUserReacted) {
                chatProvider.removeReaction(message.id, emoji);
              } else {
                chatProvider.addReaction(message.id, emoji);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasUserReacted 
                  ? AppConstants.primaryColor.withOpacity(0.2)
                  : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
                border: hasUserReacted 
                  ? Border.all(color: AppConstants.primaryColor, width: 1)
                  : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${users.length}',
                    style: AppConstants.caption.copyWith(
                      color: hasUserReacted 
                        ? AppConstants.primaryColor
                        : CupertinoColors.secondaryLabel,
                      fontWeight: hasUserReacted ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatProvider chatProvider, String currentUserId) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          // Reply option
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onReply?.call(message);
            },
            child: const Row(
              children: [
                Icon(CupertinoIcons.reply),
                SizedBox(width: 12),
                Text('Reply'),
              ],
            ),
          ),
          
          // React option
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showReactionPicker(context, chatProvider);
            },
            child: const Row(
              children: [
                Icon(CupertinoIcons.smiley),
                SizedBox(width: 12),
                Text('React'),
              ],
            ),
          ),
          
          // Edit option (only for current user's messages)
          if (message.canEdit(currentUserId))
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showEditDialog(context, chatProvider);
              },
              child: const Row(
                children: [
                  Icon(CupertinoIcons.pencil),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
          
          // Delete option (only for current user's messages)
          if (message.canDelete(currentUserId))
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
                  Text('Delete'),
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

  void _showReactionPicker(BuildContext context, ChatProvider chatProvider) {
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('React to message'),
        actions: reactions.map((emoji) => 
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              chatProvider.addReaction(message.id, emoji);
            },
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ChatProvider chatProvider) {
    final controller = TextEditingController(text: message.text);
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Edit Message'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Enter new message',
              maxLines: null,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Save'),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                chatProvider.editMessage(message.id, controller.text.trim());
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ChatProvider chatProvider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              chatProvider.deleteMessage(message.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
