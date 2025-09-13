import 'package:flutter/cupertino.dart';
import '../../utils/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppConstants.backgroundColor,
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
                  color: CupertinoColors.label,
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // App Description
              Text(
                'Connect with friends and family\nthrough secure messaging',
                textAlign: TextAlign.center,
                style: AppConstants.bodyLarge.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
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
                      color: CupertinoColors.secondaryLabel,
                    ),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: AppStrings.signUp,
                        style: const TextStyle(
                          color: AppConstants.primaryColor,
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
  }
}
