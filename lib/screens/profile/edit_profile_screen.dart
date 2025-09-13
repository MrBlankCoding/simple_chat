import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/profile_image_picker.dart';
import '../../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _selectedImage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = authProvider.currentUser?.name ?? '';
    _nameController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _onImageSelected(File? image) {
    setState(() {
      _selectedImage = image;
      _hasChanges = true;
    });
  }

  void _onImageRemoved() {
    setState(() {
      _selectedImage = null;
      _hasChanges = true;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || !_hasChanges) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await authProvider.updateProfile(
      name: _nameController.text.trim(),
      profileImage: _selectedImage,
    );

    if (authProvider.error == null && mounted) {
      Navigator.of(context).pop();
      _showSuccessDialog();
    } else if (authProvider.error != null && mounted) {
      _showErrorDialog(authProvider.error!);
    }
  }

  void _showSuccessDialog() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Profile Updated', style: TextStyle(color: theme.textPrimary)),
        content: Text('Your profile has been updated successfully.', style: TextStyle(color: theme.textSecondary)),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: theme.primaryColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          child: CupertinoPageScaffold(
            backgroundColor: theme.backgroundColor,
            navigationBar: CupertinoNavigationBar(
              backgroundColor: theme.backgroundColor,
              middle: Text(
                'Edit Profile',
                style: TextStyle(color: theme.textPrimary),
              ),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text('Cancel', style: TextStyle(color: theme.primaryColor)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _hasChanges ? _saveProfile : null,
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: _hasChanges ? FontWeight.w600 : FontWeight.normal,
                    color: _hasChanges ? theme.primaryColor : theme.textSecondary,
                  ),
                ),
              ),
            ),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  children: [
                    // Profile Image Section
                    Center(
                      child: ProfileImagePicker(
                        currentImageUrl: authProvider.currentUser?.profileImageUrl,
                        selectedImage: _selectedImage,
                        onImageSelected: _onImageSelected,
                        onImageRemoved: _onImageRemoved,
                        size: 120,
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    // Name Field
                    CupertinoFormSection.insetGrouped(
                      backgroundColor: theme.cardColor,
                      header: Text(
                        'PROFILE INFORMATION',
                        style: TextStyle(color: theme.textSecondary),
                      ),
                      children: [
                        CupertinoTextFormFieldRow(
                          controller: _nameController,
                          prefix: Text(
                            'Name',
                            style: TextStyle(color: theme.textPrimary),
                          ),
                          placeholder: 'Enter your name',
                          style: TextStyle(color: theme.textPrimary),
                          placeholderStyle: TextStyle(color: theme.textSecondary),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        CupertinoTextFormFieldRow(
                          initialValue: authProvider.currentUser?.email ?? '',
                          prefix: Text(
                            'Email',
                            style: TextStyle(color: theme.textPrimary),
                          ),
                          enabled: false,
                          style: TextStyle(
                            color: theme.textSecondary,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    // Account Information
                    CupertinoFormSection.insetGrouped(
                      backgroundColor: theme.cardColor,
                      header: Text(
                        'ACCOUNT',
                        style: TextStyle(color: theme.textSecondary),
                      ),
                      children: [
                        CupertinoFormRow(
                          prefix: Text(
                            'Member Since',
                            style: TextStyle(color: theme.textPrimary),
                          ),
                          child: Text(
                            authProvider.currentUser?.createdAt != null
                                ? '${authProvider.currentUser!.createdAt.day}/${authProvider.currentUser!.createdAt.month}/${authProvider.currentUser!.createdAt.year}'
                                : 'Unknown',
                            style: TextStyle(
                              color: theme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
