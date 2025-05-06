// lib/core/services/payment_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import 'package:uuid/uuid.dart';

class PaymentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  bool _isProcessing = false;
  String? _error;
  
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  
  // Mock payment processing - simulates a payment gateway integration
  Future<Map<String, dynamic>> processPayment({
    required BuildContext context,
    required EventModel event,
    required String userId,
    required String userEmail,
    required int ticketCount,
    required DateTime bookingDate,
  }) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();
      
      // Calculate total amount
      final totalAmount = event.price * ticketCount;
      
      // Generate a unique reference
      final String reference = _uuid.v4();
      
      // In a real app, this would show a payment UI and process the transaction
      // For now, we'll show a dialog to simulate the payment process
      final bool paymentConfirmed = await _showPaymentConfirmationDialog(
        context, 
        totalAmount,
        event.title
      );
      
      if (!paymentConfirmed) {
        return {
          'success': false,
          'message': 'Payment cancelled by user',
        };
      }
      
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Return success response with transaction data
      return {
        'success': true,
        'reference': reference,
        'amount': totalAmount,
        'message': 'Payment processed successfully',
        'data': {
          'transactionDate': DateTime.now().toIso8601String(),
          'status': 'success',
          'reference': reference,
          'paymentMethod': 'Card', // Simulated payment method
          'currency': 'GHS',
          'customerEmail': userEmail,
          'eventId': event.id,
          'ticketCount': ticketCount,
        }
      };
    } catch (e) {
      _error = 'Payment processing error: ${e.toString()}';
      print('PaymentService Error: $_error');
      return {
        'success': false,
        'message': _error,
        'reference': _uuid.v4(), // Still return a reference for tracking
      };
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  // Show a dialog to confirm payment
  Future<bool> _showPaymentConfirmationDialog(
    BuildContext context, 
    double amount,
    String eventTitle
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to pay GHS ${amount.toStringAsFixed(2)} for:'),
            const SizedBox(height: 8),
            Text(
              eventTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('This is a simulation. No actual payment will be made.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRM PAYMENT'),
          ),
        ],
      ),
    ) ?? false; // Default to false if dialog is dismissed
  }
  
  // Save payment details to Firestore
  Future<void> savePaymentDetails({
    required String bookingId,
    required String reference,
    required double amount,
    required String paymentMethod,
    required String status,
    Map<String, dynamic>? paymentData,
  }) async {
    try {
      // Create payment document
      await _firestore.collection('payments').add({
        'bookingId': bookingId,
        'reference': reference,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': status,
        'paymentData': paymentData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update booking with payment information
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentReference': reference,
        'paymentStatus': status,
        'paymentMethod': paymentMethod,
        'paymentAmount': amount,
        'paymentDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving payment details: $e');
      throw Exception('Failed to save payment details: ${e.toString()}');
    }
  }
  
  // Get payment history for a user
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      // Get all bookings for the user
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Extract booking IDs
      final List<String> bookingIds = bookingsQuery.docs.map((doc) => doc.id).toList();
      
      if (bookingIds.isEmpty) {
        return [];
      }
      
      // Process bookings in batches to handle Firebase's "in" query limitation
      List<Map<String, dynamic>> allPayments = [];
      
      // Process in batches of 10 (Firestore limit)
      for (var i = 0; i < bookingIds.length; i += 10) {
        final end = (i + 10 < bookingIds.length) ? i + 10 : bookingIds.length;
        final batch = bookingIds.sublist(i, end);
        
        final paymentsQuery = await _firestore
            .collection('payments')
            .where('bookingId', whereIn: batch)
            .orderBy('createdAt', descending: true)
            .get();
            
        final payments = paymentsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
            'createdAt': data['createdAt'] is Timestamp 
                ? (data['createdAt'] as Timestamp).toDate() 
                : DateTime.now(),
          };
        }).toList();
        
        allPayments.addAll(payments);
      }
      
      // Sort all payments by date (most recent first)
      allPayments.sort((a, b) => 
        (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime)
      );
      
      return allPayments;
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }
  
  // Request refund for a payment
  Future<bool> requestRefund(String bookingId, String paymentReference) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();
      
      // Update payment status in Firestore
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('reference', isEqualTo: paymentReference)
          .limit(1)
          .get();
          
      if (paymentsQuery.docs.isEmpty) {
        _error = 'Payment not found';
        return false;
      }
      
      // Update payment document
      await paymentsQuery.docs.first.reference.update({
        'status': 'refunded',
        'refundedAt': FieldValue.serverTimestamp(),
        'refundReference': _uuid.v4(), // Generate refund reference
      });
      
      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'paymentStatus': 'refunded',
        'cancellationReason': 'Refunded by user',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      _error = 'Refund request failed: ${e.toString()}';
      print('Refund Error: $_error');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  // Verify payment status
  Future<Map<String, dynamic>> verifyPaymentStatus(String reference) async {
    try {
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('reference', isEqualTo: reference)
          .limit(1)
          .get();
          
      if (paymentsQuery.docs.isNotEmpty) {
        final paymentData = paymentsQuery.docs.first.data();
        final createdAt = paymentData['createdAt'] is Timestamp 
            ? (paymentData['createdAt'] as Timestamp).toDate() 
            : null;
            
        return {
          'verified': true,
          'status': paymentData['status'],
          'amount': paymentData['amount'],
          'paymentMethod': paymentData['paymentMethod'],
          'createdAt': createdAt,
          'paymentData': paymentData['paymentData'],
          'bookingId': paymentData['bookingId'],
        };
      } else {
        return {
          'verified': false,
          'message': 'Payment not found',
        };
      }
    } catch (e) {
      print('Error verifying payment: $e');
      return {
        'verified': false,
        'message': 'Error verifying payment: ${e.toString()}',
      };
    }
  }
  
  // Helper method to get payment status display text
  String getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
  
  // Helper method to get payment status color
  Color getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}