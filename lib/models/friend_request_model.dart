import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
}

class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  // Convert FriendRequest to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  // Convert FriendRequest to Map for JSON serialization (cache)
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
    };
  }

  // Create FriendRequest from Firestore document
  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create FriendRequest from JSON Map (cache)
  factory FriendRequest.fromJsonMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['respondedAt'])
          : null,
    );
  }

  // Create FriendRequest from Firestore DocumentSnapshot
  factory FriendRequest.fromDocument(DocumentSnapshot doc) {
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
        'senderId': '',
        'receiverId': '',
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'respondedAt': null,
      };
    }
    
    return FriendRequest.fromMap(safeData);
  }

  // Create a copy of FriendRequest with updated fields
  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  // Accept the friend request
  FriendRequest accept() {
    return copyWith(
      status: FriendRequestStatus.accepted,
      respondedAt: DateTime.now(),
    );
  }

  // Decline the friend request
  FriendRequest decline() {
    return copyWith(
      status: FriendRequestStatus.declined,
      respondedAt: DateTime.now(),
    );
  }

  // Check if request is pending
  bool get isPending => status == FriendRequestStatus.pending;

  // Check if request is accepted
  bool get isAccepted => status == FriendRequestStatus.accepted;

  // Check if request is declined
  bool get isDeclined => status == FriendRequestStatus.declined;

  @override
  String toString() {
    return 'FriendRequest(id: $id, senderId: $senderId, receiverId: $receiverId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Friendship {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
  });

  // Convert Friendship to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create Friendship from Firestore document
  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      id: map['id'] ?? '',
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create Friendship from Firestore DocumentSnapshot
  factory Friendship.fromDocument(DocumentSnapshot doc) {
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
        'user1Id': '',
        'user2Id': '',
        'createdAt': Timestamp.now(),
      };
    }
    
    return Friendship.fromMap(safeData);
  }

  // Get the other user's ID in the friendship
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  // Check if user is part of this friendship
  bool hasUser(String userId) {
    return user1Id == userId || user2Id == userId;
  }

  @override
  String toString() {
    return 'Friendship(id: $id, user1Id: $user1Id, user2Id: $user2Id)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Friendship && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
