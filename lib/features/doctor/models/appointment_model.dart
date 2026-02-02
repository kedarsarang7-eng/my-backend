enum AppointmentStatus { scheduled, completed, cancelled }

class AppointmentModel {
  String id;
  String doctorId;
  String patientId;
  DateTime scheduledTime;
  AppointmentStatus status;
  String? purpose;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.scheduledTime,
    this.status = AppointmentStatus.scheduled,
    this.purpose,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] ?? '',
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      scheduledTime:
          DateTime.tryParse(map['scheduledTime'] ?? '') ?? DateTime.now(),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'scheduled'),
        orElse: () => AppointmentStatus.scheduled,
      ),
      purpose: map['purpose'],
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'doctorId': doctorId,
    'patientId': patientId,
    'scheduledTime': scheduledTime.toIso8601String(),
    'status': status.name,
    'purpose': purpose,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  AppointmentModel copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    DateTime? scheduledTime,
    AppointmentStatus? status,
    String? purpose,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
