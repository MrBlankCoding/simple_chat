import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Profile Updated'),
        content: const Text('Your profile has been updated successfully.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          child: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('Edit Profile'),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _hasChanges ? _saveProfile : null,
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: _hasChanges ? FontWeight.w600 : FontWeight.normal,
                    color: _hasChanges ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray,
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
                      header: const Text('PROFILE INFORMATION'),
                      children: [
                        CupertinoTextFormFieldRow(
                          controller: _nameController,
                          prefix: const Text('Name'),
                          placeholder: 'Enter your name',
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
                          prefix: const Text('Email'),
                          enabled: false,
                          style: const TextStyle(
                            color: CupertinoColors.inactiveGray,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    // Account Information
                    CupertinoFormSection.insetGrouped(
                      header: const Text('ACCOUNT'),
                      children: [
                        CupertinoFormRow(
                          prefix: const Text('Member Since'),
                          child: Text(
                            authProvider.currentUser?.createdAt != null
                                ? '${authProvider.currentUser!.createdAt.day}/${authProvider.currentUser!.createdAt.month}/${authProvider.currentUser!.createdAt.year}'
                                : 'Unknown',
                            style: const TextStyle(
                              color: CupertinoColors.inactiveGray,
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
