import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'connectivity_service.dart';
import 'firebase_connection_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; 
import 'cache_service.dart';
import 'event_service.dart';
import 'booking_service.dart';
import 'auth_service.dart';

class SyncService extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  final FirebaseConnectionHandler _firebaseHandler;
  final AuthService _authService;
  final EventService _eventService;
  final BookingService _bookingService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  StreamSubscription<bool>? _firebaseConnectionSubscription;
  
  bool _isSyncing = false;
  bool _hasPendingChanges = false;
  String? _error;
  
  // Getters
  bool get isSyncing => _isSyncing;
  bool get hasPendingChanges => _hasPendingChanges;
  String? get error => _error;
  bool get isConnected => _connectivityService.isConnected && _firebaseHandler.isFirebaseConnected;
  
  SyncService({
    required ConnectivityService connectivityService,
    required FirebaseConnectionHandler firebaseHandler,
    required AuthService authService,
    required EventService eventService,
    required BookingService bookingService,
  }) : 
    _connectivityService = connectivityService,
    _firebaseHandler = firebaseHandler,
    _authService = authService,
    _eventService = eventService,
    _bookingService = bookingService {
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Listen for Firebase connection state changes
    _firebaseConnectionSubscription = _firebaseHandler.connectionState.listen(_handleFirebaseConnectionChange);
    
    // Check for pending operations on initialization
    _checkPendingChanges();
  }
  
  // Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    if (result != ConnectivityResult.none && _firebaseHandler.isFirebaseConnected) {
      // We're online and Firebase is connected, sync pending changes
      _syncPendingChanges();
    }
    notifyListeners();
  }
  
  // Handle Firebase connection changes
  void _handleFirebaseConnectionChange(bool isConnected) {
    if (isConnected && _connectivityService.isConnected) {
      // Firebase is now connected, sync pending changes
      _syncPendingChanges();
    }
    notifyListeners();
  }
  
  // Add a method to let consumers listen to connectivity changes
  StreamSubscription<ConnectivityResult> listenToConnectivity(void Function(ConnectivityResult) listener) {
    return _connectivityService.onConnectivityChanged.listen(listener);
  }
  
  // Check if there are pending changes
  Future<void> _checkPendingChanges() async {
    final pendingOps = CacheService.getPendingOperations();
    _hasPendingChanges = pendingOps.isNotEmpty;
    notifyListeners();
  }
  
  // Sync all pending changes when online
  Future<void> _syncPendingChanges() async {
    if (!isConnected || _isSyncing) return;
    
    _isSyncing = true;
    _error = null;
    notifyListeners();
    
    try {
      final pendingOps = CacheService.getPendingOperations();
      if (pendingOps.isEmpty) {
        _isSyncing = false;
        _hasPendingChanges = false;
        notifyListeners();
        return;
      }
      
      print('Syncing ${pendingOps.length} pending operations');
      
      // Process each pending operation
      for (int i = 0; i < pendingOps.length; i++) {
        // Skip processing if we're no longer connected
        if (!isConnected) {
          _isSyncing = false;
          notifyListeners();
          return;
        }
        
        final operation = pendingOps[i];
        final type = operation['type'] as String;
        final data = operation['data'] as Map<String, dynamic>;
        
        bool success = false;
        
        switch (type) {
          case 'create_booking':
            success = await _processCreateBooking(data);
            break;
          case 'cancel_booking':
            success = await _processCancelBooking(data);
            break;
          // Add other operation types as needed
          
          default:
            print('Unknown operation type: $type');
            break;
        }
        
        if (success) {
          // Remove the processed operation
          await CacheService.removePendingOperation(i);
          // Since we're removing an item, adjust the index
          i--;
        }
      }
      
      // Refresh cached data after syncing
      await _refreshCachedData();
      
      // Update pending changes status
      _checkPendingChanges();
    } catch (e) {
      print('Error syncing pending changes: $e');
      _error = 'Error syncing: ${e.toString()}';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  // Process a create booking operation with batch writing
  Future<bool> _processCreateBooking(Map<String, dynamic> data) async {
    try {
      // Extract booking data
      final String eventId = data['eventId'];
      final int ticketCount = data['ticketCount'];
      final DateTime bookingDate = DateTime.parse(data['bookingDate']);
      final userData = data['userData'];
      
      // Get the event
      final event = await _eventService.getEventById(eventId);
      if (event == null) return false;
      
      // Create the booking using a batch for atomicity
      WriteBatch batch = _firestore.batch();
      
      // Create booking document
      DocumentReference bookingRef = _firestore.collection('bookings').doc();
      batch.set(bookingRef, {
        'userId': _authService.user!.uid,
        'eventId': eventId,
        'ticketCount': ticketCount,
        'totalAmount': event.price * ticketCount,
        'bookingDate': bookingDate,
        'userData': userData,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update event ticket count
      DocumentReference eventRef = _firestore.collection('events').doc(eventId);
      batch.update(eventRef, {
        'availableTickets': FieldValue.increment(-ticketCount),
      });
      
      // Commit the batch
      await batch.commit();
      
      return true;
    } catch (e) {
      print('Error processing create booking: $e');
      return false;
    }
  }
  
  // Process a cancel booking operation with batch writing
  Future<bool> _processCancelBooking(Map<String, dynamic> data) async {
    try {
      final String bookingId = data['bookingId'];
      final int ticketCount = data['ticketCount']; // Assume this is included in cached operation
      final String eventId = data['eventId']; // Assume this is included in cached operation
      
      // Use a batch for atomicity
      WriteBatch batch = _firestore.batch();
      
      // Update booking status
      DocumentReference bookingRef = _firestore.collection('bookings').doc(bookingId);
      batch.update(bookingRef, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Return tickets to event
      DocumentReference eventRef = _firestore.collection('events').doc(eventId);
      batch.update(eventRef, {
        'availableTickets': FieldValue.increment(ticketCount),
      });
      
      // Commit the batch
      await batch.commit();
      
      return true;
    } catch (e) {
      print('Error processing cancel booking: $e');
      return false;
    }
  }
  
  // Refresh all cached data - called after syncing or on demand
  Future<void> _refreshCachedData() async {
    if (!isConnected) return;
    
    try {
      // Refresh events
      await _eventService.fetchEvents();
      
      // Refresh user bookings if logged in
      if (_authService.user != null) {
        await _bookingService.fetchUserBookings(_authService.user!.uid);
      }
    } catch (e) {
      print('Error refreshing cached data: $e');
    }
  }
  
  // Force sync - can be called from UI
  Future<void> forceSyncNow() async {
    if (!_connectivityService.isConnected) {
      _error = 'No internet connection available';
      notifyListeners();
      return;
    }
    
    if (!_firebaseHandler.isFirebaseConnected) {
      // Try to check the connection again
      bool isConnected = await _firebaseHandler.checkConnection();
      if (!isConnected) {
        _error = 'Firebase servers unreachable';
        notifyListeners();
        return;
      }
    }
    
    await _syncPendingChanges();
    await _refreshCachedData();
  }
  
  // Add a new pending operation for offline use
  Future<void> addPendingOperation(String type, Map<String, dynamic> data) async {
    await CacheService.addPendingOperation({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    _hasPendingChanges = true;
    notifyListeners();
    
    // If we're online, try to sync immediately
    if (isConnected) {
      _syncPendingChanges();
    }
  }
  
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _firebaseConnectionSubscription?.cancel();
    super.dispose();
  }
}