import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/event_model.dart';

class EventDetailsScreen extends StatefulWidget {
  final String? eventId;
  const EventDetailsScreen({Key? key, this.eventId}) : super(key: key);

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  EventModel? _event;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _distanceText;

  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvent();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 200;
    if (showTitle != _showTitle) {
      setState(() => _showTitle = showTitle);
    }
  }

  Future<void> _loadEvent() async {
    final eventId = widget.eventId ?? ModalRoute.of(context)!.settings.arguments as String;
    final eventService = Provider.of<EventService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      final event = await eventService.getEventById(eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
        _checkFavoriteStatus(eventId);
        _calculateDistance(event);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading event: $e')),
        );
      }
    }
  }

  Future<void> _checkFavoriteStatus(String eventId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.userModel?.preferences != null) {
      final favs = List<String>.from(authService.userModel!.preferences?['favoriteEvents'] ?? []);
      setState(() => _isFavorite = favs.contains(eventId));
    }
  }

  Future<void> _calculateDistance(EventModel? event) async {
    if (event == null) return;
    final locationService = Provider.of<LocationService>(context, listen: false);
    try {
      await locationService.getCurrentLocation();
      if (locationService.currentPosition != null) {
        final distance = await locationService.getDistanceToEvent(
          event.location.geopoint.latitude,
          event.location.geopoint.longitude,
        );
        setState(() => _distanceText = locationService.formatDistance(distance));
      }
    } catch (_) {}
  }

  void _toggleFavorite() async {
    if (_event == null) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to save favorites')));
      return;
    }

    setState(() => _isFavorite = !_isFavorite);
    try {
      final prefs = authService.userModel?.preferences ?? {};
      List<String> favs = List<String>.from(prefs['favoriteEvents'] ?? []);
      _isFavorite ? favs.add(_event!.id) : favs.remove(_event!.id);
      prefs['favoriteEvents'] = favs;
      await authService.updateProfile(preferences: prefs);
    } catch (_) {
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update favorites')));
    }
  }

  void _shareEvent() {
    if (_event == null) return;
    final String msg = 'Check out ${_event!.title} on ${DateFormat('E, MMM d').format(_event!.date)} at ${_event!.location.name}!';
    Share.share('$msg\nhttps://evently.app/events/${_event!.id}');
  }

  Future<void> _openDirections() async {
    if (_event == null) return;
    final lat = _event!.location.geopoint.latitude;
    final lng = _event!.location.geopoint.longitude;
    final name = Uri.encodeComponent(_event!.location.name);
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_name=$name');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open map')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? const Center(child: Text('Event not found'))
              : Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 300,
                          pinned: true,
                          backgroundColor: Colors.black,
                          title: _showTitle
                              ? Text(_event!.title, style: const TextStyle(fontWeight: FontWeight.bold))
                              : null,
                          actions: [
                            IconButton(
                              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                              onPressed: _toggleFavorite,
                              color: _isFavorite ? Colors.red : Colors.white,
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: _shareEvent,
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
     CachedNetworkImage(
  imageUrl: _event?.imageUrl?.isNotEmpty == true
      ? _event!.imageUrl
      : 'https://via.placeholder.com/600x400?text=No+Image+Available',
  fit: BoxFit.cover,
  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
  errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 48)),
),

                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.black54, Colors.black.withOpacity(0.05)],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(24),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_event!.title, style: theme.textTheme.headlineMedium),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(_event!.category,
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              )),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'GHS ${_event!.price.toStringAsFixed(2)}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_month_outlined, size: 20),
                                            const SizedBox(width: 12),
                                            Text(
                                              DateFormat('EEE, MMM d • h:mm a').format(_event!.date),
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(_event!.location.name,
                                                      style: theme.textTheme.bodyLarge?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      )),
                                                  const SizedBox(height: 4),
                                                  Text(_event!.location.address,
                                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                                                  if (_distanceText != null) ...[
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Text(
                                                        _distanceText!,
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  ]
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.directions, size: 16),
                                              label: const Text("Map"),
                                              onPressed: _openDirections,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orangeAccent,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 100),
                            ]),
                          ),
                        ),
                      ],
                    ),

                    // Booking button
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: ElevatedButton(
                        onPressed: _event!.date.isAfter(DateTime.now())
                            ? () => Navigator.pushNamed(context, '/booking', arguments: _event!.id)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          backgroundColor: _event!.date.isAfter(DateTime.now())
                              ? theme.primaryColor
                              : Colors.grey,
                          elevation: 6,
                        ),
                        child: Text(
                          _event!.date.isAfter(DateTime.now())
                              ? 'Book Now – GHS ${_event!.price.toStringAsFixed(2)}'
                              : 'Event has ended',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
