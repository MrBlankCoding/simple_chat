import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final bool isGroup;
  final String? groupName;
  final String? groupImageUrl;
  final DateTime createdAt;
  final String createdBy;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = const {},
    this.isGroup = false,
    this.groupName,
    this.groupImageUrl,
    required this.createdAt,
    required this.createdBy,
  });

  // Convert Chat to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImageUrl': groupImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  // Convert Chat to Map for JSON serialization (cache)
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImageUrl': groupImageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
    };
  }

  // Create Chat from Firestore document
  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupImageUrl: map['groupImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  // Create Chat from JSON Map (cache)
  factory Chat.fromJsonMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupImageUrl: map['groupImageUrl'],
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  // Create Chat from Firestore DocumentSnapshot
  factory Chat.fromDocument(DocumentSnapshot doc) {
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
        'participants': [],
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSenderId': null,
        'unreadCount': <String, int>{},
        'isGroup': false,
        'groupName': null,
        'groupImageUrl': null,
        'createdAt': Timestamp.now(),
        'createdBy': '',
      };
    }
    
    return Chat.fromMap(safeData);
  }

  // Create a copy of Chat with updated fields
  Chat copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    bool? isGroup,
    String? groupName,
    String? groupImageUrl,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Chat(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Get unread count for specific user
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  // Update unread count for user
  Chat updateUnreadCount(String userId, int count) {
    final updatedUnreadCount = Map<String, int>.from(unreadCount);
    updatedUnreadCount[userId] = count;
    return copyWith(unreadCount: updatedUnreadCount);
  }

  // Reset unread count for user
  Chat resetUnreadCount(String userId) {
    final updatedUnreadCount = Map<String, int>.from(unreadCount);
    updatedUnreadCount[userId] = 0;
    return copyWith(unreadCount: updatedUnreadCount);
  }

  // Get other participant in direct chat
  String? getOtherParticipant(String currentUserId) {
    if (isGroup) return null;
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // Check if user is participant
  bool hasParticipant(String userId) {
    return participants.contains(userId);
  }

  // Get chat title for display
  String getChatTitle(String currentUserId, Map<String, String> userNames) {
    if (isGroup) {
      return groupName ?? 'Group Chat';
    } else {
      final otherUserId = getOtherParticipant(currentUserId);
      return userNames[otherUserId] ?? 'Unknown User';
    }
  }

  @override
  String toString() {
    return 'Chat(id: $id, participants: $participants, isGroup: $isGroup, groupName: $groupName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
