import 'dart:convert' as json_convert;
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_queue_state_machine.dart';
import '../../models/prescription_model.dart';
import 'package:uuid/uuid.dart';

class PrescriptionRepository {
  final AppDatabase _db;
  final SyncManager _syncManager;

  PrescriptionRepository({
    required AppDatabase db,
    required SyncManager syncManager,
  }) : _db = db,
       _syncManager = syncManager;

  /// Create Prescription
  Future<void> createPrescription(PrescriptionModel prescription) async {
    try {
      await _db.transaction(() async {
        // 1. Insert Header
        await _db
            .into(_db.prescriptions)
            .insert(
              PrescriptionsCompanion.insert(
                id: prescription.id,
                userId: 'SYSTEM', // Context required
                visitId: prescription.visitId,
                patientId: prescription.patientId,
                doctorId: Value(prescription.doctorId),
                date: prescription.date,
                medicinesJson: prescription.medicinesJson,
                advice: Value(prescription.advice),
                createdAt: prescription.createdAt,
                updatedAt: prescription.updatedAt,
                isSynced: const Value(false),
              ),
            );

        // 2. Insert Items (Batch)
        for (var item in prescription.items) {
          await _db
              .into(_db.prescriptionItems)
              .insert(
                PrescriptionItemsCompanion.insert(
                  id: item.id.isNotEmpty ? item.id : const Uuid().v4(),
                  prescriptionId: prescription.id,
                  medicineName: item.medicineName,
                  dosage: Value(item.dosage),
                  frequency: Value(item.frequency),
                  duration: Value(item.duration),
                  instructions: Value(item.instructions),
                ),
              );
        }
      });

      // 3. Queue Sync
      await _syncManager.enqueue(
        SyncQueueItem.create(
          userId: 'SYSTEM',
          operationType: SyncOperationType.create,
          targetCollection: 'prescriptions',
          documentId: prescription.id,
          payload: prescription.toMap(),
          priority: 1,
        ),
      );
    } catch (e, stack) {
      ErrorHandler.handle(
        e,
        stackTrace: stack,
        userMessage: 'Failed to create prescription',
      );
      rethrow;
    }
  }

  /// Watch Prescriptions for Patient
  Stream<List<PrescriptionModel>> watchPrescriptionsForPatient(
    String patientId,
  ) {
    return (_db.select(_db.prescriptions)
          ..where((t) => t.patientId.equals(patientId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch()
        .map((rows) => rows.map((row) => _mapToModel(row)).toList());
  }

  /// Get Recent Prescriptions for Doctor (Dashboard/List)
  Future<List<PrescriptionModel>> getRecentPrescriptions(
    String doctorId,
  ) async {
    // If doctorId is SYSTEM/Admin, might return all, otherwise filter
    // For now, simpler query
    final rows =
        await (_db.select(_db.prescriptions)
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(50))
            .get();

    return rows.map((row) => _mapToModel(row)).toList();
  }

  /// Get Prescription by ID
  Future<PrescriptionModel?> getPrescriptionById(String id) async {
    final row = await (_db.select(
      _db.prescriptions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (row == null) return null;
    return _mapToModel(row);
  }

  PrescriptionModel _mapToModel(PrescriptionEntity row) {
    List<PrescriptionItemModel> items = [];
    try {
      if (row.medicinesJson.isNotEmpty) {
        final List<dynamic> jsonList = json_convert.jsonDecode(
          row.medicinesJson,
        );
        items = jsonList.map((e) => PrescriptionItemModel.fromMap(e)).toList();
      }
    } catch (e) {
      // Ignore parse error
    }

    return PrescriptionModel(
      id: row.id,
      doctorId: row.doctorId ?? '',
      patientId: row.patientId,
      visitId: row.visitId,
      date: row.date,
      advice: row.advice,
      items: items,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
