import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_provider.dart';
import '../utils/constants.dart';
import 'chat/chat_list_screen.dart';
import 'friends/friends_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatListScreen(),
    const FriendsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Set user as online when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).updateOnlineStatus(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground
        authProvider.updateOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is in background or closed
        authProvider.updateOnlineStatus(false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, FriendProvider>(
      builder: (context, chatProvider, friendProvider, child) {
        // Calculate badge counts
        final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
        final chatBadgeCount = currentUserId != null 
            ? chatProvider.getTotalUnreadCount(currentUserId) 
            : 0;
        final friendBadgeCount = friendProvider.friendRequestCount;

        return CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            backgroundColor: AppConstants.surfaceColor,
            activeColor: AppConstants.primaryColor,
            inactiveColor: CupertinoColors.secondaryLabel,
            items: [
              BottomNavigationBarItem(
                icon: _buildTabIcon(
                  CupertinoIcons.chat_bubble_2,
                  CupertinoIcons.chat_bubble_2_fill,
                  0,
                  badgeCount: chatBadgeCount,
                ),
                label: AppStrings.chats,
              ),
              BottomNavigationBarItem(
                icon: _buildTabIcon(
                  CupertinoIcons.person_2,
                  CupertinoIcons.person_2_fill,
                  1,
                  badgeCount: friendBadgeCount,
                ),
                label: AppStrings.friends,
              ),
              BottomNavigationBarItem(
                icon: _buildTabIcon(
                  CupertinoIcons.person,
                  CupertinoIcons.person_fill,
                  2,
                ),
                label: AppStrings.profile,
              ),
            ],
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          tabBuilder: (context, index) {
            return CupertinoTabView(
              builder: (context) => _screens[index],
            );
          },
        );
      },
    );
  }

  Widget _buildTabIcon(IconData icon, IconData activeIcon, int index, {int badgeCount = 0}) {
    final isActive = _currentIndex == index;
    
    Widget iconWidget = Icon(
      isActive ? activeIcon : icon,
      size: 24,
    );

    if (badgeCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppConstants.errorColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return iconWidget;
  }
}
