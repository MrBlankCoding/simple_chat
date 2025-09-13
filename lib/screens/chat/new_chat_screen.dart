import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../themes/app_theme.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../widgets/common/loading_overlay.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredFriends = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFriends() {
    // Friends are automatically loaded in FriendProvider constructor
    // No need to call a separate method
  }

  void _filterFriends(String query) {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    final friendsList = friendProvider.getFriendsList();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredFriends = friendsList;
      } else {
        _filteredFriends = friendsList
            .where((friend) =>
                friend.name.toLowerCase().contains(query.toLowerCase()) ||
                friend.email.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _startChat(UserModel friend) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;

    try {
      final chatId = await chatProvider.getOrCreateDirectChat(friend.uid);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushReplacementNamed(
          '/chat',
          arguments: {'chatId': chatId},
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error', style: TextStyle(color: theme.textPrimary)),
            content: Text('Failed to start chat. Please try again.', style: TextStyle(color: theme.textSecondary)),
            actions: [
              CupertinoDialogAction(
                child: Text('OK', style: TextStyle(color: theme.primaryColor)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FriendProvider, ThemeProvider>(
      builder: (context, friendProvider, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        final friends = _isSearching ? _filteredFriends : friendProvider.getFriendsList();

        return LoadingOverlay(
          isLoading: friendProvider.isLoading,
          child: CupertinoPageScaffold(
            backgroundColor: theme.backgroundColor,
            navigationBar: CupertinoNavigationBar(
              backgroundColor: theme.backgroundColor,
              border: null,
              middle: Text(
                'New Chat',
                style: TextStyle(color: theme.textPrimary),
              ),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: Icon(CupertinoIcons.back, color: theme.primaryColor),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    margin: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: CupertinoTextField(
                      controller: _searchController,
                      placeholder: 'Search friends...',
                      style: TextStyle(color: theme.textPrimary),
                      placeholderStyle: TextStyle(color: theme.textSecondary),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                      ),
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: AppConstants.paddingMedium),
                        child: Icon(
                          CupertinoIcons.search,
                          color: theme.textSecondary,
                        ),
                      ),
                      suffix: _searchController.text.isNotEmpty
                          ? CupertinoButton(
                              padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
                              onPressed: () {
                                _searchController.clear();
                                _filterFriends('');
                              },
                              child: Icon(
                                CupertinoIcons.clear_circled_solid,
                                color: theme.textSecondary,
                              ),
                            )
                          : null,
                      onChanged: _filterFriends,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium,
                        vertical: AppConstants.paddingMedium,
                      ),
                    ),
                  ),

                  // Friends List
                  Expanded(
                    child: friends.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView.builder(
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              final friend = friends[index];
                              return _buildFriendTile(friend, theme);
                            },
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

  Widget _buildFriendTile(UserModel friend, AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        onPressed: () => _startChat(friend),
        child: Row(
          children: [
            // Profile Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.1),
              ),
              child: friend.profileImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        friend.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            CupertinoIcons.person_fill,
                            color: theme.primaryColor,
                          );
                        },
                      ),
                    )
                  : Icon(
                      CupertinoIcons.person_fill,
                      color: theme.primaryColor,
                    ),
            ),
            
            const SizedBox(width: AppConstants.paddingMedium),
            
            // Friend Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: AppConstants.bodyLarge.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.email,
                    style: AppConstants.bodyMedium.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chat Icon
            Icon(
              CupertinoIcons.chat_bubble_fill,
              color: theme.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
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
                CupertinoIcons.person_2,
                size: 40,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              _isSearching ? 'No friends found' : 'No friends yet',
              style: AppConstants.titleMedium.copyWith(
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              _isSearching
                  ? 'Try searching with a different name or email.'
                  : 'Add friends to start chatting with them.',
              style: AppConstants.bodyMedium.copyWith(
                color: theme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
