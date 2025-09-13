import 'package:intl/intl.dart';

class AppHelpers {
  // Date and Time Formatting
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(timestamp);
    } else {
      // Older - show date
      return DateFormat('MMM d').format(timestamp);
    }
  }
  
  static String formatMessageTime(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }
  
  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(lastSeen);
    }
  }
  
  // Text Validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 8 && 
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[a-z]')) &&
           password.contains(RegExp(r'[0-9]')) &&
           password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!isValidPassword(value)) {
      return 'Password must contain uppercase, lowercase, number and special character';
    }
    return null;
  }
  
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }
  
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
  
  // String Utilities
  static String getInitials(String name) {
    List<String> names = name.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    } else {
      return (names[0].substring(0, 1) + names[1].substring(0, 1)).toUpperCase();
    }
  }
  
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  // Image Utilities
  static String getImageUrl(String? imageUrl) {
    return imageUrl ?? '';
  }
  
  // Chat Utilities
  static String getChatTitle(List<String> participants, String currentUserId, Map<String, String> userNames) {
    if (participants.length == 2) {
      // Direct chat - return other user's name
      final otherUserId = participants.firstWhere((id) => id != currentUserId);
      return userNames[otherUserId] ?? 'Unknown User';
    } else {
      // Group chat - return comma-separated names (excluding current user)
      final otherUsers = participants.where((id) => id != currentUserId).toList();
      final names = otherUsers.map((id) => userNames[id] ?? 'Unknown').toList();
      if (names.length <= 3) {
        return names.join(', ');
      } else {
        return '${names.take(2).join(', ')} and ${names.length - 2} others';
      }
    }
  }
  
  static String getLastMessagePreview(String? lastMessage) {
    if (lastMessage == null || lastMessage.isEmpty) {
      return 'No messages yet';
    }
    return truncateText(lastMessage, 50);
  }
  
  // Error Handling
  static String getErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (error.toString().contains('permission')) {
      return 'Permission denied. Please try again.';
    } else if (error.toString().contains('not-found')) {
      return 'User not found.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
}
