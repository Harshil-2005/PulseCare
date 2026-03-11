class User {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String fullName;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final int age;
  final String gender;
  final String role;
  final String? avatarPath;

  User({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.fullName,
    String? firstName,
    String? lastName,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    required this.age,
    required this.gender,
    this.role = 'patient',
    this.avatarPath,
  }) : firstName = _resolveFirstName(fullName, firstName),
       lastName = _resolveLastName(fullName, lastName);

  User copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fullName,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    int? age,
    String? gender,
    String? role,
    String? avatarPath,
  }) {
    final nextFullName = fullName ?? this.fullName;
    return User(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: nextFullName,
      firstName: firstName ?? (fullName != null ? null : this.firstName),
      lastName: lastName ?? (fullName != null ? null : this.lastName),
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      age: age ?? this.age,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      fullName: (json['fullName'] ?? '').toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse((json['age'] ?? '').toString()) ?? 0,
      gender: (json['gender'] ?? '').toString(),
      role: (json['role'] ?? 'patient').toString(),
      avatarPath: json['avatarPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'fullName': fullName,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'age': age,
      'gender': gender,
      'role': role,
      'avatarPath': avatarPath,
    };
  }

  static String _resolveFirstName(String fullName, String? firstName) {
    if (firstName != null && firstName.trim().isNotEmpty) {
      return firstName.trim();
    }
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    return parts.first;
  }

  static String _resolveLastName(String fullName, String? lastName) {
    if (lastName != null && lastName.trim().isNotEmpty) {
      return lastName.trim();
    }
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(' ');
  }
}
