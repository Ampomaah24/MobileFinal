import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/location_service.dart';
import '../../widgets/event/event_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/distance_filter_dialog.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String? _selectedCategory;
  String _sortOption = 'date'; // 'date', 'price', 'distance'
  bool _isAscending = true;
  bool _isGettingLocation = false;
  int _currentTabIndex = 0;
  double _searchRadius = 25000; // Default to 25km

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      
      // If switching to nearby tab, ensure location is available
      if (_currentTabIndex == 1) {
        _ensureLocationAvailable();
      }
    }
  }

  Future<void> _loadEvents() async {
    final eventService = Provider.of<EventService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);

    // Request location permission for nearby events tab
    await locationService.requestLocationPermission();
    
    // Fetch all events
    await eventService.fetchEvents();
    
    // Get location if on nearby tab or sorting by distance
    if (_currentTabIndex == 1 || _sortOption == 'distance') {
      _ensureLocationAvailable();
    }
  }

  Future<void> _ensureLocationAvailable() async {
    if (mounted) {
      setState(() {
        _isGettingLocation = true;
      });
    }
    
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      
      // Get current location and update EventService
      await locationService.getCurrentLocation(context: context);
      
      if (locationService.error != null) {
        // Show error if there was a problem getting location
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationService.error!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _applySearch(String query) {
    final eventService = Provider.of<EventService>(context, listen: false);
    eventService.setSearchQuery(query);
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    
    final eventService = Provider.of<EventService>(context, listen: false);
    eventService.setSelectedCategory(category);
  }

  void _sortEvents() {
    final eventService = Provider.of<EventService>(context, listen: false);
    // Call the sortEvents method from EventService
    eventService.sortEvents(_sortOption, _isAscending);
    
    // If sorting by distance, ensure location is available
    if (_sortOption == 'distance') {
      _ensureLocationAvailable();
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _searchController.clear();
      _sortOption = 'date';
      _isAscending = true;
    });
    
    final eventService = Provider.of<EventService>(context, listen: false);
    eventService.resetFilters();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sort Events By',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isAscending = !_isAscending;
                          });
                        },
                        tooltip: _isAscending ? 'Ascending' : 'Descending',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sort options
                  _buildSortOption(
                    setState,
                    'Date',
                    'date',
                    Icons.calendar_today,
                  ),
                  const Divider(),
                  _buildSortOption(
                    setState,
                    'Price',
                    'price',
                    Icons.attach_money,
                  ),
                  const Divider(),
                  _buildSortOption(
                    setState,
                    'Distance',
                    'distance',
                    Icons.place,
                    needsLocation: true,
                  ),

                  const SizedBox(height: 24),
                  // Apply button
                  ElevatedButton(
                    onPressed: () {
                      this.setState(() {
                        // Update the parent state with the selected options
                        this._sortOption = _sortOption;
                        this._isAscending = _isAscending;
                      });
                      Navigator.pop(context);
                      _sortEvents();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(
    StateSetter setState,
    String title,
    String value,
    IconData icon, {
    bool needsLocation = false,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _sortOption = value;
        });
        
        // If this option needs location, warn the user
        if (needsLocation) {
          final locationService = Provider.of<LocationService>(context, listen: false);
          if (locationService.currentPosition == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location access required for distance sorting'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: _sortOption == value
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: _sortOption == value
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: _sortOption == value
                    ? Theme.of(context).primaryColor
                    : null,
              ),
            ),
            const Spacer(),
            if (_sortOption == value)
              Icon(
                Icons.check,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventService = Provider.of<EventService>(context);
    final locationService = Provider.of<LocationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Events'),
        actions: [
          // Distance filter button (only show in nearby tab)
          if (_currentTabIndex == 1)
            IconButton(
              icon: const Icon(Icons.radar),
              onPressed: _showDistanceFilter,
              tooltip: 'Set distance',
            ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_alt),
            onPressed: _resetFilters,
            tooltip: 'Reset filters',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Events'),
            Tab(text: 'Nearby'),
          ],
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search events',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applySearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: _applySearch,
                ),
                const SizedBox(height: 16),

                // Categories
                _buildCategoryChips(),
              ],
            ),
          ),

          // Events list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All events tab
                _buildEventsList(eventService, false),
                
                // Nearby events tab
                Stack(
                  children: [
                    Column(
                      children: [
                        // Search radius indicator
                        if (_currentTabIndex == 1 && locationService.currentPosition != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.radar, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Search radius: ${(_searchRadius / 1000).toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: _showDistanceFilter,
                                  child: Icon(
                                    Icons.edit,
                                    size: 12,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(child: _buildEventsList(eventService, true)),
                      ],
                    ),
                    if (_isGettingLocation)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: LoadingIndicator(
                            size: LoadingSize.medium,
                            message: 'Getting your location...',
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final eventService = Provider.of<EventService>(context);
    final categories = eventService.getCategories();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('All', null),
          ...categories.map((category) {
            return _buildCategoryChip(category, category);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          _filterByCategory(selected ? category : null);
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _showDistanceFilter() {
    showDialog(
      context: context,
      builder: (context) => DistanceFilterDialog(
        initialDistance: _searchRadius,
        onDistanceChanged: (newRadius) {
          setState(() {
            _searchRadius = newRadius;
          });
          // Refresh the nearby events list with new radius
          if (_currentTabIndex == 1) {
            _loadEvents();
          }
        },
      ),
    );
  }

  Widget _buildEventsList(EventService eventService, bool nearbyOnly) {
    final locationService = Provider.of<LocationService>(context);
    
    // Filter for nearby events if on the nearby tab
    final events = nearbyOnly && locationService.currentPosition != null
        ? eventService.getEventsByLocation(
            locationService.currentPosition!.latitude,
            locationService.currentPosition!.longitude,
            _searchRadius, // Use the configurable search radius
          )
        : eventService.getFilteredEvents;

    if (eventService.isLoading) {
      return const Center(
        child: LoadingIndicator(
          size: LoadingSize.medium,
          message: 'Loading events...',
        ),
      );
    }

    if (nearbyOnly && locationService.currentPosition == null && !_isGettingLocation) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Location access required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Please enable location access to see events near you',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('Get My Location'),
              onPressed: _ensureLocationAvailable,
            ),
          ],
        ),
      );
    }

    if (events.isEmpty) {
      return _buildEmptyState(nearbyOnly);
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
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
      ),
    );
  }

  Widget _buildEmptyState(bool nearbyOnly) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            nearbyOnly ? Icons.location_off : Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            nearbyOnly
                ? 'No events found nearby'
                : 'No events match your search',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              nearbyOnly
                  ? 'Try increasing the search radius or check out events in other areas'
                  : 'Try adjusting your filters or search with different keywords',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedCategory != null || _searchController.text.isNotEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
              onPressed: _resetFilters,
            ),
        ],
      ),
    );
  }
}