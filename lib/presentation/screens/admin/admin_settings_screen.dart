
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/theme_provider.dart';
import '../admin/admin_drawer.dart';
import '../admin/admin_app_bar.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  // App settings
  bool _enableNotifications = true;
  bool _enableLocationServices = true;
  String _defaultCurrency = 'GHS';
  int _sessionTimeout = 30;
  bool _maintenanceMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
     
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
  
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
  
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: const AdminAppBar(title: 'Admin Settings'),
      drawer: const AdminDrawer(currentIndex: 5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      'General Settings',
                      [
                        _buildSwitchSetting(
                          'Enable Notifications',
                          'Send push notifications for bookings, events, etc.',
                          _enableNotifications,
                          (value) {
                            setState(() {
                              _enableNotifications = value;
                            });
                          },
                        ),
                        _buildSwitchSetting(
                          'Enable Location Services',
                          'Use location for nearby events and venues',
                          _enableLocationServices,
                          (value) {
                            setState(() {
                              _enableLocationServices = value;
                            });
                          },
                        ),
                        _buildSwitchSetting(
                          'Dark Mode',
                          'Enable dark theme across the app',
                          themeProvider.isDarkMode,
                          (value) {
                            themeProvider.setDarkMode(value);
                          },
                        ),
                        _buildDropdownSetting(
                          'Default Currency',
                          'Currency used for transactions',
                          _defaultCurrency,
                          ['GHS', 'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'],
                          (value) {
                            if (value != null) {
                              setState(() {
                                _defaultCurrency = value as String;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Security Settings',
                      [
                        _buildSliderSetting(
                          'Session Timeout (minutes)',
                          'Automatically log out inactive admin users',
                          _sessionTimeout.toDouble(),
                          5,
                          120,
                          (value) {
                            setState(() {
                              _sessionTimeout = value.round();
                            });
                          },
                        ),
                        
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownSetting<T>(
    String title,
    String subtitle,
    T value,
    List<T> options,
    Function(T?) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<T>(
        value: value,
        items: options.map((T option) {
          return DropdownMenuItem<T>(
            value: option,
            child: Text(option.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Text(
            value.round().toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / 5).round(),
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showConfirmationDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}