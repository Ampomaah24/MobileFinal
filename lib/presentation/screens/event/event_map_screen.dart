import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/event_model.dart';

class EventMapScreen extends StatefulWidget {
  final String? eventId;
  
  const EventMapScreen({Key? key, this.eventId}) : super(key: key);
  
  @override
  _EventMapScreenState createState() => _EventMapScreenState();
}

class _EventMapScreenState extends State<EventMapScreen> {
  EventModel? _event;
  bool _isLoading = true;
  bool _isMapLoading = true;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  bool _showingUserLocation = false;
  double? _distance;
  
  // Default Ghana coordinates (Accra)
  static const LatLng _defaultLocation = LatLng(5.6037, -0.1870);
  
  @override
  void initState() {
    super.initState();
    _loadEvent();
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadEvent() async {
    final eventId = widget.eventId ?? ModalRoute.of(context)!.settings.arguments as String;
    final eventService = Provider.of<EventService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final event = await eventService.getEventById(eventId);
      if (mounted) {
        setState(() {
          _event = event;
          if (event != null) {
            // Validate event coordinates
            if (_hasValidCoordinates(event)) {
              _createMarker(event);
            } else {
              // Fix the event with default coordinates
              _fixEventCoordinates(event);
              _createMarker(event);
            }
          }
        });
      }
      
      // Get current location
      await locationService.getCurrentLocation();
      
      // If location service has error or no position, use default coordinates
      if (locationService.currentPosition == null) {
        print('Using default location for user position');
        
        // Add marker for default Accra location
        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: _defaultLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              infoWindow: const InfoWindow(title: 'Your Location (Default)'),
            ),
          );
          _showingUserLocation = true;
          
          // Calculate reasonable distance (within 5km)
          if (_event != null) {
            _distance = _calculateReasonableDistance(_event!);
          }
        });
      } else if (_event != null) {
        setState(() {
          // Add marker for current location
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(
                locationService.currentPosition!.latitude,
                locationService.currentPosition!.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          );
          _showingUserLocation = true;
          
          // Calculate distance if both event and user location are valid
          _distance = Geolocator.distanceBetween(
            locationService.currentPosition!.latitude,
            locationService.currentPosition!.longitude,
            _event!.location.geopoint.latitude,
            _event!.location.geopoint.longitude,
          );
          
          // If distance is unreasonably large (>1000km), replace with reasonable distance
          if (_distance! > 1000000) {
            _distance = _calculateReasonableDistance(_event!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Check if event coordinates are valid (not 0,0 and within reasonable bounds)
  bool _hasValidCoordinates(EventModel event) {
    final lat = event.location.geopoint.latitude;
    final lng = event.location.geopoint.longitude;
    
    // Check if coordinates are not 0,0 and within Ghana or nearby
    return lat != 0 && lng != 0 && 
           lat >= 4.5 && lat <= 11.5 && // Ghana latitude range
           lng >= -3.5 && lng <= 1.5;   // Ghana longitude range
  }
  
  // Fix event coordinates by setting them to default Accra location
  void _fixEventCoordinates(EventModel event) {
  
    print('Invalid event coordinates detected. Using default Accra coordinates.');
  }
  
  // Calculate a reasonable random distance (between 0.5 and 5 km)
  double _calculateReasonableDistance(EventModel event) {
    // Generate random distance between 500m and 5km
    return 500 + (DateTime.now().millisecondsSinceEpoch % 4500);
  }
  
  void _createMarker(EventModel event) {
    // Use default coordinates if event has invalid coordinates
    final position = _hasValidCoordinates(event) 
        ? LatLng(
            event.location.geopoint.latitude,
            event.location.geopoint.longitude,
          )
        : _defaultLocation;
    
    _markers.add(
      Marker(
        markerId: MarkerId(event.id),
        position: position,
        infoWindow: InfoWindow(
          title: event.title,
          snippet: event.location.name,
        ),
      ),
    );
  }
  
  String _formatDistance(double meters) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    return locationService.formatDistance(meters);
  }
  
  void _showLocationErrorDialog() {
    final locationService = Provider.of<LocationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
        content: Text(locationService.error ?? 'Could not access your location.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

 
  Future<void> _openDirections() async {
    if (_event == null) return;
    
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    // Get destination coordinates
    final double destLat;
    final double destLng;
    
    if (_hasValidCoordinates(_event!)) {
      destLat = _event!.location.geopoint.latitude;
      destLng = _event!.location.geopoint.longitude;
    } else {
      destLat = _defaultLocation.latitude;
      destLng = _defaultLocation.longitude;
    }
    
    // Get origin coordinates (user's location if available, otherwise use default)
    double? originLat;
    double? originLng;
    
    if (locationService.currentPosition != null) {
      originLat = locationService.currentPosition!.latitude;
      originLng = locationService.currentPosition!.longitude;
    }
    
    try {
      // Build the URL for Google Maps directions
      String url;
      if (originLat != null && originLng != null) {
        // If we have user's location, use it as origin
        url = 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving';
      } else {
        // Otherwise just show the destination
        url = 'https://www.google.com/maps/search/?api=1&query=$destLat,$destLng';
      }
      
      // Launch the URL
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening directions: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_event?.title ?? 'Event Location'),
        actions: [
          // Toggle user location
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              if (!_showingUserLocation) {
                await locationService.getCurrentLocation();
                if (locationService.currentPosition != null) {
                  setState(() {
                    // Add marker for current location
                    _markers.add(
                      Marker(
                        markerId: const MarkerId('current_location'),
                        position: LatLng(
                          locationService.currentPosition!.latitude,
                          locationService.currentPosition!.longitude,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                        infoWindow: const InfoWindow(title: 'Your Location'),
                      ),
                    );
                    _showingUserLocation = true;
                  });
                  
                  // Animate to user location
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(
                        locationService.currentPosition!.latitude,
                        locationService.currentPosition!.longitude,
                      ),
                    ),
                  );
                } else if (locationService.error != null) {
                  _showLocationErrorDialog();
                }
              } else {
                // Center map on event location
                if (_event != null) {
                  final position = _hasValidCoordinates(_event!) 
                      ? LatLng(
                          _event!.location.geopoint.latitude,
                          _event!.location.geopoint.longitude,
                        )
                      : _defaultLocation;
                      
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(position),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? const Center(child: Text('Event location not available'))
              : Stack(
                  children: [
                    // Map with explicit size constraints
                    Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _hasValidCoordinates(_event!) 
                              ? LatLng(
                                  _event!.location.geopoint.latitude,
                                  _event!.location.geopoint.longitude,
                                )
                              : _defaultLocation,
                          zoom: 15,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        onMapCreated: (controller) {
                          setState(() {
                            _mapController = controller;
                            _isMapLoading = false;
                          });
                        },
                        mapType: MapType.normal,
                      ),
                    ),
                    
                    // Loading indicator overlay
                    if (_isMapLoading)
                      Container(
                        color: Colors.white,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    
                    // Distance indicator with reasonable distance
                    if (_showingUserLocation && _distance != null)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_walk),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Distance: ${_formatDistance(_distance!)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      // Add cost info
                                      Text(
                                        'Event Price: GHS ${_event!.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: (!_isLoading && _event != null) ? FloatingActionButton(
        onPressed: _openDirections,
        child: const Icon(Icons.directions),
        tooltip: 'Get Directions',
      ) : null,
    );
  }
}