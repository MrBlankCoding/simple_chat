import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/profile_image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _selectedProfileImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Handle profile image upload through AuthProvider
    String? profileImageUrl;
    if (_selectedProfileImage != null) {
      // The AuthProvider will handle the upload during user creation
      // We'll pass the image file directly
    }
    
    final success = await authProvider.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      profileImageUrl: profileImageUrl,
    );
    
    // If user was created successfully and we have a profile image, update it
    if (success && _selectedProfileImage != null && mounted) {
      await authProvider.updateProfile(profileImage: _selectedProfileImage);
    }

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else if (mounted && authProvider.error != null) {
      _showErrorDialog(authProvider.error!);
    }
  }

  void _showErrorDialog(String error) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Registration Failed'),
        content: Text(error),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).clearError();
            },
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
            backgroundColor: AppConstants.backgroundColor,
            navigationBar: const CupertinoNavigationBar(
              backgroundColor: AppConstants.backgroundColor,
              border: null,
              middle: Text(AppStrings.createAccount),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Welcome Text
                      Text(
                        'Create Account',
                        style: AppConstants.titleMedium.copyWith(
                          color: CupertinoColors.label,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      Text(
                        'Join SimpleChat to connect with friends',
                        style: AppConstants.bodyMedium.copyWith(
                          color: CupertinoColors.secondaryLabel,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      // Profile Image Picker
                      Center(
                        child: ProfileImagePicker(
                          onImageSelected: (image) {
                            setState(() {
                              _selectedProfileImage = image;
                            });
                          },
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      // Name Field
                      CupertinoTextFormFieldRow(
                        controller: _nameController,
                        placeholder: AppStrings.name,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: AppHelpers.validateName,
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium,
                          vertical: AppConstants.paddingMedium,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      // Email Field
                      CupertinoTextFormFieldRow(
                        controller: _emailController,
                        placeholder: AppStrings.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: AppHelpers.validateEmail,
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium,
                          vertical: AppConstants.paddingMedium,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      // Password Field
                      Container(
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CupertinoTextFormFieldRow(
                                controller: _passwordController,
                                placeholder: AppStrings.password,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                validator: AppHelpers.validatePassword,
                                decoration: const BoxDecoration(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.paddingMedium,
                                  vertical: AppConstants.paddingMedium,
                                ),
                              ),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.only(right: AppConstants.paddingMedium),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: Icon(
                                _obscurePassword 
                                  ? CupertinoIcons.eye 
                                  : CupertinoIcons.eye_slash,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      // Confirm Password Field
                      Container(
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CupertinoTextFormFieldRow(
                                controller: _confirmPasswordController,
                                placeholder: AppStrings.confirmPassword,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _signUp(),
                                validator: (value) => AppHelpers.validateConfirmPassword(
                                  value, 
                                  _passwordController.text,
                                ),
                                decoration: const BoxDecoration(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.paddingMedium,
                                  vertical: AppConstants.paddingMedium,
                                ),
                              ),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.only(right: AppConstants.paddingMedium),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                              child: Icon(
                                _obscureConfirmPassword 
                                  ? CupertinoIcons.eye 
                                  : CupertinoIcons.eye_slash,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      // Sign Up Button
                      CupertinoButton.filled(
                        onPressed: authProvider.isLoading ? null : _signUp,
                        child: const Text(
                          AppStrings.createAccount,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      // Sign In Link
                      CupertinoButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: RichText(
                          text: TextSpan(
                            style: AppConstants.bodyMedium.copyWith(
                              color: CupertinoColors.secondaryLabel,
                            ),
                            children: [
                              const TextSpan(text: "Already have an account? "),
                              TextSpan(
                                text: AppStrings.signIn,
                                style: const TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
