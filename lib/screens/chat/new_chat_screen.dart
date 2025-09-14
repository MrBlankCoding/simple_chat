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
  final TextEditingController _groupNameController = TextEditingController();
  List<UserModel> _filteredFriends = [];
  Set<String> _selectedFriends = {};
  bool _isSearching = false;
  bool _isGroupMode = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
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

  void _toggleGroupMode() {
    setState(() {
      _isGroupMode = !_isGroupMode;
      if (!_isGroupMode) {
        _selectedFriends.clear();
        _groupNameController.clear();
      }
    });
  }

  void _toggleFriendSelection(String friendId) {
    setState(() {
      if (_selectedFriends.contains(friendId)) {
        _selectedFriends.remove(friendId);
      } else {
        _selectedFriends.add(friendId);
      }
    });
  }

  Future<void> _startChat(UserModel friend) async {
    if (_isGroupMode) {
      _toggleFriendSelection(friend.uid);
      return;
    }

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
        _showErrorDialog('Failed to start chat. Please try again.');
      }
    }
  }

  Future<void> _createGroupChat() async {
    if (_selectedFriends.isEmpty) {
      _showErrorDialog('Please select at least one friend for the group chat.');
      return;
    }

    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      _showErrorDialog('Please enter a name for the group chat.');
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;

    try {
      final chatId = await chatProvider.createGroupChat(
        _selectedFriends.toList(),
        groupName,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushReplacementNamed(
          '/chat',
          arguments: {'chatId': chatId},
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to create group chat. Please try again.');
      }
    }
  }

  void _showErrorDialog(String message) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Error', style: TextStyle(color: theme.textPrimary)),
        content: Text(message, style: TextStyle(color: theme.textSecondary)),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: theme.primaryColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
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
                _isGroupMode ? 'New Group Chat' : 'New Chat',
                style: TextStyle(color: theme.textPrimary),
              ),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: Icon(CupertinoIcons.back, color: theme.primaryColor),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _toggleGroupMode,
                child: Icon(
                  _isGroupMode ? CupertinoIcons.person : CupertinoIcons.group,
                  color: theme.primaryColor,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Group Name Input (only visible in group mode)
                  if (_isGroupMode) _buildGroupNameInput(theme),

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

                  // Selected Friends Counter (only visible in group mode)
                  if (_isGroupMode && _selectedFriends.isNotEmpty)
                    _buildSelectedCounter(theme),

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

                  // Create Group Chat Button (only visible in group mode)
                  if (_isGroupMode) _buildCreateGroupButton(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupNameInput(AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppConstants.paddingMedium,
        AppConstants.paddingMedium,
        AppConstants.paddingMedium,
        0,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: CupertinoTextField(
        controller: _groupNameController,
        placeholder: 'Enter group name...',
        style: TextStyle(color: theme.textPrimary),
        placeholderStyle: TextStyle(color: theme.textSecondary),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: AppConstants.paddingMedium),
          child: Icon(
            CupertinoIcons.textformat,
            color: theme.textSecondary,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingMedium,
        ),
      ),
    );
  }

  Widget _buildSelectedCounter(AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: theme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Text(
            '${_selectedFriends.length} friend${_selectedFriends.length == 1 ? '' : 's'} selected',
            style: AppConstants.bodyMedium.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateGroupButton(AppThemeData theme) {
    final isEnabled = _selectedFriends.isNotEmpty && _groupNameController.text.trim().isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      width: double.infinity,
      child: CupertinoButton(
        onPressed: isEnabled ? _createGroupChat : null,
        color: isEnabled ? theme.primaryColor : theme.textSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Text(
          'Create Group Chat',
          style: AppConstants.bodyLarge.copyWith(
            color: isEnabled ? CupertinoColors.white : theme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendTile(UserModel friend, AppThemeData theme) {
    final isSelected = _selectedFriends.contains(friend.uid);
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: _isGroupMode && isSelected 
            ? theme.primaryColor.withOpacity(0.1)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: _isGroupMode && isSelected
            ? Border.all(color: theme.primaryColor, width: 2)
            : null,
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
            
            // Selection indicator or chat icon
            if (_isGroupMode)
              Icon(
                isSelected 
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                color: isSelected ? theme.primaryColor : theme.textSecondary,
                size: 24,
              )
            else
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
