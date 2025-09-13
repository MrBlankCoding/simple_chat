import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
    Clipboard.setData(ClipboardData(text: text));
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('$label Copied'),
        content: Text('$label has been copied to clipboard.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('About'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: AppConstants.paddingLarge),
            
            // App Icon and Name
            const Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    size: 80,
                    color: CupertinoColors.activeBlue,
                  ),
                  SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'SimpleChat',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // App Information
            CupertinoFormSection.insetGrouped(
              header: const Text('APP INFORMATION'),
              children: [
                const CupertinoFormRow(
                  prefix: Text('Version'),
                  child: Text(
                    '1.0.0',
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                ),
                const CupertinoFormRow(
                  prefix: Text('Build'),
                  child: Text(
                    '1',
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Developer'),
                  child: GestureDetector(
                    onTap: () => _copyToClipboard(context, 'SimpleChat Team', 'Developer'),
                    child: const Text(
                      'SimpleChat Team',
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                  ),
                ),
              ],
            ),
            
            // Legal
            CupertinoFormSection.insetGrouped(
              header: const Text('LEGAL'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Privacy Policy'),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('View'),
                    onPressed: () async {
                      try {
                        await _launchURL('https://simplechat.com/privacy');
                      } catch (e) {
                        if (context.mounted) {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Error'),
                              content: const Text('Could not open privacy policy. Please visit simplechat.com/privacy'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
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
                  prefix: const Text('Terms of Service'),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('View'),
                    onPressed: () async {
                      try {
                        await _launchURL('https://simplechat.com/terms');
                      } catch (e) {
                        if (context.mounted) {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Error'),
                              content: const Text('Could not open terms of service. Please visit simplechat.com/terms'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
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
                  prefix: const Text('Open Source Licenses'),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('View'),
                    onPressed: () => _showLicenses(context),
                  ),
                ),
              ],
            ),
            
            // Support
            CupertinoFormSection.insetGrouped(
              header: const Text('SUPPORT'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Contact Support'),
                  child: GestureDetector(
                    onTap: () => _copyToClipboard(context, 'support@simplechat.com', 'Email'),
                    child: const Text(
                      'support@simplechat.com',
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Rate App'),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Rate on App Store'),
                    onPressed: () async {
                      try {
                        await _launchURL('https://apps.apple.com/app/id123456789?action=write-review');
                      } catch (e) {
                        if (context.mounted) {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Error'),
                              content: const Text('Could not open App Store. Please search for SimpleChat in the App Store.'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
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
                  prefix: const Text('Share App'),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Share'),
                    onPressed: () async {
                      await _shareApp();
                      if (context.mounted) {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('App Link Copied'),
                            content: const Text('The app link has been copied to your clipboard. You can now paste it to share SimpleChat with others!'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('OK'),
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
                  color: CupertinoColors.secondaryLabel,
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
                  color: CupertinoColors.tertiaryLabel,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
