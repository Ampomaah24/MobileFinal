import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/models/booking_model.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String? bookingId;
  
  const BookingConfirmationScreen({Key? key, this.bookingId}) : super(key: key);
  
  @override
  _BookingConfirmationScreenState createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  BookingModel? _booking;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // Moved loading to initState from didChangeDependencies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooking();
    });
  }
  
  Future<void> _loadBooking() async {
    // Use the bookingId from the widget instead of from route arguments
    final bookingId = widget.bookingId;
    if (bookingId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    final bookingService = Provider.of<BookingService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get booking by ID (we need to add this method to BookingService)
      final doc = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        setState(() {
          _booking = BookingModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load booking details')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Success icon
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      
                      // Confirmation message
                      Text(
                        'Booking Confirmed!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        'Your booking has been successfully confirmed. We\'ve sent the details to your email.',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Booking details card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking Details',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              
                              // Booking ID
                              _buildDetailRow('Booking ID', _booking!.id.substring(0, 8)),
                              const SizedBox(height: 8),
                              
                              // Event name
                              _buildDetailRow(
                                'Event',
                                _booking!.eventData?['title'] ?? 'Event details not available',
                              ),
                              const SizedBox(height: 8),
                              
                              // Date and time
                              _buildDetailRow(
                                'Date & Time',
                                DateFormat('E, MMM d, yyyy • h:mm a').format(_booking!.bookingDate),
                              ),
                              const SizedBox(height: 8),
                              
                              // Venue
                              _buildDetailRow(
                                'Venue',
                                _booking!.eventData?['location']?['name'] ?? 'Venue details not available',
                              ),
                              const SizedBox(height: 8),
                              
                              // Number of tickets
                              _buildDetailRow('Tickets', '${_booking!.ticketCount}'),
                              const SizedBox(height: 8),
                              
                              // Total amount
                             _buildDetailRow('Total Amount', 'GHS ${_booking!.totalAmount.toStringAsFixed(2)}'),

                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Add to Calendar'),
                        onPressed: () {
                          // Add to calendar functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to calendar')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      OutlinedButton(
                        child: const Text('View My Bookings'),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/booking-history');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextButton(
                        child: const Text('Back to Home'),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}