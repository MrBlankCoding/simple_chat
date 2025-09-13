import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';
import 'new_chat_screen.dart';
import '../../widgets/chat/chat_list_item.dart';
import '../../widgets/common/loading_overlay.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        final currentUser = authProvider.currentUser;
        if (currentUser == null) {
          return const CupertinoPageScaffold(
            child: Center(
              child: Text('Not authenticated'),
            ),
          );
        }

        return CupertinoPageScaffold(
          backgroundColor: AppConstants.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: AppConstants.backgroundColor,
            border: null,
            middle: const Text(AppStrings.chats),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).pushNamed('/new-chat');
              },
              child: const Icon(
                CupertinoIcons.add,
                size: 24,
              ),
            ),
          ),
          child: LoadingOverlay(
            isLoading: chatProvider.isLoading,
            child: _buildChatList(chatProvider, currentUser.uid),
          ),
        );
      },
    );
  }

  Widget _buildChatList(ChatProvider chatProvider, String currentUserId) {
    final chats = chatProvider.chats;

    if (chats.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListItem(
          chat: chat,
          currentUserId: currentUserId,
          onTap: () {
            Navigator.of(context).pushNamed(
              '/chat',
              arguments: {'chatId': chat.id},
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
              'No Conversations Yet',
              style: AppConstants.titleMedium.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Start a conversation with your friends to see your chats here.',
              style: AppConstants.bodyMedium.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXLarge),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const NewChatScreen(),
                  ),
                );
              },
              child: const Text('Start New Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
