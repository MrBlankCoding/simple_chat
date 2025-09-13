import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  // Log error for debugging
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('ERROR: $message');
      if (error != null) print('Error object: $error');
      if (stackTrace != null) print('Stack trace: $stackTrace');
    }
  }

  // Show error dialog
  void showErrorDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // Show error with retry option
  void showRetryDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onRetry,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Retry'),
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
          ),
        ],
      ),
    );
  }

  // Handle network errors
  String getNetworkErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check your account permissions.';
    } else if (errorString.contains('not found')) {
      return 'The requested resource was not found.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Handle Firebase errors
  String getFirebaseErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission-denied')) {
      return 'You don\'t have permission to perform this action.';
    } else if (errorString.contains('unavailable')) {
      return 'Service is temporarily unavailable. Please try again later.';
    } else if (errorString.contains('deadline-exceeded')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('already-exists')) {
      return 'This item already exists.';
    } else if (errorString.contains('not-found')) {
      return 'The requested item was not found.';
    } else {
      return 'A server error occurred. Please try again.';
    }
  }
}
