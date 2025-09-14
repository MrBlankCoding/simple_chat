import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message_model.dart';
import '../../models/chat_model.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input.dart';
import '../../widgets/common/offline_banner.dart';
import '../../services/connectivity_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

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
  List<Message> _previousMessages = [];
  bool _isDisposed = false;
  Message? _replyingToMessage;
  Message? _editingMessage;
  bool _isLoadingMoreMessages = false;

  // Getter for _chat to access the current chat
  Chat? get _chat => _currentChat;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _typingTimer?.cancel();
    _typingTimer = null;
    
    // Safely dispose scroll controller
    _scrollController.removeListener(_onScroll);
    if (_scrollController.hasClients) {
      _scrollController.dispose();
    }
    
    // Safely unsubscribe from chat
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.unsubscribeFromChat(widget.chatId);
    } catch (e) {
      // Ignore disposal errors
    }
    
    _messageController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Subscribe to chat messages
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
    
    // Initial scroll to bottom after messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    if (!_isDisposed && mounted && _scrollController.hasClients) {
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
        
        // Auto-scroll when new messages arrive (only if not disposed)
        if (!_isDisposed && messages.length > _previousMessages.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed && mounted) {
              _scrollToBottom();
            }
          });
        }
        _previousMessages = List.from(messages);

        return Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            return CupertinoPageScaffold(
              backgroundColor: AppConstants.backgroundColor,
              navigationBar: CupertinoNavigationBar(
              backgroundColor: AppConstants.backgroundColor,
              border: null,
              middle: _buildChatHeader(chatProvider, currentUser.uid),
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
                  // Offline banner
                  OfflineBanner(
                    isOffline: connectivityService.isOffline,
                    onRetry: () => _retryConnection(chatProvider),
                  ),
                  
                  // Messages List
                  Expanded(
                    child: _buildMessagesList(messages, currentUser.uid),
                  ),
                  
                  // Reply preview
                  if (_replyingToMessage != null) _buildReplyPreview(),
                  
                  // Edit preview
                  if (_editingMessage != null) _buildEditPreview(),
                  
                  // Message Input
                  MessageInput(
                    controller: _messageController,
                    onSendMessage: (text) => _editingMessage != null 
                      ? _saveEditedMessage(chatProvider, text)
                      : _sendMessage(chatProvider, text),
                    onSendImage: () => _sendImage(chatProvider),
                    isEditing: _editingMessage != null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatHeader(ChatProvider chatProvider, String currentUserId) {
    if (_chat == null) {
      return const Text(
        'Chat',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final chatTitle = chatProvider.getChatTitle(_chat!, currentUserId);
    final chatImageUrl = chatProvider.getChatImageUrl(_chat!, currentUserId);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile photo
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppConstants.primaryColor.withOpacity(0.1),
          ),
          child: chatImageUrl != null && chatImageUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    chatImageUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar(chatTitle);
                    },
                  ),
                )
              : _buildDefaultAvatar(chatTitle),
        ),
        const SizedBox(width: 8),
        // Name and status
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chatTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (_chat != null && !_chat!.isGroup)
                _buildOnlineStatus(chatProvider, currentUserId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppConstants.primaryColor.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.primaryColor,
          ),
        ),
      ),
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

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final hasMoreMessages = chatProvider.hasMoreMessages(widget.chatId);
        final isLoadingMore = chatProvider.isLoadingMoreMessages(widget.chatId);
        
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingMedium,
          ),
          itemCount: messages.length + (hasMoreMessages ? 1 : 0),
          itemBuilder: (context, index) {
            // Load more indicator at the top (last item when reversed)
            if (index == messages.length) {
              return _buildLoadMoreIndicator(isLoadingMore, hasMoreMessages);
            }
            
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
                  onReply: _handleReply,
                  onEdit: _handleEdit,
                ),
              ],
            );
          },
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
      await chatProvider.sendTextMessage(
        widget.chatId, 
        text, 
        replyToMessageId: _replyingToMessage?.id,
      );
      
      // Clear reply state
      setState(() {
        _replyingToMessage = null;
      });
      
      // Scroll will happen automatically when new message arrives via stream
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to send message: ${e.toString()}'),
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

  void _handleReply(Message message) {
    setState(() {
      _replyingToMessage = message;
      _editingMessage = null; // Clear editing if replying
    });
  }

  void _handleEdit(Message message) {
    setState(() {
      _editingMessage = message;
      _replyingToMessage = null; // Clear reply if editing
      _messageController.text = message.text;
    });
  }

  Widget _buildReplyPreview() {
    if (_replyingToMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border(
          left: BorderSide(
            color: AppConstants.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to message',
                  style: AppConstants.caption.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyingToMessage!.text,
                  style: AppConstants.bodyMedium.copyWith(
                    color: CupertinoColors.secondaryLabel,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _replyingToMessage = null;
              });
            },
            child: const Icon(
              CupertinoIcons.clear,
              size: 20,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPreview() {
    if (_editingMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border(
          left: BorderSide(
            color: CupertinoColors.systemOrange,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing message',
                  style: AppConstants.caption.copyWith(
                    color: CupertinoColors.systemOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _editingMessage!.text,
                  style: AppConstants.bodyMedium.copyWith(
                    color: CupertinoColors.secondaryLabel,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _editingMessage = null;
                _messageController.clear();
              });
            },
            child: const Icon(
              CupertinoIcons.clear,
              size: 20,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEditedMessage(ChatProvider chatProvider, String text) async {
    if (_editingMessage == null) return;
    
    try {
      await chatProvider.editMessage(_editingMessage!.id, text);
      
      // Clear editing state
      setState(() {
        _editingMessage = null;
        _messageController.clear();
      });
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to edit message: ${e.toString()}'),
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

  void _onScroll() {
    if (_isDisposed || !mounted) return;
    
    // Check if user scrolled to the top (end of list when reversed)
    // Trigger loading when within 100 pixels of the top for smoother experience
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMoreMessages || _isDisposed || !mounted) return;
    
    setState(() {
      _isLoadingMoreMessages = true;
    });
    
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.loadMoreMessages(widget.chatId);
    } catch (e) {
      if (mounted) {
        // Show error snackbar or handle error
        debugPrint('Failed to load more messages: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreMessages = false;
        });
      }
    }
  }

  void _retryConnection(ChatProvider chatProvider) {
    // Retry loading messages and refresh chat data
    chatProvider.subscribeToChat(widget.chatId);
  }

  Widget _buildLoadMoreIndicator(bool isLoading, bool hasMore) {
    if (!hasMore) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Center(
          child: Text(
            'No more messages',
            style: AppConstants.caption.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      );
    }
    
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }
    
    // Return empty container for seamless scroll loading
    return const SizedBox.shrink();
  }
}
