class PatientModel {
  String id;
  String name;
  String? phone;
  int? age;
  String? gender;
  String? bloodGroup;
  String? address;
  String? qrToken;
  String? chronicConditions;
  String? allergies;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSynced;

  PatientModel({
    required this.id,
    required this.name,
    this.phone,
    this.age,
    this.gender,
    this.bloodGroup,
    this.address,
    this.qrToken,
    this.chronicConditions,
    this.allergies,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      age: map['age'],
      gender: map['gender'],
      bloodGroup: map['bloodGroup'],
      address: map['address'],
      qrToken: map['qrToken'],
      chronicConditions: map['chronicConditions'],
      allergies: map['allergies'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      isSynced: map['isSynced'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'age': age,
        'gender': gender,
        'bloodGroup': bloodGroup,
        'address': address,
        'qrToken': qrToken,
        'chronicConditions': chronicConditions,
        'allergies': allergies,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isSynced': isSynced,
      };

  PatientModel copyWith({
    String? id,
    String? name,
    String? phone,
    int? age,
    String? gender,
    String? bloodGroup,
    String? address,
    String? qrToken,
    String? chronicConditions,
    String? allergies,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      qrToken: qrToken ?? this.qrToken,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      allergies: allergies ?? this.allergies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
