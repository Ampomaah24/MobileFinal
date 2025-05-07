
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/models/event_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../presentation/screens/booking/payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final String? eventId;
  
  const BookingScreen({Key? key, this.eventId}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  EventModel? _event;
  bool _isLoading = true;
  int _ticketCount = 1;
  final int _maxTickets = 10;
  bool _isProcessingBooking = false;
  
  @override
  void initState() {
    super.initState();
    // Use post-frame callback to load event after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvent();
    });
  }
  
  Future<void> _loadEvent() async {
    final eventId = widget.eventId ?? ModalRoute.of(context)!.settings.arguments as String;
    final eventService = Provider.of<EventService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final event = await eventService.getEventById(eventId);
      if (mounted) {
        setState(() {
          _event = event;
          // Ensure we don't allow selecting more tickets than available
          if (event != null && _ticketCount > event.availableSpots) {
            _ticketCount = event.availableSpots > 0 ? event.availableSpots : 1;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading event: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
 void _proceedToPayment() async {
  if (_event == null) return;
  
  final authService = Provider.of<AuthService>(context, listen: false);
  
  // Check if user is logged in
  if (authService.user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please sign in to book this event'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
    
    // Navigate to login screen with return route
    final result = await Navigator.pushNamed(context, '/login');
    if (result == null || result != true) {
      return; // User didn't complete login
    }
  }
  
  setState(() {
    _isProcessingBooking = true;
  });
  
  try {
    // Verify event availability again before proceeding to payment
    if (_event!.availableSpots < _ticketCount) {
      throw Exception('Not enough tickets available');
    }
    
    // Navigate to payment screen with necessary data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          event: _event,
          ticketCount: _ticketCount,
          bookingDate: _event!.date,
        ),
      ),
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isProcessingBooking = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Booking'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? const Center(child: Text('Event not found'))
              : _buildBookingForm(),
      bottomNavigationBar: _event == null || _isLoading
          ? null
          : _buildBottomBar(),
    );
  }
  
  Widget _buildBookingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event summary card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: _event!.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),
                
                // Event details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event title
                      Text(
                        _event!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Event date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(_event!.date),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Event time
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('h:mm a').format(_event!.date),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Event location
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _event!.location.name,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  _event!.location.address,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Ticket selection section
          const Text(
            'Select Tickets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'General Admission',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'GHS ${_event!.price.toStringAsFixed(2)} / ticket',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Available tickets
                  Text(
                    '${_event!.availableSpots} tickets available',
                    style: TextStyle(
                      color: _event!.availableSpots < 10 ? Colors.orange : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Ticket quantity selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity'),
                      Row(
                        children: [
                          // Decrease button
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _ticketCount > 1
                                ? () {
                                    setState(() {
                                      _ticketCount--;
                                    });
                                  }
                                : null,
                            color: Theme.of(context).primaryColor,
                          ),
                          
                          // Ticket count
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$_ticketCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Increase button
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: (_ticketCount < _maxTickets && _ticketCount < _event!.availableSpots)
                                ? () {
                                    setState(() {
                                      _ticketCount++;
                                    });
                                  }
                                : null,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Order summary section
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Ticket price
                  _buildSummaryRow(
                    'Ticket Price',
                    'GHS ${_event!.price.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  
                  // Quantity
                  _buildSummaryRow(
                    'Quantity',
                    '$_ticketCount ${_ticketCount > 1 ? 'tickets' : 'ticket'}',
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtotal
                  _buildSummaryRow(
                    'Subtotal',
                    'GHS ${(_event!.price * _ticketCount).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  
                  // Service fee (example)
                  _buildSummaryRow(
                    'Service Fee',
                    'GHS 0.00',
                  ),
                  
                  const Divider(height: 24),
                  
                  // Total
                  _buildSummaryRow(
                    'Total',
                    'GHS ${(_event!.price * _ticketCount).toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment information
          const Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: const Icon(Icons.payment, color: Colors.green),
                    ),
                    title: const Text('PayStack'),
                    subtitle: const Text('Secure payment via PayStack'),
                    trailing: const Icon(Icons.credit_card, size: 30),
                  ),
                  const Divider(),
                  const ListTile(
                    title: Text('Accepted Payment Methods'),
                    subtitle: Text('Visa, Mastercard, Mobile Money'),
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Additional information
          const Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'After proceeding, you will be redirected to our secure payment gateway to complete your purchase.',
            style: TextStyle(color: Colors.grey),
          ),
          
          // Add space at the bottom for the bottom sheet
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Total price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'GHS ${(_event!.price * _ticketCount).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            
            // Proceed to Payment button 
            ElevatedButton(
              onPressed: (_isProcessingBooking || !_event!.isAvailable || _event!.availableSpots < _ticketCount)
                  ? null
                  : _proceedToPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isProcessingBooking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Proceed to Payment',  
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}