import 'package:flutter/cupertino.dart';
import '../../utils/constants.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: CupertinoColors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CupertinoActivityIndicator(
                      radius: 15,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppConstants.paddingMedium),
                      Text(
                        message!,
                        style: AppConstants.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
