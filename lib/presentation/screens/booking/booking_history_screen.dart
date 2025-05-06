import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/models/booking_model.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookings());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = Provider.of<BookingService>(context, listen: false);

    if (authService.user != null) {
      await bookingService.fetchUserBookings(authService.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bookingService = Provider.of<BookingService>(context);

    if (authService.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Sign in to view your bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You need to be signed in to see your booking history', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: bookingService.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(
                    context,
                    bookingService.bookings.where((b) => b.status.toLowerCase() == 'confirmed' && b.bookingDate.isAfter(DateTime.now())).toList(),
                    'upcoming',
                  ),
                  _buildBookingsList(
                    context,
                    bookingService.bookings.where((b) => b.status.toLowerCase() == 'confirmed' && b.bookingDate.isBefore(DateTime.now())).toList(),
                    'past',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context, List<BookingModel> bookings, String type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'upcoming' ? Icons.event_available : Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'upcoming' ? 'No upcoming bookings' : 'No past bookings',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'upcoming'
                  ? 'Explore events and book your next experience'
                  : 'Your completed bookings will appear here',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (type == 'upcoming')
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/discover'),
                child: const Text('Discover Events'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _buildBookingCard(context, bookings[index], type),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking, String type) {
    final eventTitle = booking.eventData?['title'] ?? 'Event details not available';
    final eventImageUrl = booking.eventData?['imageUrl'] ?? '';
    final venueName = booking.eventData?['location']?['name'] ?? 'Venue not available';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: type == 'upcoming' ? Colors.green : Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  type == 'upcoming' ? Icons.event_available : Icons.event,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  type == 'upcoming' ? 'Upcoming' : 'Completed',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'Booking ID: ${booking.id.substring(0, 8)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/event-details', arguments: booking.eventId),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: eventImageUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: eventImageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[300], child: const Icon(Icons.event, color: Colors.grey)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(eventTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(DateFormat('E, MMM d, yyyy').format(booking.bookingDate), style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(DateFormat('h:mm a').format(booking.bookingDate), style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                venueName,
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
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${booking.ticketCount} ${booking.ticketCount > 1 ? 'tickets' : 'ticket'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Total: GHS ${booking.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
                ]),
                if (type == 'past')
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/event-details', arguments: booking.eventId),
                    child: const Text('Book Again'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
