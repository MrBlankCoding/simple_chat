import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/friend/friend_requests_tab.dart';
import 'search_users_screen.dart';
import '../../widgets/friend/friends_list_tab.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        return CupertinoPageScaffold(
          backgroundColor: AppConstants.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: AppConstants.backgroundColor,
            border: null,
            middle: const Text(AppStrings.friends),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const SearchUsersScreen(),
                  ),
                );
              },
              child: const Icon(
                CupertinoIcons.add,
                size: 24,
              ),
            ),
          ),
          child: Column(
            children: [
              // Segmented Control
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: CupertinoSlidingSegmentedControl<int>(
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(AppStrings.requests),
                          if (friendProvider.friendRequestCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: AppConstants.errorColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                friendProvider.friendRequestCount.toString(),
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${AppStrings.allFriends} (${friendProvider.friendsCount})',
                      ),
                    ),
                  },
                  groupValue: _selectedSegment,
                  onValueChanged: (value) {
                    setState(() {
                      _selectedSegment = value!;
                    });
                  },
                ),
              ),
              
              // Content
              Expanded(
                child: _selectedSegment == 0
                    ? const FriendRequestsTab()
                    : const FriendsListTab(),
              ),
            ],
          ),
        );
      },
    );
  }
}
