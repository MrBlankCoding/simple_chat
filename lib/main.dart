import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/connectivity_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/main_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/new_chat_screen.dart';
import 'screens/friends/search_users_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/notifications_screen.dart';
import 'screens/profile/privacy_screen.dart';
import 'screens/profile/theme_settings_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  try {
    await NotificationService().initialize();
  } catch (e) {
    print('Failed to initialize notifications: $e');
  }
  
  // Initialize connectivity service
  try {
    await ConnectivityService().initialize();
  } catch (e) {
    print('Failed to initialize connectivity service: $e');
  }
  
  runApp(const SimpleChat());
}

class SimpleChat extends StatelessWidget {
  const SimpleChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          return CupertinoApp(
            title: AppConstants.appName,
            theme: themeProvider.currentTheme.cupertinoThemeData,
            home: _buildHome(authProvider),
            routes: {
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/main': (context) => const MainScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle routes with arguments
              switch (settings.name) {
                case '/chat':
                  final args = settings.arguments as Map<String, dynamic>?;
                  final chatId = args?['chatId'] as String?;
                  if (chatId != null) {
                    return CupertinoPageRoute(
                      builder: (context) => ChatScreen(chatId: chatId),
                    );
                  }
                  break;
                case '/search-users':
                  return CupertinoPageRoute(
                    builder: (context) => const SearchUsersScreen(),
                  );
                case '/new-chat':
                  return CupertinoPageRoute(
                    builder: (context) => const NewChatScreen(),
                  );
                case '/edit-profile':
                  return CupertinoPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  );
                case '/notifications':
                  return CupertinoPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  );
                case '/privacy':
                  return CupertinoPageRoute(
                    builder: (context) => const PrivacyScreen(),
                  );
                case '/theme-settings':
                  return CupertinoPageRoute(
                    builder: (context) => const ThemeSettingsScreen(),
                  );
              }
              return null;
            },
          );
        },
      ),
    );
  }

  Widget _buildHome(AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
      return const MainScreen();
    } else {
      return const WelcomeScreen();
    }
  }
}
