import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = false;
  
  // Add this property to expose the connectivity stream
  Stream<ConnectivityResult> get onConnectivityChanged => _connectivity.onConnectivityChanged;
  
  // Getter for current connection state
  bool get isConnected => _isConnected;
  
  ConnectivityService() {
    // Initialize connection status
    _initConnectivity();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  // Initialize connectivity
  Future<void> _initConnectivity() async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Couldn\'t check connectivity status: $e');
      _isConnected = false;
    }
  }
  
  // Update connection status when it changes
  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected = (result != ConnectivityResult.none);
    notifyListeners();
  }
  
  // Override the standard addListener method from ChangeNotifier
  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
  }
  
  // Create a new method with a different name to avoid conflicts
  StreamSubscription<ConnectivityResult> listenToConnectivityChanges(void Function(ConnectivityResult) listener) {
    return _connectivity.onConnectivityChanged.listen(listener);
  }
  
  // Method to check current connectivity status
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    return _isConnected;
  }
}