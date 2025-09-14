import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/theme_provider.dart';
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
    return Consumer2<FriendProvider, ThemeProvider>(
      builder: (context, friendProvider, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        return CupertinoPageScaffold(
          backgroundColor: theme.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.backgroundColor,
            border: null,
            middle: Text(
              AppStrings.friends,
              style: TextStyle(color: theme.textPrimary),
            ),
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
              child: Icon(
                CupertinoIcons.add,
                size: 24,
                color: theme.primaryColor,
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
                      child: Text(
                        '${AppStrings.allFriends} (${friendProvider.friendsCount})',
                      ),
                    ),
                    1: Padding(
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
                              decoration: BoxDecoration(
                                color: theme.errorColor,
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
                    ? const FriendsListTab()
                    : const FriendRequestsTab(),
              ),
            ],
          ),
        );
      },
    );
  }
}
