// lib/presentation/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../../../core/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploading = false;
  File? _imageFile;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.userModel != null) {
      setState(() {
        _nameController.text = authService.userModel!.name;
        _phoneController.text = authService.userModel!.phone ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    setState(() => _isUploading = true);

    try {
      final cloudinary = CloudinaryPublic(
        'dcmsie5au', 
        'evenly', 
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_imageFile!.path, resourceType: CloudinaryResourceType.Image),
      );

      return response.secureUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: ${e.toString()}')),
      );
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      if (_imageFile != null) {
        final downloadUrl = await _uploadImage();
        if (downloadUrl != null) {
          updateData['profileImageUrl'] = downloadUrl;
        }
      }

      await authService.updateProfile(
        name: updateData['name'],
        phone: updateData['phone'],
        profileImageUrl: updateData['profileImageUrl'] ?? authService.userModel?.profileImageUrl,
      );

      setState(() {
        _isEditing = false;
        _isLoading = false;
        _imageFile = null;
      });


    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
        ],
      ),
    );

    if (result == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (_isLoading) {
      return  Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authService.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please sign in to view your profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('Sign In'),
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _updateProfile,
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadUserData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: _imageFile != null
                              ? Image.file(_imageFile!, fit: BoxFit.cover)
                              : (authService.userModel?.profileImageUrl?.isNotEmpty == true
                                  ? Image.network(
                                      authService.userModel!.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) =>
                                          loadingProgress == null ? child : const Center(child: CircularProgressIndicator()),
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: Colors.grey),
                                    )
                                  : const Icon(Icons.person, size: 60, color: Colors.grey)),
                        ),
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                            child: const Center(
                              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            ),
                          ),
                        ),
                      if (_isEditing)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                  enabled: _isEditing,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number (Optional)', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: authService.user?.email,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                  enabled: false,
                ),
                const SizedBox(height: 32),
                Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: const Text('My Bookings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/booking-history'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: _signOut,
                ),
                const SizedBox(height: 32),
                const Text('Evently v1.0.0', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
