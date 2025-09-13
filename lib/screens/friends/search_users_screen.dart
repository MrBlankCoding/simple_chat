import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/theme_provider.dart';
import '../../themes/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/friend/user_search_item.dart';
import '../../widgets/common/loading_overlay.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FriendProvider, ThemeProvider>(
      builder: (context, friendProvider, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        return LoadingOverlay(
          isLoading: friendProvider.isLoading,
          child: CupertinoPageScaffold(
            backgroundColor: theme.backgroundColor,
            navigationBar: CupertinoNavigationBar(
              backgroundColor: theme.backgroundColor,
              border: null,
              middle: Text(
                'Search Users',
                style: TextStyle(color: theme.textPrimary),
              ),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: TextStyle(color: theme.primaryColor)),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: 'Search by name or email',
                      style: TextStyle(color: theme.textPrimary),
                      placeholderStyle: TextStyle(color: theme.textSecondary),
                      backgroundColor: theme.cardColor,
                      onChanged: (value) {
                        if (value.trim().isNotEmpty) {
                          friendProvider.searchUsers(value.trim());
                        } else {
                          friendProvider.clearSearchResults();
                        }
                      },
                    ),
                  ),
                  
                  // Search Results
                  Expanded(
                    child: _buildSearchResults(friendProvider, theme),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(FriendProvider friendProvider, AppThemeData theme) {
    if (friendProvider.isSearching) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    final searchResults = friendProvider.searchResults;
    
    if (_searchController.text.trim().isEmpty) {
      return _buildEmptyState(theme);
    }

    if (searchResults.isEmpty) {
      return _buildNoResultsState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final user = searchResults[index];
        return UserSearchItem(
          user: user,
          onSendRequest: () => _sendFriendRequest(friendProvider, user.uid),
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
                CupertinoIcons.search,
                size: 40,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Search for Users',
              style: AppConstants.titleMedium.copyWith(
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Enter a name or email address to find users and send friend requests.',
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

  Widget _buildNoResultsState(AppThemeData theme) {
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
                color: theme.secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.person_crop_circle_badge_xmark,
                size: 40,
                color: theme.secondaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'No Users Found',
              style: AppConstants.titleMedium.copyWith(
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'No users found matching "${_searchController.text.trim()}". Try a different search term.',
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

  Future<void> _sendFriendRequest(FriendProvider friendProvider, String userId) async {
    final success = await friendProvider.sendFriendRequest(userId);
    
    if (success && mounted) {
      final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Request Sent', style: TextStyle(color: theme.textPrimary)),
          content: Text('Friend request sent successfully!', style: TextStyle(color: theme.textSecondary)),
          actions: [
            CupertinoDialogAction(
              child: Text('OK', style: TextStyle(color: theme.primaryColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else if (mounted && friendProvider.error != null) {
      final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Error', style: TextStyle(color: theme.textPrimary)),
          content: Text(friendProvider.error!, style: TextStyle(color: theme.textSecondary)),
          actions: [
            CupertinoDialogAction(
              child: Text('OK', style: TextStyle(color: theme.primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
                friendProvider.clearError();
              },
            ),
          ],
        ),
      );
    }
  }
}
