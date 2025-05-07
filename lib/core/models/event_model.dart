import 'package:cloud_firestore/cloud_firestore.dart';

// This class represents a location with name, address and geographical point
class LocationModel {
  final String name;
  final String address;
  final GeoPoint geopoint;
  
  LocationModel({
    required this.name,
    required this.address,
    required this.geopoint,
  });
  
  factory LocationModel.fromMap(Map<String, dynamic> data) {
    // Handle possible null data or missing geopoint
    final geopoint = data['geopoint'] is GeoPoint 
        ? data['geopoint'] 
        : const GeoPoint(0, 0);
        
    return LocationModel(
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      geopoint: geopoint,
    );
  }
  
  // Add fromEventLocation constructor to handle conversion
  factory LocationModel.fromEventLocation(dynamic location) {
    // If it's already a LocationModel, just return it
    if (location is LocationModel) {
      return location;
    }
    
    // If it's a Map, use the fromMap constructor
    if (location is Map<String, dynamic>) {
      return LocationModel.fromMap(location);
    }
    
    // Handle EventLocation or similar type with similar properties
    try {
      return LocationModel(
        name: location.name ?? '',
        address: location.address ?? '',
        geopoint: location.geopoint is GeoPoint 
            ? location.geopoint 
            : const GeoPoint(0, 0),
      );
    } catch (e) {
      
      print('Error converting location: $e');
      return LocationModel(
        name: 'Unknown',
        address: 'Unknown',
        geopoint: const GeoPoint(0, 0),
      );
    }
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'geopoint': geopoint,
    };
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final dynamic _location; 
  final String category;
  final double price;
  final String imageUrl;
  final int capacity;
  final int bookedCount;
  final bool featured;
  final bool isActive;
  
  // Private constructor that takes the raw location
  EventModel._({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required dynamic location,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.capacity,
    required this.bookedCount,
    required this.featured,
    required this.isActive,
  }) : _location = location;
  
  // Public constructor that ensures LocationModel type
  factory EventModel({
    required String id,
    required String title,
    required String description,
    required DateTime date,
    required dynamic location,
    required String category,
    required double price,
    required String imageUrl,
    required int capacity,
    required int bookedCount,
    required bool featured,
    required bool isActive,
  }) {
    return EventModel._(
      id: id,
      title: title,
      description: description,
      date: date,
      location: location, 
      category: category,
      price: price,
      imageUrl: imageUrl,
      capacity: capacity,
      bookedCount: bookedCount,
      featured: featured,
      isActive: isActive,
    );
  }
  
  // Getter that converts to LocationModel when accessed
  LocationModel get location {
    return LocationModel.fromEventLocation(_location);
  }
  
  // Calculate available spots with safety check
  int get availableSpots => capacity > bookedCount ? capacity - bookedCount : 0;
  
  // Check if event is available and not in the past
  bool get isAvailable => availableSpots > 0 && date.isAfter(DateTime.now());
  
  // Factory method to create EventModel from Firestore
  factory EventModel.fromMap(String id, Map<String, dynamic> data) {
    // Safe parsing for numeric values
    int parseCapacity() {
      if (data['capacity'] is int) {
        return data['capacity'];
      } else if (data['capacity'] is String) {
        return int.tryParse(data['capacity']) ?? 0;
      } else {
        return 0;
      }
    }
    
    int parseBookedCount() {
      if (data['bookedCount'] is int) {
        return data['bookedCount'];
      } else if (data['bookedCount'] is String) {
        return int.tryParse(data['bookedCount']) ?? 0;
      } else {
        return 0;
      }
    }
    
    double parsePrice() {
      if (data['price'] is double) {
        return data['price'];
      } else if (data['price'] is int) {
        return data['price'].toDouble();
      } else if (data['price'] is String) {
        return double.tryParse(data['price']) ?? 0.0;
      } else {
        return 0.0;
      }
    }
    
    DateTime parseDate() {
      if (data['date'] is Timestamp) {
        return (data['date'] as Timestamp).toDate();
      } else {
        // Fallback to current date if no valid date is provided
        return DateTime.now();
      }
    }
    
    return EventModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: parseDate(),
      location: data['location'], // Store original location value
      category: data['category'] ?? 'Uncategorized',
      price: parsePrice(),
      imageUrl: data['imageUrl'] ?? '',
      capacity: parseCapacity(),
      bookedCount: parseBookedCount(),
      featured: data['featured'] ?? false,
      isActive: data['isActive'] ?? true,
    );
  }
  
  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': _location is Map ? _location : location.toMap(),
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'capacity': capacity,
      'bookedCount': bookedCount,
      'featured': featured,
      'isActive': isActive,
    };
  }
}