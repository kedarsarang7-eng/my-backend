import 'package:flutter/material.dart';
import '../sync/sync_status_manager.dart';
import '../sync/sync_manager.dart';
import '../di/service_locator.dart';

class LogoutGuard {
  static Future<void> attemptLogout(BuildContext context) async {
    final status = SyncStatusManager.instance;

    // 1. Safety Check
    if (!status.canSafeLogout()) {
      if (!context.mounted) return;

      final shouldForce = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text("डेटा अजून सेव्ह झाला नाही!"), // Marathi Warning
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "तुमचा डेटा अजून Cloud मध्ये सेव्ह झालेला नाही.\nLogout केल्यास डेटा कायमचा नष्ट होऊ शकतो.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                "Pending Changes: ${status.pendingWritesCount}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                SyncManager.instance.forceSyncAll();
                Navigator.pop(context, false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Syncing now... Please wait")),
                );
              },
              icon: const Icon(Icons.sync),
              label: const Text("Sync Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // FORCE LOGOUT
              child: const Text(
                "Force Logout (Lose Data)",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );

      if (shouldForce != true) return;
    }

    // 2. Perform Logout
    await status.clear(); // Clear local sync status cache
    await sessionManager.signOut(); // Use centralized session manager

    if (context.mounted) {
      // Navigate to unified auth
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/unified_auth', (route) => false);
    }
  }
}
