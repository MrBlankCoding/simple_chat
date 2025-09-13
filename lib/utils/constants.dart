import 'package:flutter/cupertino.dart';

class AppConstants {
  // App Information
  static const String appName = 'SimpleChat';
  static const String appVersion = '1.0.0';
  
  // Colors
  static const Color primaryColor = CupertinoColors.systemBlue;
  static const Color secondaryColor = CupertinoColors.systemGrey;
  static const Color backgroundColor = CupertinoColors.systemBackground;
  static const Color surfaceColor = CupertinoColors.systemGroupedBackground;
  static const Color errorColor = CupertinoColors.systemRed;
  static const Color successColor = CupertinoColors.systemGreen;
  
  // Text Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: CupertinoColors.label,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: CupertinoColors.secondaryLabel,
  );
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  // Animation Durations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String friendRequestsCollection = 'friendRequests';
  static const String friendsCollection = 'friends';
  
  // Message Limits
  static const int messagesPerPage = 20;
  static const int maxMessageLength = 1000;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  
  // Profile Image
  static const double profileImageSize = 40.0;
  static const double profileImageSizeLarge = 80.0;
}

class AppStrings {
  // Authentication
  static const String welcome = 'Welcome to SimpleChat';
  static const String getStarted = 'Get Started';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String createAccount = 'Create Account';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String name = 'Name';
  static const String signOut = 'Sign Out';
  
  // Navigation
  static const String chats = 'Chats';
  static const String friends = 'Friends';
  static const String profile = 'Profile';
  
  // Friends
  static const String requests = 'Requests';
  static const String allFriends = 'All Friends';
  static const String searchUsers = 'Search Users';
  static const String sendRequest = 'Send Request';
  static const String accept = 'Accept';
  static const String decline = 'Decline';
  static const String online = 'Online';
  static const String offline = 'Offline';
  
  // Chat
  static const String typeMessage = 'Type a message...';
  static const String send = 'Send';
  static const String newChat = 'New Chat';
  static const String groupChat = 'Group Chat';
  
  // Profile
  static const String editProfile = 'Edit Profile';
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';
  static const String privacy = 'Privacy';
  static const String about = 'About';
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorPasswordTooShort = 'Password must be at least 8 characters.';
  static const String errorPasswordsNotMatch = 'Passwords do not match.';
  static const String errorNameTooLong = 'Name must be less than 50 characters.';
  static const String errorUserNotFound = 'User not found.';
  static const String errorPermissionDenied = 'Permission denied.';
  
  // Success Messages
  static const String successAccountCreated = 'Account created successfully!';
  static const String successPasswordReset = 'Password reset email sent!';
  static const String successProfileUpdated = 'Profile updated successfully!';
  static const String successFriendRequestSent = 'Friend request sent!';
  static const String successFriendAdded = 'Friend added successfully!';
}
