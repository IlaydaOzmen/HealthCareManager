class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String tcNumber;
  final int age;
  final String gender;
  final String phone;
  final String email;
  final String address;
  final String diagnosis;
  final String bloodType;
  final double? height;
  final double? weight;
  final bool hasChronicDisease;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? allergies;
  final String? medications;
  final String? notes;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? doctorName;
  final String? insuranceNumber;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.tcNumber,
    required this.age,
    required this.gender,
    required this.phone,
    this.email = '',
    this.address = '',
    this.diagnosis = '',
    this.bloodType = '',
    this.height,
    this.weight,
    required this.hasChronicDisease,
    this.emergencyContact,
    this.emergencyPhone,
    this.allergies,
    this.medications,
    this.notes,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.doctorName,
    this.insuranceNumber,
  });

  String get fullName => '$firstName $lastName';

  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      double heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Bilinmiyor';

    if (bmiValue < 18.5) return 'Zayıf';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'tcNumber': tcNumber,
      'age': age,
      'gender': gender,
      'phone': phone,
      'email': email,
      'address': address,
      'diagnosis': diagnosis,
      'bloodType': bloodType,
      'height': height,
      'weight': weight,
      'hasChronicDisease': hasChronicDisease ? 1 : 0,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'allergies': allergies,
      'medications': medications,
      'notes': notes,
      'imagePath': imagePath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
      'doctorName': doctorName,
      'insuranceNumber': insuranceNumber,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      tcNumber: map['tcNumber'] ?? '',
      age: map['age']?.toInt() ?? 0,
      gender: map['gender'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      bloodType: map['bloodType'] ?? '',
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      hasChronicDisease:
          (map['hasChronicDisease'] == 1 || map['hasChronicDisease'] == true)
              ? true
              : false,
      emergencyContact: map['emergencyContact'],
      emergencyPhone: map['emergencyPhone'],
      allergies: map['allergies'],
      medications: map['medications'],
      notes: map['notes'],
      imagePath: map['imagePath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isActive: (map['isActive'] ?? 1) == 1,
      doctorName: map['doctorName'],
      insuranceNumber: map['insuranceNumber'],
    );
  }

  Patient copyWith({
    String? firstName,
    String? lastName,
    String? tcNumber,
    int? age,
    String? gender,
    String? phone,
    String? email,
    String? address,
    String? diagnosis,
    String? bloodType,
    double? height,
    double? weight,
    bool? hasChronicDisease,
    String? emergencyContact,
    String? emergencyPhone,
    String? allergies,
    String? medications,
    String? notes,
    String? imagePath,
    DateTime? updatedAt,
    bool? isActive,
    String? doctorName,
    String? insuranceNumber,
  }) {
    return Patient(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      tcNumber: tcNumber ?? this.tcNumber,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      diagnosis: diagnosis ?? this.diagnosis,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      hasChronicDisease: hasChronicDisease ?? this.hasChronicDisease,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
      doctorName: doctorName ?? this.doctorName,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Patient && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
