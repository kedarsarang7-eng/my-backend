import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../logic/credit_score_calculator.dart';

/// Repository for Udhar Circle (Credit Network)
/// Handles fetching scores, syncing with Firestore, and local caching
class CreditNetworkRepository {
  final AppDatabase _db;

  CreditNetworkRepository(this._db);

  /// Get Trust Score for a customer (Privacy Preserving)
  /// 1. Hash the phone
  /// 2. Check local cache
  /// 3. If stale, fetch from Firestore (Mocked for now)
  Future<CreditProfileEntity?> getCreditProfile(String phone) async {
    final phoneHash = CreditScoreCalculator.hashPhone(phone);

    // Check local DB
    final localProfile = await (_db.select(
      _db.creditProfiles,
    )..where((t) => t.customerPhoneHash.equals(phoneHash))).getSingleOrNull();

    if (localProfile != null) {
      // Check if cache is stale (e.g., > 24 hours)
      if (DateTime.now().difference(localProfile.lastUpdated).inHours < 24) {
        return localProfile;
      }
    }

    // Mock Network Fetch (Simulating Cloud Function response)
    // In real implementation, this calls Firestore `credit_scores` collection
    // where keys are hashes.
    final remoteProfile = await _fetchFromCloud(phoneHash);

    if (remoteProfile != null) {
      // Cache it
      await _db
          .into(_db.creditProfiles)
          .insert(
            CreditProfilesCompanion(
              customerPhoneHash: Value(phoneHash),
              trustScore: Value(remoteProfile.trustScore),
              totalDefaults: Value(remoteProfile.totalDefaults),
              lastUpdated: Value(DateTime.now()),
            ),
            mode: InsertMode.insertOrReplace,
          );
      return remoteProfile;
    }

    return localProfile; // Fallback
  }

  /// Mark a customer as a defaulter (Locally & Cloud)
  Future<void> reportDefault(String phone) async {
    final phoneHash = CreditScoreCalculator.hashPhone(phone);

    // Update Local
    // We don't just set score, we assume cloud will recalculate.
    // For local-first, we reduce score immediately.
    final current = await getCreditProfile(phone);
    final newDefaults = (current?.totalDefaults ?? 0) + 1;
    final newScore = CreditScoreCalculator.calculate(
      totalDefaults: newDefaults,
      maxOverdueDays: 0, // Unknown/Irrelevant for this action
      onTimePaymentsCount: 0,
    );

    await _db
        .into(_db.creditProfiles)
        .insert(
          CreditProfilesCompanion(
            customerPhoneHash: Value(phoneHash),
            trustScore: Value(newScore),
            totalDefaults: Value(newDefaults),
            lastUpdated: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Queue Sync Job to update Cloud
    // Uses existing SyncManager pattern for eventual consistency
    // The sync operation will update the credit_scores Firestore collection
    // with the hashed phone as the document ID for privacy preservation
    _queueCreditProfileSync(phoneHash, newScore.toInt(), newDefaults);
  }

  /// Queue sync job for credit profile update (non-blocking)
  Future<void> _queueCreditProfileSync(
    String phoneHash,
    int trustScore,
    int totalDefaults,
  ) async {
    try {
      // Note: SyncManager should be accessed via service locator in production
      // This is a placeholder that logs the sync intent
      // Actual implementation: SyncManager.instance.enqueue(SyncQueueItem.create(...))
      debugPrint(
        '[CreditNetwork] Sync queued: hash=$phoneHash, score=$trustScore, defaults=$totalDefaults',
      );
    } catch (e) {
      // Non-blocking - credit sync failure shouldn't affect main flow
      debugPrint('[CreditNetwork] Sync queue error: $e');
    }
  }

  Future<CreditProfileEntity?> _fetchFromCloud(String hash) async {
    return null; // Simulate 404 / No record found for now
  }
}
