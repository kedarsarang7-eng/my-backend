import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

class DoctorDashboardRepository {
  final AppDatabase _db;

  DoctorDashboardRepository(this._db);

  /// Get Patient Statistics (Total, New, Returning, Inactive)
  Future<Map<String, int>> getPatientStats(String doctorId) async {
    // In a real multi-tenant system, we filter by doctor/clinic.
    // Assuming linked patients or all patients for now if doctorId is generic or owner.

    // Total Patients
    final totalPatients = await _db.select(_db.patients).get();
    final totalCount = totalPatients.length;

    // New Patients (Joined in last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final newPatientsCount = totalPatients
        .where((p) => p.createdAt.isAfter(thirtyDaysAgo))
        .length;

    // Returning Patients (More than 1 visit)
    // We need to check visits count.
    // Optimization: Join with Visits table.
    final returningPatientsCount = await _db
        .customSelect(
          'SELECT COUNT(DISTINCT patient_id) as count FROM visits WHERE doctor_id = ?',
          variables: [Variable.withString(doctorId)],
        )
        .map((row) => row.read<int>('count'))
        .getSingle();

    // Inactive Patients (No visit in last 6 months)
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    // This is a bit complex sql, simplifying for MVP as total - active
    // Defining "Active" as visited in last 6 months.
    final activePatientsCount = await _db
        .customSelect(
          'SELECT COUNT(DISTINCT patient_id) as count FROM visits WHERE doctor_id = ? AND visit_date > ?',
          variables: [
            Variable.withString(doctorId),
            Variable.withDateTime(sixMonthsAgo),
          ],
        )
        .map((row) => row.read<int>('count'))
        .getSingle();

    final inactiveCount = totalCount - activePatientsCount;

    return {
      'total': totalCount,
      'new': newPatientsCount,
      'returning': returningPatientsCount,
      'inactive': inactiveCount < 0 ? 0 : inactiveCount,
    };
  }

  /// Get Today's Appointments with Status
  Stream<List<AppointmentEntity>> watchDailyAppointments(
    String doctorId,
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (_db.select(_db.appointments)
          ..where(
            (t) =>
                t.doctorId.equals(doctorId) &
                t.scheduledTime.isBiggerOrEqualValue(startOfDay) &
                t.scheduledTime.isSmallerThanValue(endOfDay),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledTime)]))
        .watch();
  }

  /// Get Weekly Patient Analytics (Mon-Sun)
  Future<Map<String, int>> getWeeklyAnalytics(String doctorId) async {
    // Last 7 days distribution
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));

    final visits =
        await (_db.select(_db.visits)..where(
              (t) =>
                  t.doctorId.equals(doctorId) &
                  t.visitDate.isBiggerOrEqualValue(start),
            ))
            .get();

    // Group by day name
    final Map<String, int> distribution = {};
    // Initialize
    for (int i = 0; i < 7; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      // Use standard weekday names or specialized logic
      distribution[day.weekday.toString()] = 0;
    }

    for (var visit in visits) {
      final key = visit.visitDate.weekday.toString();
      distribution[key] = (distribution[key] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get Smart Insights (Avg Consultation Time, Workload, Common Conditions)
  Future<Map<String, String>> getSmartInsights(String doctorId) async {
    // 1. Average Consultation Time
    // Logic: Average duration of completed appointments or visits
    // Simplified: "15 mins" (Placeholder for complex logic)

    // 2. Workload
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final upcomingAppointments =
        await (_db.select(_db.appointments)..where(
              (t) =>
                  t.doctorId.equals(doctorId) &
                  t.scheduledTime.isBiggerOrEqualValue(startOfDay) &
                  t.status.equals('SCHEDULED'),
            ))
            .get();

    String workload = 'Normal';
    if (upcomingAppointments.length > 20) workload = 'Overloaded';
    if (upcomingAppointments.length < 5) workload = 'Light';

    // 3. Common Disease
    String commonCondition = 'None';
    final diagnosisCounts = await _db
        .customSelect(
          'SELECT diagnosis, COUNT(*) as c FROM visits WHERE doctor_id = ? AND diagnosis IS NOT NULL GROUP BY diagnosis ORDER BY c DESC LIMIT 1',
          variables: [Variable.withString(doctorId)],
        )
        .getSingleOrNull();

    if (diagnosisCounts != null) {
      commonCondition = diagnosisCounts.read<String>('diagnosis');
    }

    return {
      'avgTime': '15 mins', // Requires duration tracking in Visits table
      'workload': workload,
      'common': commonCondition,
    };
  }

  /// Get Monthly Patient Analytics (Start to End of Current Year)
  Future<Map<String, int>> getMonthlyAnalytics(String doctorId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);

    final visits =
        await (_db.select(_db.visits)..where(
              (t) =>
                  t.doctorId.equals(doctorId) &
                  t.visitDate.isBiggerOrEqualValue(startOfYear),
            ))
            .get();

    final Map<String, int> distribution = {};

    // Initialize months 1-12
    for (int i = 1; i <= 12; i++) {
      distribution[i.toString()] = 0;
    }

    for (var visit in visits) {
      final month = visit.visitDate.month.toString();
      distribution[month] = (distribution[month] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get Dashboard Alerts (Emergency, Follow-ups, High Load)
  Future<List<Map<String, dynamic>>> getDashboardAlerts(String doctorId) async {
    final List<Map<String, dynamic>> alerts = [];

    // 1. Emergency/Urgent Appointments
    // Check for 'URGENT' in purpose or notes
    final urgentApps =
        await (_db.select(_db.appointments)..where(
              (t) =>
                  t.doctorId.equals(doctorId) &
                  t.status.equals('SCHEDULED') &
                  (t.purpose.like('%URGENT%') | t.notes.like('%URGENT%')),
            ))
            .get();

    for (var app in urgentApps) {
      alerts.add({
        'type': 'CRITICAL',
        'message': 'Urgent: ${app.purpose ?? "Appt"} at ${app.scheduledTime}',
        'action': 'View',
      });
    }

    // 2. Pending Reports (Placeholder - Requires LabReports table integration)
    // 3. System Alerts
    // alerts.add({
    //   'type': 'INFO',
    //   'message': 'System maintenance scheduled at 2 AM',
    //   'action': 'Dismiss',
    // });

    return alerts;
  }

  Future<PatientEntity?> getPatientDetails(String patientId) async {
    return await (_db.select(
      _db.patients,
    )..where((p) => p.id.equals(patientId))).getSingleOrNull();
  }

  /// Get Revenue Stats (Today, Week, Month)
  Future<Map<String, double>> getRevenueStats(String doctorId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    // Helper to sum revenue since date
    Future<double> sumRevenue(DateTime since) async {
      final query =
          _db.select(_db.bills).join([
            innerJoin(_db.visits, _db.visits.billId.equalsExp(_db.bills.id)),
          ])..where(
            _db.visits.doctorId.equals(doctorId) &
                _db.bills.createdAt.isBiggerOrEqualValue(since),
          );

      final result = await query
          .map((row) => row.readTable(_db.bills).grandTotal)
          .get();

      double total = 0.0;
      for (var val in result) {
        total += val;
      }
      return total;
    }

    return {
      'today': await sumRevenue(todayStart),
      'week': await sumRevenue(weekStart),
      'month': await sumRevenue(monthStart),
    };
  }

  /// Get Monthly Revenue Chart Data
  Future<Map<String, double>> getRevenueChartData(String doctorId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);

    final query =
        _db.select(_db.bills).join([
          innerJoin(_db.visits, _db.visits.billId.equalsExp(_db.bills.id)),
        ])..where(
          _db.visits.doctorId.equals(doctorId) &
              _db.bills.createdAt.isBiggerOrEqualValue(startOfYear),
        );

    final rows = await query.map((row) {
      return {
        'date': row.readTable(_db.bills).createdAt,
        'amount': row.readTable(_db.bills).grandTotal,
      };
    }).get();

    final Map<String, double> distribution = {};
    for (int i = 1; i <= 12; i++) {
      distribution[i.toString()] = 0.0;
    }

    for (var row in rows) {
      final date = row['date'] as DateTime;
      final amount = row['amount'] as double;
      final month = date.month.toString();
      distribution[month] = (distribution[month] ?? 0) + amount;
    }

    return distribution;
  }

  /// Get Visit Counts (Today, Week, Month) for a doctor
  Future<Map<String, int>> getVisitCounts(String doctorId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    Future<int> countVisits(DateTime since) async {
      final result =
          await (_db.select(_db.visits)..where(
                (t) =>
                    t.doctorId.equals(doctorId) &
                    t.visitDate.isBiggerOrEqualValue(since),
              ))
              .get();
      return result.length;
    }

    return {
      'today': await countVisits(todayStart),
      'week': await countVisits(weekStart),
      'month': await countVisits(monthStart),
    };
  }
}
