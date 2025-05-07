
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Fetch all users
  Future<void> fetchUsers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore.collection('users').get();

      _users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      _error = 'Error fetching users: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserModel.fromMap(data);
    } catch (e) {
      _error = 'Error getting user: ${e.toString()}';
      print(_error);
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update({
        ...userData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchUsers(); // Refresh the users list
      return true;
    } catch (e) {
      _error = 'Error updating user profile: ${e.toString()}';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get active users
  List<UserModel> get activeUsers {
    return _users.where((user) => user.isActive).toList();
  }

  // Get admin users
  List<UserModel> get adminUsers {
    return _users.where((user) => user.isAdmin).toList();
  }
}