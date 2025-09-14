import 'package:flutter/cupertino.dart';
import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';

class MessageOptionsModal extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final String currentUserId;
  final ChatProvider chatProvider;
  final Function(Message)? onReply;
  final Function(Message)? onEdit;

  const MessageOptionsModal({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.currentUserId,
    required this.chatProvider,
    this.onReply,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Message Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark_circle_fill),
                  ),
                ],
              ),
            ),
            
            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildOptionTile(
                    icon: CupertinoIcons.reply,
                    title: 'Reply',
                    subtitle: 'Reply to this message',
                    onTap: () {
                      Navigator.pop(context);
                      onReply?.call(message);
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: CupertinoIcons.smiley,
                    title: 'React',
                    subtitle: 'Add a reaction',
                    onTap: () {
                      Navigator.pop(context);
                      _showReactionPicker(context);
                    },
                  ),
                  
                  if (message.canEdit(currentUserId))
                    _buildOptionTile(
                      icon: CupertinoIcons.pencil,
                      title: 'Edit',
                      subtitle: 'Edit this message',
                      onTap: () {
                        Navigator.pop(context);
                        onEdit?.call(message);
                      },
                    ),
                  
                  if (message.canDelete(currentUserId))
                    _buildOptionTile(
                      icon: CupertinoIcons.trash,
                      title: 'Delete',
                      subtitle: 'Delete this message',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteModal(context);
                      },
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive 
                  ? CupertinoColors.systemRed.withOpacity(0.1)
                  : AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive 
                  ? CupertinoColors.systemRed
                  : AppConstants.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive 
                        ? CupertinoColors.systemRed
                        : CupertinoColors.label,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey3,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ReactionPickerModal(
        message: message,
        chatProvider: chatProvider,
      ),
    );
  }


  void _showDeleteModal(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => DeleteMessageModal(
        message: message,
        chatProvider: chatProvider,
      ),
    );
  }
}

class ReactionPickerModal extends StatelessWidget {
  final Message message;
  final ChatProvider chatProvider;

  const ReactionPickerModal({
    super.key,
    required this.message,
    required this.chatProvider,
  });

  @override
  Widget build(BuildContext context) {
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '😡', '🔥', '💯', '👏', '🎉'];
    
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'React to Message',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark_circle_fill),
                  ),
                ],
              ),
            ),
            
            // Reactions grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: reactions.length,
                itemBuilder: (context, index) {
                  final emoji = reactions[index];
                  final hasReacted = message.reactions[emoji]?.isNotEmpty ?? false;
                  
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      chatProvider.addReaction(message.id, emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: hasReacted 
                          ? AppConstants.primaryColor.withOpacity(0.1)
                          : CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                        border: hasReacted 
                          ? Border.all(color: AppConstants.primaryColor, width: 1)
                          : null,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


class DeleteMessageModal extends StatefulWidget {
  final Message message;
  final ChatProvider chatProvider;

  const DeleteMessageModal({
    super.key,
    required this.message,
    required this.chatProvider,
  });

  @override
  State<DeleteMessageModal> createState() => _DeleteMessageModalState();
}

class _DeleteMessageModalState extends State<DeleteMessageModal> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: CupertinoColors.systemRed,
                      size: 32,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Delete Message',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Are you sure you want to delete this message? This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoButton.filled(
                          color: CupertinoColors.systemRed,
                          onPressed: _isLoading ? null : _deleteMessage,
                          child: _isLoading 
                            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                            : const Text('Delete'),
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
    );
  }

  Future<void> _deleteMessage() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await widget.chatProvider.deleteMessage(widget.message.id);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Error handling is done in the provider
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
