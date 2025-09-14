import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _hasInitialized = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get hasInitialized => _hasInitialized;

  Future<void> initialize() async {
    if (_hasInitialized) return;

    try {
      // Check initial connectivity
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          debugPrint('Connectivity service error: $error');
        },
      );

      _hasInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize connectivity service: $e');
      // Assume online if we can't check connectivity
      _isOnline = true;
      _hasInitialized = true;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    // Consider online if any connection type is available (not none)
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    
    if (wasOnline != _isOnline) {
      debugPrint('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
      notifyListeners();
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      debugPrint('Failed to check connectivity: $e');
      return _isOnline; // Return cached status
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    super.dispose();
  }
}
