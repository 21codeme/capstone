enum UserType { student, instructor, admin }

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserType userType;
  final String? profilePictureUrl;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final DateTime? lastLogin;
  final bool emailVerified;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.profilePictureUrl,
    this.dateOfBirth,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.lastLogin,
    required this.emailVerified,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == json['user_type'],
        orElse: () => UserType.student,
      ),
      profilePictureUrl: json['profile_picture_url'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      phoneNumber: json['phone_number'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      emailVerified: json['email_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType.toString().split('.').last,
      'profile_picture_url': profilePictureUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'email_verified': emailVerified,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    UserType? userType,
    String? profilePictureUrl,
    DateTime? dateOfBirth,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DateTime? lastLogin,
    bool? emailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userType: userType ?? this.userType,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, fullName: $fullName, userType: $userType}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class UserRegistrationData {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final UserType userType;
  final String? phoneNumber;
  final DateTime? dateOfBirth;

  UserRegistrationData({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.phoneNumber,
    this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType.toString().split('.').last,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth!.toIso8601String(),
    };
  }
}

class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

class Student extends User {
  final String studentId;
  final String course;
  final int yearLevel;
  final String section;
  final DateTime enrollmentDate;
  final DateTime? graduationDate;
  final String academicStatus;

  Student({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    super.profilePictureUrl,
    super.dateOfBirth,
    super.phoneNumber,
    required super.createdAt,
    required super.updatedAt,
    required super.isActive,
    super.lastLogin,
    required super.emailVerified,
    required this.studentId,
    required this.course,
    required this.yearLevel,
    required this.section,
    required this.enrollmentDate,
    this.graduationDate,
    required this.academicStatus,
  }) : super(userType: UserType.student);

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePictureUrl: json['profile_picture_url'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      phoneNumber: json['phone_number'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      emailVerified: json['email_verified'] ?? false,
      studentId: json['student_id'],
      course: json['course'],
      yearLevel: json['year_level'],
      section: json['section'],
      enrollmentDate: DateTime.parse(json['enrollment_date']),
      graduationDate: json['graduation_date'] != null 
          ? DateTime.parse(json['graduation_date']) 
          : null,
      academicStatus: json['academic_status'] ?? 'active',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'student_id': studentId,
      'course': course,
      'year_level': yearLevel,
      'section': section,
      'enrollment_date': enrollmentDate.toIso8601String(),
      if (graduationDate != null) 'graduation_date': graduationDate!.toIso8601String(),
      'academic_status': academicStatus,
    };
  }
}

class Instructor extends User {
  final String instructorId;
  final String department;
  final String specialization;
  final List<String> qualifications;
  final DateTime hireDate;
  final String status;

  Instructor({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    super.profilePictureUrl,
    super.dateOfBirth,
    super.phoneNumber,
    required super.createdAt,
    required super.updatedAt,
    required super.isActive,
    super.lastLogin,
    required super.emailVerified,
    required this.instructorId,
    required this.department,
    required this.specialization,
    required this.qualifications,
    required this.hireDate,
    required this.status,
  }) : super(userType: UserType.instructor);

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePictureUrl: json['profile_picture_url'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      phoneNumber: json['phone_number'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      emailVerified: json['email_verified'] ?? false,
      instructorId: json['instructor_id'],
      department: json['department'],
      specialization: json['specialization'],
      qualifications: List<String>.from(json['qualifications'] ?? []),
      hireDate: DateTime.parse(json['hire_date']),
      status: json['status'] ?? 'active',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'instructor_id': instructorId,
      'department': department,
      'specialization': specialization,
      'qualifications': qualifications,
      'hire_date': hireDate.toIso8601String(),
      'status': status,
    };
  }
}
