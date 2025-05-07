import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String eventsBoxName = 'events';
  static const String bookingsBoxName = 'bookings';
  static const String userBoxName = 'user';
  static const String preferencesBoxName = 'preferences';
  static const String pendingOperationsBoxName = 'pendingOperations';

  static Future<void> initialize() async {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox(eventsBoxName);
    await Hive.openBox(bookingsBoxName);
    await Hive.openBox(userBoxName);
    await Hive.openBox(preferencesBoxName);
    await Hive.openBox(pendingOperationsBoxName);
    
    print('Cache service initialized');
  }

  // Generic methods for all data types
  static Future<void> saveData<T>(String boxName, String key, T data) async {
    final box = Hive.box(boxName);
    if (data is Map || data is List) {
      // Save complex data as JSON string
      await box.put(key, jsonEncode(data));
    } else {
      // Save primitive data directly
      await box.put(key, data);
    }
  }

  static T? getData<T>(String boxName, String key) {
    final box = Hive.box(boxName);
    final data = box.get(key);
    
    if (data == null) return null;
    
    if (data is String && (T == Map || T == List)) {
      try {
        // Parse JSON string back to Map or List
        return jsonDecode(data) as T;
      } catch (e) {
        print('Error parsing cached data: $e');
        return null;
      }
    }
    
    return data as T;
  }

  static Future<void> removeData(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  static Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  // Events-specific methods
  static Future<void> saveEvents(List<Map<String, dynamic>> events) async {
    // Save all events
    await saveData(eventsBoxName, 'all_events', events);
    
    // Also save each event individually by ID for easy lookup
    for (final event in events) {
      if (event['id'] != null) {
        await saveData(eventsBoxName, 'event_${event['id']}', event);
      }
    }
  }

  static List<Map<String, dynamic>> getEvents() {
    final data = getData<List>(eventsBoxName, 'all_events');
    if (data == null) return [];
    
    // Convert List<dynamic> to List<Map<String, dynamic>>
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Map<String, dynamic>? getEventById(String eventId) {
    final data = getData<Map>(eventsBoxName, 'event_$eventId');
    if (data == null) return null;
    
    return Map<String, dynamic>.from(data);
  }

  // Bookings-specific methods
  static Future<void> saveBookings(List<Map<String, dynamic>> bookings) async {
    // Save all bookings
    await saveData(bookingsBoxName, 'all_bookings', bookings);
    
    // Also save each booking individually by ID for easy lookup
    for (final booking in bookings) {
      if (booking['id'] != null) {
        await saveData(bookingsBoxName, 'booking_${booking['id']}', booking);
      }
    }
  }

  static List<Map<String, dynamic>> getBookings() {
    final data = getData<List>(bookingsBoxName, 'all_bookings');
    if (data == null) return [];
    
    // Convert List<dynamic> to List<Map<String, dynamic>>
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // User-specific methods
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await saveData(userBoxName, 'current_user', userData);
  }

  static Map<String, dynamic>? getUserData() {
    final data = getData<Map>(userBoxName, 'current_user');
    if (data == null) return null;
    
    return Map<String, dynamic>.from(data);
  }

  // Pending operations methods for offline transactions
  static Future<void> addPendingOperation(Map<String, dynamic> operation) async {
    final box = Hive.box(pendingOperationsBoxName);
    final pendingOps = box.get('operations', defaultValue: []) as List;
    pendingOps.add(operation);
    await box.put('operations', pendingOps);
  }

  static List<Map<String, dynamic>> getPendingOperations() {
    final box = Hive.box(pendingOperationsBoxName);
    final pendingOps = box.get('operations', defaultValue: []) as List;
    return pendingOps.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> removePendingOperation(int index) async {
    final box = Hive.box(pendingOperationsBoxName);
    final pendingOps = box.get('operations', defaultValue: []) as List;
    pendingOps.removeAt(index);
    await box.put('operations', pendingOps);
  }

  static Future<void> clearPendingOperations() async {
    final box = Hive.box(pendingOperationsBoxName);
    await box.put('operations', []);
  }
}