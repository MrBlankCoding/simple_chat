import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../themes/app_theme.dart';
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
    return Consumer3<AuthProvider, ChatProvider, ThemeProvider>(
      builder: (context, authProvider, chatProvider, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        final currentUser = authProvider.currentUser;
        if (currentUser == null) {
          return const CupertinoPageScaffold(
            child: Center(
              child: Text('Not authenticated'),
            ),
          );
        }

        return CupertinoPageScaffold(
          backgroundColor: theme.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.backgroundColor,
            border: null,
            middle: Text(
              AppStrings.chats,
              style: TextStyle(color: theme.textPrimary),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pushNamed('/new-chat');
              },
              child: Icon(
                CupertinoIcons.add,
                size: 24,
                color: theme.primaryColor,
              ),
            ),
          ),
          child: LoadingOverlay(
            isLoading: chatProvider.isLoading,
            child: _buildChatList(chatProvider, currentUser.uid, theme),
          ),
        );
      },
    );
  }

  Widget _buildChatList(ChatProvider chatProvider, String currentUserId, AppThemeData theme) {
    final chats = chatProvider.chats;

    if (chats.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Sort chats: pinned chats first, then by last message time
    final sortedChats = List<Chat>.from(chats);
    sortedChats.sort((a, b) {
      final aPinned = a.isPinnedBy(currentUserId);
      final bPinned = b.isPinnedBy(currentUserId);
      
      // If one is pinned and the other isn't, pinned comes first
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      
      // If both are pinned or both are not pinned, sort by last message time
      final aTime = a.lastMessageTime;
      final bTime = b.lastMessageTime;
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return bTime.compareTo(aTime); // Most recent first
    });

    return ListView.builder(
      itemCount: sortedChats.length,
      itemBuilder: (context, index) {
        final chat = sortedChats[index];
        return ChatListItem(
          chat: chat,
          currentUserId: currentUserId,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pushNamed(
              '/chat',
              arguments: {'chatId': chat.id},
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(AppThemeData theme) {
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
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.chat_bubble_2,
                size: 40,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'No Conversations Yet',
              style: AppConstants.titleMedium.copyWith(
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Start a conversation with your friends to see your chats here.',
              style: AppConstants.bodyMedium.copyWith(
                color: theme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXLarge),
            CupertinoButton.filled(
              color: theme.primaryColor,
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
