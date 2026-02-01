import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/database/app_database.dart';
import '../services/data_integrity_service.dart';
import '../core/di/service_locator.dart';
// import '../core/sync/sync_manager.dart'; // Removed
import '../core/sync/engine/sync_engine.dart'; // Added
// import '../core/sync/models/sync_types.dart'; // Removed (unused)
import '../core/monitoring/firebase_health_service.dart';
import '../core/session/session_manager.dart';

class DeveloperHealthScreen extends StatefulWidget {
  const DeveloperHealthScreen({super.key});

  @override
  State<DeveloperHealthScreen> createState() => _DeveloperHealthScreenState();
}

class _DeveloperHealthScreenState extends State<DeveloperHealthScreen> {
  bool _runningSql = false;
  bool _runningFirebase = false;
  String _sqliteResult = '';
  String _firebaseResult = '';

  Future<void> _runSqliteCheck() async {
    setState(() {
      _runningSql = true;
      _sqliteResult = '';
    });
    try {
      final sm = sl<SessionManager>();
      final userId = sm.currentSession.odId;
      final res = await AppDatabase.instance.performHealthCheck(userId);
      setState(() {
        _sqliteResult = const JsonEncoder.withIndent('  ').convert(res);
      });
    } catch (e) {
      setState(() {
        _sqliteResult = 'Error: $e';
      });
    } finally {
      setState(() => _runningSql = false);
    }
  }

  Future<void> _runAutoFix() async {
    setState(() {
      _runningSql = true;
      _sqliteResult = '';
    });
    try {
      final sm = sl<SessionManager>();
      final userId = sm.currentSession.odId;
      final service = sl<DataIntegrityService>();
      final res = await service.verifyAndAutoFixStockIntegrity(userId);
      final res2 = await service.reconcileCustomerBalance(userId);

      setState(() {
        _sqliteResult =
            'Stock Integrity:\n${res.toString()}\n\nLedger Integrity:\n${res2.toString()}';
      });
    } catch (e) {
      setState(() {
        _sqliteResult = 'Auto-fix error: $e';
      });
    } finally {
      setState(() => _runningSql = false);
    }
  }

  Future<void> _attemptSyncFix() async {
    setState(() {
      _runningFirebase = true;
      _firebaseResult = '';
    });
    try {
      // Use the new SyncEngine instead of legacy sync services
      await SyncEngine.instance.triggerSync();

      final stats = await SyncEngine.instance.getStats();
      setState(() {
        _firebaseResult = 'Sync triggered. Current Stats:\n'
            'Pending: ${stats.pendingCount}\n'
            'In Progress: ${stats.inProgressCount}\n'
            'Failed: ${stats.failedCount}\n'
            'Dead Letter: ${stats.deadLetterCount}\n'
            'Synced: ${stats.syncedCount}\n'
            'Circuit Open: ${stats.isCircuitOpen}';
      });
    } catch (e) {
      setState(() {
        _firebaseResult = 'Sync attempt failed: $e';
      });
    } finally {
      setState(() => _runningFirebase = false);
    }
  }

  Future<void> _runFirebaseCheck() async {
    setState(() {
      _runningFirebase = true;
      _firebaseResult = '';
    });
    try {
      final res = await FirebaseHealthService().checkHealth();
      setState(() {
        _firebaseResult = const JsonEncoder.withIndent('  ').convert(res);
      });
    } catch (e) {
      setState(() {
        _firebaseResult = 'Error: $e';
      });
    } finally {
      setState(() => _runningFirebase = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Allow access in debug builds OR for authenticated owner sessions
    var allow = kDebugMode;
    try {
      final sm = sl<SessionManager>();
      final session = sm.currentSession;
      if (session.isAuthenticated && session.isOwner) allow = true;
    } catch (_) {}

    if (!allow) {
      return Scaffold(
        appBar: AppBar(title: const Text('Developer Health')),
        body: const Center(
            child: Text(
                'Developer Health screen is available only to owners or in debug builds.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Health')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: _runningSql
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ))
                  : const Icon(Icons.storage),
              label: Text(_runningSql
                  ? 'Running SQLite Check...'
                  : 'Run SQLite Health Check'),
              onPressed: _runningSql ? null : _runSqliteCheck,
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _sqliteResult.isEmpty ? 'No result yet.' : _sqliteResult,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _runningFirebase
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ))
                  : const Icon(Icons.cloud),
              label: Text(_runningFirebase
                  ? 'Running Firebase Check...'
                  : 'Run Firebase Health Check'),
              onPressed: _runningFirebase ? null : _runFirebaseCheck,
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _firebaseResult.isEmpty
                        ? 'No result yet.'
                        : _firebaseResult,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Auto-fix controls
            ElevatedButton.icon(
              icon: const Icon(Icons.build_circle),
              label: const Text('Run Data Integrity Check & Fix'),
              onPressed: _runningSql ? null : _runAutoFix,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Attempt Sync Fix (retry queued sync)'),
              onPressed: _runningFirebase ? null : _attemptSyncFix,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }
}
