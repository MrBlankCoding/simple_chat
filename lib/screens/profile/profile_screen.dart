import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common/profile_image_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        if (user == null) {
          return const CupertinoPageScaffold(
            child: Center(
              child: Text('Not authenticated'),
            ),
          );
        }

        return CupertinoPageScaffold(
          backgroundColor: AppConstants.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: AppConstants.backgroundColor,
            border: null,
            middle: const Text(AppStrings.profile),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).pushNamed('/edit-profile');
              },
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: AppConstants.primaryColor,
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
                      color: CupertinoColors.label,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  // User Email
                  Text(
                    user.email,
                    style: AppConstants.bodyMedium.copyWith(
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingXLarge),
                  
                  // Profile Options
                  _buildProfileSection(context, [
                    _ProfileOption(
                      icon: CupertinoIcons.person_circle,
                      title: AppStrings.editProfile,
                      onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
                    ),
                    _ProfileOption(
                      icon: CupertinoIcons.bell,
                      title: AppStrings.notifications,
                      onTap: () => Navigator.of(context).pushNamed('/notifications'),
                    ),
                    _ProfileOption(
                      icon: CupertinoIcons.lock,
                      title: AppStrings.privacy,
                      onTap: () => Navigator.of(context).pushNamed('/privacy'),
                    ),
                  ]),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // App Options
                  _buildProfileSection(context, [
                    _ProfileOption(
                      icon: CupertinoIcons.info_circle,
                      title: AppStrings.about,
                      onTap: () => Navigator.of(context).pushNamed('/about'),
                    ),
                  ]),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppConstants.errorColor,
                      onPressed: () => _showSignOutDialog(context, authProvider),
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

  Widget _buildProfileSection(BuildContext context, List<_ProfileOption> options) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
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
                      color: AppConstants.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Text(
                        option.title,
                        style: AppConstants.bodyLarge.copyWith(
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      color: CupertinoColors.secondaryLabel,
                      size: 16,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(left: 56),
                  height: 1,
                  color: CupertinoColors.separator,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
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
