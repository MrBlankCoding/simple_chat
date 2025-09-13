import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

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
        title: const Text('Sign In Failed'),
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
              middle: Text(AppStrings.signIn),
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
                      
                      // Welcome Back Text
                      Text(
                        'Welcome Back',
                        style: AppConstants.titleMedium.copyWith(
                          color: CupertinoColors.label,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      Text(
                        'Sign in to continue to your account',
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
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _signIn(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                },
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
                      
                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.of(context).pushNamed('/forgot-password');
                          },
                          child: Text(
                            AppStrings.forgotPassword,
                            style: AppConstants.bodyMedium.copyWith(
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      // Sign In Button
                      CupertinoButton.filled(
                        onPressed: authProvider.isLoading ? null : _signIn,
                        child: const Text(
                          AppStrings.signIn,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Sign Up Link
                      CupertinoButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/register');
                        },
                        child: RichText(
                          text: TextSpan(
                            style: AppConstants.bodyMedium.copyWith(
                              color: CupertinoColors.secondaryLabel,
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: AppStrings.createAccount,
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
