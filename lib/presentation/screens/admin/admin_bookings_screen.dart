
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/models/booking_model.dart';
import '../admin/admin_drawer.dart';
import '../admin/admin_app_bar.dart';
import 'admin_booking_details_screen.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  bool _isLoading = true;
  List<BookingModel> _bookings = [];
  String _searchQuery = '';
  String _statusFilter = 'All';
  
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the widget tree is built before loading bookings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }
  
  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    
    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final bookings = await bookingService.getAllBookings();
      
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }
  
  List<BookingModel> get _filteredBookings {
    List<BookingModel> result = _bookings;
    
    // Apply status filter
    if (_statusFilter != 'All') {
      result = result.where((booking) => booking.status == _statusFilter).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((booking) {
        final eventTitle = booking.eventData?['title'] as String? ?? '';
        final userName = booking.userData?['name'] as String? ?? '';
        
        return booking.id.contains(_searchQuery) ||
               eventTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               userName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Manage Bookings'),
      drawer: const AdminDrawer(currentIndex: 3),
      body: Column(
        children: [
       
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search bookings...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                    DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _statusFilter = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Bookings list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBookings.isEmpty
                    ? const Center(child: Text('No bookings found'))
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _filteredBookings[index];
                            return _buildBookingCard(booking);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBookingCard(BookingModel booking) {
    final eventTitle = booking.eventData?['title'] as String? ?? 'Unknown Event';
    final userName = booking.userData?['name'] as String? ?? 'Unknown User';
    final bookingDate = DateFormat('MMM d, yyyy • h:mm a').format(booking.bookingDate);
    
    // Determine status color
    Color statusColor;
    switch (booking.status) {
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                eventTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Customer: $userName'),
            Text('Date: $bookingDate'),
            Text('Tickets: ${booking.ticketCount} • Total: GHS ${booking.totalAmount.toStringAsFixed(2)}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showBookingActions(booking),
        ),
        onTap: () => _showBookingDetails(booking),
      ),
    );
  }
  
  void _showBookingActions(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showBookingDetails(booking);
              },
            ),
            if (booking.status == 'Pending')
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Confirm Booking'),
                onTap: () {
                  Navigator.pop(context);
                  _updateBookingStatus(booking, 'Confirmed');
                },
              ),
            if (booking.status != 'Cancelled' && booking.status != 'Completed')
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancel Booking'),
                onTap: () {
                  Navigator.pop(context);
                  _updateBookingStatus(booking, 'Cancelled');
                },
              ),
            if (booking.status == 'Confirmed')
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.blue),
                title: const Text('Mark as Completed'),
                onTap: () {
                  Navigator.pop(context);
                  _updateBookingStatus(booking, 'Completed');
                },
              ),
          ],
        );
      },
    );
  }
  
  void _showBookingDetails(BookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminBookingDetailsScreen(booking: booking),
      ),
    ).then((_) => _loadBookings());
  }
  
  Future<void> _updateBookingStatus(BookingModel booking, String newStatus) async {
    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      await bookingService.updateBookingStatus(booking.id, newStatus);
      
      await _loadBookings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}