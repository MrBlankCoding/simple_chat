import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
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
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        return LoadingOverlay(
          isLoading: friendProvider.isLoading,
          child: CupertinoPageScaffold(
            backgroundColor: AppConstants.backgroundColor,
            navigationBar: CupertinoNavigationBar(
              backgroundColor: AppConstants.backgroundColor,
              border: null,
              middle: const Text('Search Users'),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
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
                    child: _buildSearchResults(friendProvider),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(FriendProvider friendProvider) {
    if (friendProvider.isSearching) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    final searchResults = friendProvider.searchResults;
    
    if (_searchController.text.trim().isEmpty) {
      return _buildEmptyState();
    }

    if (searchResults.isEmpty) {
      return _buildNoResultsState();
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
                CupertinoIcons.search,
                size: 40,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Search for Users',
              style: AppConstants.titleMedium.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Enter a name or email address to find users and send friend requests.',
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

  Widget _buildNoResultsState() {
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
                color: AppConstants.secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.person_crop_circle_badge_xmark,
                size: 40,
                color: AppConstants.secondaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'No Users Found',
              style: AppConstants.titleMedium.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'No users found matching "${_searchController.text.trim()}". Try a different search term.',
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

  Future<void> _sendFriendRequest(FriendProvider friendProvider, String userId) async {
    final success = await friendProvider.sendFriendRequest(userId);
    
    if (success && mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Request Sent'),
          content: const Text('Friend request sent successfully!'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else if (mounted && friendProvider.error != null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(friendProvider.error!),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
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
