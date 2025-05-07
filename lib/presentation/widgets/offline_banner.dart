
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectivityService = Provider.of<ConnectivityService>(context);
    final syncService = Provider.of<SyncService>(context);
    
    if (connectivityService.isConnected) {
      if (syncService.hasPendingChanges) {
        // Online but with pending changes
        return Container(
          color: Colors.orange.shade100,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.sync, size: 14, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                syncService.isSyncing ? 'Syncing data...' : 'Pending changes to sync',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
              ),
              const Spacer(),
              if (!syncService.isSyncing)
                TextButton(
                  onPressed: syncService.forceSyncNow,
                  child: Text(
                    'Sync Now',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                  ),
                ),
              if (syncService.isSyncing)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade900),
                  ),
                ),
            ],
          ),
        );
      }
      return const SizedBox.shrink(); // No banner when online and fully synced
    }
    
    // Offline banner
    return Container(
      color: Colors.red.shade100,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 14, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            'You\'re offline. Some features may be limited.',
            style: TextStyle(fontSize: 12, color: Colors.red.shade900),
          ),
        ],
      ),
    );
  }
}
