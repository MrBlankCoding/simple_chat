import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common/profile_image_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        final user = authProvider.currentUser;
        final theme = themeProvider.currentTheme;
        
        if (user == null) {
          return CupertinoPageScaffold(
            backgroundColor: theme.backgroundColor,
            child: Center(
              child: Text('Not authenticated', style: TextStyle(color: theme.textPrimary)),
            ),
          );
        }

        return CupertinoPageScaffold(
          backgroundColor: theme.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.backgroundColor,
            border: null,
            middle: Text(AppStrings.profile, style: TextStyle(color: theme.textPrimary)),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pushNamed('/edit-profile');
              },
              child: Text(
                'Edit',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Profile Image
                  ProfileImagePicker(
                    currentImageUrl: authProvider.currentUser?.profileImageUrl,
                    onImageSelected: (image) async {
                      if (image != null) {
                        await authProvider.updateProfile(profileImage: image);
                        if (authProvider.error != null) {
                          _showErrorDialog(context, authProvider.error!);
                        }
                      }
                    },
                    size: 80,
                  ),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // User Name
                  Text(
                    user.name,
                    style: AppConstants.titleMedium.copyWith(
                      color: theme.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  // User Email
                  Text(
                    user.email,
                    style: AppConstants.bodyMedium.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingXLarge),
                  
                  // Profile Options
                  _buildProfileSection(context, theme, [
                    _ProfileOption(
                      icon: CupertinoIcons.person_circle,
                      title: AppStrings.editProfile,
                      onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/edit-profile'),
                    ),
                    _ProfileOption(
                      icon: CupertinoIcons.bell,
                      title: AppStrings.notifications,
                      onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/notifications'),
                    ),
                    _ProfileOption(
                      icon: CupertinoIcons.lock,
                      title: AppStrings.privacy,
                      onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/privacy'),
                    ),
                  ]),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // App Options
                  _buildProfileSection(context, theme, [
                    _ProfileOption(
                      icon: CupertinoIcons.paintbrush,
                      title: 'Appearance',
                      onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/theme-settings'),
                    ),
                    _ProfileOption(
                      icon: CupertinoIcons.info_circle,
                      title: AppStrings.about,
                      onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/about'),
                    ),
                  ]),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: theme.errorColor,
                      onPressed: () => _showSignOutDialog(context, authProvider, theme),
                      child: const Text(
                        AppStrings.signOut,
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(BuildContext context, theme, List<_ProfileOption> options) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        children: options.map((option) {
          final isLast = option == options.last;
          return Column(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingMedium,
                ),
                onPressed: option.onTap,
                child: Row(
                  children: [
                    Icon(
                      option.icon,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Text(
                        option.title,
                        style: AppConstants.bodyLarge.copyWith(
                          color: theme.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: theme.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(left: 56),
                  height: 1,
                  color: theme.borderColor,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Error', style: TextStyle(color: theme.textPrimary)),
        content: Text(error, style: TextStyle(color: theme.textSecondary)),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: theme.primaryColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider, theme) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Sign Out', style: TextStyle(color: theme.textPrimary)),
        content: Text('Are you sure you want to sign out?', style: TextStyle(color: theme.textSecondary)),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: TextStyle(color: theme.primaryColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/welcome',
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
