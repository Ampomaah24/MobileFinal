import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _userModel?.isAdmin ?? false;

  AuthService() {
    _initializeAuth();
  }
  
  // Initialize auth state
  Future<void> _initializeAuth() async {
    try {
      _auth.authStateChanges().listen(_onAuthStateChanged);
    } catch (e) {
      print("Error setting up auth state changes listener: $e");
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Method to update user admin status
  Future<void> updateUserAdminStatus(String userId, bool isAdmin) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // If updating current user, refresh the data
      if (_user?.uid == userId) {
        await _fetchUserData();
      }
    } catch (e) {
      _error = 'Error updating admin status: ${e.toString()}';
      print(_error);
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Method to delete user
  Future<void> deleteUser(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Delete user data from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete the user's bookings
      QuerySnapshot bookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();
          
      for (var doc in bookings.docs) {
        await _firestore.collection('bookings').doc(doc.id).delete();
      }
      
      // If the user is deleting their own account
      if (_auth.currentUser?.uid == userId) {
        await _auth.currentUser?.delete();
      } else {
        // For admin functionality, you'll need to use Firebase Cloud Functions
        // as client-side code cannot delete other users from Firebase Auth
        throw Exception('Admin deletion of users requires a Cloud Function with Firebase Admin SDK');
      }
    } catch (e) {
      _error = 'Error deleting user: ${e.toString()}';
      print(_error);
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Authentication state changes listener - with safe type checking
  Future<void> _onAuthStateChanged(User? authUser) async {
    try {
      print("Auth state changed. User: ${authUser?.uid ?? 'null'}");
      _user = authUser;
      if (authUser != null) {
        await _fetchUserData();
      } else {
        _userModel = null;
      }
    } catch (e) {
      print("Error in auth state change handler: $e");
      _user = null;
      _userModel = null;
    }
    notifyListeners();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    if (_user == null) return;
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      print("Fetching user data for UID: ${_user!.uid}");
      DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
      
      if (doc.exists) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print("User data fetched successfully");
          
          // Safely create the user model
          _userModel = UserModel.fromMap(data);
          print("User model created. Is admin: ${_userModel?.isAdmin}");
        } catch (e) {
          print("Error parsing user data: $e");
          _userModel = null;
        }
      } else {
        _error = 'User data not found';
        print("Error: User document doesn't exist for UID: ${_user!.uid}");
        _userModel = null;
      }
    } catch (e) {
      _error = 'Error fetching user data: ${e.toString()}';
      print("Error in _fetchUserData: $_error");
      _userModel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      print("Attempting to create auth user with email: $email");
      // Create auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("Auth user created successfully with UID: ${result.user!.uid}");
      
      // Create user profile in Firestore
      try {
        print("Creating user document in Firestore");
        await _firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'email': email,
          'name': name,
          'phone': phone ?? '',
          'profileImageUrl': profileImageUrl ?? '',
          'isAdmin': false,
          'isActive': true,
          'isEmailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'preferences': {},
        });
        print("Firestore user document created successfully");
        
        // Send email verification
        try {
          await result.user!.sendEmailVerification();
          print("Verification email sent");
        } catch (e) {
          print("Error sending verification email: $e");
          // Continue despite the error - user is still created
        }
      } catch (firestoreError) {
        print("Error creating Firestore document: $firestoreError");
        _error = 'Error creating user profile: ${firestoreError.toString()}';
        
        // Clean up the Auth user if Firestore creation fails
        try {
          await result.user?.delete();
          print("Auth user deleted due to Firestore document creation failure");
        } catch (deleteError) {
          print("Error deleting auth user: $deleteError");
        }
        
        throw firestoreError;
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception during signup: ${e.code} - ${e.message}");
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'This email is already registered.';
          break;
        case 'invalid-email':
          _error = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          _error = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          _error = 'The password is too weak.';
          break;
        default:
          _error = 'Error creating account: ${e.message}';
      }
      rethrow;
    } catch (e) {
      print("Error in signUp: $e");
      _error = 'Error creating account: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn({
    required String email, 
    required String password
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      print("Attempting to sign in user: $email");
      
      // Use try-catch specifically around the signInWithEmailAndPassword call
      UserCredential result;
      try {
        result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print("Firebase Auth signIn successful for user: ${result.user?.uid}");
      } catch (signInError) {
        print("Error during signInWithEmailAndPassword: $signInError");
        rethrow;
      }
      
      // Update last login timestamp in Firestore
      try {
        if (result.user != null) {
          await _firestore.collection('users').doc(result.user!.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
          print("Last login timestamp updated for user: ${result.user!.uid}");
        }
      } catch (firestoreError) {
        // Don't fail the login if timestamp update fails
        print("Error updating lastLoginAt: $firestoreError");
      }
      
      // Explicitly fetch user data after successful login
      if (result.user != null) {
        _user = result.user;
        try {
          await _fetchUserData();
          print("User data fetched after login. IsAdmin: ${_userModel?.isAdmin}");
        } catch (fetchError) {
          print("Error fetching user data after login: $fetchError");
          // Don't fail the login if data fetch fails
        }
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception: ${e.code} - ${e.message}");
      switch (e.code) {
        case 'user-not-found':
          _error = 'No user found for that email.';
          break;
        case 'wrong-password':
          _error = 'Wrong password provided.';
          break;
        case 'invalid-email':
          _error = 'The email address is not valid.';
          break;
        case 'user-disabled':
          _error = 'This account has been disabled.';
          break;
        case 'invalid-credential':
          _error = 'Invalid email or password.';
          break;
        default:
          _error = 'An error occurred: ${e.message}';
      }
      rethrow;
    } catch (e) {
      print("Unexpected error during sign in: $e");
      _error = 'An unexpected error occurred: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      print("Signing out user");
      await _auth.signOut();
      _user = null;
      _userModel = null;
      print("User signed out successfully");
    } catch (e) {
      _error = 'Error signing out: ${e.toString()}';
      print("Error in signOut: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      print("Sending password reset email to: $email");
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent successfully");
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception in resetPassword: ${e.code} - ${e.message}");
      switch (e.code) {
        case 'invalid-email':
          _error = 'The email address is not valid.';
          break;
        case 'user-not-found':
          _error = 'No user found for that email.';
          break;
        default:
          _error = 'An error occurred: ${e.message}';
      }
      rethrow;
    } catch (e) {
      _error = 'Error sending password reset: ${e.toString()}';
      print("Error in resetPassword: $_error");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
    Map<String, dynamic>? preferences
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
      if (preferences != null) data['preferences'] = preferences;
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(_user!.uid).update(data);
      await _fetchUserData();
    } catch (e) {
      _error = 'Error updating profile: ${e.toString()}';
      print(_error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_auth.currentUser == null || _auth.currentUser!.email == null) {
      _error = 'No user logged in';
      notifyListeners();
      throw Exception(_error);
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!,
        password: currentPassword,
      );
      
      await _auth.currentUser!.reauthenticateWithCredential(credential);
      
      // Change password
      await _auth.currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          _error = 'The current password is incorrect.';
          break;
        case 'weak-password':
          _error = 'The new password is too weak.';
          break;
        default:
          _error = 'An error occurred: ${e.message}';
      }
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
Future<UserModel?> registerWithEmailAndPassword(
  String email, 
  String password,
  String name,
  bool isAdmin
) async {
  try {
    // Create authentication account
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Create user profile
    if (userCredential.user != null) {
      final user = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        isAdmin: isAdmin,
        profileImageUrl: '',
        createdAt: DateTime.now(),
      );
      
      // Save user to database
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      return user;
    }
    return null;
  } catch (e) {
    _error = e.toString();
    return null;
  }
}
  // Check if email is verified
  Future<bool> checkEmailVerified() async {
    if (_auth.currentUser == null) {
      return false;
    }
    
    await _auth.currentUser!.reload();
    final isVerified = _auth.currentUser!.emailVerified;
    
    // Fixed: Check if user model exists then check if email is verified in Firestore
    if (isVerified && _userModel != null) {
      // Update user data in Firestore
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'isEmailVerified': true,
        'updatedAt': FieldValue.serverTimestamp()
      });
      
      // Reload user data
      await _fetchUserData();
    }
    
    return isVerified;
  }
  
  // Get all users (admin function)
  Future<List<UserModel>> getAllUsers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      
      List<UserModel> users = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          users.add(UserModel.fromMap(data));
        } catch (e) {
          print("Error parsing user data for document ${doc.id}: $e");
          // Skip invalid user documents
        }
      }
      
      return users;
    } catch (e) {
      _error = 'Error fetching users: ${e.toString()}';
      print(_error);
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}