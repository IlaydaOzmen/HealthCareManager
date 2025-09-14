class Doctor {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String specialization;
  final String licenseNumber;
  final String phone;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Doctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.specialization,
    required this.licenseNumber,
    required this.phone,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'specialization': specialization,
      'licenseNumber': licenseNumber,
      'phone': phone,
      'imagePath': imagePath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      specialization: map['specialization'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      phone: map['phone'] ?? '',
      imagePath: map['imagePath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isActive: (map['isActive'] ?? 1) == 1,
    );
  }

  Doctor copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? specialization,
    String? licenseNumber,
    String? phone,
    String? imagePath,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Doctor(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      specialization: specialization ?? this.specialization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      phone: phone ?? this.phone,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Doctor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
