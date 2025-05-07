import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FirebaseConnectionHandler {
  final ConnectivityService _connectivityService;
  final FirebaseFirestore _firestore;
  
  // Stream controller to broadcast connection state changes
  final _connectionStateController = StreamController<bool>.broadcast();
  
  // Subscription for connectivity changes
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  
  // Flag to track if Firebase is connected
  bool _isFirebaseConnected = false;
  
  // Getter for the stream
  Stream<bool> get connectionState => _connectionStateController.stream;
  
  // Getter for current connection state
  bool get isFirebaseConnected => _isFirebaseConnected;
  
  FirebaseConnectionHandler({
    required ConnectivityService connectivityService,
    FirebaseFirestore? firestore,
  }) : 
    _connectivityService = connectivityService,
    _firestore = firestore ?? FirebaseFirestore.instance {
    
    // Configure Firestore for offline persistence
    _configureFirestoreSettings();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Initial connection check
    _checkFirebaseConnection();
  }
  
  // Configure Firestore for offline persistence
  void _configureFirestoreSettings() {
    _firestore.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  
  // Handle connectivity changes
  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    if (result != ConnectivityResult.none) {
      // We're online, check Firebase connection
      await _checkFirebaseConnection();
    } else {
      // We're offline, set Firebase connection to false
      _updateConnectionState(false);
    }
  }
  
  // Check if Firebase is reachable
  Future<void> _checkFirebaseConnection() async {
    if (!_connectivityService.isConnected) {
      _updateConnectionState(false);
      return;
    }
    
    try {
      // Try to make a lightweight query to check connectivity
      await _firestore.collection('connection_test').limit(1).get()
          .timeout(Duration(seconds: 5));
      
      _updateConnectionState(true);
    } catch (e) {
      print('Firebase connection check failed: $e');
      _updateConnectionState(false);
    }
  }
  
  // Update connection state and notify listeners
  void _updateConnectionState(bool isConnected) {
    if (_isFirebaseConnected != isConnected) {
      _isFirebaseConnected = isConnected;
      _connectionStateController.add(isConnected);
    }
  }
  
  // Enable/disable network for testing purposes
  Future<void> toggleFirebaseNetwork(bool enable) async {
    try {
      if (enable) {
        await _firestore.enableNetwork();
      } else {
        await _firestore.disableNetwork();
      }
      
      // Update connection state
      _updateConnectionState(enable && _connectivityService.isConnected);
    } catch (e) {
      print('Error toggling Firebase network: $e');
    }
  }
  
  // Force connection check
  Future<bool> checkConnection() async {
    await _checkFirebaseConnection();
    return _isFirebaseConnected;
  }
  
  // Dispose resources
  void dispose() {
    _connectivitySubscription.cancel();
    _connectionStateController.close();
  }
}