// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/firebase_connection_handler.dart';
import '../../../core/services/sync_service.dart';
import '../../widgets/event/event_card.dart';
import '../../widgets/notification_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();
  List _searchResults = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set the build context for EventService
      final eventService = Provider.of<EventService>(context, listen: false);
      eventService.setBuildContext(context);
      
      // Fetch events (this will now use the connectivity-aware implementation)
      eventService.fetchEvents();
      _loadUserNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    if (authService.user != null) {
      await notificationService.getNotifications(authService.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final eventService = Provider.of<EventService>(context);
    final connectivityService = Provider.of<ConnectivityService>(context);
    final firebaseHandler = Provider.of<FirebaseConnectionHandler>(context);
    final syncService = Provider.of<SyncService>(context);

    final upcomingEvents = eventService.filteredEvents
        .where((event) => event.date.isAfter(DateTime.now()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Offline banner
          if (!syncService.isConnected && syncService.hasPendingChanges)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'You\'re offline. Some changes will sync when you\'re back online.',
                      style: TextStyle(color: Colors.amber.shade900),
                    ),
                  ),
                  if (syncService.hasPendingChanges)
                    TextButton(
                      onPressed: syncService.isConnected ? () => syncService.forceSyncNow() : null,
                      child: Text(
                        'Sync Now', 
                        style: TextStyle(
                          color: syncService.isConnected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // Main content
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() => _showSuggestions = false);
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 1,
                    title: const Text('Evently', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    actions: [
                      // Connection status indicator
                      StreamBuilder<bool>(
                        stream: firebaseHandler.connectionState,
                        initialData: firebaseHandler.isFirebaseConnected,
                        builder: (context, snapshot) {
                          final isConnected = connectivityService.isConnected;
                          final isFirebaseConnected = snapshot.data ?? false;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isConnected ? Icons.wifi : Icons.wifi_off,
                                  color: isConnected ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                if (isConnected && !isFirebaseConnected)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.cloud_off,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      // Sync indicator
                      if (syncService.hasPendingChanges)
                        IconButton(
                          icon: Icon(
                            syncService.isSyncing ? Icons.sync : Icons.sync_problem,
                            color: syncService.isSyncing ? Colors.blue : Colors.amber,
                          ),
                          onPressed: syncService.isConnected ? () => syncService.forceSyncNow() : null,
                          tooltip: 'Sync pending changes',
                        ),
                      
                      NotificationIcon.appBar(),
                      IconButton(
                        icon: const Icon(Icons.person_outline, color: Colors.black87),
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          'Hello, ${authService.userModel?.name ?? 'Guest'} 👋',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find your next event adventure',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 20),

                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search events by title',
                              prefixIcon: const Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onChanged: (value) {
                              eventService.setSearchQuery(value);
                              final results = eventService.filteredEvents.where((event) {
                                return event.title.toLowerCase().contains(value.toLowerCase());
                              }).toList();
                              setState(() {
                                _searchResults = results;
                                _showSuggestions = value.isNotEmpty && results.isNotEmpty;
                              });
                            },
                          ),
                        ),

                        // Suggestions dropdown
                        if (_showSuggestions)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final event = _searchResults[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  subtitle: Text(event.location.name, style: const TextStyle(color: Colors.grey)),
                                  onTap: () {
                                    setState(() {
                                      _showSuggestions = false;
                                      _searchController.text = event.title;
                                    });
                                    Navigator.pushNamed(
                                      context,
                                      '/event-details',
                                      arguments: event.id,
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Featured section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '🎉 Featured Events',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/discover');
                              },
                              child: const Text('See All', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ]),
                    ),
                  ),

                  // Featured events list
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: eventService.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : eventService.featuredEvents.isEmpty
                              ? const Center(child: Text('No featured events available'))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(left: 16, right: 8),
                                  itemCount: eventService.featuredEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = eventService.featuredEvents[index];
                                    return EventCard(
                                      event: event,
                                      width: 280,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/event-details',
                                          arguments: event.id,
                                        );
                                      },
                                    );
                                  },
                                ),
                    ),
                  ),

                  // Categories section
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎯 Categories',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildCategoryChip('All', null),
                                ...eventService.getCategories().map((category) {
                                  return _buildCategoryChip(category, category);
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            '📅 Upcoming Events',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Upcoming events list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: eventService.isLoading
                        ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                        : upcomingEvents.isEmpty
                            ? const SliverFillRemaining(child: Center(child: Text('No upcoming events')))
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final event = upcomingEvents[index];
                                    return EventCard(
                                      event: event,
                                      isHorizontal: true,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/event-details',
                                          arguments: event.id,
                                        );
                                      },
                                    );
                                  },
                                  childCount: upcomingEvents.length,
                                ),
                              ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            switch (index) {
              case 1:
                Navigator.pushNamed(context, '/discover');
                break;
              case 2:
                Navigator.pushNamed(context, '/booking-history');
                break;
            }
          },
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookings'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final eventService = Provider.of<EventService>(context);
    final isSelected = eventService.selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          eventService.setSelectedCategory(selected ? category : null);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}