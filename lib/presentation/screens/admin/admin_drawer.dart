import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/auth_service.dart';

class AdminDrawer extends StatelessWidget {
  final int currentIndex;

  const AdminDrawer({Key? key, required this.currentIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userModel;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'Admin User'),
            accountEmail: Text(user?.email ?? 'admin@evently.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl.isNotEmpty
                  ? NetworkImage(user.profileImageUrl)
                  : null,
              child: user?.profileImageUrl == null || user!.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),

          // Navigation Items
          _buildDrawerItem(
            context,
            title: 'Dashboard',
            icon: Icons.dashboard,
            index: 0,
            route: '/admin',
          ),
          _buildDrawerItem(
            context,
            title: 'Manage Events',
            icon: Icons.event,
            index: 1,
            route: '/admin/events',
          ),
          _buildDrawerItem(
            context,
            title: 'Manage Users',
            icon: Icons.people,
            index: 2,
            route: '/admin/users',
          ),
          _buildDrawerItem(
            context,
            title: 'Bookings',
            icon: Icons.confirmation_number,
            index: 3,
            route: '/admin/bookings',
          ),
          _buildDrawerItem(
            context,
            title: 'Analytics',
            icon: Icons.analytics,
            index: 4,
            route: '/admin/analytics',
          ),
          _buildDrawerItem(
            context,
            title: 'Settings',
            icon: Icons.settings,
            index: 5,
            route: '/admin/settings',
          ),

          const Divider(),

          // Push logout button to bottom
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: ListTile(
                  tileColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int index,
    required String route,
  }) {
    final isSelected = index == currentIndex;

    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
