import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  
  // Cached values for improved performance
  LatLng? _cachedLatLng;
  
  // Default values
  final double _defaultSearchRadius = 25000; // 25km in meters
  
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get defaultSearchRadius => _defaultSearchRadius;
  
  // Request location permission
  Future<bool> requestLocationPermission({BuildContext? context}) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled. Please enable location services.';
        notifyListeners();
        
        // Show dialog if context is provided
        if (context != null) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text('Please enable location services to use this feature.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return false;
      }
      
      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions are denied.';
          notifyListeners();
          
          // Show dialog if context is provided
          if (context != null) {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Permission Denied'),
                content: const Text('Location permission is required for this feature.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return false;
        }
      }
      
      // Check if permanently denied
      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied, we cannot request permissions.';
        notifyListeners();
        
        // Show dialog if context is provided
        if (context != null) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Permission Permanently Denied'),
              content: const Text('Location permissions are permanently denied. Please enable them in app settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await Geolocator.openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return false;
      }
      
      return true;
    } catch (e) {
      _error = 'Error requesting location permission: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Get current location
  Future<void> getCurrentLocation({BuildContext? context}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final hasPermission = await requestLocationPermission(context: context);
      if (!hasPermission) return;
      
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Update cached LatLng
      _cachedLatLng = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } catch (e) {
      _error = 'Error getting current location: ${e.toString()}';
      
      // Show error dialog if context is provided
      if (context != null) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location Error'),
            content: Text('Could not get your location: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Calculate distance to event
  Future<double> getDistanceToEvent(double latitude, double longitude) async {
    if (_currentPosition == null) {
      await getCurrentLocation();
      if (_currentPosition == null) return -1; // Error or no permission
    }
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }
  
  // Format distance in human-readable format
  String formatDistance(double meters) {
    if (meters < 0) return 'Unknown distance';
    
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      double km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
  
  // Get LatLng for Google Maps from Position
  LatLng? getCurrentLatLng() {
    if (_cachedLatLng != null) return _cachedLatLng;
    if (_currentPosition == null) return null;
    
    _cachedLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    return _cachedLatLng;
  }
  
  // Clear current position
  void clearPosition() {
    _currentPosition = null;
    _cachedLatLng = null;
    notifyListeners();
  }
  
  
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    
    return "Address lookup not implemented";
  }
}