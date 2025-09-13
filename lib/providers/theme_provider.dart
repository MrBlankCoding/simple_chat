import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  late AppThemeData _currentTheme;
  
  ThemeProvider() {
    _updateCurrentTheme();
    _loadThemeFromPreferences();
  }
  
  ThemeMode get themeMode => _themeMode;
  AppThemeData get currentTheme => _currentTheme;
  bool get isDarkMode => _currentTheme.isDark;
  
  void _updateCurrentTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        _currentTheme = AppThemeData.light;
        break;
      case ThemeMode.dark:
        _currentTheme = AppThemeData.dark;
        break;
      case ThemeMode.system:
        // Get system brightness
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _currentTheme = brightness == Brightness.dark ? AppThemeData.dark : AppThemeData.light;
        break;
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    _updateCurrentTheme();
    notifyListeners();
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }
  
  Future<void> _loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeKey);
      
      if (themeModeString != null) {
        final mode = ThemeMode.values.firstWhere(
          (e) => e.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
        
        _themeMode = mode;
        _updateCurrentTheme();
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, keep default system theme
      print('Failed to load theme preference: $e');
    }
  }
  
  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        // If system mode, toggle to opposite of current system theme
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        setThemeMode(brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
        break;
    }
  }
  
  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
