// lib/presentation/screens/admin/event_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../core/services/event_service.dart';
import '../../../core/models/event_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EventFormScreen extends StatefulWidget {
  final EventModel? event;
  
  const EventFormScreen({Key? key, this.event}) : super(key: key);

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;
  late TextEditingController _locationNameController;
  late TextEditingController _locationAddressController;
  late TextEditingController _searchController;
  String _selectedCategory = 'Music';
  DateTime _eventDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _eventTime = TimeOfDay.now();
  File? _imageFile;
  bool _isUploading = false;
  bool _isMapLoading = true;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  
  // Google Maps related variables
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  // Ghana cities for offline selection
  final List<Map<String, dynamic>> _ghanaCities = [
    {'name': 'Accra', 'lat': 5.6037, 'lng': -0.1870, 'keywords': ['accra', 'capital', 'greater accra']},
    {'name': 'Kumasi', 'lat': 6.6885, 'lng': -1.6244, 'keywords': ['kumasi', 'ashanti', 'garden city']},
    {'name': 'Tamale', 'lat': 9.4075, 'lng': -0.8533, 'keywords': ['tamale', 'northern region']},
    {'name': 'Takoradi', 'lat': 4.9125, 'lng': -1.7750, 'keywords': ['takoradi', 'sekondi', 'western region']},
    {'name': 'Cape Coast', 'lat': 5.1053, 'lng': -1.2466, 'keywords': ['cape', 'cape coast', 'central region']},
    {'name': 'Sunyani', 'lat': 7.3349, 'lng': -2.3288, 'keywords': ['sunyani', 'bono region']},
    {'name': 'Koforidua', 'lat': 6.0940, 'lng': -0.2598, 'keywords': ['koforidua', 'eastern region']},
    {'name': 'Ho', 'lat': 6.6019, 'lng': 0.4714, 'keywords': ['ho', 'volta region']},
    {'name': 'Wa', 'lat': 10.0601, 'lng': -2.5099, 'keywords': ['wa', 'upper west']},
    {'name': 'Bolgatanga', 'lat': 10.7865, 'lng': -0.8486, 'keywords': ['bolgatanga', 'upper east']},
    {'name': 'Techiman', 'lat': 7.5870, 'lng': -1.9377, 'keywords': ['techiman', 'bono east']},
    {'name': 'Teshie', 'lat': 5.5765, 'lng': -0.1034, 'keywords': ['teshie', 'accra suburb']},
    {'name': 'Tema', 'lat': 5.6700, 'lng': -0.0167, 'keywords': ['tema', 'port', 'harbour']},
    {'name': 'Obuasi', 'lat': 6.2024, 'lng': -1.6687, 'keywords': ['obuasi', 'gold', 'mining']},
    {'name': 'Madina', 'lat': 5.6695, 'lng': -0.1648, 'keywords': ['madina', 'accra suburb']},
    {'name': 'Ejisu', 'lat': 6.7246, 'lng': -1.4794, 'keywords': ['ejisu', 'ashanti region']},
    {'name': 'Agona Swedru', 'lat': 5.5338, 'lng': -0.7025, 'keywords': ['agona', 'swedru']},
    {'name': 'Berekuso', 'lat': 5.7613, 'lng': -0.2217, 'keywords': ['berekuso', 'ashesi', 'university']},
    {'name': 'Winneba', 'lat': 5.3478, 'lng': -0.6288, 'keywords': ['winneba', 'effutu', 'central region']},
    {'name': 'Nungua', 'lat': 5.6006, 'lng': -0.0735, 'keywords': ['nungua', 'accra beach']},
  ];

  // Popular places in Ghana
  final List<Map<String, dynamic>> _popularPlaces = [
    {'name': 'Ashesi University', 'lat': 5.7598, 'lng': -0.2203, 'city': 'Berekuso', 'keywords': ['ashesi', 'university', 'college', 'campus', 'berekuso']},
    {'name': 'University of Ghana', 'lat': 5.6500, 'lng': -0.1870, 'city': 'Accra', 'keywords': ['legon', 'university of ghana', 'ug', 'campus']},
    {'name': 'Kwame Nkrumah University of Science and Technology', 'lat': 6.6866, 'lng': -1.5740, 'city': 'Kumasi', 'keywords': ['knust', 'science', 'technology', 'university', 'kumasi']},
    {'name': 'Accra Mall', 'lat': 5.6333, 'lng': -0.1758, 'city': 'Accra', 'keywords': ['accra mall', 'mall', 'shopping']},
    {'name': 'Kotoka International Airport', 'lat': 5.6051, 'lng': -0.1669, 'city': 'Accra', 'keywords': ['airport', 'kotoka', 'international']},
    {'name': 'Labadi Beach', 'lat': 5.5577, 'lng': -0.1421, 'city': 'Accra', 'keywords': ['labadi', 'beach', 'la']},
    {'name': 'Kakum National Park', 'lat': 5.3500, 'lng': -1.3833, 'city': 'Cape Coast', 'keywords': ['kakum', 'national park', 'canopy walk']},
    {'name': 'Cape Coast Castle', 'lat': 5.1033, 'lng': -1.2425, 'city': 'Cape Coast', 'keywords': ['cape coast', 'castle', 'fort', 'slave']},
    {'name': 'Elmina Castle', 'lat': 5.0846, 'lng': -1.3493, 'city': 'Elmina', 'keywords': ['elmina', 'castle', 'fort', 'slave']},
    {'name': 'Mole National Park', 'lat': 9.2616, 'lng': -1.8412, 'city': 'Larabanga', 'keywords': ['mole', 'national park', 'safari', 'elephant']},
    {'name': 'Lake Bosumtwi', 'lat': 6.5032, 'lng': -1.4093, 'city': 'Kumasi', 'keywords': ['bosumtwi', 'lake', 'crater']},
    {'name': 'Aburi Botanical Gardens', 'lat': 5.8500, 'lng': -0.1744, 'city': 'Aburi', 'keywords': ['aburi', 'gardens', 'botanical']},
    {'name': 'West Hills Mall', 'lat': 5.5652, 'lng': -0.3136, 'city': 'Accra', 'keywords': ['west hills', 'mall', 'shopping']},
    {'name': 'Makola Market', 'lat': 5.5489, 'lng': -0.2154, 'city': 'Accra', 'keywords': ['makola', 'market', 'shopping']},
    {'name': 'Black Star Square', 'lat': 5.5450, 'lng': -0.1994, 'city': 'Accra', 'keywords': ['black star', 'independence', 'square']},
  ];
  
  // Default to Ghana's coordinates
  final LatLng _ghanaCoordinates = const LatLng(7.9465, -1.0232); // Ghana's center coordinates
  
  List<String> _categories = [
    'Music',
    'Sports',
    'Arts & Theatre',
    'Food & Drink',
    'Technology',
    'Business',
    'Health & Wellness',
    'Education',
    'Outdoors',
    'Charity',
    'Other',
  ];
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
   
    _priceController = TextEditingController(
      text: widget.event?.price != null ? widget.event!.price.toString() : '',
    );
    _capacityController = TextEditingController(
      text: widget.event?.capacity != null ? widget.event!.capacity.toString() : '',
    );
    _locationNameController = TextEditingController(text: widget.event?.location.name ?? '');
    _locationAddressController = TextEditingController(text: widget.event?.location.address ?? '');
    _searchController = TextEditingController();
    _selectedCategory = widget.event?.category ?? _categories[0];
    
    if (widget.event != null) {
      _eventDate = widget.event!.date;
      _eventTime = TimeOfDay.fromDateTime(widget.event!.date);
      
      // Initialize map location if event has coordinates
      if (widget.event?.location.geopoint != null) {
        final geopoint = widget.event!.location.geopoint;
        if (_isValidGeopoint(geopoint)) {
          _selectedLocation = LatLng(geopoint.latitude, geopoint.longitude);
          _updateMarker();
        }
      }
    }
  }
  
  // Check if geopoint is valid (not 0,0 and within Ghana's bounds)
  bool _isValidGeopoint(GeoPoint geopoint) {
    final lat = geopoint.latitude;
    final lng = geopoint.longitude;
    return lat != 0 && lng != 0 && 
           lat >= 4.5 && lat <= 11.5 && // Ghana latitude range
           lng >= -3.5 && lng <= 1.5;   // Ghana longitude range  
  }
  
  @override
  void dispose() {
    _titleController.dispose();

    _priceController.dispose();
    _capacityController.dispose();
    _locationNameController.dispose();
    _locationAddressController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
  
  // Google Maps related methods
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapLoading = false;
    });
    
    if (_selectedLocation == null) {
      // Default to Ghana's coordinates
      setState(() {
        _selectedLocation = _ghanaCoordinates;
        _updateMarker();
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 7), // Lower zoom to show more of Ghana
        );
      });
    }
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _updateMarker();
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
          );
        });
        
        // Get address from coordinates
        _getAddressFromLatLng();
      }
    } catch (e) {
      print('Error getting location: $e');
      // Show a message to the user about location error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access your location. Please select manually.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  void _updateMarker() {
    if (_selectedLocation == null) return;
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
              _getAddressFromLatLng();
            });
          },
        ),
      };
    });
  }
  
  Future<void> _getAddressFromLatLng() async {
    if (_selectedLocation == null) return;
    
    try {
      // Try platform geocoding first
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _selectedLocation!.latitude, 
          _selectedLocation!.longitude
        );
        
        if (placemarks.isNotEmpty && mounted) {
          Placemark place = placemarks[0];
          setState(() {
            String address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
            _locationAddressController.text = address.replaceAll(RegExp(r', ,'), ',').replaceAll(RegExp(r',,'), ',').replaceAll(RegExp(r'^,|,$'), '');
            
            // If the venue name is empty, use locality or street
            if (_locationNameController.text.isEmpty) {
              _locationNameController.text = place.name ?? place.locality ?? place.street ?? 'Unnamed Venue';
            }
          });
          return;
        }
      } catch (e) {
        print('Platform geocoding failed: $e');
        // Continue to fallback methods
      }
      
      // Fallback: Find closest known city/place
      _findNearestPlace();
      
    } catch (e) {
      print('Error in address lookup: $e');

      if (mounted) {
        setState(() {
          _locationAddressController.text = 'Location at ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}';
          if (_locationNameController.text.isEmpty) {
            _locationNameController.text = 'Unnamed Venue';
          }
        });
      }
    }
  }
  
  void _findNearestPlace() {
    if (_selectedLocation == null) return;
    
    double minDistance = double.infinity;
    Map<String, dynamic>? closestPlace;
    
    // Check popular places first
    for (var place in _popularPlaces) {
      double distance = Geolocator.distanceBetween(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        place['lat'] as double,
        place['lng'] as double
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        closestPlace = place;
      }
    }
    
    // If no close popular place (within 2km), check cities
    if (minDistance > 2000) {
      minDistance = double.infinity;
      for (var city in _ghanaCities) {
        double distance = Geolocator.distanceBetween(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
          city['lat'] as double,
          city['lng'] as double
        );
        
        if (distance < minDistance) {
          minDistance = distance;
          closestPlace = city;
        }
      }
    }
    
    if (closestPlace != null && mounted) {
      setState(() {
        if (minDistance < 500) {
          // Very close to a known place
          _locationAddressController.text = closestPlace!['name'] + ', Ghana';
          if (_locationNameController.text.isEmpty) {
            _locationNameController.text = closestPlace['name'] as String;
          }
        } else if (minDistance < 5000) {
          // Within 5km of a known place
          _locationAddressController.text = 'Near ' + closestPlace!['name'] + ', Ghana';
          if (_locationNameController.text.isEmpty) {
            _locationNameController.text = 'Venue near ' + closestPlace['name'] as String;
          }
        } else {
          // Far from known places
          String distanceText = '';
          if (minDistance < 20000) {
            distanceText = '${(minDistance / 1000).toStringAsFixed(1)}km from ';
          }
          _locationAddressController.text = '${distanceText}${closestPlace!['name']}, Ghana';
          if (_locationNameController.text.isEmpty) {
            _locationNameController.text = 'Unnamed Venue';
          }
        }
      });
    } else {
      // Fallback to coordinates
      setState(() {
        _locationAddressController.text = 'Location at ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}';
        if (_locationNameController.text.isEmpty) {
          _locationNameController.text = 'Unnamed Venue';
        }
      });
    }
  }
  
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    
    try {
      // Try platform geocoding first
      try {
        List<Location> locations = await locationFromAddress("$query, Ghana");
        
        if (locations.isNotEmpty) {
          setState(() {
            _selectedLocation = LatLng(locations[0].latitude, locations[0].longitude);
            _updateMarker();
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
            );
            _isSearching = false;
          });
          
          // Get address
          _getAddressFromLatLng();
          return;
        }
      } catch (e) {
        print('Online geocoding failed: $e');
        // Continue to offline search
      }
      
      // Offline search - keyword matching with local data
      final normalizedQuery = query.toLowerCase().trim();
      
      // Search in popular places first
      List<Map<String, dynamic>> matchingPlaces = _popularPlaces.where((place) {
        final keywords = place['keywords'] as List<dynamic>;
        return keywords.any((keyword) => 
          keyword.toString().toLowerCase().contains(normalizedQuery) || 
          normalizedQuery.contains(keyword.toString().toLowerCase())
        ) || (place['name'] as String).toLowerCase().contains(normalizedQuery) ||
        normalizedQuery.contains((place['name'] as String).toLowerCase());
      }).toList();
      
      // Then search in cities
      List<Map<String, dynamic>> matchingCities = _ghanaCities.where((city) {
        final keywords = city['keywords'] as List<dynamic>;
        return keywords.any((keyword) => 
          keyword.toString().toLowerCase().contains(normalizedQuery) || 
          normalizedQuery.contains(keyword.toString().toLowerCase())
        ) || (city['name'] as String).toLowerCase().contains(normalizedQuery) ||
        normalizedQuery.contains((city['name'] as String).toLowerCase());
      }).toList();
      
      setState(() {
        _searchResults = [...matchingPlaces, ...matchingCities];
        _isSearching = false;
      });
      
      // If only one result, select it automatically
      if (_searchResults.length == 1) {
        _selectSearchResult(_searchResults[0]);
      }
      
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isSearching = false;
      });
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed. Please try a different term or select a location manually.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _selectSearchResult(Map<String, dynamic> place) {
    setState(() {
      _selectedLocation = LatLng(place['lat'] as double, place['lng'] as double);
      _updateMarker();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 14),
      );
      
      // Set address and venue
      final city = place['city'] as String?;
      _locationAddressController.text = place['name'] + ', ' + (city ?? 'Ghana');
      if (_locationNameController.text.isEmpty) {
        _locationNameController.text = place['name'] as String;
      }
      
      // Clear search results
      _searchResults = [];
      _searchController.text = place['name'] as String;
    });
  }
  
  // Show the city selection dialog
  Future<void> _showCitySelectionDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a City in Ghana'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _ghanaCities.length,
            itemBuilder: (context, index) {
              final city = _ghanaCities[index];
              return ListTile(
                title: Text(city['name'] as String),
                onTap: () {
                  setState(() {
                    _selectedLocation = LatLng(city['lat'] as double, city['lng'] as double);
                    _updateMarker();
                    _locationAddressController.text = '${city['name']}, Ghana';
                    if (_locationNameController.text.isEmpty) {
                      _locationNameController.text = 'Venue in ${city['name']}';
                    }
                    _searchController.text = city['name'] as String;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  // Show popular places dialog
  Future<void> _showPopularPlacesDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Popular Place'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _popularPlaces.length,
            itemBuilder: (context, index) {
              final place = _popularPlaces[index];
              final city = place['city'] as String?;
              return ListTile(
                title: Text(place['name'] as String),
                subtitle: Text(city ?? 'Ghana'),
                onTap: () {
                  setState(() {
                    _selectedLocation = LatLng(place['lat'] as double, place['lng'] as double);
                    _updateMarker();
                    _locationAddressController.text = '${place['name']}, ${city ?? 'Ghana'}';
                    if (_locationNameController.text.isEmpty) {
                      _locationNameController.text = place['name'] as String;
                    }
                    _searchController.text = place['name'] as String;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showMapPicker() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Search box with quick selection buttons
                  Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search for a location',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              suffixIcon: _isSearching 
                                ? Container(
                                    width: 24, 
                                    height: 24, 
                                    padding: const EdgeInsets.all(6.0),
                                    child: CircularProgressIndicator(strokeWidth: 2)
                                  )
                                : IconButton(
                                    icon: Icon(Icons.search),
                                    onPressed: () {
                                      if (_searchController.text.isNotEmpty) {
                                        _searchPlaces(_searchController.text);
                                      }
                                    },
                                  ),
                            ),
                            onEditingComplete: () {
                              if (_searchController.text.isNotEmpty) {
                                _searchPlaces(_searchController.text);
                              }
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Quick selection options
                  Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showCitySelectionDialog();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Cities'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showPopularPlacesDialog();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Popular'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Search results
                  if (_searchResults.isNotEmpty)
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final place = _searchResults[index];
                            final city = place['city'] as String?;
                            return ListTile(
                              title: Text(place['name'] as String),
                              subtitle: Text(city ?? 'Ghana'),
                              onTap: () {
                                _selectSearchResult(place);
                                setDialogState(() {
                                  _searchResults = [];
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  
                  // Map
                  Expanded(
                    flex: _searchResults.isEmpty ? 1 : 2,
                    child: Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child:                         GoogleMap(
                              onMapCreated: (controller) {
                                setDialogState(() {
                                  _mapController = controller;
                                  
                                  // Initialize to Ghana if no location is selected
                                  if (_selectedLocation == null) {
                                    _selectedLocation = _ghanaCoordinates;
                                    _updateMarker();
                                  }
                                  
                                  // Animate to the current selected location
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(_selectedLocation!, 8),
                                  );
                                });
                              },
                              initialCameraPosition: CameraPosition(
                                target: _selectedLocation ?? _ghanaCoordinates,
                                zoom: 8,
                              ),
                              markers: _markers,
                              onTap: (position) {
                                setDialogState(() {
                                  _selectedLocation = position;
                                  _updateMarker();
                                });
                                _getAddressFromLatLng();
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: true,
                              mapToolbarEnabled: false,
                            ),
                          ),
                        ),
                        
                        // Loading indicator
                        if (_isMapLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                  
                  // Selected location info
                  if (_selectedLocation != null && _locationAddressController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Selected: ${_locationAddressController.text}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_selectedLocation != null) {
                _updateMarker();
                _getAddressFromLatLng();
              }
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  // Original methods
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _eventTime,
    );
    
    if (picked != null && picked != _eventTime) {
      setState(() {
        _eventTime = picked;
      });
    }
  }
  
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if location is selected
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location for the event'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Check if venue name is provided
    if (_locationNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a venue name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Combine date and time
    final eventDateTime = DateTime(
      _eventDate.year,
      _eventDate.month,
      _eventDate.day,
      _eventTime.hour,
      _eventTime.minute,
    );
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      
      // Use selected coordinates
      final geoPoint = GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude);
      
      // Prepare event data
      final eventData = {
        'title': _titleController.text,

        'category': _selectedCategory,
        'price': double.parse(_priceController.text),
        'capacity': int.parse(_capacityController.text),
        'date': eventDateTime,
        'location': {
          'name': _locationNameController.text,
          'address': _locationAddressController.text,
          'geopoint': geoPoint,
        },
        'isActive': true,
        'featured': false,
        'bookedCount': widget.event?.bookedCount ?? 0,
      };
      
      if (widget.event == null) {
        // Create new event
        final eventId = await eventService.createEvent(eventData, _imageFile);
        if (mounted && eventId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          throw Exception('Failed to create event');
        }
      } else {
        // Update existing event
        final success = await eventService.updateEvent(widget.event!.id, eventData, _imageFile);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          throw Exception('Failed to update event');
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : widget.event?.imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(widget.event!.imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: _imageFile == null && widget.event?.imageUrl == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Add Event Image'),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        hintText: 'Enter event title',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an event title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    
                    
                    // Price and capacity
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              hintText: '0.00',
                              prefixText: 'GHS ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _capacityController,
                            decoration: const InputDecoration(
                              labelText: 'Capacity',
                              hintText: '100',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Date and time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Time',
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                _eventTime.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Location section
                    const Text(
                      'Location',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    // Search field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Find Location',
                        hintText: 'Search for a place or landmark',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(6.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: Icon(Icons.search),
                                onPressed: () {
                                  if (_searchController.text.isNotEmpty) {
                                    _searchPlaces(_searchController.text);
                                  }
                                },
                              ),
                      ),
                      onEditingComplete: () {
                        if (_searchController.text.isNotEmpty) {
                          _searchPlaces(_searchController.text);
                        }
                      },
                    ),
                    
                    // Search results
                    if (_searchResults.isNotEmpty)
                      Container(
                        height: 200,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final place = _searchResults[index];
                            final city = place['city'] as String?;
                            return ListTile(
                              title: Text(place['name'] as String),
                              subtitle: Text(city ?? 'Ghana'),
                              onTap: () {
                                _selectSearchResult(place);
                              },
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Quick selection buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('Map'),
                            onPressed: _showMapPicker,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.location_city, size: 16),
                            label: const Text('Cities'),
                            onPressed: _showCitySelectionDialog,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.place, size: 16),
                            label: const Text('Popular'),
                            onPressed: _showPopularPlacesDialog,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Venue name field
                    TextFormField(
                      controller: _locationNameController,
                      decoration: const InputDecoration(
                        labelText: 'Venue Name',
                        hintText: 'Enter venue name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a venue name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Address field
                    TextFormField(
                      controller: _locationAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter venue address',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Show small map preview if location is selected
                    if (_selectedLocation != null)
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _selectedLocation!,
                                  zoom: 13,
                                ),
                                markers: _markers,
                                zoomControlsEnabled: false,
                                scrollGesturesEnabled: false,
                                rotateGesturesEnabled: false,
                                tiltGesturesEnabled: false,
                                zoomGesturesEnabled: false,
                                liteModeEnabled: true,
                                mapType: MapType.normal,
                                onMapCreated: (controller) {
                                  // Do nothing, just display the map
                                },
                              ),
                              // Edit button overlay
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: InkWell(
                                  onTap: _showMapPicker,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.edit_location_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEvent,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.event == null ? 'Create Event' : 'Update Event',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}