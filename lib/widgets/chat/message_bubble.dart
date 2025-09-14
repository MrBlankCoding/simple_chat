import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'message_options_modal.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isCurrentUser;
  final Function(Message)? onReply;
  final Function(Message)? onEdit;
  final bool showSenderName;
  final String? senderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onReply,
    this.onEdit,
    this.showSenderName = false,
    this.senderName,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    // Mark message as read when it comes into view (for received messages)
    if (!widget.isCurrentUser && !_hasMarkedAsRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markMessageAsRead();
      });
    }
  }

  void _markMessageAsRead() {
    if (!_hasMarkedAsRead && !widget.isCurrentUser && mounted) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;
      
      if (currentUserId != null && !widget.message.readBy.contains(currentUserId)) {
        chatProvider.markMessageAsRead(widget.message.id, widget.message.chatId);
        setState(() {
          _hasMarkedAsRead = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isDeleted) {
      return _buildDeletedMessage();
    }

    return Consumer2<ChatProvider, AuthProvider>(
      builder: (context, chatProvider, authProvider, child) {
        final currentUserId = authProvider.currentUser?.uid ?? '';
        
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
          child: Column(
            crossAxisAlignment: widget.isCurrentUser 
                ? CrossAxisAlignment.end 
                : CrossAxisAlignment.start,
            children: [
              // Optional sender name header (group chats)
              if (widget.showSenderName && !widget.isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    right: 4,
                    bottom: 4,
                  ),
                  child: Text(
                    widget.senderName?.trim().isNotEmpty == true
                        ? widget.senderName!.trim()
                        : 'Unknown',
                    style: AppConstants.caption.copyWith(
                      color: CupertinoColors.secondaryLabel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              // Reply preview if this is a reply
              if (widget.message.isReply) _buildReplyPreview(),
              
              // Main message bubble
              GestureDetector(
                onLongPress: () => _showMessageOptions(context, chatProvider, currentUserId),
                child: Row(
                  mainAxisAlignment: widget.isCurrentUser 
                    ? MainAxisAlignment.end 
                    : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.isCurrentUser) const Spacer(flex: 1),
                    Flexible(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium,
                          vertical: AppConstants.paddingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isCurrentUser 
                            ? AppConstants.primaryColor 
                            : AppConstants.surfaceColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppConstants.borderRadiusMedium),
                            topRight: const Radius.circular(AppConstants.borderRadiusMedium),
                            bottomLeft: Radius.circular(
                              widget.isCurrentUser ? AppConstants.borderRadiusMedium : AppConstants.borderRadiusSmall,
                            ),
                            bottomRight: Radius.circular(
                              widget.isCurrentUser ? AppConstants.borderRadiusSmall : AppConstants.borderRadiusMedium,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.message.type == MessageType.image)
                              _buildImageContent()
                            else
                              _buildTextContent(),
                            
                            const SizedBox(height: 4),
                            
                            // Message metadata
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppHelpers.formatMessageTime(widget.message.timestamp),
                                  style: AppConstants.caption.copyWith(
                                    color: widget.isCurrentUser 
                                      ? CupertinoColors.white.withOpacity(0.7)
                                      : CupertinoColors.secondaryLabel,
                                  ),
                                ),
                                if (widget.message.isEdited) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '• edited',
                                    style: AppConstants.caption.copyWith(
                                      color: widget.isCurrentUser 
                                        ? CupertinoColors.white.withOpacity(0.7)
                                        : CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                ],
                                if (widget.isCurrentUser) ...[
                                  const SizedBox(width: 4),
                                  _buildReadStatusIcon(),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!widget.isCurrentUser) const Spacer(flex: 1),
                  ],
                ),
              ),
              
              // Reactions
              if (widget.message.reactions.isNotEmpty) _buildReactions(chatProvider, currentUserId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextContent() {
    return Text(
      widget.message.text,
      style: AppConstants.bodyMedium.copyWith(
        color: widget.isCurrentUser 
          ? CupertinoColors.white 
          : CupertinoColors.label,
      ),
    );
  }

  Widget _buildImageContent() {
    if (widget.message.imageUrl == null || widget.message.imageUrl!.isEmpty) {
      return _buildTextContent();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          child: CachedNetworkImage(
            imageUrl: widget.message.imageUrl!,
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
        if (widget.message.text.isNotEmpty && widget.message.text != 'Photo') ...[
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
        mainAxisAlignment: widget.isCurrentUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        children: [
          if (widget.isCurrentUser) const Spacer(flex: 1),
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
          if (!widget.isCurrentUser) const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: EdgeInsets.only(
        bottom: 4,
        left: widget.isCurrentUser ? 50 : 0,
        right: widget.isCurrentUser ? 0 : 50,
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
              'Replying to ${widget.message.replyToSenderId == widget.message.senderId ? 'themselves' : 'message'}',
              style: AppConstants.caption.copyWith(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.message.replyToText ?? 'Original message',
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

  Widget _buildReadStatusIcon() {
    // For current user's messages, show read status
    final senderId = widget.message.senderId;
    
    // Count how many people other than sender have read the message
    final readByOthers = widget.message.readBy.where((userId) => userId != senderId).length;
    
    if (readByOthers == 0) {
      // Only sender has read it (message sent but not read by others)
      return Icon(
        CupertinoIcons.checkmark,
        size: 12,
        color: CupertinoColors.white.withOpacity(0.7),
      );
    } else {
      // Message has been read by others - show double checkmark in blue
      return Icon(
        CupertinoIcons.checkmark_alt,
        size: 12,
        color: CupertinoColors.systemBlue,
      );
    }
  }

  Widget _buildReactions(ChatProvider chatProvider, String currentUserId) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: widget.message.reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final hasUserReacted = users.contains(currentUserId);
          
          return GestureDetector(
            onTap: () {
              if (hasUserReacted) {
                chatProvider.removeReaction(widget.message.id, emoji);
              } else {
                chatProvider.addReaction(widget.message.id, emoji);
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
      builder: (context) => MessageOptionsModal(
        message: widget.message,
        isCurrentUser: widget.isCurrentUser,
        currentUserId: currentUserId,
        chatProvider: chatProvider,
        onReply: widget.onReply,
        onEdit: widget.onEdit,
      ),
    );
  }

}
