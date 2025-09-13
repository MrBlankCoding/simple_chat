import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
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
        Navigator.of(context).pushReplacementNamed(
          '/chat',
          arguments: {'chatId': chatId},
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to start chat. Please try again.'),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        final friends = _isSearching ? _filteredFriends : friendProvider.getFriendsList();

        return LoadingOverlay(
          isLoading: friendProvider.isLoading,
          child: CupertinoPageScaffold(
            backgroundColor: AppConstants.backgroundColor,
            navigationBar: CupertinoNavigationBar(
              backgroundColor: AppConstants.backgroundColor,
              border: null,
              middle: const Text('New Chat'),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(CupertinoIcons.back),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    margin: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: CupertinoTextField(
                      controller: _searchController,
                      placeholder: 'Search friends...',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: AppConstants.paddingMedium),
                        child: Icon(
                          CupertinoIcons.search,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      suffix: _searchController.text.isNotEmpty
                          ? CupertinoButton(
                              padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
                              onPressed: () {
                                _searchController.clear();
                                _filterFriends('');
                              },
                              child: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            )
                          : null,
                      onChanged: _filterFriends,
                      decoration: const BoxDecoration(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium,
                        vertical: AppConstants.paddingMedium,
                      ),
                    ),
                  ),

                  // Friends List
                  Expanded(
                    child: friends.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              final friend = friends[index];
                              return _buildFriendTile(friend);
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

  Widget _buildFriendTile(UserModel friend) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
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
                color: AppConstants.primaryColor.withOpacity(0.1),
              ),
              child: friend.profileImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        friend.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            CupertinoIcons.person_fill,
                            color: AppConstants.primaryColor,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      CupertinoIcons.person_fill,
                      color: AppConstants.primaryColor,
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
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.email,
                    style: AppConstants.bodyMedium.copyWith(
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chat Icon
            const Icon(
              CupertinoIcons.chat_bubble_fill,
              color: AppConstants.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
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
                CupertinoIcons.person_2,
                size: 40,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              _isSearching ? 'No friends found' : 'No friends yet',
              style: AppConstants.titleMedium.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              _isSearching
                  ? 'Try searching with a different name or email.'
                  : 'Add friends to start chatting with them.',
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
}
