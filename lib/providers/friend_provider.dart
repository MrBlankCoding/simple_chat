import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class FriendProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<UserModel> _searchResults = [];
  List<FriendRequest> _friendRequests = [];
  List<Friendship> _friends = [];
  final Map<String, UserModel> _friendUsers = {};
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  StreamSubscription<List<FriendRequest>>? _requestsSubscription;
  StreamSubscription<List<Friendship>>? _friendsSubscription;

  List<UserModel> get searchResults => _searchResults;
  List<FriendRequest> get friendRequests => _friendRequests;
  List<Friendship> get friends => _friends;
  Map<String, UserModel> get friendUsers => _friendUsers;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;

  FriendProvider() {
    _initializeFriends();
  }

  void _initializeFriends() {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    // Subscribe to friend requests
    _requestsSubscription = _firestoreService.getFriendRequests(currentUserId).listen(
      (requests) {
        _friendRequests = requests;
        _loadRequestUsers();
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );

    // Subscribe to friends
    _friendsSubscription = _firestoreService.getFriends(currentUserId).listen(
      (friends) {
        _friends = friends;
        _loadFriendUsers();
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  Future<void> _loadRequestUsers() async {
    try {
      final Set<String> userIds = {};
      for (final request in _friendRequests) {
        userIds.add(request.senderId);
      }
      
      if (userIds.isNotEmpty) {
        final usersMap = await _firestoreService.getUsersMap(userIds.toList());
        _friendUsers.addAll(usersMap);
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _loadFriendUsers() async {
    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) return;

      final Set<String> userIds = {};
      for (final friendship in _friends) {
        userIds.add(friendship.getOtherUserId(currentUserId));
      }
      
      if (userIds.isNotEmpty) {
        final usersMap = await _firestoreService.getUsersMap(userIds.toList());
        _friendUsers.addAll(usersMap);
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _setSearching(true);
      _clearError();
      
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      _searchResults = await _firestoreService.searchUsers(query.trim(), currentUserId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setSearching(false);
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  Future<bool> sendFriendRequest(String receiverId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestoreService.sendFriendRequest(currentUserId, receiverId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService.respondToFriendRequest(requestId, true);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> declineFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService.respondToFriendRequest(requestId, false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool isFriend(String userId) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return false;

    return _friends.any((friendship) => 
      friendship.hasUser(currentUserId) && friendship.hasUser(userId));
  }

  bool hasPendingRequest(String userId) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return false;

    return _friendRequests.any((request) => 
      request.senderId == currentUserId && request.receiverId == userId && request.isPending);
  }

  bool hasIncomingRequest(String userId) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return false;

    return _friendRequests.any((request) => 
      request.senderId == userId && request.receiverId == currentUserId && request.isPending);
  }

  List<UserModel> getFriendsList() {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return [];

    final List<UserModel> friendsList = [];
    for (final friendship in _friends) {
      final otherUserId = friendship.getOtherUserId(currentUserId);
      if (_friendUsers.containsKey(otherUserId)) {
        friendsList.add(_friendUsers[otherUserId]!);
      }
    }
    
    // Sort by online status and name
    friendsList.sort((a, b) {
      if (a.isOnline && !b.isOnline) return -1;
      if (!a.isOnline && b.isOnline) return 1;
      return a.name.compareTo(b.name);
    });
    
    return friendsList;
  }

  List<UserModel> getOnlineFriends() {
    return getFriendsList().where((user) => user.isOnline).toList();
  }

  int get friendRequestCount => _friendRequests.length;

  int get friendsCount => _friends.length;

  UserModel? getFriendUser(String userId) {
    return _friendUsers[userId];
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _friendsSubscription?.cancel();
    super.dispose();
  }
}
