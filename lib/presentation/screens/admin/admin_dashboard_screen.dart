// lib/presentation/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/booking_service.dart';
import 'admin_drawer.dart';
import 'admin_app_bar.dart';
import 'stat_card.dart';
import '../admin/event_form_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardStats = {};
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _navigateToEventForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventFormScreen(),
      ),
    );
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final eventService = Provider.of<EventService>(context, listen: false);
    
    try {
      // Fetch dashboard statistics
      final stats = await eventService.getAdminDashboardStats();
      
      setState(() {
        _dashboardStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Admin Dashboard'),
      drawer: const AdminDrawer(currentIndex: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(),
                    const SizedBox(height: 24),
                    
                    // Statistics cards
                    _buildStatsGrid(),
                    
                    const SizedBox(height: 30),
                    
                    // Quick actions section
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildWelcomeHeader() {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.userModel?.name ?? 'Admin';
    final currentDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.9),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $userName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentDate,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsGrid() {
    final events = _dashboardStats['events'] ?? {};
    final bookings = _dashboardStats['bookings'] ?? {};
    final revenue = _dashboardStats['revenue'] ?? {};
    
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          title: 'Total Events',
          value: events['total']?.toString() ?? '0',
          subtitle: '${events['upcoming'] ?? 0} upcoming',
          icon: Icons.event,
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/admin/events'),
        ),
        StatCard(
          title: 'Bookings',
          value: bookings['total']?.toString() ?? '0',
          subtitle: '${bookings['today'] ?? 0} today',
          icon: Icons.confirmation_number,
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, '/admin/bookings'),
        ),
        StatCard(
          title: 'Revenue',
          value: 'GHS ${revenue['total']?.toStringAsFixed(2) ?? '0.00'}',
          subtitle: 'GHS ${revenue['today']?.toStringAsFixed(2) ?? '0.00'} today',
          icon: Icons.attach_money,
          color: Colors.purple,
          onTap: () => Navigator.pushNamed(context, '/admin/analytics'),
        ),
        StatCard(
          title: 'Active Events',
          value: events['active']?.toString() ?? '0',
          subtitle: 'Available for booking',
          icon: Icons.event_available,
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, '/admin/events'),
        ),
      ],
    );
  }
  
  Widget _buildQuickActions() {
    return Container(
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildActionCard(
            title: 'New Event',
            icon: Icons.add_circle_outline,
            color: Theme.of(context).primaryColor,
            onTap: _navigateToEventForm,
          ),     
          _buildActionCard(
            title: 'Manage Users',
            icon: Icons.people_outline,
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/admin/users'),
          ),
          _buildActionCard(
            title: 'View Bookings',
            icon: Icons.confirmation_number_outlined,
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, '/admin/bookings'),
          ),
          _buildActionCard(
            title: 'Analytics',
            icon: Icons.bar_chart_outlined,
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, '/admin/analytics'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}