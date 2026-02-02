import 'package:drift/drift.dart';
import '../app_database.dart';

/// Pharmacy DAO (Data Access Object)
///
/// Handles all database operations specific to the Pharmacy / Medical business type.
/// Encapsulates logic for Batches, Expiry, and Prescription linking.
class PharmacyDao {
  final AppDatabase db;

  PharmacyDao(this.db);

  // ==========================================================================
  // BATCH MANAGEMENT
  // ==========================================================================

  /// Get all active batches for a specific product, sorted by Expiry (FEFO)
  /// STRICT ISOLATION: Must filter by [userId]
  Future<List<ProductBatchEntity>> getBatchesForProduct(
    String userId,
    String productId,
  ) {
    return (db.select(db.productBatches)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.productId.equals(productId))
          ..where((t) => t.status.equals('ACTIVE'))
          ..orderBy([(t) => OrderingTerm.asc(t.expiryDate)]))
        .get();
  }

  /// Get all batches expiring within the next [days] days
  Future<List<ProductBatchEntity>> getExpiringBatches(
    String userId, {
    int days = 30,
  }) {
    final expiryThreshold = DateTime.now().add(Duration(days: days));
    return (db.select(db.productBatches)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.expiryDate.isSmallerOrEqualValue(expiryThreshold))
          ..where((t) => t.status.equals('ACTIVE'))
          ..orderBy([(t) => OrderingTerm.asc(t.expiryDate)]))
        .get();
  }

  /// Find a specific batch by its number
  Future<ProductBatchEntity?> getBatchByNumber(
    String userId,
    String productId,
    String batchNumber,
  ) {
    return (db.select(db.productBatches)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.productId.equals(productId))
          ..where((t) => t.batchNumber.equals(batchNumber)))
        .getSingleOrNull();
  }

  // ==========================================================================
  // STOCK OPERATIONS
  // ==========================================================================

  /// Consumes stock from a specific batch.
  /// Returns true if successful, false if insufficient stock.
  Future<bool> consumeBatchStock(
    String userId,
    String batchId,
    double quantity,
  ) async {
    return db.transaction(() async {
      final batch =
          await (db.select(db.productBatches)
                ..where((t) => t.id.equals(batchId))
                ..where(
                  (t) => t.userId.equals(userId),
                )) // Double check isolation
              .getSingle();

      if (batch.stockQuantity < quantity) {
        return false; // Insufficient stock
      }

      await (db.update(
        db.productBatches,
      )..where((t) => t.id.equals(batchId))).write(
        ProductBatchesCompanion(
          stockQuantity: Value(batch.stockQuantity - quantity),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Also log movement in generic stock table
      await db
          .into(db.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              id: '${batchId}_${DateTime.now().millisecondsSinceEpoch}', // Simple ID gen
              userId: userId,
              productId: batch.productId,
              type: 'OUT',
              reason: 'SALE',
              quantity: quantity,
              stockBefore: Value(batch.stockQuantity),
              stockAfter: Value(batch.stockQuantity - quantity),
              batchId: Value(batchId),
              batchNumber: Value(batch.batchNumber),
              date: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          );

      return true;
    });
  }

  // ==========================================================================
  // PRESCRIPTION LINKING
  // ==========================================================================

  // Future methods for Rx linking can be added here
}
