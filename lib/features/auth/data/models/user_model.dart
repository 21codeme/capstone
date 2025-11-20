class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final bool isStudent;                 // student = true, instructor = false
  final String accountStatus;           // 'active' | 'inactive'
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? lastName;
  final int? age;
  final String? gender;
  final String profilePicture;
  final String phoneNumber;
  final List<String> enrolledCourses;
  final Map<String, dynamic> preferences;
  final String? course;
  final String? year;
  final String? section;
  // Legacy fields removed: assignedSections, assignedYearLevels, assignedCourses
  final List<String>? assignedYearSectionCourses; // For instructors - combined year-section-course assignments

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.isStudent,
    this.accountStatus = 'active',
    required this.createdAt,
    this.lastLogin,
    this.lastName,
    this.age,
    this.gender,
    this.profilePicture = '',
    this.phoneNumber = '',
    this.enrolledCourses = const [],
    this.preferences = const {},
    this.course,
    this.year,
    this.section,
    this.assignedYearSectionCourses,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    bool isStudent;
    if (map.containsKey('isStudent')) {
      isStudent = map['isStudent'] == true;
    } else if (map.containsKey('role')) {
      isStudent = (map['role'] as String?) == 'student';
    } else {
      isStudent = true;
    }

    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      final s = v.toString();
      try {
        // Firestore Timestamp toString contains "seconds=..."
        final m = RegExp(r'seconds=(\d+)').firstMatch(s);
        if (m != null) return DateTime.fromMillisecondsSinceEpoch(int.parse(m.group(1)!) * 1000);
        return DateTime.parse(s);
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? _toDateOrNull(dynamic v) {
      if (v == null) return null;
      try {
        final s = v.toString();
        final m = RegExp(r'seconds=(\d+)').firstMatch(s);
        if (m != null) return DateTime.fromMillisecondsSinceEpoch(int.parse(m.group(1)!) * 1000);
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return UserModel(
      uid: (map['uid'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      fullName: (map['fullName'] ?? '') as String,
      isStudent: isStudent,
      accountStatus: (map['accountStatus'] ?? 'active') as String,
      createdAt: _toDate(map['createdAt']),
      lastLogin: _toDateOrNull(map['lastLogin']),
      lastName: map['lastName'] as String?,
      age: (map['age'] as num?)?.toInt(),
      gender: map['gender'] as String?,
      profilePicture: (map['profilePicture'] ?? '') as String,
      phoneNumber: (map['phoneNumber'] ?? '') as String,
      enrolledCourses: List<String>.from(map['enrolledCourses'] ?? const []),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? const {}),
      course: map['course'] as String?,
      year: map['year'] as String?,
      section: map['section'] as String?,
      // Removed legacy fields: assignedSections, assignedYearLevels, assignedCourses
      assignedYearSectionCourses: map['assignedYearSectionCourses'] != null ? List<String>.from(map['assignedYearSectionCourses']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'isStudent': isStudent,
        'role': isStudent ? 'student' : 'instructor', // back-compat
        'accountStatus': accountStatus,
        'createdAt': createdAt.toIso8601String(),
        if (lastLogin != null) 'lastLogin': lastLogin!.toIso8601String(),
        if (lastName != null) 'lastName': lastName,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        'profilePicture': profilePicture,
        'phoneNumber': phoneNumber,
        'enrolledCourses': enrolledCourses,
        'preferences': preferences,
        if (course != null) 'course': course,
        if (year != null) 'year': year,
        if (section != null) 'section': section,
        // Removed legacy fields from output
        if (assignedYearSectionCourses != null) 'assignedYearSectionCourses': assignedYearSectionCourses,
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    bool? isStudent,
    String? accountStatus,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? lastName,
    int? age,
    String? gender,
    String? profilePicture,
    String? phoneNumber,
    List<String>? enrolledCourses,
    Map<String, dynamic>? preferences,
    String? course,
    String? year,
    String? section,
    // Removed legacy fields from copyWith signature
    List<String>? assignedYearSectionCourses,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isStudent: isStudent ?? this.isStudent,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      profilePicture: profilePicture ?? this.profilePicture,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      preferences: preferences ?? this.preferences,
      course: course ?? this.course,
      year: year ?? this.year,
      section: section ?? this.section,
      // Removed legacy fields assignment
      assignedYearSectionCourses: assignedYearSectionCourses ?? this.assignedYearSectionCourses,
    );
  }
}
