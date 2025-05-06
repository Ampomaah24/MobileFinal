import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String>? fcmTokens;
  final Map<String, dynamic>? preferences;
  final bool isAdmin;
  final bool isActive;
  final bool isEmailVerified;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.profileImageUrl = '',
    required this.createdAt,
    this.lastLoginAt,
    this.fcmTokens,
    this.preferences,
    this.isAdmin = false,
    this.isActive = true,
    this.isEmailVerified = false,
  });

  // Factory method to create a UserModel from a Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      profileImageUrl: map['profileImageUrl'] ?? '',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null 
          ? (map['lastLoginAt'] as Timestamp).toDate() 
          : null,
      fcmTokens: map['fcmTokens'] != null 
          ? List<String>.from(map['fcmTokens']) 
          : null,
      preferences: map['preferences'],
      isAdmin: map['isAdmin'] ?? false,
      isActive: map['isActive'] ?? true,
      isEmailVerified: map['isEmailVerified'] ?? false,
    );
  }

  // Convert UserModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'fcmTokens': fcmTokens,
      'preferences': preferences,
      'isAdmin': isAdmin,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
    };
  }

  // Create a copy of the user with updated fields
  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImageUrl,
    List<String>? fcmTokens,
    Map<String, dynamic>? preferences,
    bool? isAdmin,
    bool? isActive,
    bool? isEmailVerified,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: this.createdAt,
      lastLoginAt: this.lastLoginAt,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      preferences: preferences ?? this.preferences,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  // String representation for debugging
  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, isAdmin: $isAdmin, isEmailVerified: $isEmailVerified)';
  }
}