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

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, text: $text, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
