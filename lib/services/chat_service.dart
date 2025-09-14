import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  final ImagePicker _imagePicker = ImagePicker();

  // Get or create direct chat between two users
  Future<String> getOrCreateDirectChat(String otherUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if direct chat already exists
      String? existingChatId = await _firestoreService.getDirectChatId(
        currentUserId,
        otherUserId,
      );

      if (existingChatId != null) {
        return existingChatId;
      }

      // Create new direct chat
      return await _firestoreService.createChat([currentUserId, otherUserId]);
    } catch (e) {
      throw Exception('Failed to get or create chat: ${e.toString()}');
    }
  }

  // Create group chat
  Future<String> createGroupChat(List<String> participantIds, String groupName) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Add current user to participants if not already included
      if (!participantIds.contains(currentUserId)) {
        participantIds.add(currentUserId);
      }

      return await _firestoreService.createChat(
        participantIds,
        isGroup: true,
        groupName: groupName,
      );
    } catch (e) {
      throw Exception('Failed to create group chat: ${e.toString()}');
    }
  }

  // Send text message
  Future<void> sendTextMessage(String chatId, String text, {String? replyToMessageId}) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (text.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      await _firestoreService.sendMessage(
        chatId: chatId,
        senderId: currentUserId,
        text: text.trim(),
        type: MessageType.text,
        replyToMessageId: replyToMessageId,
      );
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  // Send image message
  Future<void> sendImageMessage(String chatId, XFile imageFile) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Compress and upload image
      final imageUrl = await _uploadImage(imageFile, 'chat_images');

      await _firestoreService.sendMessage(
        chatId: chatId,
        senderId: currentUserId,
        text: 'Photo',
        type: MessageType.image,
        imageUrl: imageUrl,
      );
    } catch (e) {
      throw Exception('Failed to send image: ${e.toString()}');
    }
  }

  // Pick and send image
  Future<void> pickAndSendImage(String chatId, ImageSource source) async {
    try {
      final XFile? imageFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (imageFile != null) {
        await sendImageMessage(chatId, imageFile);
      }
    } catch (e) {
      throw Exception('Failed to pick and send image: ${e.toString()}');
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(XFile imageFile, String folder) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // Compress image
      final compressedBytes = await _compressImage(bytes);
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final ref = _storage.ref().child(folder).child(fileName);
      
      final uploadTask = ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  // Compress image
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Resize if too large
      img.Image resized = image;
      if (image.width > 1024 || image.height > 1024) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1024 : null,
          height: image.height > image.width ? 1024 : null,
        );
      }

      // Compress to JPEG with quality 80
      final compressedBytes = img.encodeJpg(resized, quality: 80);
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      return bytes; // Return original if compression fails
    }
  }

  // Get chat messages stream
  Stream<List<Message>> getChatMessages(String chatId) {
    return _firestoreService.getChatMessages(chatId);
  }

  // Get user chats stream
  Stream<List<Chat>> getUserChats() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return _firestoreService.getUserChats(currentUserId);
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestoreService.markMessagesAsRead(chatId, currentUserId);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  // Get chat participants info
  Future<Map<String, UserModel>> getChatParticipants(Chat chat) async {
    try {
      return await _firestoreService.getUsersMap(chat.participants);
    } catch (e) {
      throw Exception('Failed to get chat participants: ${e.toString()}');
    }
  }

  // Get chat title for display
  Future<String> getChatTitle(Chat chat) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return 'Unknown Chat';

      if (chat.isGroup) {
        return chat.groupName ?? 'Group Chat';
      } else {
        final otherUserId = chat.getOtherParticipant(currentUserId);
        if (otherUserId != null) {
          final user = await _firestoreService.getUserById(otherUserId);
          return user?.name ?? 'Unknown User';
        }
        return 'Direct Chat';
      }
    } catch (e) {
      return 'Unknown Chat';
    }
  }

  // Delete message (for sender only)
  Future<void> deleteMessage(String messageId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestoreService.deleteMessage(messageId, currentUserId);
    } catch (e) {
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  // Edit message (for sender only)
  Future<void> editMessage(String messageId, String newText) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (newText.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      await _firestoreService.editMessage(messageId, newText.trim(), currentUserId);
    } catch (e) {
      throw Exception('Failed to edit message: ${e.toString()}');
    }
  }

  // Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestoreService.addReaction(messageId, emoji, currentUserId);
    } catch (e) {
      throw Exception('Failed to add reaction: ${e.toString()}');
    }
  }

  // Remove reaction from message
  Future<void> removeReaction(String messageId, String emoji) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestoreService.removeReaction(messageId, emoji, currentUserId);
    } catch (e) {
      throw Exception('Failed to remove reaction: ${e.toString()}');
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestoreService.deleteChat(chatId, currentUserId);
    } catch (e) {
      throw Exception('Failed to delete chat: ${e.toString()}');
    }
  }

  // Pin/unpin chat
  Future<void> pinChat(String chatId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestoreService.pinChat(chatId, currentUserId);
    } catch (e) {
      throw Exception('Failed to pin chat: ${e.toString()}');
    }
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestoreService.markChatAsRead(chatId, currentUserId);
    } catch (e) {
      throw Exception('Failed to mark chat as read: ${e.toString()}');
    }
  }

  // Get unread message count for all chats
  Future<int> getTotalUnreadCount() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return 0;

      final chats = await _firestoreService.getUserChats(currentUserId).first;
      int totalUnread = 0;

      for (final chat in chats) {
        totalUnread += chat.getUnreadCount(currentUserId);
      }

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }
}
