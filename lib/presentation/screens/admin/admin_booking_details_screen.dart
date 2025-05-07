// lib/presentation/screens/admin/admin_booking_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/models/booking_model.dart';
import 'admin_app_bar.dart';

class AdminBookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;
  
  const AdminBookingDetailsScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<AdminBookingDetailsScreen> createState() => _AdminBookingDetailsScreenState();
}

class _AdminBookingDetailsScreenState extends State<AdminBookingDetailsScreen> {
  bool _isLoading = false;
  late BookingModel _booking;
  
  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }
  
  Future<void> _updateBookingStatus(String status) async {
    setState(() => _isLoading = true);
    
    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      await bookingService.updateBookingStatus(_booking.id, status);
      
      // Refresh booking details after update
      final updatedBooking = await bookingService.getBookingById(_booking.id);
      
      if (updatedBooking != null) {
        setState(() {
          _booking = updatedBooking;
          _isLoading = false;
        });
      } else {
        // If unable to fetch updated booking, just update status locally
        setState(() {
          _booking = _booking.copyWith(status: status);
          _isLoading = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(title: 'Booking #${_booking.id.substring(0, 8)}'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildEventDetails(),
                  const SizedBox(height: 24),
                  _buildCustomerDetails(),
                  const SizedBox(height: 24),
                  _buildBookingDetails(),
                  const SizedBox(height: 24),
                  _buildPaymentDetails(),
                  const SizedBox(height: 32),
                  _buildActions(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildStatusCard() {
    // Determine status color
    Color statusColor;
    switch (_booking.status) {
      case 'Confirmed':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      case 'Completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(_booking.status),
              color: statusColor,
              size: 36,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _booking.status,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: _updateBookingStatus,
              itemBuilder: (context) => [
                if (_booking.status != 'Confirmed')
                  const PopupMenuItem(
                    value: 'Confirmed',
                    child: Text('Mark as Confirmed'),
                  ),
                if (_booking.status != 'Pending')
                  const PopupMenuItem(
                    value: 'Pending',
                    child: Text('Mark as Pending'),
                  ),
                if (_booking.status != 'Completed')
                  const PopupMenuItem(
                    value: 'Completed',
                    child: Text('Mark as Completed'),
                  ),
                if (_booking.status != 'Cancelled')
                  const PopupMenuItem(
                    value: 'Cancelled',
                    child: Text('Mark as Cancelled'),
                  ),
              ],
              child: const Chip(
                label: Text('Change Status'),
                avatar: Icon(Icons.edit),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Confirmed':
        return Icons.check_circle;
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Cancelled':
        return Icons.cancel;
      case 'Completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }
  
  Widget _buildEventDetails() {
    final eventTitle = _booking.eventData?['title'] as String? ?? 'Unknown Event';
    final eventDate = _booking.bookingDate;
    final eventLocation = _booking.eventData?['location'] != null
        ? _booking.eventData!['location'] is String
            ? _booking.eventData!['location']
            : _booking.eventData!['location']['name'] ?? 'Unknown Location'
        : 'Unknown Location';
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Event Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              eventTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              'Date',
              DateFormat('EEEE, MMMM d, yyyy').format(eventDate),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.access_time,
              'Time',
              DateFormat('h:mm a').format(eventDate),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.location_on,
              'Location',
              eventLocation.toString(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomerDetails() {
    final userName = _booking.userData?['name'] as String? ?? 'Unknown User';
    final userEmail = _booking.userData?['email'] as String? ?? 'Unknown Email';
    final userId = _booking.userId;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Customer Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.person_outline,
              'Name',
              userName,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.email,
              'Email',
              userEmail,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.badge,
              'User ID',
              userId,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBookingDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.confirmation_number, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Booking Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.confirmation_number_outlined,
              'Booking ID',
              _booking.id,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.date_range,
              'Booking Date',
              DateFormat('MMM d, yyyy • h:mm a').format(_booking.createdAt),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.people,
              'Ticket Count',
              '${_booking.ticketCount} tickets',
            ),
            if (_booking.updatedAt != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.update,
                'Last Updated',
                DateFormat('MMM d, yyyy • h:mm a').format(_booking.updatedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Payment Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.receipt,
              'Ticket Price',
              'GHS ${(_booking.totalAmount / _booking.ticketCount).toStringAsFixed(2)} each',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.money,
              'Total Amount',
              'GHS ${_booking.totalAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.payment,
              'Payment Method',
              'Credit Card', 
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.check_circle,
              'Payment Status',
              'Paid', 
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
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
  
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.email),
            label: const Text('Email Customer'),
            onPressed: () {
      
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Print Details'),
            onPressed: () {
         
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}