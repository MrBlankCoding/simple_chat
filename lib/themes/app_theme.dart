import 'package:flutter/cupertino.dart';

enum ThemeMode { light, dark, system }

class AppTheme {
  // Light Theme Colors
  static const Color lightPrimaryColor = CupertinoColors.systemBlue;
  static const Color lightSecondaryColor = CupertinoColors.systemGrey;
  static const Color lightBackgroundColor = CupertinoColors.systemBackground;
  static const Color lightSurfaceColor = CupertinoColors.systemGroupedBackground;
  static const Color lightCardColor = CupertinoColors.secondarySystemBackground;
  static const Color lightTextPrimary = CupertinoColors.label;
  static const Color lightTextSecondary = CupertinoColors.secondaryLabel;
  static const Color lightBorderColor = CupertinoColors.separator;
  
  // Dark Theme Colors
  static const Color darkPrimaryColor = CupertinoColors.systemBlue;
  static const Color darkSecondaryColor = CupertinoColors.systemGrey;
  static const Color darkBackgroundColor = CupertinoColors.black;
  static const Color darkSurfaceColor = CupertinoColors.systemGrey6;
  static const Color darkCardColor = CupertinoColors.systemGrey5;
  static const Color darkTextPrimary = CupertinoColors.white;
  static const Color darkTextSecondary = CupertinoColors.systemGrey2;
  static const Color darkBorderColor = CupertinoColors.systemGrey4;
  
  // Common Colors (same for both themes)
  static const Color errorColor = CupertinoColors.systemRed;
  static const Color successColor = CupertinoColors.systemGreen;
  static const Color warningColor = CupertinoColors.systemOrange;
  
  // Message Bubble Colors
  static const Color lightSentMessageColor = CupertinoColors.systemBlue;
  static const Color lightReceivedMessageColor = CupertinoColors.systemGrey5;
  static const Color darkSentMessageColor = CupertinoColors.systemBlue;
  static const Color darkReceivedMessageColor = CupertinoColors.systemGrey4;
  
  // Online Status Colors
  static const Color onlineColor = CupertinoColors.systemGreen;
  static const Color offlineColor = CupertinoColors.systemGrey3;
}

class AppThemeData {
  final bool isDark;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color sentMessageColor;
  final Color receivedMessageColor;
  final Color errorColor;
  final Color successColor;
  final Color warningColor;
  final Color onlineColor;
  final Color offlineColor;
  
  const AppThemeData({
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.sentMessageColor,
    required this.receivedMessageColor,
    required this.errorColor,
    required this.successColor,
    required this.warningColor,
    required this.onlineColor,
    required this.offlineColor,
  });
  
  static const AppThemeData light = AppThemeData(
    isDark: false,
    primaryColor: AppTheme.lightPrimaryColor,
    secondaryColor: AppTheme.lightSecondaryColor,
    backgroundColor: AppTheme.lightBackgroundColor,
    surfaceColor: AppTheme.lightSurfaceColor,
    cardColor: AppTheme.lightCardColor,
    textPrimary: AppTheme.lightTextPrimary,
    textSecondary: AppTheme.lightTextSecondary,
    borderColor: AppTheme.lightBorderColor,
    sentMessageColor: AppTheme.lightSentMessageColor,
    receivedMessageColor: AppTheme.lightReceivedMessageColor,
    errorColor: AppTheme.errorColor,
    successColor: AppTheme.successColor,
    warningColor: AppTheme.warningColor,
    onlineColor: AppTheme.onlineColor,
    offlineColor: AppTheme.offlineColor,
  );
  
  static const AppThemeData dark = AppThemeData(
    isDark: true,
    primaryColor: AppTheme.darkPrimaryColor,
    secondaryColor: AppTheme.darkSecondaryColor,
    backgroundColor: AppTheme.darkBackgroundColor,
    surfaceColor: AppTheme.darkSurfaceColor,
    cardColor: AppTheme.darkCardColor,
    textPrimary: AppTheme.darkTextPrimary,
    textSecondary: AppTheme.darkTextSecondary,
    borderColor: AppTheme.darkBorderColor,
    sentMessageColor: AppTheme.darkSentMessageColor,
    receivedMessageColor: AppTheme.darkReceivedMessageColor,
    errorColor: AppTheme.errorColor,
    successColor: AppTheme.successColor,
    warningColor: AppTheme.warningColor,
    onlineColor: AppTheme.onlineColor,
    offlineColor: AppTheme.offlineColor,
  );
  
  // Helper method to get CupertinoThemeData
  CupertinoThemeData get cupertinoThemeData {
    return CupertinoThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      barBackgroundColor: surfaceColor,
      textTheme: CupertinoTextThemeData(
        primaryColor: textPrimary,
        textStyle: TextStyle(color: textPrimary),
      ),
    );
  }
}
