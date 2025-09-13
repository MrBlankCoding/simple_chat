import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_overlay.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted && authProvider.error != null) {
      _showErrorDialog(authProvider.error!);
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reset Email Sent'),
        content: Text(
          'A password reset email has been sent to ${_emailController.text.trim()}. '
          'Please check your email and follow the instructions to reset your password.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to login
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reset Failed'),
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
              middle: Text(AppStrings.resetPassword),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      // Reset Password Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.lock_rotation,
                            size: 40,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      // Title
                      Text(
                        'Reset Password',
                        style: AppConstants.titleMedium.copyWith(
                          color: CupertinoColors.label,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      // Description
                      Text(
                        'Enter your email address and we\'ll send you a link to reset your password.',
                        style: AppConstants.bodyMedium.copyWith(
                          color: CupertinoColors.secondaryLabel,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      // Email Field
                      CupertinoTextFormFieldRow(
                        controller: _emailController,
                        placeholder: AppStrings.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _sendResetEmail(),
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
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      // Send Reset Email Button
                      CupertinoButton.filled(
                        onPressed: authProvider.isLoading ? null : _sendResetEmail,
                        child: const Text(
                          'Send Reset Email',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Back to Sign In Link
                      CupertinoButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: RichText(
                          text: TextSpan(
                            style: AppConstants.bodyMedium.copyWith(
                              color: CupertinoColors.secondaryLabel,
                            ),
                            children: [
                              const TextSpan(text: "Remember your password? "),
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
