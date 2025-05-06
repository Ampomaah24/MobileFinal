// lib/presentation/screens/admin/admin_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/booking_service.dart';
import 'admin_drawer.dart';
import 'admin_app_bar.dart';
import 'stat_card.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      final stats = await eventService.getAdminDashboardStats();
      
      setState(() {
        _analyticsData = stats;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Analytics'),
      drawer: const AdminDrawer(currentIndex: 4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Revenue'),
                    Tab(text: 'Bookings'),
                    Tab(text: 'Events'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRevenueTab(),
                      _buildBookingsTab(),
                      _buildEventsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

 Widget _buildRevenueTab() {
  final Map<String, dynamic> revenue = _analyticsData['revenue'] ?? {};
  final double totalRevenue = revenue['total'] ?? 0.0;
  final double todayRevenue = revenue['today'] ?? 0.0;
  final double monthlyRevenue = revenue['monthly'] ?? 0.0;

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Revenue Overview'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Today',
                value: 'GHS ${NumberFormat('#,##0.00').format(todayRevenue)}',
                icon: Icons.today,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'This Month',
                value: 'GHS ${NumberFormat('#,##0.00').format(monthlyRevenue)}',
                icon: Icons.calendar_today,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StatCard(
          title: 'Total Revenue',
          value: 'GHS ${NumberFormat('#,##0.00').format(totalRevenue)}',
          icon: Icons.account_balance_wallet,
          color: Colors.purple,
        ),
        const SizedBox(height: 24),

        // Removed: Revenue Trends chart

        _buildRevenueMetricCard(
          title: 'Average Transaction Value',
          value: totalRevenue > 0
              ? 'GHS ${NumberFormat('#,##0.00').format(totalRevenue / (_analyticsData['bookings']?['total'] ?? 1))}'
              : 'GHS 0.00',
          icon: Icons.trending_up,
        ),
        const SizedBox(height: 16),
        _buildRevenueMetricCard(
          title: 'Revenue per Event',
          value: totalRevenue > 0
              ? 'GHS${NumberFormat('#,##0.00').format(totalRevenue / (_analyticsData['events']?['total'] ?? 1))}'
              : 'GHS 0.00',
          icon: Icons.event,
        ),
      ],
    ),
  );
}

  Widget _buildBookingsTab() {
  final Map<String, dynamic> bookings = _analyticsData['bookings'] ?? {};
  final int totalBookings = bookings['total'] ?? 0;
  final int todayBookings = bookings['today'] ?? 0;

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Booking Statistics'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Today',
                value: todayBookings.toString(),
                icon: Icons.today,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Total',
                value: totalBookings.toString(),
                icon: Icons.confirmation_number,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Removed: Booking Trends chart

        _buildBookingMetricsCard(
          title: 'Conversion Rate',
          value: '${totalBookings > 0 ? (totalBookings / 100).toStringAsFixed(1) : 0}%',
          icon: Icons.swap_horiz,
        ),
      ],
    ),
  );
}


  Widget _buildEventsTab() {
    // Extract events data
    final Map<String, dynamic> events = _analyticsData['events'] ?? {};
    final int totalEvents = events['total'] ?? 0;
    final int upcomingEvents = events['upcoming'] ?? 0;
    final int pastEvents = events['past'] ?? 0;
    final int activeEvents = events['active'] ?? 0;
    final String popularCategory = events['popularCategory'] ?? 'None';
    final Map<String, dynamic> categories = events['categories'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Event Statistics'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Events',
                  value: totalEvents.toString(),
                  icon: Icons.event,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Upcoming',
                  value: upcomingEvents.toString(),
                  icon: Icons.upcoming,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Active',
                  value: activeEvents.toString(),
                  icon: Icons.event_available,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Past',
                  value: pastEvents.toString(),
                  icon: Icons.event_busy,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Category Distribution'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Popular Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Most Popular: $popularCategory',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Simple category visualization instead of a chart
                  ...categories.entries.map((entry) {
                    final percentage = totalEvents > 0 
                        ? (entry.value / totalEvents * 100).toInt() 
                        : 0;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${entry.key} (${entry.value})'),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: totalEvents > 0 ? entry.value / totalEvents : 0,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getCategoryColor(entry.key),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('$percentage%'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildRevenueMetricCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingMetricsCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Simple way to assign colors to categories
    final Map<String, Color> categoryColors = {
      'Music': Colors.purple,
      'Sports': Colors.green,
      'Arts & Theatre': Colors.blue,
      'Food & Drink': Colors.orange,
      'Technology': Colors.teal,
      'Business': Colors.indigo,
      'Health & Wellness': Colors.red,
      'Education': Colors.amber,
      'Outdoors': Colors.lightGreen,
      'Charity': Colors.pink,
    };

    return categoryColors[category] ?? Colors.grey;
  }
}