import 'package:flutter/cupertino.dart';
import '../../utils/constants.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      color: CupertinoColors.systemOrange.withOpacity(0.9),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.wifi_slash,
              size: 16,
              color: CupertinoColors.white,
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            Expanded(
              child: Text(
                'You\'re offline. Some features may be limited.',
                style: AppConstants.caption.copyWith(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: AppConstants.caption.copyWith(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
