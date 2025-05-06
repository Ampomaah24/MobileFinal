import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import 'event_service.dart';
import 'notification_service.dart';
import 'user_service.dart';

class BookingService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EventService _eventService;
  final NotificationService? _notificationService;
  final UserService? _userService;
  
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;
  
  // Fixed constructor to match the parameter order used in app.dart
  BookingService(this._eventService, [this._notificationService, this._userService]);
  
  // Getters
  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Get upcoming bookings
  List<BookingModel> get upcomingBookings {
    return _bookings.where((booking) => 
      booking.status.toLowerCase() == 'confirmed' && 
      booking.bookingDate.isAfter(DateTime.now())
    ).toList();
  }
  
  // Get past bookings
  List<BookingModel> get pastBookings {
    return _bookings.where((booking) => 
      booking.status.toLowerCase() == 'confirmed' && 
      booking.bookingDate.isBefore(DateTime.now())
    ).toList();
  }
  
  // Get cancelled bookings
  List<BookingModel> get cancelledBookings {
    return _bookings.where((booking) => 
      booking.status.toLowerCase() == 'cancelled'
    ).toList();
  }
  
  // Method needed by AdminBookingsScreen
  Future<List<BookingModel>> getAllBookings() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();
      
      List<BookingModel> allBookings = await Future.wait(
        snapshot.docs.map((doc) async {
          final bookingData = doc.data() as Map<String, dynamic>;
          
          // Enrich booking with event data if not present
          if (bookingData['eventData'] == null && bookingData['eventId'] != null) {
            try {
              final event = await _eventService.getEventById(bookingData['eventId']);
              if (event != null) {
                bookingData['eventData'] = event.toMap();
              }
            } catch (e) {
              print('Error fetching event data for booking: $e');
            }
          }
          
          // Enrich booking with user data if not present
          if (bookingData['userData'] == null && bookingData['userId'] != null && _userService != null) {
            try {
              final user = await _userService!.getUserById(bookingData['userId']);
              if (user != null) {
                bookingData['userData'] = {
                  'name': user.name,
                  'email': user.email,
                  'phone': user.phone,
                  'profileImage': user.profileImageUrl
                };
              }
            } catch (e) {
              print('Error fetching user data for booking: $e');
            }
          }
          
          return BookingModel.fromMap(doc.id, bookingData);
        }).toList(),
      );
      
      return allBookings;
    } catch (e) {
      print('Error getting all bookings: $e');
      _error = 'Error getting all bookings: ${e.toString()}';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Method needed by AdminBookingDetailsScreen
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Get the booking
      DocumentSnapshot doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!doc.exists) {
        _error = 'Booking not found';
        return;
      }
      
      final bookingData = doc.data() as Map<String, dynamic>;
      final userId = bookingData['userId'];
      
      // Handle cancellation logic if status is changed to Cancelled
      if (newStatus == 'Cancelled' && bookingData['status'] != 'Cancelled') {
        final eventId = bookingData['eventId'];
        final ticketCount = bookingData['ticketCount'] ?? 0;
        
        // Update event booked count in a transaction
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot eventDoc = await transaction.get(
            _firestore.collection('events').doc(eventId),
          );
          
          if (!eventDoc.exists) {
            throw Exception('Event does not exist!');
          }
          
          int currentBookedCount = (eventDoc.data() as Map<String, dynamic>)['bookedCount'] ?? 0;
          int newBookedCount = (currentBookedCount - ticketCount).toInt();
          if (newBookedCount < 0) newBookedCount = 0;
          
          transaction.update(
            _firestore.collection('events').doc(eventId),
            {'bookedCount': newBookedCount},
          );
        });
        
        // Cancel event reminder notification
        if (_notificationService != null) {
          await _notificationService!.cancelEventReminder(eventId);
        }
      }
      
      // Handle completion logic if status is changed to Completed
      if (newStatus == 'Completed' && bookingData['status'] != 'Completed') {
        // Any completion-specific logic here
      }
      
      // Refresh the event service
      await _eventService.fetchEvents();
      
      // Refresh user bookings if needed
      if (userId != null) {
        await fetchUserBookings(userId);
      }
      
    } catch (e) {
      _error = 'Error updating booking status: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get user's bookings
  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<BookingModel> userBookings = await Future.wait(
        snapshot.docs.map((doc) async {
          final bookingData = doc.data() as Map<String, dynamic>;
          
          // Enrich booking with event data if not present
          if (bookingData['eventData'] == null && bookingData['eventId'] != null) {
            try {
              final event = await _eventService.getEventById(bookingData['eventId']);
              if (event != null) {
                bookingData['eventData'] = event.toMap();
              }
            } catch (e) {
              print('Error fetching event data for booking: $e');
            }
          }
          
          // Add user data if needed
          if (_userService != null && bookingData['userData'] == null) {
            try {
              final user = await _userService!.getUserById(userId);
              if (user != null) {
                bookingData['userData'] = {
                  'name': user.name,
                  'email': user.email,
                  'phone': user.phone,
                  'profileImage': user.profileImageUrl
                };
              }
            } catch (e) {
              print('Error fetching user data for booking: $e');
            }
          }
          
          return BookingModel.fromMap(doc.id, bookingData);
        }).toList(),
      );
      
      return userBookings;
    } catch (e) {
      print('Error getting user bookings: $e');
      _error = 'Error getting user bookings: ${e.toString()}';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch user bookings
  Future<void> fetchUserBookings(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Query bookings collection for user's bookings
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      // Process each booking document
      _bookings = await Future.wait(
        snapshot.docs.map((doc) async {
          final bookingData = doc.data() as Map<String, dynamic>;
          
          // If event data is not included, fetch it from the events collection
          if (bookingData['eventData'] == null && bookingData['eventId'] != null) {
            try {
              final event = await _eventService.getEventById(bookingData['eventId']);
              if (event != null) {
                bookingData['eventData'] = event.toMap();
                
                // Update the booking with event data
                await _firestore.collection('bookings').doc(doc.id).update({
                  'eventData': event.toMap(),
                });
              }
            } catch (e) {
              print('Error fetching event data for booking: $e');
            }
          }
          
          // Add user data if needed
          if (_userService != null && bookingData['userData'] == null) {
            try {
              final user = await _userService!.getUserById(userId);
              if (user != null) {
                bookingData['userData'] = {
                  'name': user.name,
                  'email': user.email,
                  'phone': user.phone,
                  'profileImage': user.profileImageUrl
                };
                
                // Update the booking with user data
                await _firestore.collection('bookings').doc(doc.id).update({
                  'userData': bookingData['userData'],
                });
              }
            } catch (e) {
              print('Error fetching user data for booking: $e');
            }
          }
          
          return BookingModel.fromMap(doc.id, bookingData);
        }).toList(),
      );
      
      // Sort bookings by date
      _bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      
    } catch (e) {
      _error = 'Failed to load bookings: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      DocumentSnapshot doc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (!doc.exists) {
        _error = 'Booking not found';
        return null;
      }
      
      final bookingData = doc.data() as Map<String, dynamic>;
      
      // Enrich with event data if missing
      if (bookingData['eventData'] == null && bookingData['eventId'] != null) {
        try {
          final event = await _eventService.getEventById(bookingData['eventId']);
          if (event != null) {
            bookingData['eventData'] = event.toMap();
          }
        } catch (e) {
          print('Error fetching event data for booking: $e');
        }
      }
      
      // Enrich with user data if missing
      if (bookingData['userData'] == null && bookingData['userId'] != null && _userService != null) {
        try {
          final user = await _userService!.getUserById(bookingData['userId']);
          if (user != null) {
            bookingData['userData'] = {
              'name': user.name,
              'email': user.email,
              'phone': user.phone,
              'profileImage': user.profileImageUrl
            };
          }
        } catch (e) {
          print('Error fetching user data for booking: $e');
        }
      }
      
      return BookingModel.fromMap(doc.id, bookingData);
    } catch (e) {
      _error = 'Error getting booking: ${e.toString()}';
      print(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a new booking
  Future<BookingModel?> createBooking({
    required String userId,
    required EventModel event,
    required int ticketCount,
    required DateTime bookingDate,
    Map<String, dynamic>? userData,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Verify event availability
      if (event.availableSpots < ticketCount) {
        _error = 'Not enough tickets available';
        return null;
      }
      
      // Calculate total amount
      final totalAmount = event.price * ticketCount;
      
      // Create booking data
      final bookingData = {
        'userId': userId,
        'eventId': event.id,
        'status': 'Confirmed',
        'bookingDate': Timestamp.fromDate(bookingDate),
        'ticketCount': ticketCount,
        'totalAmount': totalAmount,
        'createdAt': FieldValue.serverTimestamp(),
        'eventData': event.toMap(),
        'userData': userData,
      };
      
      // Create booking document
      final docRef = await _firestore.collection('bookings').add(bookingData);
      
      // Update event booked count in a transaction
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot eventDoc = await transaction.get(
          _firestore.collection('events').doc(event.id),
        );
        
        if (!eventDoc.exists) {
          throw Exception('Event does not exist!');
        }
        
        int currentBookedCount = (eventDoc.data() as Map<String, dynamic>)['bookedCount'] ?? 0;
        int newBookedCount = currentBookedCount + ticketCount;
        
        transaction.update(
          _firestore.collection('events').doc(event.id),
          {'bookedCount': newBookedCount},
        );
      });
      
      // Refresh the event to update available spots
      await _eventService.fetchEvents();
      
      // Send booking confirmation notification
      if (_notificationService != null) {
        await _notificationService!.scheduleEventReminder(
          event.id,
          event.title,
          event.date,
        );
        
        await _notificationService!.sendEventBookingConfirmation(
          userId,
          event.id,
          event.title,
          event.date,
          ticketCount,
          docRef.id, // Add the missing bookingId parameter here
          totalAmount: totalAmount,
          eventImage: event.imageUrl,
        );
      }
      
      // Get the created booking with ID
      DocumentSnapshot doc = await docRef.get();
      final createdBooking = BookingModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      
      // Refresh user bookings
      await fetchUserBookings(userId);
      
      return createdBooking;
    } catch (e) {
      _error = 'Error creating booking: ${e.toString()}';
      print(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Get the booking
      DocumentSnapshot doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!doc.exists) {
        _error = 'Booking not found';
        return false;
      }
      
      final bookingData = doc.data() as Map<String, dynamic>;
      final userId = bookingData['userId'];
      final eventId = bookingData['eventId'];
      final ticketCount = bookingData['ticketCount'] ?? 0;
      
      // Check if booking is already cancelled
      if (bookingData['status'] == 'Cancelled') {
        _error = 'Booking is already cancelled';
        return false;
      }
      
      // Check if booking is for a past event
      final bookingDate = (bookingData['bookingDate'] as Timestamp).toDate();
      if (bookingDate.isBefore(DateTime.now())) {
        _error = 'Cannot cancel a booking for a past event';
        return false;
      }
      
      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update event booked count in a transaction
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot eventDoc = await transaction.get(
          _firestore.collection('events').doc(eventId),
        );
        
        if (!eventDoc.exists) {
          throw Exception('Event does not exist!');
        }
        
        int currentBookedCount = (eventDoc.data() as Map<String, dynamic>)['bookedCount'] ?? 0;
        int newBookedCount = (currentBookedCount - ticketCount).toInt();
        if (newBookedCount < 0) newBookedCount = 0;
        
        transaction.update(
          _firestore.collection('events').doc(eventId),
          {'bookedCount': newBookedCount},
        );
      });
      
      // Cancel event reminder notification
      if (_notificationService != null) {
        await _notificationService!.cancelEventReminder(eventId);
      }
      
      // Refresh the events to update available spots
      await _eventService.fetchEvents();
      
      // Refresh user bookings
      await fetchUserBookings(userId);
      
      return true;
    } catch (e) {
      _error = 'Error cancelling booking: ${e.toString()}';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get booking statistics for a user
  Future<Map<String, dynamic>> getUserBookingStats(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Fetch user's bookings if not already loaded
      if (_bookings.isEmpty) {
        await fetchUserBookings(userId);
      }
      
      // Calculate statistics
      int totalBookings = _bookings.length;
      int completedBookings = pastBookings.length;
      int upcomingBookings = this.upcomingBookings.length;
      int cancelledBookings = this.cancelledBookings.length;
      
      // Calculate total spent
      double totalSpent = pastBookings.fold(0, (sum, booking) => sum + booking.totalAmount);
      
      // Get most booked category
      Map<String, int> categoryCounts = {};
      for (var booking in _bookings) {
        if (booking.eventData != null && booking.eventData!['category'] != null) {
          String category = booking.eventData!['category'];
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }
      
      String? mostBookedCategory;
      int maxCount = 0;
      categoryCounts.forEach((category, count) {
        if (count > maxCount) {
          mostBookedCategory = category;
          maxCount = count;
        }
      });
      
      return {
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'upcomingBookings': upcomingBookings,
        'cancelledBookings': cancelledBookings,
        'totalSpent': totalSpent,
        'formattedTotalSpent': 'GHS ${NumberFormat('#,##0.00').format(totalSpent)}',
        'mostBookedCategory': mostBookedCategory ?? 'None',
      };
    } catch (e) {
      _error = 'Error getting booking statistics: ${e.toString()}';
      print(_error);
      return {
        'error': _error,
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get recommended events based on booking history
  Future<List<EventModel>> getRecommendedEvents(String userId) async {
    try {
      // Fetch user's bookings if not already loaded
      if (_bookings.isEmpty) {
        await fetchUserBookings(userId);
      }
      
      // Extract categories from past bookings
      Set<String> userCategories = {};
      for (var booking in _bookings) {
        if (booking.eventData != null && booking.eventData!['category'] != null) {
          userCategories.add(booking.eventData!['category']);
        }
      }
      
      // If no booking history, return featured events
      if (userCategories.isEmpty) {
        return _eventService.featuredEvents;
      }
      
      // Get all events
      List<EventModel> allEvents = _eventService.events;
      
      // Filter events by user's preferred categories and that are not already booked
      Set<String> bookedEventIds = _bookings.map((booking) => booking.eventId).toSet();
      
      List<EventModel> recommendedEvents = allEvents.where((event) {
        return userCategories.contains(event.category) && 
               !bookedEventIds.contains(event.id) &&
               event.date.isAfter(DateTime.now());
      }).toList();
      
      // Sort by date (closest first)
      recommendedEvents.sort((a, b) => a.date.compareTo(b.date));
      
      // Return up to 10 recommendations
      return recommendedEvents.take(10).toList();
    } catch (e) {
      print('Error getting recommended events: $e');
      return [];
    }
  }
}