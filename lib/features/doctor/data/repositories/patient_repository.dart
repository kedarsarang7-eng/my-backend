import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_queue_state_machine.dart';
import '../../models/patient_model.dart'; // Corrected Path

class PatientRepository {
  final AppDatabase _db;
  final SyncManager _syncManager;

  PatientRepository({required AppDatabase db, required SyncManager syncManager})
    : _db = db,
      _syncManager = syncManager;

  /// Create a new patient (Offline-First)
  Future<void> createPatient(PatientModel patient) async {
    try {
      // 1. Insert into Local Database
      await _db
          .into(_db.patients)
          .insert(
            PatientsCompanion.insert(
              id: patient.id,
              userId:
                  'SYSTEM', // Default userId as existing table requires it? Wait, let's check definition.
              // Existing table has userId as non-nullable string.
              // We need to provide userId. In real app, it comes from SessionManager.
              name: patient.name,
              phone: Value(patient.phone),
              age: Value(patient.age),
              gender: Value(patient.gender),
              bloodGroup: Value(patient.bloodGroup),
              address: Value(patient.address),
              qrToken: Value(patient.qrToken),
              chronicConditions: Value(patient.chronicConditions),
              allergies: Value(patient.allergies),
              createdAt: patient.createdAt,
              updatedAt: patient.updatedAt,
              isSynced: const Value(false),
            ),
          );

      // 2. Queue for Sync
      await _syncManager.enqueue(
        SyncQueueItem.create(
          userId:
              'SYSTEM', // Or specific Doctor ID if we had context here. Using SYSTEM for now.
          operationType: SyncOperationType.create,
          targetCollection: 'patients',
          documentId: patient.id,
          payload: patient.toMap(),
          priority: 1,
        ),
      );
    } catch (e, stack) {
      ErrorHandler.handle(
        e,
        stackTrace: stack,
        userMessage: 'Failed to create patient',
      );
      rethrow;
    }
  }

  /// Update a patient
  Future<void> updatePatient(PatientModel patient) async {
    try {
      final now = DateTime.now();
      patient.updatedAt = now;

      await (_db.update(
        _db.patients,
      )..where((t) => t.id.equals(patient.id))).write(
        PatientsCompanion(
          name: Value(patient.name),
          phone: Value(patient.phone),
          age: Value(patient.age),
          gender: Value(patient.gender),
          bloodGroup: Value(patient.bloodGroup),
          address: Value(patient.address),
          qrToken: Value(patient.qrToken),
          chronicConditions: Value(patient.chronicConditions),
          allergies: Value(patient.allergies),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );

      await _syncManager.enqueue(
        SyncQueueItem.create(
          userId: 'SYSTEM',
          operationType: SyncOperationType.update,
          targetCollection: 'patients',
          documentId: patient.id,
          payload: patient.toMap(),
          priority: 1,
        ),
      );
    } catch (e, stack) {
      ErrorHandler.handle(
        e,
        stackTrace: stack,
        userMessage: 'Failed to update patient',
      );
      rethrow;
    }
  }

  /// Get patient by ID
  Future<PatientModel?> getPatientById(String id) async {
    final row = await (_db.select(
      _db.patients,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _mapToModel(row);
  }

  /// Search patients by name or phone
  Future<List<PatientModel>> searchPatients(String query) async {
    final rows = await (_db.select(
      _db.patients,
    )..where((t) => t.name.contains(query) | t.phone.contains(query))).get();
    return rows.map((row) => _mapToModel(row)).toList();
  }

  /// Get patient by QR Token
  Future<PatientModel?> getPatientByQrToken(String token) async {
    final row = await (_db.select(
      _db.patients,
    )..where((t) => t.qrToken.equals(token))).getSingleOrNull();
    if (row == null) return null;
    return _mapToModel(row);
  }

  /// Watch all patients
  Stream<List<PatientModel>> watchAllPatients() {
    return (_db.select(_db.patients)..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
        .watch()
        .map((rows) => rows.map((row) => _mapToModel(row)).toList());
  }

  PatientModel _mapToModel(PatientEntity row) {
    return PatientModel(
      id: row.id,
      name: row.name,
      phone: row.phone,
      age: row.age,
      gender: row.gender,
      bloodGroup: row.bloodGroup,
      address: row.address,
      qrToken: row.qrToken,
      chronicConditions: row.chronicConditions,
      allergies: row.allergies,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isSynced: row.isSynced,
    );
  }
}
