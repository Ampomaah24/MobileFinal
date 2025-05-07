
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/models/event_model.dart';
import '../../widgets/common/loading_indicator.dart';

class PaymentScreen extends StatefulWidget {
  final EventModel? event;
  final int? ticketCount;
  final DateTime? bookingDate;
  
  const PaymentScreen({
    Key? key,
    this.event,
    this.ticketCount,
    this.bookingDate,
  }) : super(key: key);
  
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String? _errorMessage;
  
  // Local variables to store passed arguments
  EventModel? _event;
  int? _ticketCount;
  DateTime? _bookingDate;
  bool _initialized = false;
  bool _hasError = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeData();
      _initialized = true;
    }
  }
  
  void _initializeData() {
    // If direct props are provided, use them
    if (widget.event != null && widget.ticketCount != null && widget.bookingDate != null) {
      _event = widget.event;
      _ticketCount = widget.ticketCount;
      _bookingDate = widget.bookingDate;
      return;
    }
    
    // Otherwise try to get from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args == null) {
      // Handle missing arguments without using SnackBar during build
      _hasError = true;
      _showErrorAfterBuild('Error: Missing booking information');
      return;
    }
    
    // Extract data from arguments
    if (args is Map<String, dynamic>) {
      _event = args['event'] as EventModel?;
      _ticketCount = args['ticketCount'] as int?;
      _bookingDate = args['bookingDate'] as DateTime?;
      
      // Validate all required data is present
      if (_event == null || _ticketCount == null || _bookingDate == null) {
        _hasError = true;
        _showErrorAfterBuild('Error: Incomplete booking information');
      }
    } else {
      // If arguments are not in the expected format
      _hasError = true;
      _showErrorAfterBuild('Error: Invalid booking information format');
    }
  }
  
  // Show error after build is complete
  void _showErrorAfterBuild(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
        // Navigate back after error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final paymentService = Provider.of<PaymentService>(context);
    
    // Check if user is logged in
    if (authService.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please login to complete your booking'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Handle case where data isn't loaded yet or is invalid
    final event = widget.event ?? _event;
    final ticketCount = widget.ticketCount ?? _ticketCount;
    final bookingDate = widget.bookingDate ?? _bookingDate;
    
    if (_hasError || event == null || ticketCount == null || bookingDate == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Loading payment information...'),
        ),
      );
    }
    
    // Calculate total amount
    final price = event.price;
    final totalAmount = price * ticketCount;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        elevation: 0,
      ),
      body: _isProcessing
          ? const Center(
              child: LoadingIndicator(
                size: LoadingSize.large,
                message: 'Processing payment...',
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event summary card
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.event, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('E, MMM d, yyyy').format(bookingDate),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('h:mm a').format(bookingDate),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location.name,
                                  style: const TextStyle(color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Order summary
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Order details card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildOrderRow(
                            'Ticket price',
                            'GHS ${price.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 24),
                          _buildOrderRow(
                            'Number of tickets',
                            '$ticketCount',
                          ),
                          const Divider(height: 24),
                          _buildOrderRow(
                            'Subtotal',
                            'GHS ${totalAmount.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 24),
                          _buildOrderRow(
                            'Transaction fee',
                            'GHS 0.00',
                            isTotal: false,
                          ),
                          const Divider(height: 24),
                          _buildOrderRow(
                            'Total',
                            'GHS ${totalAmount.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Payment button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _processPayment(context),
                      icon: const Icon(Icons.payment),
                      label: const Text(
                        'Pay with PayStack',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  // Payment information
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your payment is securely processed by PayStack. We do not store your payment details.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildOrderRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
      ],
    );
  }
  
  Future<void> _processPayment(BuildContext context) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    final bookingService = Provider.of<BookingService>(context, listen: false);
    
    try {
      if (authService.user == null || authService.userModel == null) {
        throw Exception('User not authenticated');
      }
      
      // Get the event and ticket count
      final event = widget.event ?? _event;
      final ticketCount = widget.ticketCount ?? _ticketCount;
      final bookingDate = widget.bookingDate ?? _bookingDate;
      
      // Make sure we have all the necessary data
      if (event == null || ticketCount == null || bookingDate == null) {
        throw Exception('Missing booking information');
      }
      
      // Process payment
      final paymentResult = await paymentService.processPayment(
        context: context,
        event: event,
        userId: authService.user!.uid,
        userEmail: authService.user!.email!,
        ticketCount: ticketCount,
        bookingDate: bookingDate,
      );
      
      if (paymentResult['success'] == true) {
        // Create booking ONLY after successful payment
        final booking = await bookingService.createBooking(
          userId: authService.user!.uid,
          event: event,
          ticketCount: ticketCount,
          bookingDate: bookingDate,
          userData: {
            'name': authService.userModel!.name,
            'email': authService.userModel!.email,
            'phone': authService.userModel!.phone,
          },
        );
        
        if (booking != null) {
          // Save payment details
          await paymentService.savePaymentDetails(
            bookingId: booking.id,
            reference: paymentResult['reference'],
            amount: paymentResult['amount'],
            paymentMethod: 'PayStack',
            status: 'completed',
            paymentData: paymentResult['data'],
          );
          
          // Navigate to booking confirmation
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/booking-confirmation',
              (route) => route.settings.name == '/home',
              arguments: booking.id,
            );
          }
        } else {
          throw Exception('Failed to create booking');
        }
      } else {
        setState(() {
          _errorMessage = paymentResult['message'] ?? 'Payment failed';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment error: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }
}