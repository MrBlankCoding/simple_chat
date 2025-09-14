import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  system,
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final List<String> readBy;
  final MessageType type;
  final String? imageUrl;
  final bool isEdited;
  final DateTime? editedAt;
  final Map<String, List<String>> reactions;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;
  final bool isDeleted;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.readBy = const [],
    this.type = MessageType.text,
    this.imageUrl,
    this.isEdited = false,
    this.editedAt,
    this.reactions = const {},
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.isDeleted = false,
  });

  // Convert Message to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'reactions': reactions,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderId': replyToSenderId,
      'isDeleted': isDeleted,
    };
  }

  // Convert Message to Map for JSON serialization (cache)
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'readBy': readBy,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'isEdited': isEdited,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'reactions': reactions,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderId': replyToSenderId,
      'isDeleted': isDeleted,
    };
  }

  // Create Message from Firestore document
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(map['readBy'] ?? []),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.text,
      ),
      imageUrl: map['imageUrl'],
      isEdited: map['isEdited'] ?? false,
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
      reactions: Map<String, List<String>>.from(
        (map['reactions'] ?? {}).map(
          (key, value) => MapEntry(key.toString(), List<String>.from(value ?? [])),
        ),
      ),
      replyToMessageId: map['replyToMessageId'],
      replyToText: map['replyToText'],
      replyToSenderId: map['replyToSenderId'],
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  // Create Message from JSON Map (cache)
  factory Message.fromJsonMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      readBy: List<String>.from(map['readBy'] ?? []),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.text,
      ),
      imageUrl: map['imageUrl'],
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
      reactions: Map<String, List<String>>.from(
        (map['reactions'] ?? {}).map(
          (key, value) => MapEntry(key.toString(), List<String>.from(value ?? [])),
        ),
      ),
      replyToMessageId: map['replyToMessageId'],
      replyToText: map['replyToText'],
      replyToSenderId: map['replyToSenderId'],
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  // Create Message from Firestore DocumentSnapshot
  factory Message.fromDocument(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    
    // Safe type casting for web compatibility
    Map<String, dynamic> safeData;
    try {
      if (data is Map<String, dynamic>) {
        safeData = data;
      } else {
        // Handle LegacyJavaScriptObject case - convert to Map first
        final Map<dynamic, dynamic> rawMap = data as Map<dynamic, dynamic>;
        safeData = <String, dynamic>{};
        rawMap.forEach((key, value) {
          safeData[key.toString()] = value;
        });
      }
    } catch (e) {
      // Fallback: try to extract data manually
      safeData = {
        'id': doc.id,
        'chatId': '',
        'senderId': '',
        'text': '',
        'timestamp': Timestamp.now(),
        'readBy': <String>[],
        'type': 'text',
        'imageUrl': null,
        'isEdited': false,
        'editedAt': null,
        'reactions': <String, List<String>>{},
        'replyToMessageId': null,
        'replyToText': null,
        'replyToSenderId': null,
        'isDeleted': false,
      };
    }
    
    return Message.fromMap(safeData);
  }

  // Create a copy of Message with updated fields
  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    List<String>? readBy,
    MessageType? type,
    String? imageUrl,
    bool? isEdited,
    DateTime? editedAt,
    Map<String, List<String>>? reactions,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    bool? isDeleted,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      readBy: readBy ?? this.readBy,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Check if message is read by specific user
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  // Mark message as read by user
  Message markAsRead(String userId) {
    if (readBy.contains(userId)) return this;
    
    final updatedReadBy = List<String>.from(readBy)..add(userId);
    return copyWith(readBy: updatedReadBy);
  }

  // Check if message is from current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  // Add reaction to message
  Message addReaction(String emoji, String userId) {
    final updatedReactions = Map<String, List<String>>.from(reactions);
    if (updatedReactions.containsKey(emoji)) {
      if (!updatedReactions[emoji]!.contains(userId)) {
        updatedReactions[emoji] = [...updatedReactions[emoji]!, userId];
      }
    } else {
      updatedReactions[emoji] = [userId];
    }
    return copyWith(reactions: updatedReactions);
  }

  // Remove reaction from message
  Message removeReaction(String emoji, String userId) {
    final updatedReactions = Map<String, List<String>>.from(reactions);
    if (updatedReactions.containsKey(emoji)) {
      updatedReactions[emoji]!.remove(userId);
      if (updatedReactions[emoji]!.isEmpty) {
        updatedReactions.remove(emoji);
      }
    }
    return copyWith(reactions: updatedReactions);
  }

  // Check if user has reacted with specific emoji
  bool hasUserReacted(String emoji, String userId) {
    return reactions[emoji]?.contains(userId) ?? false;
  }

  // Get total reaction count for emoji
  int getReactionCount(String emoji) {
    return reactions[emoji]?.length ?? 0;
  }

  // Check if message is a reply
  bool get isReply => replyToMessageId != null;

  // Check if message can be edited (only by sender and within time limit)
  bool canEdit(String currentUserId) {
    if (senderId != currentUserId || isDeleted) return false;
    final timeDiff = DateTime.now().difference(timestamp);
    return timeDiff.inMinutes <= 15; // 15 minute edit window
  }

  // Check if message can be deleted (only by sender)
  bool canDelete(String currentUserId) {
    return senderId == currentUserId && !isDeleted;
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, text: $text, type: $type, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
