import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        
        return CupertinoPageScaffold(
          backgroundColor: theme.backgroundColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                children: [
              const Spacer(flex: 2),
              
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                ),
                child: const Icon(
                  CupertinoIcons.chat_bubble_2_fill,
                  size: 60,
                  color: CupertinoColors.white,
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingXLarge),
              
              // App Name
              Text(
                AppConstants.appName,
                style: AppConstants.titleLarge.copyWith(
                  color: theme.textPrimary,
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // App Description
              Text(
                'Connect with friends and family\nthrough secure messaging',
                textAlign: TextAlign.center,
                style: AppConstants.bodyLarge.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  color: theme.primaryColor,
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: const Text(
                    AppStrings.getStarted,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Sign Up Link
              CupertinoButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/register');
                },
                child: RichText(
                  text: TextSpan(
                    style: AppConstants.bodyMedium.copyWith(
                      color: theme.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: AppStrings.signUp,
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
