
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/booking_model.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final UserModel user;
  
  const AdminUserDetailsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  List<BookingModel> _userBookings = [];
  Map<String, dynamic> _userStats = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final userBookings = await bookingService.getUserBookings(widget.user.uid);
      
      // Example user stats calculation
      final totalSpent = userBookings.fold<double>(
        0, (sum, booking) => sum + booking.totalAmount);
      final totalEvents = userBookings.length;
      final bookingStatuses = {
        'Confirmed': 0,
        'Cancelled': 0,
      };
      
      for (final booking in userBookings) {
        if (bookingStatuses.containsKey(booking.status)) {
          bookingStatuses[booking.status] = bookingStatuses[booking.status]! + 1;
        }
      }
      
      setState(() {
        _userBookings = userBookings;
        _userStats = {
          'totalSpent': totalSpent,
          'totalEvents': totalEvents,
          'bookingStatuses': bookingStatuses,
          'firstBookingDate': userBookings.isNotEmpty 
              ? userBookings.map((b) => b.createdAt ?? DateTime.now()).reduce(
                  (min, date) => date.isBefore(min) ? date : min)
              : null,
          'lastBookingDate': userBookings.isNotEmpty 
              ? userBookings.map((b) => b.createdAt ?? DateTime.now()).reduce(
                  (max, date) => date.isAfter(max) ? date : max)
              : null,
        };
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _updateUserAdminStatus() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateUserAdminStatus(widget.user.uid, !widget.user.isAdmin);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.user.isAdmin
                  ? 'Admin rights removed'
                  : 'User is now an admin',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User: ${widget.user.name}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'toggleAdmin') {
                _updateUserAdminStatus();
              } else if (value == 'resetPassword') {
                _showResetPasswordConfirmation();
              } else if (value == 'deleteUser') {
                _showDeleteUserConfirmation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggleAdmin',
                child: Text(widget.user.isAdmin ? 'Remove Admin Rights' : 'Make Admin'),
              ),
              const PopupMenuItem(
                value: 'resetPassword',
                child: Text('Reset Password'),
              ),
              const PopupMenuItem(
                value: 'deleteUser',
                child: Text('Delete User', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Bookings'),
            
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildBookingsTab(),
               
              ],
            ),
    );
  }
  
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),
          const SizedBox(height: 24),
          _buildUserDetails(),
          const SizedBox(height: 24),
          _buildUserStats(),
        ],
      ),
    );
  }
  
  Widget _buildUserHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: widget.user.profileImageUrl.isNotEmpty
                ? NetworkImage(widget.user.profileImageUrl)
                : null,
            child: widget.user.profileImageUrl.isEmpty
                ? Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0] : '?',
                    style: const TextStyle(fontSize: 40),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.user.isAdmin ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.user.isAdmin ? 'Admin' : 'User',
              style: TextStyle(
                color: widget.user.isAdmin ? Colors.blue[900] : Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildDetailRow('User ID', widget.user.uid),
            const SizedBox(height: 8),
            _buildDetailRow('Email', widget.user.email),
            const SizedBox(height: 8),
            _buildDetailRow('Name', widget.user.name),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Account Created', 
              'January 15, 2023', // Replace with actual data
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Last Login', 
              'Today, 10:30 AM', // Replace with actual data
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserStats() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildDetailRow(
              'Total Bookings', 
              _userStats['totalEvents'].toString(),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Total Spent', 
              'GHS ${_userStats['totalSpent'].toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'First Booking', 
              _userStats['firstBookingDate'] != null
                  ? DateFormat('MMM d, yyyy').format(_userStats['firstBookingDate'])
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Latest Booking', 
              _userStats['lastBookingDate'] != null
                  ? DateFormat('MMM d, yyyy').format(_userStats['lastBookingDate'])
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Completed Events', 
              _userStats['bookingStatuses']['Completed'].toString(),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Cancelled Bookings', 
              _userStats['bookingStatuses']['Cancelled'].toString(),
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
          width: 140,
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
  
  Widget _buildBookingsTab() {
    return _userBookings.isEmpty
        ? const Center(child: Text('No bookings found for this user'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _userBookings.length,
            itemBuilder: (context, index) {
              final booking = _userBookings[index];
              return _buildBookingCard(booking);
            },
          );
  }
  
  Widget _buildBookingCard(BookingModel booking) {
    final eventTitle = booking.eventData?['title'] as String? ?? 'Unknown Event';
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
            Text('Date: $bookingDate'),
            Text('Tickets: ${booking.ticketCount} • Total:GHS ${booking.totalAmount.toStringAsFixed(2)}'),
          ],
        ),
        onTap: () {
          // Navigate to booking details
          Navigator.pushNamed(
            context,
            '/admin/bookings/details',
            arguments: booking,
          );
        },
      ),
    );
  }
  

  
  void _showResetPasswordConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to ${widget.user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetUserPassword();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteUserConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${widget.user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _resetUserPassword() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resetPassword(widget.user.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent'),
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
  
  Future<void> _deleteUser() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.deleteUser(widget.user.uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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