import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message_model.dart';
import '../../models/chat_model.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_overlay.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  Chat? _currentChat;
  Timer? _typingTimer;

  // Getter for _chat to access the current chat
  Chat? get _chat => _currentChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.unsubscribeFromChat(widget.chatId);
    super.dispose();
  }

  void _initializeChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.subscribeToChat(widget.chatId);
    
    // Find the chat in the provider
    _currentChat = chatProvider.chats.firstWhere(
      (chat) => chat.id == widget.chatId,
      orElse: () => Chat(
        id: widget.chatId,
        participants: [],
        createdAt: DateTime.now(),
        createdBy: '',
      ),
    );
    
    // Mark messages as read
    chatProvider.markMessagesAsRead(widget.chatId);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppConstants.animationDurationShort,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        final currentUser = authProvider.currentUser;
        if (currentUser == null) {
          return const CupertinoPageScaffold(
            child: Center(child: Text('Not authenticated')),
          );
        }

        final messages = chatProvider.getChatMessages(widget.chatId);
        final chatTitle = _chat != null 
          ? chatProvider.getChatTitle(_chat!, currentUser.uid)
          : 'Chat';

        return LoadingOverlay(
          isLoading: chatProvider.isLoading,
          child: CupertinoPageScaffold(
            backgroundColor: AppConstants.backgroundColor,
            navigationBar: CupertinoNavigationBar(
              backgroundColor: AppConstants.backgroundColor,
              border: null,
              middle: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chatTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_chat != null && !_chat!.isGroup)
                    _buildOnlineStatus(chatProvider, currentUser.uid),
                ],
              ),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(CupertinoIcons.back),
              ),
              trailing: _chat?.isGroup == true
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // TODO: Show group info
                    },
                    child: const Icon(CupertinoIcons.info),
                  )
                : null,
            ),
            child: Column(
              children: [
                // Messages List
                Expanded(
                  child: _buildMessagesList(messages, currentUser.uid),
                ),
                
                // Message Input
                MessageInput(
                  onSendMessage: (text) => _sendMessage(chatProvider, text),
                  onSendImage: () => _sendImage(chatProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnlineStatus(ChatProvider chatProvider, String currentUserId) {
    if (_chat == null || _chat!.isGroup) return const SizedBox.shrink();
    
    final otherUserId = _chat!.getOtherParticipant(currentUserId);
    if (otherUserId == null) return const SizedBox.shrink();
    
    final isOnline = chatProvider.isUserOnline(otherUserId);
    final lastSeen = chatProvider.getUserLastSeen(otherUserId);
    
    return Text(
      isOnline 
        ? AppStrings.online 
        : 'Last seen ${AppHelpers.formatLastSeen(lastSeen)}',
      style: AppConstants.caption.copyWith(
        color: isOnline 
          ? AppConstants.successColor 
          : CupertinoColors.secondaryLabel,
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages, String currentUserId) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingMedium,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.isFromCurrentUser(currentUserId);
        final showTimestamp = _shouldShowTimestamp(messages, index);
        
        return Column(
          children: [
            if (showTimestamp)
              _buildTimestampDivider(message.timestamp),
            MessageBubble(
              message: message,
              isCurrentUser: isCurrentUser,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.chat_bubble_2,
                size: 40,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Start the Conversation',
              style: AppConstants.titleMedium.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Send a message to start chatting.',
              style: AppConstants.bodyMedium.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampDivider(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: CupertinoColors.separator,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Text(
              AppHelpers.formatTimestamp(timestamp),
              style: AppConstants.caption,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: CupertinoColors.separator,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(List<Message> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];
    
    final timeDiff = currentMessage.timestamp.difference(nextMessage.timestamp);
    return timeDiff.inMinutes > 30;
  }

  Future<void> _sendMessage(ChatProvider chatProvider, String text) async {
    try {
      await chatProvider.sendTextMessage(widget.chatId, text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to send message. Please try again.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _sendImage(ChatProvider chatProvider) async {
    // TODO: Implement image sending
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('Image sharing will be available in a future update.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
