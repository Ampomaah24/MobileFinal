// lib/core/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String eventId;
  final String status; // 'Confirmed', 'Pending', 'Cancelled', 'Completed'
  final DateTime bookingDate;
  final int ticketCount;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? eventData;
  final Map<String, dynamic>? userData;

  BookingModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.bookingDate,
    required this.ticketCount,
    required this.totalAmount,
    required this.createdAt,
    this.updatedAt,
    this.eventData,
    this.userData,
  });

  // Factory method to create a BookingModel from a Firestore document
  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      id: id,
      userId: map['userId'] ?? '',
      eventId: map['eventId'] ?? '',
      status: map['status'] ?? 'Pending',
      bookingDate: map['bookingDate'] != null
          ? (map['bookingDate'] as Timestamp).toDate()
          : DateTime.now(),
      ticketCount: map['ticketCount'] ?? 0,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      eventData: map['eventData'],
      userData: map['userData'],
    );
  }

  // Alternative factory method for compatibility with admin screens
  factory BookingModel.fromMap2(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      eventId: map['eventId'] ?? '',
      status: map['status'] ?? 'Pending',
      bookingDate: map['bookingDate'] is Timestamp
          ? (map['bookingDate'] as Timestamp).toDate()
          : (map['bookingDate'] ?? DateTime.now()),
      ticketCount: map['ticketCount'] ?? 0,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] ?? DateTime.now()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : map['updatedAt'],
      eventData: map['eventData'],
      userData: map['userData'],
    );
  }

  // Convert BookingModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'status': status,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'ticketCount': ticketCount,
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'eventData': eventData,
      'userData': userData,
    };
  }

  // Create a copy of the booking with updated fields
  BookingModel copyWith({
    String? status,
    Map<String, dynamic>? eventData,
    Map<String, dynamic>? userData,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: this.id,
      userId: this.userId,
      eventId: this.eventId,
      status: status ?? this.status,
      bookingDate: this.bookingDate,
      ticketCount: this.ticketCount,
      totalAmount: this.totalAmount,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      eventData: eventData ?? this.eventData,
      userData: userData ?? this.userData,
    );
  }

  // Helpers for status checks
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCompleted => status.toLowerCase() == 'completed';

  // Helper to check if the event is upcoming
  bool get isUpcoming => bookingDate.isAfter(DateTime.now());

  // Helper to check if the event has passed
  bool get isPast => bookingDate.isBefore(DateTime.now());

  // String representation for debugging
  @override
  String toString() {
    return 'BookingModel(id: $id, eventId: $eventId, status: $status, bookingDate: $bookingDate)';
  }
}