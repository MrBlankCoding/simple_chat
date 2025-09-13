import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _showLicenses(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const LicensePage(
          applicationName: 'SimpleChat',
          applicationVersion: '1.0.0',
          applicationIcon: Icon(
            CupertinoIcons.chat_bubble_2_fill,
            size: 64,
            color: CupertinoColors.activeBlue,
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    Clipboard.setData(ClipboardData(text: text));
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('$label Copied', style: TextStyle(color: theme.textPrimary)),
        content: Text('$label has been copied to clipboard.', style: TextStyle(color: theme.textSecondary)),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: theme.primaryColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Handle error - could show a dialog or copy URL to clipboard
      throw 'Could not launch $url';
    }
  }

  Future<void> _shareApp() async {
    const String appStoreUrl = 'https://apps.apple.com/app/simplechat';
    const String shareText = 'Check out SimpleChat - A modern, secure messaging app! $appStoreUrl';
    
    // Copy to clipboard as a simple sharing mechanism
    await Clipboard.setData(const ClipboardData(text: shareText));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        
        return CupertinoPageScaffold(
          backgroundColor: theme.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.backgroundColor,
            middle: Text(
              'About',
              style: TextStyle(color: theme.textPrimary),
            ),
          ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: AppConstants.paddingLarge),
            
            // App Icon and Name
            Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    size: 80,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'SimpleChat',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // App Information
            CupertinoFormSection.insetGrouped(
              backgroundColor: theme.cardColor,
              header: Text(
                'APP INFORMATION',
                style: TextStyle(color: theme.textSecondary),
              ),
              children: [
                CupertinoFormRow(
                  prefix: Text(
                    'Version',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: Text(
                    '1.0.0',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                ),
                CupertinoFormRow(
                  prefix: Text(
                    'Build',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                ),
                CupertinoFormRow(
                  prefix: Text(
                    'Developer',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: GestureDetector(
                    onTap: () => _copyToClipboard(context, 'SimpleChat Team', 'Developer'),
                    child: Text(
                      'SimpleChat Team',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
            
            // Legal
            CupertinoFormSection.insetGrouped(
              backgroundColor: theme.cardColor,
              header: Text(
                'LEGAL',
                style: TextStyle(color: theme.textSecondary),
              ),
              children: [
                CupertinoFormRow(
                  prefix: Text(
                    'Privacy Policy',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('View', style: TextStyle(color: theme.primaryColor)),
                    onPressed: () async {
                      try {
                        await _launchURL('https://simplechat.com/privacy');
                      } catch (e) {
                        if (context.mounted) {
                          final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: Text('Error', style: TextStyle(color: theme.textPrimary)),
                              content: Text('Could not open privacy policy. Please visit simplechat.com/privacy', style: TextStyle(color: theme.textSecondary)),
                              actions: [
                                CupertinoDialogAction(
                                  child: Text('OK', style: TextStyle(color: theme.primaryColor)),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                CupertinoFormRow(
                  prefix: Text(
                    'Terms of Service',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('View', style: TextStyle(color: theme.primaryColor)),
                    onPressed: () async {
                      try {
                        await _launchURL('https://simplechat.com/terms');
                      } catch (e) {
                        if (context.mounted) {
                          final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: Text('Error', style: TextStyle(color: theme.textPrimary)),
                              content: Text('Could not open terms of service. Please visit simplechat.com/terms', style: TextStyle(color: theme.textSecondary)),
                              actions: [
                                CupertinoDialogAction(
                                  child: Text('OK', style: TextStyle(color: theme.primaryColor)),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                CupertinoFormRow(
                  prefix: Text(
                    'Open Source Licenses',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('View', style: TextStyle(color: theme.primaryColor)),
                    onPressed: () => _showLicenses(context),
                  ),
                ),
              ],
            ),
            
            // Support
            CupertinoFormSection.insetGrouped(
              backgroundColor: theme.cardColor,
              header: Text(
                'SUPPORT',
                style: TextStyle(color: theme.textSecondary),
              ),
              children: [
                CupertinoFormRow(
                  prefix: Text(
                    'Contact Support',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: GestureDetector(
                    onTap: () => _copyToClipboard(context, 'support@simplechat.com', 'Email'),
                    child: Text(
                      'support@simplechat.com',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                ),
                CupertinoFormRow(
                  prefix: Text(
                    'Rate App',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('Rate on App Store', style: TextStyle(color: theme.primaryColor)),
                    onPressed: () async {
                      try {
                        await _launchURL('https://apps.apple.com/app/id123456789?action=write-review');
                      } catch (e) {
                        if (context.mounted) {
                          final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: Text('Error', style: TextStyle(color: theme.textPrimary)),
                              content: Text('Could not open App Store. Please search for SimpleChat in the App Store.', style: TextStyle(color: theme.textSecondary)),
                              actions: [
                                CupertinoDialogAction(
                                  child: Text('OK', style: TextStyle(color: theme.primaryColor)),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                CupertinoFormRow(
                  prefix: Text(
                    'Share App',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('Share', style: TextStyle(color: theme.primaryColor)),
                    onPressed: () async {
                      await _shareApp();
                      if (context.mounted) {
                        final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: Text('App Link Copied', style: TextStyle(color: theme.textPrimary)),
                            content: Text('The app link has been copied to your clipboard. You can now paste it to share SimpleChat with others!', style: TextStyle(color: theme.textSecondary)),
                            actions: [
                              CupertinoDialogAction(
                                child: Text('OK', style: TextStyle(color: theme.primaryColor)),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Description
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Text(
                'SimpleChat is a modern, secure messaging app built with Flutter and Firebase. Connect with friends, share moments, and stay in touch with beautiful, intuitive design.',
                style: AppConstants.body.copyWith(
                  color: theme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Copyright
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Text(
                '© 2024 SimpleChat Team. All rights reserved.',
                style: AppConstants.caption.copyWith(
                  color: theme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}
