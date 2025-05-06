import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io'; // Import for File
import '../models/event_model.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:geolocator/geolocator.dart';

class EventService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final cloudinary = CloudinaryPublic('dcmsie5au', 'evently');
  
  // Original event lists
  List<EventModel> _events = [];
  List<EventModel> _featuredEvents = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = false;
  String? _searchQuery;
  String? _selectedCategory;
  String _sortOption = 'date';
  bool _isAscending = true;
  
  // Distance cache for performance
  Map<String, double> _eventDistances = {};
  
  // User position for distance calculations
  Position? _userPosition;
  
  String? get selectedCategory => _selectedCategory;
  List<EventModel> get events => _events;
  List<EventModel> get featuredEvents => _featuredEvents;
  List<EventModel> get getFilteredEvents => _filteredEvents;
  List<EventModel> get filteredEvents => _filteredEvents;
  bool get isLoading => _isLoading;
  
  // Set user position for distance calculations
  void setUserPosition(Position? position) {
    _userPosition = position;
    // Clear distance cache when position changes
    _eventDistances.clear();
    // Re-apply filters and sorting if we're using distance sorting
    if (_sortOption == 'distance') {
      _applyFilters();
    }
    notifyListeners();
  }
  
  Future<void> fetchEvents() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      QuerySnapshot snapshot = await _firestore.collection('events').get();
      _events = snapshot.docs.map((doc) {
        return EventModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      _featuredEvents = _events.where((event) => event.featured).toList();
      _applyFilters();
    } catch (e) {
      print('Error fetching events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get event by ID - Implementation for the method used in multiple places
  Future<EventModel?> getEventById(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting event by ID: $e');
      return null;
    }
  }
  
  // Dashboard statistics
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      // Calculate current date boundaries
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      // Fetch all events if not already loaded
      if (_events.isEmpty) {
        QuerySnapshot snapshot = await _firestore.collection('events').get();
        _events = snapshot.docs.map((doc) {
          return EventModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
        
        _featuredEvents = _events.where((event) => event.featured).toList();
        _applyFilters();
      }
      
      // Calculate statistics
      int upcomingEvents = _events.where((event) => event.date.isAfter(now)).length;
      int pastEvents = _events.where((event) => event.date.isBefore(now)).length;
      int activeEvents = _events.where((event) => event.isAvailable).length;
      
      // Get bookings data
      QuerySnapshot bookingsSnapshot = await _firestore.collection('bookings').get();
      List<Map<String, dynamic>> bookings = bookingsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      
      // Calculate booking statistics
      int totalBookings = bookings.length;
      int todayBookings = bookings.where((booking) {
        final bookingTime = (booking['createdAt'] as Timestamp).toDate();
        return bookingTime.isAfter(today);
      }).length;
      
      // Calculate revenue
      double totalRevenue = 0;
      double todayRevenue = 0;
      double weeklyRevenue = 0;
      double monthlyRevenue = 0;
      
      for (var booking in bookings) {
        final bookingTime = (booking['createdAt'] as Timestamp).toDate();
        final amount = booking['totalAmount'] as double? ?? 0.0;
        
        totalRevenue += amount;
        if (bookingTime.isAfter(today)) {
          todayRevenue += amount;
        }
        if (bookingTime.isAfter(startOfWeek)) {
          weeklyRevenue += amount;
        }
        if (bookingTime.isAfter(startOfMonth)) {
          monthlyRevenue += amount;
        }
      }
      
      // Calculate category statistics
      Map<String, int> categoryCounts = {};
      for (var event in _events) {
        categoryCounts[event.category] = (categoryCounts[event.category] ?? 0) + 1;
      }
      
      // Get the most popular category
      String? popularCategory;
      int maxCount = 0;
      categoryCounts.forEach((category, count) {
        if (count > maxCount) {
          maxCount = count;
          popularCategory = category;
        }
      });
      
      return {
        'events': {
          'total': _events.length,
          'upcoming': upcomingEvents,
          'past': pastEvents,
          'active': activeEvents,
          'popularCategory': popularCategory ?? 'None',
          'categories': categoryCounts,
        },
        'bookings': {
          'total': totalBookings,
          'today': todayBookings,
        },
        'revenue': {
          'total': totalRevenue,
          'today': todayRevenue,
          'weekly': weeklyRevenue,
          'monthly': monthlyRevenue,
        },
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Method to upload images to Cloudinary
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'events',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }
  
  // Create a new event - Implementation for use in event_form_screen.dart
  Future<String?> createEvent(Map<String, dynamic> eventData, File? imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Add server timestamp
      eventData['createdAt'] = FieldValue.serverTimestamp();
      eventData['updatedAt'] = FieldValue.serverTimestamp();
      eventData['featured'] = false; // Default to not featured
      
      // If we have an image, upload it first
      if (imageFile != null) {
        String? imageUrl = await _uploadImageToCloudinary(imageFile);
        if (imageUrl != null) {
          // Add the image URL to the event data
          eventData['imageUrl'] = imageUrl;
        }
      }
      
      // Create event document with image URL already included
      DocumentReference docRef = await _firestore.collection('events').add(eventData);
      
      // Refresh events list
      await fetchEvents();
      
      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update an existing event - Implementation for event_form_screen.dart
  Future<bool> updateEvent(String eventId, Map<String, dynamic> eventData, File? imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Add update timestamp
      eventData['updatedAt'] = FieldValue.serverTimestamp();
      
      // If new image provided, upload it
      if (imageFile != null) {
        String? imageUrl = await _uploadImageToCloudinary(imageFile);
        if (imageUrl != null) {
          // Add the new image URL to the event data
          eventData['imageUrl'] = imageUrl;
        }
      }
      
      // Update event document
      await _firestore.collection('events').doc(eventId).update(eventData);
      
      // Refresh events list
      await fetchEvents();
      
      return true;
    } catch (e) {
      print('Error updating event: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void setSearchQuery(String? query) {
    _searchQuery = query;
    _applyFilters();
  }
  
  // Fixed method for setting category
  void setSelectedCategory(String? category) {
    // If new category is same as current one, treat as toggle
    if (_selectedCategory == category) {
      _selectedCategory = null; // Clear category if it's the same
    } else {
      _selectedCategory = category; // Set to new category
    }
    
    print('Category selected: $_selectedCategory'); // Debug log
    _applyFilters();
  }
  
  // Method to sort events
  void sortEvents(String sortOption, bool isAscending) {
    _sortOption = sortOption;
    _isAscending = isAscending;
    _applyFilters();
  }
  
  // Reset all filters to default
  void resetFilters() {
    _searchQuery = null;
    _selectedCategory = null;
    _sortOption = 'date';
    _isAscending = true;
    _applyFilters();
  }
  
  // Calculate distance for an event
  double _getEventDistance(EventModel event) {
    // Use cached distance if available
    if (_eventDistances.containsKey(event.id)) {
      return _eventDistances[event.id]!;
    }
    
    // If no user position, return a very large distance as fallback
    if (_userPosition == null) {
      return double.maxFinite;
    }
    
    // Calculate distance
    double distance = Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      event.location.geopoint.latitude,
      event.location.geopoint.longitude,
    );
    
    // Cache the result
    _eventDistances[event.id] = distance;
    return distance;
  }
  
  // Apply filters to events - with fixed category filtering
  void _applyFilters() {
    // Start with a copy of all events
    _filteredEvents = List.from(_events);
    
    // Apply search filter (case-insensitive)
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final lowercaseQuery = _searchQuery!.toLowerCase();
      _filteredEvents = _filteredEvents.where((event) {
        return event.title.toLowerCase().contains(lowercaseQuery) ||
               event.description.toLowerCase().contains(lowercaseQuery) ||
               event.category.toLowerCase().contains(lowercaseQuery) ||
               event.location.name.toLowerCase().contains(lowercaseQuery) ||
               event.location.address.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
    
    // Apply category filter with robust check
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      print('Filtering by category: $_selectedCategory');
      print('Before filter: ${_filteredEvents.length} events');
      
      // Fixed comparison - case-insensitive for better matching
      _filteredEvents = _filteredEvents.where((event) {
        bool matches = event.category.toLowerCase() == _selectedCategory!.toLowerCase();
        // Debug log for each event
        //print('Event: ${event.title}, Category: ${event.category}, Matches: $matches');
        return matches;
      }).toList();
      
      print('After filter: ${_filteredEvents.length} events');
    }
    
    // Apply sorting based on the selected option
    switch (_sortOption) {
      case 'date':
        _filteredEvents.sort((a, b) =>
            _isAscending
                ? a.date.compareTo(b.date)
                : b.date.compareTo(a.date)
        );
        break;
      case 'price':
        _filteredEvents.sort((a, b) =>
            _isAscending
                ? a.price.compareTo(b.price)
                : b.price.compareTo(a.price)
        );
        break;
      case 'distance':
        // Pre-calculate distances for better performance
        if (_userPosition != null) {
          for (var event in _filteredEvents) {
            _getEventDistance(event);
          }
          
          _filteredEvents.sort((a, b) {
            double distanceA = _getEventDistance(a);
            double distanceB = _getEventDistance(b);
            return _isAscending
                ? distanceA.compareTo(distanceB)
                : distanceB.compareTo(distanceA);
          });
        }
        break;
    }
    
    notifyListeners();
  }
  
  // Fixed method to get unique categories from events
  List<String> getCategories() {
    // Use a Set for unique categories only
    Set<String> categories = {};
    for (var event in _events) {
      if (event.category.isNotEmpty) {
        categories.add(event.category);
      }
    }
    // Convert to list and sort alphabetically for consistency
    List<String> categoryList = categories.toList();
    categoryList.sort();
    return categoryList;
  }
  
  // Get events by location (for nearby events tab)
  List<EventModel> getEventsByLocation(double lat, double lng, double radiusInMeters) {
    // Update user position if not set
    if (_userPosition == null) {
      _userPosition = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
    
    List<EventModel> nearbyEvents = [];
    
    // First, filter by other criteria
    List<EventModel> baseEvents = List.from(_filteredEvents);
    
    // Then filter by distance
    for (var event in baseEvents) {
      double distance = _getEventDistance(event);
      
      if (distance <= radiusInMeters) {
        nearbyEvents.add(event);
      }
    }
    
    // If we're sorting by distance, sort the nearby events
    if (_sortOption == 'distance') {
      nearbyEvents.sort((a, b) {
        double distanceA = _getEventDistance(a);
        double distanceB = _getEventDistance(b);
        
        return _isAscending
            ? distanceA.compareTo(distanceB)
            : distanceB.compareTo(distanceA);
      });
    } else {
      // Apply the current sort option
      switch (_sortOption) {
        case 'date':
          nearbyEvents.sort((a, b) =>
              _isAscending
                  ? a.date.compareTo(b.date)
                  : b.date.compareTo(a.date)
          );
          break;
        case 'price':
          nearbyEvents.sort((a, b) =>
              _isAscending
                  ? a.price.compareTo(b.price)
                  : b.price.compareTo(a.price)
          );
          break;
      }
    }
    
    return nearbyEvents;
  }

  // Toggle event featured status
  Future<bool> toggleEventFeatured(String eventId, bool isFeatured) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'featured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Refresh events to update the UI
      await fetchEvents();
      
      return true;
    } catch (e) {
      print('Error toggling featured status: $e');
      return false;
    }
  }
  
  // Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      
      // Remove from local lists
      _events.removeWhere((event) => event.id == eventId);
      _featuredEvents.removeWhere((event) => event.id == eventId);
      _filteredEvents.removeWhere((event) => event.id == eventId);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }
}